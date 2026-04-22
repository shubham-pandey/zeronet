import 'package:flutter/material.dart';

enum IncidentType { crash, fall, manual, falseAlarm }

enum TransmissionMode { wifi, bleMesh, wifiDirect, satellite, offlineCached }

class Incident {
  final String id;
  final IncidentType type;
  final DateTime timestamp;
  final String locationName;
  final double maxGForce;
  final TransmissionMode transmissionMode;
  final bool resolved;
  final String? videoClipUrl;
  final List<SensorLogEntry>? sensorLog;
  final double? latitude;
  final double? longitude;

  const Incident({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.locationName,
    required this.maxGForce,
    required this.transmissionMode,
    this.resolved = false,
    this.videoClipUrl,
    this.sensorLog,
    this.latitude,
    this.longitude,
  });

  String get typeLabel {
    switch (type) {
      case IncidentType.crash:
        return 'CRASH';
      case IncidentType.fall:
        return 'FALL';
      case IncidentType.manual:
        return 'MANUAL';
      case IncidentType.falseAlarm:
        return 'FALSE ALARM';
    }
  }

  Color get typeColor {
    switch (type) {
      case IncidentType.crash:
        return const Color(0xFFFF4444);
      case IncidentType.fall:
        return const Color(0xFFFFA94D);
      case IncidentType.manual:
        return const Color(0xFF3D8BFF);
      case IncidentType.falseAlarm:
        return const Color(0xFF6B7280);
    }
  }

  String get transmissionLabel {
    switch (transmissionMode) {
      case TransmissionMode.wifi:
        return 'WIFI';
      case TransmissionMode.bleMesh:
        return 'BLE MESH';
      case TransmissionMode.wifiDirect:
        return 'WIFI DIRECT';
      case TransmissionMode.satellite:
        return 'SATELLITE';
      case TransmissionMode.offlineCached:
        return 'CACHED';
    }
  }
}

class SensorLogEntry {
  final DateTime timestamp;
  final double gForce;
  final double? latitude;
  final double? longitude;

  const SensorLogEntry({
    required this.timestamp,
    required this.gForce,
    this.latitude,
    this.longitude,
  });
}
