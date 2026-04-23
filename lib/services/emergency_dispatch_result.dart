class EmergencyDispatchResult {
  final bool success;
  final int? statusCode;
  final String detail;

  const EmergencyDispatchResult({
    required this.success,
    this.statusCode,
    required this.detail,
  });
}
