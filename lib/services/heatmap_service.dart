import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response_models.dart';
import 'http_client_service.dart';

class HeatmapService extends ChangeNotifier {
  static final HeatmapService _instance = HeatmapService._internal();

  factory HeatmapService() => _instance;
  HeatmapService._internal();

  final HttpClientService _httpClient = HttpClientService();
  HeatmapResponse? _heatmapData;
  bool _isLoading = false;
  String? _error;

  HeatmapResponse? get heatmapData => _heatmapData;
  List<HeatmapPoint> get points => _heatmapData?.points ?? [];
  HeatmapStats? get stats => _heatmapData?.stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _httpClient.initialize();
  }

  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  Future<bool> getHeatmapData({
    String timeRange = 'week',
    String? type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final queryParams = <String, String>{
      'timeRange': timeRange,
    };
    if (type != null) {
      queryParams['type'] = type;
    }

    final response = await _httpClient.get<HeatmapResponse>(
      ZeroNetApiConfig.heatmap,
      parser: (json) => HeatmapResponse.fromMap(json),
      queryParams: queryParams,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _heatmapData = response.data;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to fetch heatmap data';
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
