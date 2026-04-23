class EmergencyDispatchConfig {
  EmergencyDispatchConfig._();

  static const String endpoint = String.fromEnvironment(
    'ZERONET_EMERGENCY_ENDPOINT',
  );
  static const String apiKey = String.fromEnvironment(
    'ZERONET_EMERGENCY_API_KEY',
  );
  static const String authHeader = String.fromEnvironment(
    'ZERONET_EMERGENCY_AUTH_HEADER',
    defaultValue: 'x-api-key',
  );
  static const int timeoutMs = int.fromEnvironment(
    'ZERONET_EMERGENCY_TIMEOUT_MS',
    defaultValue: 8000,
  );

  static bool get isConfigured => endpoint.isNotEmpty;
}
