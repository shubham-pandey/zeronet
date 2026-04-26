import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response_models.dart';
import 'http_client_service.dart';

class IncidentsService extends ChangeNotifier {
  static final IncidentsService _instance = IncidentsService._internal();

  factory IncidentsService() => _instance;
  IncidentsService._internal();

  final HttpClientService _httpClient = HttpClientService();
  List<ApiIncident> _incidents = [];
  bool _isLoading = false;
  String? _error;

  List<ApiIncident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _httpClient.initialize();
  }

  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  Future<bool> getIncidents({
    String status = 'reported',
    String? type,
    int limit = 10,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final queryParams = <String, String>{
      'status': status,
      'limit': limit.toString(),
      'page': page.toString(),
    };
    if (type != null) {
      queryParams['type'] = type;
    }

    final response = await _httpClient.get<IncidentsListResponse>(
      ZeroNetApiConfig.incidents,
      parser: (json) => IncidentsListResponse.fromMap(json),
      queryParams: queryParams,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _incidents = response.data!.incidents;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to fetch incidents';
      notifyListeners();
      return false;
    }
  }

  Future<ApiIncident?> getIncidentById(String incidentId) async {
    final response = await _httpClient.get<ApiIncident>(
      '${ZeroNetApiConfig.incidents}/$incidentId',
      parser: (json) => ApiIncident.fromMap(json),
    );

    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
  }

  Future<bool> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? responderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final body = {
      'status': status,
      if (responderId != null) 'responderId': responderId,
    };

    final response = await _httpClient.patch<dynamic>(
      '${ZeroNetApiConfig.incidents}/$incidentId/status',
      parser: (json) => json,
      body: body,
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
      await getIncidents();
      return true;
    } else {
      _error = response.error ?? 'Failed to update incident status';
      notifyListeners();
      return false;
    }
  }

  Future<bool> escalateIncident({
    required String incidentId,
    required String severity,
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final body = {
      'severity': severity,
      if (reason != null) 'reason': reason,
    };

    final response = await _httpClient.patch<dynamic>(
      '${ZeroNetApiConfig.incidents}/$incidentId/escalate',
      parser: (json) => json,
      body: body,
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
      await getIncidents();
      return true;
    } else {
      _error = response.error ?? 'Failed to escalate incident';
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignResponder({
    required String incidentId,
    required String responderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<dynamic>(
      '${ZeroNetApiConfig.incidents}/$incidentId/assign',
      parser: (json) => json,
      body: {'responderId': responderId},
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
      await getIncidents();
      return true;
    } else {
      _error = response.error ?? 'Failed to assign responder';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveIncident({
    required String incidentId,
    required String resolvedBy,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final body = {
      'resolvedBy': resolvedBy,
      if (notes != null) 'notes': notes,
    };

    final response = await _httpClient.post<dynamic>(
      '${ZeroNetApiConfig.incidents}/$incidentId/resolve',
      parser: (json) => json,
      body: body,
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
      await getIncidents();
      return true;
    } else {
      _error = response.error ?? 'Failed to resolve incident';
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
