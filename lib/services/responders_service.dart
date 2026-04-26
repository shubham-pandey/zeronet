import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response_models.dart';
import 'http_client_service.dart';

class RespondersService extends ChangeNotifier {
  static final RespondersService _instance = RespondersService._internal();

  factory RespondersService() => _instance;
  RespondersService._internal();

  final HttpClientService _httpClient = HttpClientService();
  List<Responder> _responders = [];
  bool _isLoading = false;
  String? _error;

  List<Responder> get responders => _responders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _httpClient.initialize();
  }

  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  Future<bool> getResponders({String? organizationId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final queryParams = <String, String>{};
    if (organizationId != null) {
      queryParams['organizationId'] = organizationId;
    }
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _httpClient.get<RespondersListResponse>(
      ZeroNetApiConfig.responders,
      parser: (json) => RespondersListResponse.fromMap(json),
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _responders = response.data!.responders;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to fetch responders';
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
