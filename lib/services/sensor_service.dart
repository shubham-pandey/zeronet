import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/incident.dart';
import '../models/peer_node.dart';
import '../mesh/mesh_service.dart';
import 'detection_engine.dart';
import 'alert_router.dart';

class SensorService extends ChangeNotifier {
  static final String _instanceDeviceId = _generateLocalDeviceId();

  static String _generateLocalDeviceId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomSuffix = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'node-$timestamp-$randomSuffix';
  }

  static String _generateLocalDeviceName(String deviceId) {
    final shortId = deviceId.length >= 4 ? deviceId.substring(deviceId.length - 4) : deviceId;
    return 'ZERONET $shortId';
  }

  late final DetectionEngine detectionEngine;
  final AlertRouter _alertRouter = AlertRouter();
  final MeshService _meshService = MeshService();
  final String _localDeviceId = _instanceDeviceId;
  final String _localDeviceName = _generateLocalDeviceName(_instanceDeviceId);

  SensorService() {
    detectionEngine = DetectionEngine(onIncidentConfirmed: _handleIncidentConfirmed);
    detectionEngine.addListener(notifyListeners);
  }

  void _handleIncidentConfirmed(AnomalyType type) {
     IncidentType mappedType;
     switch(type) {
        case AnomalyType.speedDrop:
        case AnomalyType.impact:
            mappedType = IncidentType.crash;
            break;
        case AnomalyType.freeFall:
            mappedType = IncidentType.fall;
            break;
        case AnomalyType.manual:
        default:
            mappedType = IncidentType.manual;
            break;
     }

     final mockIncident = Incident(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
        locationName: _lastLocation,
        maxGForce: _currentGForce,
        transmissionMode: _currentMode,
        type: mappedType,
     );
     _alertRouter.transmitIncident(
       mockIncident,
       currentMode: _currentMode,
       meshPeers: meshPeers,
     );
  }
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  double _currentGForce = 1.0;
  double get currentGForce => _currentGForce;

  String _lastLocation = 'Locating...';
  String get lastLocation => _lastLocation;

  double _latitude = 0.0;
  double get latitude => _latitude;

  double _longitude = 0.0;
  double get longitude => _longitude;

  TransmissionMode _currentMode = TransmissionMode.offlineCached;
  TransmissionMode get currentMode => _currentMode;

  List<PeerNode> _peers = [];
  List<PeerNode> get peers => _peers;
  List<PeerNode> get meshPeers => [currentDevicePeer, ..._peers];
  List<PeerNode> get relayPeers => _peers;

  PeerNode get currentDevicePeer {
    final hasDirectInternet =
        _currentMode == TransmissionMode.wifi || _currentMode == TransmissionMode.satellite;
    return PeerNode(
      id: _localDeviceId,
      name: 'THIS DEVICE',
      status: _isMonitoring ? PeerStatus.online : PeerStatus.offline,
      lastSeen: hasDirectInternet ? 'Direct internet ready' : 'Awaiting relay',
      distanceMeters: 0,
      signalBars: hasDirectInternet ? 4 : (_signalBars == 0 ? 1 : _signalBars),
      isCurrentDevice: true,
      canRelayToInternet: hasDirectInternet,
      isPreferredRoute: hasDirectInternet,
      capabilityLabel: hasDirectInternet ? 'DIRECT INTERNET' : 'SOURCE DEVICE',
    );
  }

  PeerNode? get preferredInternetRelay {
    if (_currentMode == TransmissionMode.wifi || _currentMode == TransmissionMode.satellite) {
      return currentDevicePeer;
    }
    for (final peer in _peers) {
      if (peer.isPreferredRoute) {
        return peer;
      }
    }
    return null;
  }

  int get blePeerCount => _peers.length;

  int _signalBars = 0;
  int get signalBars => _signalBars;

  int _batteryPercent = 100;
  int get batteryPercent => _batteryPercent;
  
  // Streams
  StreamSubscription? _accelerometerSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _batterySub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  
  final Battery _battery = Battery();

  bool get _hasDirectInternet =>
      _currentMode == TransmissionMode.wifi || _currentMode == TransmissionMode.satellite;

  String _formatLocationLabel(double latitude, double longitude, Placemark place) {
    final label = '${place.name}, ${place.locality}'.trim();
    if (label.startsWith(',')) {
      return label.substring(1).trimLeft();
    }
    if (label.isNotEmpty) {
      return label;
    }
    return 'Lat: ${latitude.toStringAsFixed(2)}, Lng: ${longitude.toStringAsFixed(2)}';
  }

  List<PeerNode> _decorateRelayCapabilities(List<PeerNode> rawPeers) {
    final sortedPeers = [...rawPeers]
      ..sort((a, b) {
        final scoreA = (a.canRelayToInternet ? 100 : 0) + a.signalBars - a.distanceMeters;
        final scoreB = (b.canRelayToInternet ? 100 : 0) + b.signalBars - b.distanceMeters;
        return scoreB.compareTo(scoreA);
      });

    String? preferredId;
    for (final peer in sortedPeers) {
      if (peer.canRelayToInternet) {
        preferredId = peer.id;
        break;
      }
    }

    return sortedPeers
        .map(
          (peer) => peer.copyWith(
            isPreferredRoute: peer.id == preferredId,
            capabilityLabel: peer.canRelayToInternet ? 'INTERNET RELAY' : 'BLE RELAY',
          ),
        )
        .toList();
  }
  
  Future<void> initialize() async {
    // Check initial battery
    _batteryPercent = await _battery.batteryLevel;
    notifyListeners();

    _meshService.configureLocalNode(
      deviceId: _localDeviceId,
      deviceName: _localDeviceName,
      hasInternetConnection: false,
    );
    _meshService.setPeerUpdateListener((peers) {
      _peers = _decorateRelayCapabilities(peers);
      notifyListeners();
    });

    final connectivityResults = await Connectivity().checkConnectivity();
    _updateConnectivity(connectivityResults);

    await requestPermissions();
    startMonitoring();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  void startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    notifyListeners();

    // Accelerometer
    _accelerometerSub = userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((event) {
      double gForce = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.81;
      _currentGForce = gForce;
      
      // Feed math evaluation
      detectionEngine.addGForceReading(gForce);
      
      notifyListeners();
    });

    // Location
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _latitude = lastKnown.latitude;
        _longitude = lastKnown.longitude;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(_latitude, _longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            _lastLocation = _formatLocationLabel(_latitude, _longitude, place);
          }
        } catch (e) {
          _lastLocation = 'Lat: ${_latitude.toStringAsFixed(2)}, Lng: ${_longitude.toStringAsFixed(2)}';
        }
      } else {
        _lastLocation = 'Unknown Location';
      }
      notifyListeners();
      await Geolocator.openLocationSettings();
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      ).listen((Position position) async {
        _latitude = position.latitude;
        _longitude = position.longitude;
        
        // Feed math evaluation
        detectionEngine.addSpeedReading(position.speed);
        
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(_latitude, _longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            _lastLocation = _formatLocationLabel(_latitude, _longitude, place);
          }
        } catch (e) {
          _lastLocation = 'Lat: ${_latitude.toStringAsFixed(2)}, Lng: ${_longitude.toStringAsFixed(2)}';
        }
        notifyListeners();
      }, onError: (e) {
         // Ignores stream exceptions if GPS gets toggled rapidly
      });
    }

    // Battery
    _batterySub = _battery.onBatteryStateChanged.listen((state) async {
       _batteryPercent = await _battery.batteryLevel;
       notifyListeners();
    });

    // Connectivity
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateConnectivity);

    try {
      await _meshService.startMesh();
    } catch (e) {
      debugPrint("BT Mesh Error: $e");
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSub?.cancel();
    _positionSub?.cancel();
    _batterySub?.cancel();
    _connectivitySub?.cancel();
    _meshService.stopMesh();
    _peers = [];
    notifyListeners();
  }

  Future<void> refreshMeshDiscovery() async {
    await _meshService.refreshDiscovery();
  }
  
  void _updateConnectivity(List<ConnectivityResult> results) {
     if (results.contains(ConnectivityResult.wifi)) {
       _currentMode = TransmissionMode.wifi;
       _signalBars = 4;
     } else if (results.contains(ConnectivityResult.mobile)) {
       _currentMode = TransmissionMode.satellite; // For UI text representation
       _signalBars = 3;
     } else if (results.contains(ConnectivityResult.bluetooth)) {
       _currentMode = TransmissionMode.bleMesh;
       _signalBars = 2;
     } else {
       _currentMode = TransmissionMode.offlineCached;
       _signalBars = 0;
     }
     _meshService.updateLocalInternetAvailability(_hasDirectInternet);
     notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
