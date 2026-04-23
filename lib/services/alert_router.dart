// ignore_for_file: avoid_print
import 'dart:convert';

import '../config/emergency_dispatch_config.dart';
import '../mesh/mesh_service.dart';
import '../models/incident.dart';
import '../models/peer_node.dart';
import 'emergency_dispatch_sender.dart';

class AlertRouter {
  final MeshService _meshService = MeshService();

  // To avoid duplicate overlapping dispatches
  bool _isDispatching = false;

  AlertRouter() {
    _meshService.setIncidentRelayHandler(_forwardRelayedIncident);
  }

  /// Attempts to transmit an incident payload evaluating tiers synchronously 
  Future<void> transmitIncident(
    Incident incident, {
    required TransmissionMode currentMode,
    List<PeerNode> meshPeers = const [],
  }) async {
    if (_isDispatching) return;
    _isDispatching = true;

    try {
      print('ALERT ROUTER: Initiating Tiered Dispatch for ${incident.id}');

      // Tier 1: Internet REST API Stream
      if (currentMode == TransmissionMode.wifi || currentMode == TransmissionMode.satellite) {
        bool success = await _attemptInternetDispatch(incident);
        if (success) return; 
      }

      // Tier 1.5: Direct GATT Connection to Internet-Connected Peer
      print('ALERT ROUTER: Attempting Tier 1.5 (Direct GATT Connection)');
      bool directSuccess = await _attemptDirectGattDispatch(incident, meshPeers);
      if (directSuccess) {
        return;
      }

      // Tier 2: BLE Mesh Network (Offline Connectionless Broadcast)
      print('ALERT ROUTER: Falling back to Tier 2 (BLE Mesh)');
      final relayPeer = _selectInternetRelay(meshPeers);
      bool bleSuccess = await _attemptBleMeshDispatch(incident, relayPeer: relayPeer);
      if (bleSuccess) {
        // BLE Mesh broadcasted successfully (fire & forget protocol)
        return;
      }

      // Tier 3: WiFi Direct P2P Protocol
      print('ALERT ROUTER: Falling back to Tier 3 (WiFi Direct P2P)');
      bool p2pSuccess = await _attemptWiFiDirectDispatch(incident);
      if (p2pSuccess) return;

      // Tier 4: Satellite SOS Hardware Intent
      print('ALERT ROUTER: Falling back to Tier 4 (Satellite API)');
      bool satSuccess = await _attemptSatelliteSOS(incident);
      if (satSuccess) return;

      // Tier 5: Local Database Caching for Future Retry Loop
      print('ALERT ROUTER: All active networks unavailable. Caching to Tier 5.');
      await _cacheIncidentLocally(incident);

    } catch (e) {
      print('ALERT ROUTER FATAL ERROR: $e');
    } finally {
      _isDispatching = false;
    }
  }

  // --- Tier Implementation Stubs ---

  PeerNode? _selectInternetRelay(List<PeerNode> meshPeers) {
    for (final peer in meshPeers) {
      if (!peer.isCurrentDevice && peer.canRelayToInternet && peer.status == PeerStatus.online) {
        return peer;
      }
    }
    return null;
  }

  /// Tier 1.5: Try direct GATT connection to a peer with internet
  Future<bool> _attemptDirectGattDispatch(
    Incident incident,
    List<PeerNode> meshPeers,
  ) async {
    // Find a directly connected peer with internet
    final directConnections = _meshService.getDirectConnections();
    if (directConnections.isEmpty) {
      print('--> No direct GATT connections available');
      return false;
    }

    for (final connection in directConnections) {
      if (_meshService.isDirectlyConnectedTo(connection.peerId)) {
        try {
          print(
            '--> Attempting direct GATT transmission to ${connection.peerName}...',
          );
          // Send incident JSON directly to peer
          final success = await _meshService.sendDirectToPeer(
            connection.peerId,
            utf8.encode(incident.toJson()),
          );
          if (success) {
            print('--> Direct GATT Dispatch SUCCESS to ${connection.peerName}');
            return true;
          }
        } catch (e) {
          print(
            '--> Direct GATT send failed to ${connection.peerName}: $e',
          );
        }
      }
    }
    return false;
  }

  Future<bool> _forwardRelayedIncident(String incidentJson) async {
    try {
      final incident = Incident.fromJson(incidentJson);
      print('--> Mesh relay: forwarding ${incident.id} using helper device internet...');
      return _attemptInternetDispatch(incident, relayedByMesh: true);
    } catch (e) {
      print('--> Mesh relay parse failed: $e');
      return false;
    }
  }

  Future<bool> _attemptInternetDispatch(Incident incident, {bool relayedByMesh = false}) async {
    if (!EmergencyDispatchConfig.isConfigured) {
      print('--> Emergency endpoint missing. Set --dart-define=ZERONET_EMERGENCY_ENDPOINT=<url>.');
      return false;
    }

    final requestBody = json.encode({
      'incident': incident.toMap(),
      'delivery': {
        'mode': relayedByMesh ? 'mesh_relay' : 'direct',
        'transport': relayedByMesh ? 'ble_mesh' : incident.transmissionMode.name,
        'receivedAt': DateTime.now().toIso8601String(),
      },
    });
    final headers = <String, String>{
      if (EmergencyDispatchConfig.apiKey.isNotEmpty)
        EmergencyDispatchConfig.authHeader: EmergencyDispatchConfig.apiKey,
    };
    final result = await sendEmergencyJson(
      endpoint: EmergencyDispatchConfig.endpoint,
      body: requestBody,
      headers: headers,
      timeoutMs: EmergencyDispatchConfig.timeoutMs,
    );

    if (relayedByMesh) {
      print('--> Sending relayed emergency payload to the configured endpoint...');
    } else {
      print('--> Sending emergency payload to the configured endpoint...');
    }
    if (result.success) {
      print('--> Internet Dispatch SUCCESS (${result.statusCode ?? 200})');
      return true;
    }
    print('--> Internet Dispatch FAILED (${result.statusCode ?? 0}): ${result.detail}');
    return false;
  }

  Future<bool> _attemptBleMeshDispatch(Incident incident, {PeerNode? relayPeer}) async {
    print('--> Broadcasting encrypted emergency payload over BLE mesh...');
    final meshAccepted = await _meshService.broadcastEmergencyPayload(
      incident.toJson(),
      startingTtl: relayPeer == null ? 2 : 3,
    );
    if (!meshAccepted) {
      print('--> BLE advertisement failed before the mesh handoff could begin.');
      return false;
    }
    if (relayPeer != null) {
      print('--> ${relayPeer.name} is the preferred nearby relay and can forward this device location over its internet connection.');
    } else {
      print('--> Emergency broadcasted to the mesh. Any nearby Zeronet phone with internet can forward it opportunistically.');
    }
    return true;
  }

  Future<bool> _attemptWiFiDirectDispatch(Incident incident) async {
    // Requires wifi_iot or flutter_p2p
    print('--> Mock: Scanning & Binding WiFi Direct Socket...');
    return false; // Hardcode false until explicit plugin is requested
  }

  Future<bool> _attemptSatelliteSOS(Incident incident) async {
    // Requires iOS 14+ deep link bindings 
    print('--> Mock: Evaluating hardware for Satellite Link...');
    return false;
  }

  Future<bool> _cacheIncidentLocally(Incident incident) async {
    // SQL/SharedPrefs dump
    print('--> Mock: Dumped Incident ${incident.id} to offline buffer queue.');
    return true;
  }
}
