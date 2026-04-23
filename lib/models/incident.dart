import 'dart:convert';
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'locationName': locationName,
      'maxGForce': maxGForce,
      'transmissionMode': transmissionMode.name,
      'resolved': resolved,
      'videoClipUrl': videoClipUrl,
      'sensorLog': sensorLog?.map((entry) => entry.toMap()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id']?.toString() ?? '',
      type: IncidentType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => IncidentType.manual,
      ),
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      locationName: map['locationName']?.toString() ?? 'Unknown Location',
      maxGForce: (map['maxGForce'] as num?)?.toDouble() ?? 0,
      transmissionMode: TransmissionMode.values.firstWhere(
        (value) => value.name == map['transmissionMode'],
        orElse: () => TransmissionMode.offlineCached,
      ),
      resolved: map['resolved'] as bool? ?? false,
      videoClipUrl: map['videoClipUrl']?.toString(),
      sensorLog: (map['sensorLog'] as List<dynamic>?)
          ?.map((entry) => SensorLogEntry.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Incident.fromJson(String source) => Incident.fromMap(
        Map<String, dynamic>.from(json.decode(source) as Map),
      );

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

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'gForce': gForce,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory SensorLogEntry.fromMap(Map<String, dynamic> map) {
    return SensorLogEntry(
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      gForce: (map['gForce'] as num?)?.toDouble() ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
