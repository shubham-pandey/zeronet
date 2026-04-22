import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/incident.dart';
import '../models/peer_node.dart';
import 'detection_engine.dart';
import 'alert_router.dart';

class SensorService extends ChangeNotifier {
  late final DetectionEngine detectionEngine;
  final AlertRouter _alertRouter = AlertRouter();

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
     _alertRouter.transmitIncident(mockIncident, _currentMode);
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
  StreamSubscription<List<ScanResult>>? _scanSub;
  
  final Battery _battery = Battery();

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
  
  Future<void> initialize() async {
    // Check initial battery
    _batteryPercent = await _battery.batteryLevel;
    notifyListeners();
    
    // Check initial connectivity
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

    // Bluetooth
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
    
    try {
      _scanSub = FlutterBluePlus.onScanResults.listen((results) {
        _peers = results.map((r) {
          // Determine status based on signal strength (RSSI)
          PeerStatus status = PeerStatus.online;
          if (r.rssi < -80) {
            status = PeerStatus.warning;
          }
          
          // Estimate distance (simple logic: -30 to -100 dBm map to 1-100m)
          int distance = (r.rssi.abs() - 30).clamp(1, 100);
          
          // Map RSSI to signal bars (1-4)
          int bars = 1;
          if (r.rssi > -60) {
            bars = 4;
          } else if (r.rssi > -75) {
            bars = 3;
          } else if (r.rssi > -90) {
            bars = 2;
          }

          String deviceName = r.device.platformName.isNotEmpty 
              ? r.device.platformName 
              : 'NODE-${r.device.remoteId.toString().substring(0, 4)}';

          return PeerNode(
            id: r.device.remoteId.toString(),
            name: deviceName.toUpperCase(),
            status: status,
            lastSeen: 'Just now',
            distanceMeters: distance,
            signalBars: bars,
          );
        }).toList();
        
        notifyListeners();
      });
      await FlutterBluePlus.startScan(timeout: const Duration(minutes: 5));
    } catch (e) {
      debugPrint("BT Scan Error: $e");
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _accelerometerSub?.cancel();
    _positionSub?.cancel();
    _batterySub?.cancel();
    _connectivitySub?.cancel();
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    notifyListeners();
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
     notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
