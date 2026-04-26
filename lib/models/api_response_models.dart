import 'dart:convert';

class ApiIncident {
  final String id;
  final String sosId;
  final String caseName;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String type;
  final String severity;
  final String status;
  final DateTime createdAt;
  final List<ResponderAssignment>? responders;
  final List<TimelineEvent>? timeline;

  ApiIncident({
    required this.id,
    required this.sosId,
    required this.caseName,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.type,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.responders,
    this.timeline,
  });

  factory ApiIncident.fromMap(Map<String, dynamic> map) {
    return ApiIncident(
      id: map['id']?.toString() ?? '',
      sosId: map['sosId']?.toString() ?? '',
      caseName: map['caseName']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      latitude: (map['coords']?['lat'] as num?)?.toDouble(),
      longitude: (map['coords']?['lng'] as num?)?.toDouble(),
      type: map['type']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'high',
      status: map['status']?.toString() ?? 'reported',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      responders: (map['responders'] as List<dynamic>?)
          ?.map((r) => ResponderAssignment.fromMap(r as Map<String, dynamic>))
          .toList(),
      timeline: (map['timeline'] as List<dynamic>?)
          ?.map((t) => TimelineEvent.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sosId': sosId,
      'caseName': caseName,
      'description': description,
      'location': location,
      'coords': {
        'lat': latitude,
        'lng': longitude,
      },
      'type': type,
      'severity': severity,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory ApiIncident.fromJson(String source) =>
      ApiIncident.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ResponderAssignment {
  final String id;
  final String name;
  final String status;

  ResponderAssignment({
    required this.id,
    required this.name,
    required this.status,
  });

  factory ResponderAssignment.fromMap(Map<String, dynamic> map) {
    return ResponderAssignment(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }
}

class TimelineEvent {
  final String event;
  final DateTime timestamp;

  TimelineEvent({
    required this.event,
    required this.timestamp,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    return TimelineEvent(
      event: map['event']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class IncidentsListResponse {
  final List<ApiIncident> incidents;
  final int total;
  final int page;

  IncidentsListResponse({
    required this.incidents,
    required this.total,
    required this.page,
  });

  factory IncidentsListResponse.fromMap(Map<String, dynamic> map) {
    return IncidentsListResponse(
      incidents: (map['incidents'] as List<dynamic>?)
              ?.map((i) => ApiIncident.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      total: (map['total'] as num?)?.toInt() ?? 0,
      page: (map['page'] as num?)?.toInt() ?? 1,
    );
  }
}

class Responder {
  final String id;
  final String name;
  final String role;
  final String status;
  final double latitude;
  final double longitude;

  Responder({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.latitude,
    required this.longitude,
  });

  factory Responder.fromMap(Map<String, dynamic> map) {
    return Responder(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      status: map['status']?.toString() ?? 'available',
      latitude: (map['coords']?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['coords']?['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RespondersListResponse {
  final List<Responder> responders;

  RespondersListResponse({required this.responders});

  factory RespondersListResponse.fromMap(Map<String, dynamic> map) {
    return RespondersListResponse(
      responders: (map['responders'] as List<dynamic>?)
              ?.map((r) => Responder.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HeatmapPoint {
  final double latitude;
  final double longitude;
  final String type;
  final double weight;

  HeatmapPoint({
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.weight,
  });

  factory HeatmapPoint.fromMap(Map<String, dynamic> map) {
    return HeatmapPoint(
      latitude: (map['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['lng'] as num?)?.toDouble() ?? 0.0,
      type: map['type']?.toString() ?? 'moderate',
      weight: (map['weight'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

class HeatmapResponse {
  final List<HeatmapPoint> points;
  final HeatmapStats stats;

  HeatmapResponse({
    required this.points,
    required this.stats,
  });

  factory HeatmapResponse.fromMap(Map<String, dynamic> map) {
    return HeatmapResponse(
      points: (map['points'] as List<dynamic>?)
              ?.map((p) => HeatmapPoint.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      stats: HeatmapStats.fromMap(map['stats'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class HeatmapStats {
  final int totalHotspots;
  final String avgResponseTime;

  HeatmapStats({
    required this.totalHotspots,
    required this.avgResponseTime,
  });

  factory HeatmapStats.fromMap(Map<String, dynamic> map) {
    return HeatmapStats(
      totalHotspots: (map['totalHotspots'] as num?)?.toInt() ?? 0,
      avgResponseTime: map['avgResponseTime']?.toString() ?? '0m',
    );
  }
}

class DashboardStatsResponse {
  final StatMetric activeSosAlerts;
  final StatMetric highPriorityIncidents;
  final StatMetric respondersInField;
  final StatMetric todayResolved;

  DashboardStatsResponse({
    required this.activeSosAlerts,
    required this.highPriorityIncidents,
    required this.respondersInField,
    required this.todayResolved,
  });

  factory DashboardStatsResponse.fromMap(Map<String, dynamic> map) {
    return DashboardStatsResponse(
      activeSosAlerts: StatMetric.fromMap(map['activeSosAlerts'] as Map<String, dynamic>? ?? {}),
      highPriorityIncidents:
          StatMetric.fromMap(map['highPriorityIncidents'] as Map<String, dynamic>? ?? {}),
      respondersInField: StatMetric.fromMap(map['respondersInField'] as Map<String, dynamic>? ?? {}),
      todayResolved: StatMetric.fromMap(map['todayResolved'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class StatMetric {
  final int count;
  final int? changePercent;
  final String? changeDirection;
  final String? description;
  final int? connectionRate;
  final List<int>? chartData;

  StatMetric({
    required this.count,
    this.changePercent,
    this.changeDirection,
    this.description,
    this.connectionRate,
    this.chartData,
  });

  factory StatMetric.fromMap(Map<String, dynamic> map) {
    return StatMetric(
      count: (map['count'] as num?)?.toInt() ?? 0,
      changePercent: (map['changePercent'] as num?)?.toInt(),
      changeDirection: map['changeDirection']?.toString(),
      description: map['description']?.toString(),
      connectionRate: (map['connectionRate'] as num?)?.toInt(),
      chartData: (map['chartData'] as List<dynamic>?)
          ?.map((c) => (c as num).toInt())
          .toList(),
    );
  }
}

class BroadcastResponse {
  final String id;
  final String status;
  final String type;
  final String? audioUrl;
  final int? notifiedCount;

  BroadcastResponse({
    required this.id,
    required this.status,
    required this.type,
    this.audioUrl,
    this.notifiedCount,
  });

  factory BroadcastResponse.fromMap(Map<String, dynamic> map) {
    return BroadcastResponse(
      id: map['id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      type: map['type']?.toString() ?? 'text',
      audioUrl: map['audioUrl']?.toString(),
      notifiedCount: (map['notifiedCount'] as num?)?.toInt(),
    );
  }
}
