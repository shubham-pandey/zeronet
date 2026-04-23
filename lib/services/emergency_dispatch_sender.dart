import 'emergency_dispatch_result.dart';
import 'emergency_dispatch_sender_stub.dart'
    if (dart.library.io) 'emergency_dispatch_sender_io.dart'
    if (dart.library.html) 'emergency_dispatch_sender_web.dart' as impl;

Future<EmergencyDispatchResult> sendEmergencyJson({
  required String endpoint,
  required String body,
  required Map<String, String> headers,
  required int timeoutMs,
}) {
  return impl.sendEmergencyJson(
    endpoint: endpoint,
    body: body,
    headers: headers,
    timeoutMs: timeoutMs,
  );
}
