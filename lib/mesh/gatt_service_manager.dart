import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

/// Manages GATT service advertised by this device
/// Allows other Zeronet devices to connect and communicate directly
class GattServiceManager {
  static const String serviceUuid = "0000FF01-0000-1000-8000-00805F9B34FB";
  static const String commandCharUuid = "0000FF02-0000-1000-8000-00805F9B34FB"; // Write
  static const String responseCharUuid = "0000FF03-0000-1000-8000-00805F9B34FB"; // Notify
  static const String dataCharUuid = "0000FF04-0000-1000-8000-00805F9B34FB"; // Indicate

  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;

  final Map<String, StreamController<List<int>>> _dataControllers = {};
  void Function(String remotePeerId, List<int> data)? _onDataReceived;

  GattServiceManager();

  /// Set callback for when data arrives from a connected peer
  void setDataReceiveCallback(
    void Function(String remotePeerId, List<int> data)? callback,
  ) {
    _onDataReceived = callback;
  }

  /// Start advertising GATT service so other devices can connect
  Future<void> startAdvertising({
    required String localDeviceId,
    required String localDeviceName,
    required bool hasInternet,
  }) async {
    if (_isAdvertising) return;

    try {
      // Build advertisement payload with presence info
      final presenceData = {
        'type': 'presence',
        'deviceId': localDeviceId,
        'deviceName': localDeviceName,
        'hasInternet': hasInternet,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final advertiseData = AdvertiseData(
        serviceUuid: serviceUuid,
        // Include key info in manufacturer data
        manufacturerData: Uint8List.fromList(
          utf8.encode(jsonEncode(presenceData)),
        ),
        includeDeviceName: true,
      );

      await blePeripheral.start(advertiseData: advertiseData);
      _isAdvertising = true;
      debugPrint('[GATT] Advertising service with device: $localDeviceName');
    } catch (e) {
      debugPrint('[GATT] Failed to start advertising: $e');
      rethrow;
    }
  }

  /// Stop advertising but remain connectable
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    try {
      await blePeripheral.stop();
      _isAdvertising = false;
      debugPrint('[GATT] Stopped advertising');
    } catch (e) {
      debugPrint('[GATT] Error stopping advertising: $e');
    }
  }

  /// Simulate receiving data (in actual implementation, 
  /// this would be called by the BLE peripheral callback)
  void simulateDataReceived(String remotePeerId, List<int> data) {
    _onDataReceived?.call(remotePeerId, data);
    debugPrint('[GATT] Received ${data.length} bytes from $remotePeerId');
  }

  Future<void> stop() async {
    await stopAdvertising();
    for (var controller in _dataControllers.values) {
      await controller.close();
    }
    _dataControllers.clear();
  }
}
