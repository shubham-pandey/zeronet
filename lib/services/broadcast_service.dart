import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response_models.dart';
import 'http_client_service.dart';

class BroadcastService extends ChangeNotifier {
  static final BroadcastService _instance = BroadcastService._internal();

  factory BroadcastService() => _instance;
  BroadcastService._internal();

  final HttpClientService _httpClient = HttpClientService();
  bool _isLoading = false;
  String? _error;
  BroadcastResponse? _lastBroadcast;

  bool get isLoading => _isLoading;
  String? get error => _error;
  BroadcastResponse? get lastBroadcast => _lastBroadcast;

  void initialize() {
    _httpClient.initialize();
  }

  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  Future<BroadcastResponse?> sendTextBroadcast({
    required String organizationId,
    required String message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<BroadcastResponse>(
      '${ZeroNetApiConfig.broadcast}/text',
      parser: (json) => BroadcastResponse.fromMap(json),
      body: {
        'organizationId': organizationId,
        'message': message,
      },
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _lastBroadcast = response.data;
      _error = null;
      notifyListeners();
      return response.data;
    } else {
      _error = response.error ?? 'Failed to send broadcast';
      notifyListeners();
      return null;
    }
  }

  Future<BroadcastResponse?> sendVoiceBroadcast({
    required String organizationId,
    required List<int> audioBytes,
    required String mimeType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Note: For actual file upload, we would need a multipart form implementation
    // This is a placeholder that shows the structure
    try {
      final response = await _httpClient.post<BroadcastResponse>(
        '${ZeroNetApiConfig.broadcast}/voice',
        parser: (json) => BroadcastResponse.fromMap(json),
        body: {
          'organizationId': organizationId,
          'audioData': audioBytes,
          'mimeType': mimeType,
        },
      );

      _isLoading = false;

      if (response.success && response.data != null) {
        _lastBroadcast = response.data;
        _error = null;
        notifyListeners();
        return response.data;
      } else {
        _error = response.error ?? 'Failed to send voice broadcast';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error sending voice broadcast: $e';
      notifyListeners();
      return null;
    }
  }

  Future<BroadcastResponse?> triggerEmergencyBroadcast({
    required String organizationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<BroadcastResponse>(
      '${ZeroNetApiConfig.broadcast}/emergency',
      parser: (json) => BroadcastResponse.fromMap(json),
      body: {'organizationId': organizationId},
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _lastBroadcast = response.data;
      _error = null;
      notifyListeners();
      return response.data;
    } else {
      _error = response.error ?? 'Failed to trigger emergency broadcast';
      notifyListeners();
      return null;
    }
  }

  Future<bool> stopBroadcast({required String broadcastId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<dynamic>(
      '${ZeroNetApiConfig.broadcast}/stop',
      parser: (json) => json,
      body: {'broadcastId': broadcastId},
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to stop broadcast';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _httpClient.dispose();
    super.dispose();
  }
}
