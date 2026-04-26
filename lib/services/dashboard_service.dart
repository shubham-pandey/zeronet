import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response_models.dart';
import 'http_client_service.dart';

class DashboardService extends ChangeNotifier {
  static final DashboardService _instance = DashboardService._internal();

  factory DashboardService() => _instance;
  DashboardService._internal();

  final HttpClientService _httpClient = HttpClientService();
  DashboardStatsResponse? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStatsResponse? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _httpClient.initialize();
  }

  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  Future<bool> getStats({String? organizationId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final queryParams = organizationId != null ? {'organizationId': organizationId} : null;

    final response = await _httpClient.get<DashboardStatsResponse>(
      ZeroNetApiConfig.dashboardStats,
      parser: (json) => DashboardStatsResponse.fromMap(json),
      queryParams: queryParams,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _stats = response.data;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to fetch dashboard stats';
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
