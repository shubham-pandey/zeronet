import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:location/location.dart' as loc;
import '../models/peer_node.dart';
import 'mesh_message.dart';
import 'connection_manager.dart';
import 'gatt_service_manager.dart';
import 'internet_relay_proxy.dart';
import 'peer_connection.dart';

class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;
  MeshService._internal();

  final String serviceUuid = "0000FF01-0000-1000-8000-00805F9B34FB";
  final int manufacturerId = 0xFFFF;
  static const int _maxAdvertisementBytes = 180;
  final Set<String> _seenMessageIds = {};
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  final Map<String, PeerNode> _peerRegistry = {};

  // New: GATT connection components
  late final ConnectionManager _connectionManager;
  late final GattServiceManager _gattServiceManager;
  late final InternetRelayProxy _relayProxy;

  StreamSubscription? _scanSub;
  Timer? _presenceTimer;
  bool _isRunning = false;
  String _localDeviceId = 'local-device';
  String _localDeviceName = 'THIS DEVICE';
  bool _hasInternetConnection = false;
  void Function(List<PeerNode>)? _peerUpdateListener;
  Future<bool> Function(String incidentJson)? _incidentRelayHandler;

  /// Initialize managers after construction
  void _initializeManagers() {
    _connectionManager = ConnectionManager();
    _gattServiceManager = GattServiceManager();
    _relayProxy = InternetRelayProxy(connectionManager: _connectionManager);
  }

  void configureLocalNode({
    required String deviceId,
    required String deviceName,
    required bool hasInternetConnection,
  }) {
    _localDeviceId = deviceId;
    _localDeviceName = deviceName;
    _hasInternetConnection = hasInternetConnection;
  }

  void updateLocalInternetAvailability(bool hasInternetConnection) {
    _hasInternetConnection = hasInternetConnection;
    if (_isRunning) {
      unawaited(_broadcastPresence());
    }
  }

  void setPeerUpdateListener(void Function(List<PeerNode>)? listener) {
    _peerUpdateListener = listener;
    if (listener != null) {
      listener(_peerRegistry.values.toList());
    }
  }

  void setIncidentRelayHandler(Future<bool> Function(String incidentJson) handler) {
    _incidentRelayHandler = handler;
  }

  /// Get active direct peer connections
  List<PeerConnection> getDirectConnections() => _connectionManager.getActiveConnections();

  /// Check if directly connected to a peer
  bool isDirectlyConnectedTo(String peerId) => _connectionManager.isConnectedTo(peerId);

  /// Send data directly to a connected peer (bypasses broadcast)
  Future<bool> sendDirectToPeer(String peerId, List<int> data) =>
      _connectionManager.sendToPeer(peerId, data);

  /// Use internet relay proxy to send requests through a peer with internet
  Future<Map<String, dynamic>> relayHttpRequestThroughPeer(
    String targetPeerId,
    String method,
    String url,
    {Map<String, String>? headers, String? body}
  ) => _relayProxy.relayHttpRequest(
    targetPeerId,
    method,
    url,
    headers,
    body,
  );

  /// Register this device as available to relay internet for peers
  void registerAsInternetRelay() => _relayProxy.registerAsInternetRelay();

  Future<void> refreshDiscovery() async {
    if (!_isRunning) {
      await startMesh();
      return;
    }
    try {
      if (!FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.startScan(timeout: const Duration(minutes: 5));
      }
      await _broadcastPresence();
    } catch (e) {
      debugPrint("[MESH SCAN] Refresh failed: $e");
    }
  }

  Future<void> startMesh() async {
    if (_isRunning) {
      await _broadcastPresence();
      return;
    }
    _isRunning = true;

    // Initialize managers on first run
    _initializeManagers();

    // Start GATT service (allows other devices to connect)
    try {
      await _gattServiceManager.startAdvertising(
        localDeviceId: _localDeviceId,
        localDeviceName: _localDeviceName,
        hasInternet: _hasInternetConnection,
      );
      debugPrint("[MESH] GATT service started for direct peer connections");
    } catch (e) {
      debugPrint("[MESH] Failed to start GATT service: $e");
    }

    // Force Native Location Popup via location plugin without routing to settings
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint("Location services remain disabled. Mesh might fail.");
      }
    }

    // Start Scanning - NO service filter to discover all nearby Zeronet devices
    try {
      if (!FlutterBluePlus.isScanningNow) {
        debugPrint("[MESH SCAN] Starting BLE scan (no service filter)...");
        await FlutterBluePlus.startScan(
          timeout: const Duration(minutes: 5),
          // Don't filter by service UUID - some devices may not advertise it correctly
          // We'll manually check for Zeronet presence in the data
        );
        debugPrint("[MESH SCAN] BLE scan started successfully");
      } else {
        debugPrint("[MESH SCAN] Already scanning...");
      }
    } catch (e) {
      debugPrint("[MESH SCAN] ERROR: Scan failed to launch: $e");
    }

    _scanSub = FlutterBluePlus.onScanResults.listen((results) async {
      if (results.isNotEmpty) {
        final zeronetCandidates = results.where((r) => _isLikelyZeronetPeer(r)).toList();
        debugPrint(
          "[MESH SCAN] Found ${results.length} devices (${zeronetCandidates.length} Zeronet candidates)",
        );
        for (var r in zeronetCandidates) {
          debugPrint(
            "[MESH SCAN]   - ${r.device.remoteId} (${r.device.platformName}) rssi:${r.rssi}",
          );
        }
      }
      _updatePeerRegistry(results);
      // Attempt to establish direct GATT connections
      for (ScanResult r in results) {
        _attemptDirectConnection(r);
      }
      for (ScanResult r in results) {
        final message = _decodeMeshMessage(r);
        if (message != null) {
          await _handleIncomingMessage(message, r.device);
        }
      }
    });

    _presenceTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_broadcastPresence()),
    );
    await _broadcastPresence();
  }

  MeshMessage? _decodeMeshMessage(ScanResult result) {
    if (result.advertisementData.manufacturerData.isEmpty) {
      return null;
    }
    final preferredBytes = result.advertisementData.manufacturerData[manufacturerId];
    final candidates = <List<int>>[
      if (preferredBytes != null) preferredBytes,
      ...result.advertisementData.manufacturerData.entries
          .where((entry) => entry.key != manufacturerId)
          .map((entry) => entry.value),
    ];

    for (final bytes in candidates) {
      if (bytes.isEmpty) {
        continue;
      }
      try {
        final decoded = MeshMessage.fromJson(utf8.decode(bytes));
        if (decoded.messageId.isEmpty) {
          continue;
        }
        debugPrint(
          "[MESH DECODE] Successfully decoded message from ${decoded.senderName} (kind: ${decoded.kind.name})",
        );
        return decoded;
      } catch (_) {
        // Try next manufacturer data entry.
      }
    }
    return null;
  }

  bool _hasExpectedServiceUuid(ScanResult result) {
    final expected = serviceUuid.toLowerCase();
    for (final uuid in result.advertisementData.serviceUuids) {
      final normalized = uuid.str.toLowerCase();
      if (normalized == expected || normalized.contains('ff01')) {
        return true;
      }
    }
    return false;
  }

  bool _isLikelyZeronetPeer(ScanResult result, {MeshMessage? decodedMessage}) {
    final hasExpectedService = _hasExpectedServiceUuid(result);
    final hasDecodedMeshMessage = decodedMessage != null;
    final hasZeronetName = result.device.platformName.toLowerCase().contains('zeronet');
    return hasDecodedMeshMessage || hasExpectedService || hasZeronetName;
  }

  void _updatePeerRegistry(List<ScanResult> results) {
    final peers = <String, PeerNode>{};
    int foundZeronetDevices = 0;

    for (final result in results) {
      final meshMessage = _decodeMeshMessage(result);
      if (!_isLikelyZeronetPeer(result, decodedMessage: meshMessage)) {
        continue;
      }

      final rssi = result.rssi;
      PeerStatus status = PeerStatus.online;
      if (rssi < -80) {
        status = PeerStatus.warning;
      }

      int distance = (rssi.abs() - 30).clamp(1, 100);

      int bars = 1;
      if (rssi > -60) {
        bars = 4;
      } else if (rssi > -75) {
        bars = 3;
      } else if (rssi > -90) {
        bars = 2;
      }

      final fromPresence = meshMessage?.kind == MeshMessageKind.presence;
      final peerId = fromPresence && meshMessage!.senderDeviceId.isNotEmpty
          ? meshMessage.senderDeviceId
          : result.device.remoteId.toString();

      if (peerId == _localDeviceId) {
        debugPrint("[MESH] Ignoring self (peerId: $peerId)");
        continue;
      }

      final fallbackName = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : 'NODE-${result.device.remoteId.toString().substring(0, 4)}';
      final peerName = fromPresence && meshMessage!.senderName.isNotEmpty
          ? meshMessage.senderName
          : fallbackName;
      final canRelayToInternet = fromPresence
          ? meshMessage!.senderHasInternet
          : status == PeerStatus.online && bars >= 3;

      foundZeronetDevices++;
      debugPrint(
        "[MESH PEER] Found: $peerName (id: $peerId, rssi: $rssi, bars: $bars, internet: $canRelayToInternet)",
      );

      peers[peerId] = PeerNode(
        id: peerId,
        name: peerName.toUpperCase(),
        status: status,
        lastSeen: fromPresence
            ? (canRelayToInternet ? 'Mesh beacon • internet ready' : 'Mesh beacon • offline relay')
            : 'Just now',
        distanceMeters: distance,
        signalBars: bars,
        canRelayToInternet: canRelayToInternet,
        capabilityLabel: canRelayToInternet ? 'INTERNET RELAY' : 'BLE RELAY',
      );
    }

    _peerRegistry
      ..clear()
      ..addAll(peers);
    debugPrint(
      "[MESH REGISTRY] Updated with ${peers.length} total peers (${foundZeronetDevices} with Zeronet presence)",
    );
    _peerUpdateListener?.call(_peerRegistry.values.toList());
  }

  /// Attempt to establish direct GATT connection to a discovered peer
  void _attemptDirectConnection(ScanResult result) {
    if (!_isLikelyZeronetPeer(result)) {
      return;
    }
    // Only try connecting to strong signals (save battery)
    if (result.rssi > -80) {
      final peerId = result.device.remoteId.toString();
      final peerName = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : 'PEER-${peerId.substring(0, 4)}';

      // Don't try to connect if already connected
      if (!_connectionManager.isConnectedTo(peerId)) {
        // Non-blocking connection attempt
        _connectionManager.connectToPeer(
          result.device,
          peerId,
          peerName,
        ).then((connection) {
          if (connection != null) {
            debugPrint(
              "[MESH] Direct connection established to ${connection.peerName}",
            );
            // Notify listeners that we have a direct connection
            _peerUpdateListener?.call(_peerRegistry.values.toList());
          }
        }).catchError((e) {
          // Connection failed, ignore and continue with broadcast relay
          debugPrint("[MESH] Direct connection failed: $e");
        });
      }
    }
  }

  Future<void> _handleIncomingMessage(MeshMessage message, BluetoothDevice sourceDevice) async {
    // The scanning device is available here for future connection-based handshakes.
    if (sourceDevice.remoteId.str.isEmpty) {
      return;
    }
    if (message.senderDeviceId == _localDeviceId) {
      return;
    }
    if (message.kind == MeshMessageKind.presence) {
      return;
    }
    if (_seenMessageIds.contains(message.messageId)) {
      return;
    }

    _seenMessageIds.add(message.messageId);
    debugPrint("Received emergency MESH message from ${message.senderName} (TTL: ${message.ttl})");

    bool forwarded = false;
    if (_hasInternetConnection && _incidentRelayHandler != null) {
      forwarded = await _incidentRelayHandler!(message.payload);
      if (forwarded) {
        debugPrint("Emergency payload forwarded using local internet.");
      }
    }

    if (!forwarded && message.ttl > 0) {
      await _broadcastMessage(message.copyWith(ttl: message.ttl - 1));
    }
  }

  Future<bool> broadcastEmergencyPayload(String incidentJson, {int startingTtl = 3}) async {
    final compactPayload = _compactEmergencyPayload(incidentJson);
    final shortDeviceId = _localDeviceId.length > 6
        ? _localDeviceId.substring(_localDeviceId.length - 6)
        : _localDeviceId;
    final message = MeshMessage(
      kind: MeshMessageKind.emergency,
      messageId: DateTime.now().millisecondsSinceEpoch.toString().substring(5),
      ttl: startingTtl,
      payload: compactPayload,
      senderDeviceId: shortDeviceId,
      senderName: '',
      senderHasInternet: _hasInternetConnection,
      createdAtMillis: 0,
    );
    final fittedMessage = _fitEmergencyMessageToBudget(message);
    _seenMessageIds.add(fittedMessage.messageId);
    return _broadcastMessage(fittedMessage);
  }

  Future<void> _broadcastPresence() async {
    final message = MeshMessage(
      kind: MeshMessageKind.presence,
      messageId: 'presence-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      ttl: 1,
      payload: '',
      senderDeviceId: _localDeviceId,
      senderName: _localDeviceName,
      senderHasInternet: _hasInternetConnection,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint(
      "[MESH BROADCAST] Sending presence: $_localDeviceName (internet: $_hasInternetConnection)",
    );
    await _broadcastMessage(message);
  }

  Future<void> broadcastNewMessage(String payload, {int startingTtl = 3}) async {
    await broadcastEmergencyPayload(payload, startingTtl: startingTtl);
  }

  Future<bool> _broadcastMessage(MeshMessage msg) async {
    List<int> bytes = utf8.encode(msg.toJson());
    if (bytes.length > _maxAdvertisementBytes) {
      debugPrint(
        "[MESH BROADCAST] Dropping message: ${bytes.length} bytes exceeds $_maxAdvertisementBytes byte BLE payload budget",
      );
      return false;
    }

    AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: serviceUuid,
      manufacturerId: manufacturerId,
      manufacturerData: Uint8List.fromList(bytes),
      includeDeviceName: false,
    );

    // Use blePeripheral to broadcast the message (supplementary to GATT service)
    try {
      debugPrint("[MESH BROADCAST] Broadcasting message (${bytes.length} bytes)");
      if (await blePeripheral.isAdvertising) {
        await blePeripheral.stop();
      }
      
      await blePeripheral.start(advertiseData: advertiseData);
      debugPrint("[MESH BROADCAST] Started advertising");
      
      // Stop broadcast after 3 seconds to let network propagate
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await blePeripheral.stop();
          debugPrint("[MESH BROADCAST] Stopped advertising after 3 seconds");
        } catch (_) {}
      });
      return true;
    } catch (e) {
      debugPrint("[MESH BROADCAST] ERROR: Advertising failed: $e");
      return false;
    }
  }

  String _compactEmergencyPayload(String incidentJson) {
    try {
      final parsed = jsonDecode(incidentJson);
      if (parsed is! Map<String, dynamic>) {
        return incidentJson;
      }

      double? _toRoundedDouble(dynamic value, int places) {
        if (value is num) {
          final factor = places == 0 ? 1 : (places == 1 ? 10 : 100);
          return (value * factor).roundToDouble() / factor;
        }
        return null;
      }

      final compact = <String, dynamic>{
        'id': parsed['id'],
        'lat': _toRoundedDouble(parsed['latitude'], 4) ?? parsed['latitude'],
        'lng': _toRoundedDouble(parsed['longitude'], 4) ?? parsed['longitude'],
        'g': _toRoundedDouble(parsed['maxGForce'], 1) ?? parsed['maxGForce'],
        't': parsed['type'],
      };
      compact.removeWhere((key, value) => value == null);
      final compactJson = jsonEncode(compact);
      return compactJson.length < incidentJson.length ? compactJson : incidentJson;
    } catch (_) {
      return incidentJson;
    }
  }

  MeshMessage _fitEmergencyMessageToBudget(MeshMessage message) {
    List<String> payloadCandidates = <String>[
      message.payload,
      _trimPayload(message.payload, keepGeoOnly: false),
      _trimPayload(message.payload, keepGeoOnly: true),
    ].toSet().toList();

    for (final payload in payloadCandidates) {
      final candidate = message.copyWith(payload: payload);
      if (utf8.encode(candidate.toJson()).length <= _maxAdvertisementBytes) {
        return candidate;
      }
    }
    return message;
  }

  String _trimPayload(String payloadJson, {required bool keepGeoOnly}) {
    try {
      final parsed = jsonDecode(payloadJson);
      if (parsed is! Map<String, dynamic>) {
        return payloadJson;
      }
      final minimal = <String, dynamic>{
        'id': parsed['id'],
        'lat': parsed['lat'] ?? parsed['latitude'],
        'lng': parsed['lng'] ?? parsed['longitude'],
      };
      if (!keepGeoOnly) {
        minimal['t'] = parsed['t'] ?? parsed['type'];
        minimal['g'] = parsed['g'] ?? parsed['maxGForce'];
      }
      minimal.removeWhere((key, value) => value == null);
      return jsonEncode(minimal);
    } catch (_) {
      return payloadJson;
    }
  }

  void stopMesh() {
    _isRunning = false;
    _scanSub?.cancel();
    _presenceTimer?.cancel();
    FlutterBluePlus.stopScan();
    blePeripheral.stop();
    // Clean up new managers
    unawaited(_gattServiceManager.stop());
    unawaited(_connectionManager.disconnectAll());
    unawaited(_relayProxy.cleanup());
    debugPrint("[MESH] Mesh stopped - all connections closed");
  }
}
