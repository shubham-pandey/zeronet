import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool success;

  ApiResponse({
    this.data,
    this.error,
    this.statusCode,
    required this.success,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(data: data, statusCode: statusCode, success: true);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(error: error, statusCode: statusCode, success: false);
  }
}

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();

  factory HttpClientService() => _instance;
  HttpClientService._internal();

  late HttpClient _client;
  String? _authToken;

  void initialize() {
    _client = HttpClient();
    _client.connectionTimeout = const Duration(milliseconds: ZeroNetApiConfig.connectTimeoutMs);
  }

  void setAuthToken(String token) => _authToken = token;

  void clearAuthToken() => _authToken = null;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) parser,
    Map<String, String>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    try {
      final request = await _client
          .getUrl(uri)
          .timeout(const Duration(milliseconds: ZeroNetApiConfig.readTimeoutMs));
      _setHeaders(request);

      final response =
          await request.close().timeout(const Duration(milliseconds: ZeroNetApiConfig.readTimeoutMs));
      final body = await _readResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return ApiResponse.success(parser(json), statusCode: response.statusCode);
      } else {
        final errorMsg = _extractErrorMessage(body, response.statusCode);
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } on SocketException catch (e) {
      return ApiResponse.error('Network error: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) parser,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final request = await _client
          .postUrl(uri)
          .timeout(const Duration(milliseconds: ZeroNetApiConfig.writeTimeoutMs));
      _setHeaders(request, additionalHeaders: headers);

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response =
          await request.close().timeout(const Duration(milliseconds: ZeroNetApiConfig.readTimeoutMs));
      final responseBody = await _readResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return ApiResponse.success(parser(json), statusCode: response.statusCode);
      } else {
        final errorMsg = _extractErrorMessage(responseBody, response.statusCode);
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } on SocketException catch (e) {
      return ApiResponse.error('Network error: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Error: $e');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    required T Function(Map<String, dynamic>) parser,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(endpoint);
    try {
      final request = await _client
          .patchUrl(uri)
          .timeout(const Duration(milliseconds: ZeroNetApiConfig.writeTimeoutMs));
      _setHeaders(request);

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response =
          await request.close().timeout(const Duration(milliseconds: ZeroNetApiConfig.readTimeoutMs));
      final responseBody = await _readResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return ApiResponse.success(parser(json), statusCode: response.statusCode);
      } else {
        final errorMsg = _extractErrorMessage(responseBody, response.statusCode);
        return ApiResponse.error(errorMsg, statusCode: response.statusCode);
      }
    } on TimeoutException {
      return ApiResponse.error('Request timeout');
    } on SocketException catch (e) {
      return ApiResponse.error('Network error: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Error: $e');
    }
  }

  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final url = '${ZeroNetApiConfig.baseUrl}$endpoint';
    final uri = Uri.parse(url);
    return queryParams != null && queryParams.isNotEmpty ? uri.replace(queryParameters: queryParams) : uri;
  }

  void _setHeaders(HttpClientRequest request, {Map<String, String>? additionalHeaders}) {
    request.headers.contentType = ContentType.json;

    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers.set('Authorization', 'Bearer $_authToken');
    }

    additionalHeaders?.forEach((key, value) {
      request.headers.set(key, value);
    });
  }

  Future<String> _readResponse(HttpClientResponse response) async {
    return utf8.decoder.bind(response).join();
  }

  String _extractErrorMessage(String responseBody, int statusCode) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      if (json.containsKey('message')) {
        return json['message'] as String;
      } else if (json.containsKey('error')) {
        return json['error'] as String;
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
    }
    return 'Error $statusCode';
  }

  void dispose() {
    _client.close(force: true);
  }
}
