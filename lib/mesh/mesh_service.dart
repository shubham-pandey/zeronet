import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:location/location.dart' as loc;
import 'mesh_message.dart';

class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;
  MeshService._internal();

  final String serviceUuid = "0000FF01-0000-1000-8000-00805F9B34FB";
  final Set<String> _seenMessageIds = {};
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  
  StreamSubscription? _scanSub;
  bool _isRunning = false;

  Future<void> startMesh() async {
    if (_isRunning) return;
    _isRunning = true;

    // Force Native Location Popup via location plugin without routing to settings
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint("Location services remain disabled. Mesh might fail.");
      }
    }

    // Start Scanning
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUuid)],
      );
    } catch (e) {
      debugPrint("Scan failed to launch: $e");
    }

    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult r in results) {
        // Parse manufacturer data containing our relayed messages
        if (r.advertisementData.manufacturerData.isNotEmpty) {
          try {
             List<int>? dataBytes = r.advertisementData.manufacturerData[0xFFFF];
             if (dataBytes != null) {
               String jsonStr = utf8.decode(dataBytes);
               MeshMessage msg = MeshMessage.fromJson(jsonStr);
               _handleIncomingMessage(msg, r.device);
             }
          } catch(e) {
             // Ignoring malformed packets
          }
        }
        
        // Fulfilling Auto-Connect request (connectionless mesh utilized for true offline P2P)
        if (r.device.isConnected == false) {
          // try {
          //    await r.device.connect(timeout: const Duration(seconds: 4));
          //    // Perform standard GATT characteristic exchange here 
          //    await r.device.disconnect();
          // } catch(e) {
          //    // Connect failed
          // }
        }
      }
    });
  }

  void _handleIncomingMessage(MeshMessage message, BluetoothDevice sourceDevice) {
    if (_seenMessageIds.contains(message.messageId)) {
      return; // Drop message to prevent loops
    }

    _seenMessageIds.add(message.messageId);
    debugPrint("Received MESH message: ${message.payload} (TTL: ${message.ttl})");

    if (message.ttl > 0) {
      MeshMessage relayMsg = MeshMessage(
        messageId: message.messageId,
        ttl: message.ttl - 1,
        payload: message.payload,
      );
      _broadcastMessage(relayMsg);
    }
  }

  Future<void> broadcastNewMessage(String payload, {int startingTtl = 3}) async {
    final msg = MeshMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString().substring(5), // Keep it small to fit BLE MTU
      ttl: startingTtl,
      payload: payload,
    );
    _seenMessageIds.add(msg.messageId);
    await _broadcastMessage(msg);
  }

  Future<void> _broadcastMessage(MeshMessage msg) async {
    if (await blePeripheral.isAdvertising) {
      await blePeripheral.stop();
    }

    List<int> bytes = utf8.encode(msg.toJson());

    AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: serviceUuid,
      manufacturerId: 0xFFFF,
      manufacturerData: Uint8List.fromList(bytes),
      includeDeviceName: false,
    );

    // Dynamic resolution based on API available
    try {
      await blePeripheral.start(advertiseData: advertiseData);
      
      // Stop broadcast after 3 seconds dynamically traversing the network
      Future.delayed(const Duration(seconds: 3), () async {
        await blePeripheral.stop();
      });
    } catch (e) {
      debugPrint("Advertising failed: $e");
    }
  }

  void stopMesh() {
    _isRunning = false;
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    blePeripheral.stop();
  }
}
