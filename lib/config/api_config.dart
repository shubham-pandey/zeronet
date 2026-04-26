class ZeroNetApiConfig {
  ZeroNetApiConfig._();

  // Base URL from environment or default to development server
  static const String baseUrl = String.fromEnvironment(
    'ZERONET_API_BASE_URL',
    defaultValue: 'https://zeronet-ufoc.onrender.com/v1',
  );

  // Request timeouts
  static const int connectTimeoutMs = 15000;
  static const int readTimeoutMs = 30000;
  static const int writeTimeoutMs = 30000;

  // Endpoints
  static const String authLogin = '/auth/login';
  static const String authOtpRequest = '/auth/login/otp/request';
  static const String authOtpVerify = '/auth/login/otp/verify';
  static const String authRegisterOrg = '/auth/register/organization';
  static const String authRegisterUser = '/auth/register/user';

  static const String users = '/users';
  static const String dashboardStats = '/dashboard/stats';
  static const String incidents = '/incidents';
  static const String responders = '/responders';
  static const String heatmap = '/heatmap';
  static const String broadcast = '/broadcast';

  static bool get isConfigured => baseUrl.isNotEmpty;
}
