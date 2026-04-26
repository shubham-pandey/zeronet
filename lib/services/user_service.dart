import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_models.dart';
import 'http_client_service.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();

  factory UserService() => _instance;
  UserService._internal();

  final HttpClientService _httpClient = HttpClientService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    _httpClient.initialize();
  }

  void setAuthToken(String token) {
    _httpClient.setAuthToken(token);
  }

  Future<bool> getUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _httpClient.get<User>(
      '${ZeroNetApiConfig.users}/$userId',
      parser: (json) => User.fromMap(json),
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      _currentUser = response.data;
      notifyListeners();
      return true;
    } else {
      _error = response.error ?? 'Failed to fetch user';
      notifyListeners();
      return false;
    }
  }

  Future<User?> getUserById(String userId) async {
    final response = await _httpClient.get<User>(
      '${ZeroNetApiConfig.users}/$userId',
      parser: (json) => User.fromMap(json),
    );

    if (response.success && response.data != null) {
      return response.data;
    }
    return null;
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
