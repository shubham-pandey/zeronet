import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'emergency_dispatch_result.dart';

Future<EmergencyDispatchResult> sendEmergencyJson({
  required String endpoint,
  required String body,
  required Map<String, String> headers,
  required int timeoutMs,
}) async {
  final client = HttpClient()
    ..connectionTimeout = Duration(milliseconds: timeoutMs);

  try {
    final request = await client
        .postUrl(Uri.parse(endpoint))
        .timeout(Duration(milliseconds: timeoutMs));
    request.headers.contentType = ContentType.json;
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    request.add(utf8.encode(body));

    final response =
        await request.close().timeout(Duration(milliseconds: timeoutMs));
    final responseBody = await utf8.decoder.bind(response).join();
    final ok = response.statusCode >= 200 && response.statusCode < 300;

    return EmergencyDispatchResult(
      success: ok,
      statusCode: response.statusCode,
      detail: responseBody.isNotEmpty
          ? responseBody
          : response.reasonPhrase,
    );
  } on TimeoutException {
    return const EmergencyDispatchResult(
      success: false,
      detail: 'Request timed out while contacting the emergency endpoint.',
    );
  } on SocketException catch (e) {
    return EmergencyDispatchResult(
      success: false,
      detail: 'Network error: ${e.message}',
    );
  } catch (e) {
    return EmergencyDispatchResult(
      success: false,
      detail: 'Dispatch failed: $e',
    );
  } finally {
    client.close(force: true);
  }
}
