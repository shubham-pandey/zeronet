import 'emergency_dispatch_result.dart';

Future<EmergencyDispatchResult> sendEmergencyJson({
  required String endpoint,
  required String body,
  required Map<String, String> headers,
  required int timeoutMs,
}) async {
  return const EmergencyDispatchResult(
    success: false,
    detail: 'HTTP dispatch is not supported in this build target.',
  );
}
