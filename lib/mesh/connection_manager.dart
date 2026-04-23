import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'peer_connection.dart';
import 'mesh_message.dart';

/// Manages active connections to peer devices
/// Handles connection establishment, data exchange, and cleanup
class ConnectionManager {
  static const String commandServiceUuid = "0000FF01-0000-1000-8000-00805F9B34FB";
  static const String commandCharUuid = "0000FF02-0000-1000-8000-00805F9B34FB"; // Write
  static const String responseCharUuid = "0000FF03-0000-1000-8000-00805F9B34FB"; // Notify

  final Map<String, PeerConnection> _activeConnections = {};
  final Map<String, StreamSubscription> _notificationSubs = {};

  void Function(String peerId, List<int> data)? _onDataReceived;
  void Function(String peerId)? _onConnectionLost;

  ConnectionManager();

  /// Set callbacks for data and disconnections
  void setCallbacks({
    void Function(String peerId, List<int> data)? onDataReceived,
    void Function(String peerId)? onConnectionLost,
  }) {
    _onDataReceived = onDataReceived;
    _onConnectionLost = onConnectionLost;
  }

  /// Attempt to connect to a discovered peer
  Future<PeerConnection?> connectToPeer(
    BluetoothDevice device,
    String peerId,
    String peerName,
  ) async {
    // Avoid duplicate connections
    if (_activeConnections.containsKey(peerId)) {
      debugPrint('[CONN] Already connected to $peerName');
      return _activeConnections[peerId];
    }

    try {
      debugPrint('[CONN] Connecting to $peerName...');
      
      // Connect to device
      // TODO: Verify License parameter for your flutter_blue_plus version
      // Use dynamic call to avoid strict type checking
      await (device.connect as dynamic)(license: '');
      debugPrint('[CONN] Connected to $peerName, discovering services...');

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      BluetoothService? targetService;
      BluetoothCharacteristic? writeChar;
      BluetoothCharacteristic? readChar;

      for (var service in services) {
        if (service.uuid.str.toLowerCase() == commandServiceUuid.toLowerCase()) {
          targetService = service;
          // Find command and response characteristics
          for (var char in service.characteristics) {
            if (char.uuid.str.toLowerCase() == commandCharUuid.toLowerCase()) {
              writeChar = char;
            } else if (char.uuid.str.toLowerCase() == responseCharUuid.toLowerCase()) {
              readChar = char;
            }
          }
          break;
        }
      }

      if (targetService == null || writeChar == null || readChar == null) {
        debugPrint('[CONN] Target service/characteristics not found on $peerName');
        await device.disconnect();
        return null;
      }

      // Create connection object
      final connection = PeerConnection(
        peerId: peerId,
        peerName: peerName,
        device: device,
        writeCharacteristic: writeChar,
        readCharacteristic: readChar,
      );

      // Send handshake message
      bool handshakeSuccess = await _performHandshake(connection);
      if (!handshakeSuccess) {
        await device.disconnect();
        return null;
      }

      // Listen for notifications
      if (readChar.isNotifying == false) {
        await readChar.setNotifyValue(true);
      }

      _notificationSubs[peerId] = readChar.onValueReceived.listen(
        (data) => _handlePeerData(peerId, data),
        onError: (e) => _handleConnectionError(peerId),
        onDone: () => _handleConnectionError(peerId),
      );

      connection.markConnected();
      _activeConnections[peerId] = connection;
      debugPrint('[CONN] Successfully connected to $peerName');
      return connection;
    } catch (e) {
      debugPrint('[CONN] Failed to connect to $peerName: $e');
      _onConnectionLost?.call(peerId);
      return null;
    }
  }

  /// Perform handshake with connected peer
  Future<bool> _performHandshake(PeerConnection conn) async {
    try {
      final handshakeMsg = MeshMessage(
        kind: MeshMessageKind.presence,
        messageId: 'hs-${DateTime.now().millisecondsSinceEpoch}',
        ttl: 1,
        payload: 'GATT_HANDSHAKE',
        senderDeviceId: 'local', // Will be actual ID in implementation
        senderName: 'LOCAL',
        senderHasInternet: false,
      );

      await conn.sendData(utf8.encode(handshakeMsg.toJson()));
      debugPrint('[CONN] Sent handshake to ${conn.peerName}');
      return true;
    } catch (e) {
      debugPrint('[CONN] Handshake failed: $e');
      return false;
    }
  }

  /// Handle data received from peer
  void _handlePeerData(String peerId, List<int> data) {
    try {
      debugPrint('[CONN] Received from $peerId: ${data.length} bytes');
      _onDataReceived?.call(peerId, data);
    } catch (e) {
      debugPrint('[CONN] Failed to decode data from $peerId: $e');
    }
  }

  /// Handle connection loss or error
  Future<void> _handleConnectionError(String peerId) async {
    debugPrint('[CONN] Connection lost with $peerId');
    await disconnectPeer(peerId);
    _onConnectionLost?.call(peerId);
  }

  /// Send data to a connected peer
  Future<bool> sendToPeer(String peerId, List<int> data) async {
    final conn = _activeConnections[peerId];
    if (conn == null) {
      debugPrint('[CONN] Not connected to $peerId');
      return false;
    }

    try {
      await conn.sendData(data);
      return true;
    } catch (e) {
      debugPrint('[CONN] Send failed to $peerId: $e');
      await _handleConnectionError(peerId);
      return false;
    }
  }

  /// Get all active connections
  List<PeerConnection> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  /// Check if connected to a peer
  bool isConnectedTo(String peerId) {
    return _activeConnections[peerId]?.isConnected ?? false;
  }

  /// Disconnect from a specific peer
  Future<void> disconnectPeer(String peerId) async {
    final conn = _activeConnections.remove(peerId);
    _notificationSubs.remove(peerId)?.cancel();
    if (conn != null) {
      await conn.disconnect();
      debugPrint('[CONN] Disconnected from ${conn.peerName}');
    }
  }

  /// Disconnect from all peers
  Future<void> disconnectAll() async {
    final peerIds = List<String>.from(_activeConnections.keys);
    for (final peerId in peerIds) {
      await disconnectPeer(peerId);
    }
  }
}
