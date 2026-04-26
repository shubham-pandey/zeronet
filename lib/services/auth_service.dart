import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'http_client_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;
  AuthService._internal();

  final HttpClientService _httpClient = HttpClientService();
  AuthResponse? _currentAuth;
  bool _isLoading = false;
  String? _error;

  AuthResponse? get currentAuth => _currentAuth;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentAuth != null;
  String? get token => _currentAuth?.token;

  void initialize() {
    _httpClient.initialize();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<AuthResponse>(
      ZeroNetApiConfig.authLogin,
      parser: (json) => AuthResponse.fromMap(json),
      body: {'email': email, 'password': password},
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentAuth = response.data;
      _httpClient.setAuthToken(_currentAuth!.token);
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestOtp({required String phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<OtpResponse>(
      ZeroNetApiConfig.authOtpRequest,
      parser: (json) => OtpResponse.fromMap(json),
      body: {'phone': phone},
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
    } else {
      _error = response.error ?? 'Failed to send OTP';
    }

    notifyListeners();
    return response.success;
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<AuthResponse>(
      ZeroNetApiConfig.authOtpVerify,
      parser: (json) => AuthResponse.fromMap(json),
      body: {'phone': phone, 'otp': otp},
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentAuth = response.data;
      _httpClient.setAuthToken(_currentAuth!.token);
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'OTP verification failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerOrganization({
    required String orgName,
    required String orgType,
    required String registrationId,
    required String email,
    required String phone,
    required String address,
    required String contactPerson,
    required bool is24Hours,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<AuthResponse>(
      ZeroNetApiConfig.authRegisterOrg,
      parser: (json) => AuthResponse.fromMap(json),
      body: {
        'orgName': orgName,
        'orgType': orgType,
        'registrationId': registrationId,
        'email': email,
        'phone': phone,
        'address': address,
        'contactPerson': contactPerson,
        'is24Hours': is24Hours,
        'coords': {'lat': latitude, 'lng': longitude},
      },
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentAuth = response.data;
      _httpClient.setAuthToken(_currentAuth!.token);
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Organization registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerUser({
    required String email,
    required String name,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.post<dynamic>(
      ZeroNetApiConfig.authRegisterUser,
      parser: (json) => json,
      body: {'email': email, 'name': name, 'password': password},
    );

    _isLoading = false;

    if (response.success) {
      _error = null;
    } else {
      _error = response.error ?? 'User registration failed';
    }

    notifyListeners();
    return response.success;
  }

  void logout() {
    _currentAuth = null;
    _httpClient.clearAuthToken();
    _error = null;
    notifyListeners();
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
