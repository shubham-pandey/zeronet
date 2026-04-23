import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents an active bidirectional connection to a peer device
class PeerConnection {
  final String peerId;
  final String peerName;
  final BluetoothDevice device;
  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic readCharacteristic;
  
  bool _isConnected = false;
  DateTime _connectedAt = DateTime.now();
  
  bool get isConnected => _isConnected;
  DateTime get connectedAt => _connectedAt;
  
  PeerConnection({
    required this.peerId,
    required this.peerName,
    required this.device,
    required this.writeCharacteristic,
    required this.readCharacteristic,
  });

  /// Mark connection as established after handshake
  void markConnected() {
    _isConnected = true;
    _connectedAt = DateTime.now();
  }

  /// Send data to peer (up to 512 bytes recommended for BLE)
  Future<void> sendData(List<int> data) async {
    if (!_isConnected) {
      throw Exception('Not connected to $peerName');
    }
    try {
      await writeCharacteristic.write(data, withoutResponse: false);
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  /// Disconnect from peer
  Future<void> disconnect() async {
    _isConnected = false;
    try {
      await device.disconnect();
    } catch (e) {
      // Already disconnected
    }
  }

  @override
  String toString() => 'PeerConnection($peerName, connected: $_isConnected)';
}
