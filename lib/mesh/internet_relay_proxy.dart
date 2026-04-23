import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'connection_manager.dart';

/// Manages internet connection sharing between peers
/// Allows a device without direct internet to proxy requests through a peer
class InternetRelayProxy {
  final ConnectionManager connectionManager;

  // For device with internet: serves requests from peers
  final Map<String, StreamController<Map<String, dynamic>>> _peerRequests = {};

  // For device without internet: pending requests awaiting responses
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  InternetRelayProxy({required this.connectionManager}) {
    connectionManager.setCallbacks(
      onDataReceived: _handleIncomingData,
    );
  }

  /// Register this device as having internet available for relay
  void registerAsInternetRelay() {
    debugPrint('[RELAY] This device registered as internet relay');
  }

  /// Request relay of HTTP request through a peer with internet
  /// Example: Device B (no internet) asks Device A (has internet) to make HTTP request
  Future<Map<String, dynamic>> relayHttpRequest(
    String targetPeerId,
    String method,
    String url,
    Map<String, String>? headers,
    String? body,
  ) async {
    final requestId = 'req-${DateTime.now().microsecondsSinceEpoch}';

    final requestPayload = {
      'type': 'http_request',
      'requestId': requestId,
      'method': method,
      'url': url,
      'headers': headers ?? {},
      'body': body,
    };

    // Wait for response (with timeout)
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    final timeoutTimer = Timer(const Duration(seconds: 30), () {
      _pendingRequests.remove(requestId);
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Relay request timeout'));
      }
    });

    try {
      // Send request to peer
      final success = await connectionManager.sendToPeer(
        targetPeerId,
        utf8.encode(jsonEncode(requestPayload)),
      );

      if (!success) {
        throw Exception('Failed to send relay request to $targetPeerId');
      }

      // Wait for response
      final response = await completer.future;
      timeoutTimer.cancel();
      return response;
    } catch (e) {
      timeoutTimer.cancel();
      _pendingRequests.remove(requestId);
      debugPrint('[RELAY] Request relay failed: $e');
      rethrow;
    }
  }

  /// Handle incoming data - route to appropriate handler
  void _handleIncomingData(String peerId, List<int> data) {
    try {
      final jsonStr = utf8.decode(data);
      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
      final type = payload['type'] as String?;

      if (type == 'http_request') {
        _handleHttpRequest(peerId, payload);
      } else if (type == 'http_response') {
        _handleHttpResponse(peerId, payload);
      }
    } catch (e) {
      debugPrint('[RELAY] Error handling incoming data: $e');
    }
  }

  /// Handle HTTP request from a peer (device has internet and processes request)
  void _handleHttpRequest(String peerId, Map<String, dynamic> payload) {
    final requestId = payload['requestId'] as String?;
    final method = payload['method'] as String?;
    final url = payload['url'] as String?;

    if (requestId == null || method == null || url == null) {
      debugPrint('[RELAY] Invalid HTTP request format');
      return;
    }

    // In real implementation, you'd execute the HTTP request here
    // For now, we'll simulate it
    _processHttpRequest(peerId, requestId, method, url, payload);
  }

  /// Process HTTP request and send response back
  Future<void> _processHttpRequest(
    String peerId,
    String requestId,
    String method,
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      // TODO: Implement actual HTTP request here
      // For now, simulate a successful response
      debugPrint('[RELAY] Processing $method request to $url from $peerId');

      final response = {
        'type': 'http_response',
        'requestId': requestId,
        'statusCode': 200,
        'headers': {'content-type': 'application/json'},
        'body': jsonEncode({'success': true, 'message': 'Relayed through ${peerId}'}),
      };

      await connectionManager.sendToPeer(
        peerId,
        utf8.encode(jsonEncode(response)),
      );
    } catch (e) {
      debugPrint('[RELAY] Failed to process request: $e');

      // Send error response
      try {
        await connectionManager.sendToPeer(
          peerId,
          utf8.encode(jsonEncode({
            'type': 'http_response',
            'requestId': requestId,
            'statusCode': 500,
            'body': jsonEncode({'error': e.toString()}),
          })),
        );
      } catch (e) {
        debugPrint('[RELAY] Failed to send error response: $e');
      }
    }
  }

  /// Handle HTTP response from a peer
  void _handleHttpResponse(String peerId, Map<String, dynamic> payload) {
    final requestId = payload['requestId'] as String?;
    if (requestId == null) {
      debugPrint('[RELAY] Invalid HTTP response format');
      return;
    }

    final completer = _pendingRequests.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(payload);
      debugPrint('[RELAY] Received response for request $requestId');
    }
  }

  /// Cleanup all pending requests
  Future<void> cleanup() async {
    for (var completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Proxy shutdown'));
      }
    }
    _pendingRequests.clear();
    for (var controller in _peerRequests.values) {
      await controller.close();
    }
    _peerRequests.clear();
  }
}
