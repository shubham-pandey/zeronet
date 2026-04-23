import 'dart:convert';

enum MeshMessageKind { presence, emergency }

class MeshMessage {
  final MeshMessageKind kind;
  final String messageId;
  final int ttl;
  final String payload;
  final String senderDeviceId;
  final String senderName;
  final bool senderHasInternet;
  final int createdAtMillis;

  const MeshMessage({
    this.kind = MeshMessageKind.emergency,
    required this.messageId,
    required this.ttl,
    required this.payload,
    this.senderDeviceId = '',
    this.senderName = '',
    this.senderHasInternet = false,
    this.createdAtMillis = 0,
  });

  MeshMessage copyWith({
    MeshMessageKind? kind,
    String? messageId,
    int? ttl,
    String? payload,
    String? senderDeviceId,
    String? senderName,
    bool? senderHasInternet,
    int? createdAtMillis,
  }) {
    return MeshMessage(
      kind: kind ?? this.kind,
      messageId: messageId ?? this.messageId,
      ttl: ttl ?? this.ttl,
      payload: payload ?? this.payload,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      senderName: senderName ?? this.senderName,
      senderHasInternet: senderHasInternet ?? this.senderHasInternet,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'k': kind.name,
      'i': messageId,
      't': ttl,
    };
    if (payload.isNotEmpty) {
      map['p'] = payload;
    }
    if (senderDeviceId.isNotEmpty) {
      map['d'] = senderDeviceId;
    }
    if (senderName.isNotEmpty) {
      map['n'] = senderName;
    }
    if (senderHasInternet) {
      map['h'] = true;
    }
    if (createdAtMillis > 0) {
      map['c'] = createdAtMillis;
    }
    return map;
  }

  factory MeshMessage.fromMap(Map<String, dynamic> map) {
    final kindValue = (map['k'] ?? map['kind'])?.toString() ?? MeshMessageKind.emergency.name;
    return MeshMessage(
      kind: MeshMessageKind.values.firstWhere(
        (value) => value.name == kindValue,
        orElse: () => MeshMessageKind.emergency,
      ),
      messageId: (map['i'] ?? map['messageId'])?.toString() ?? '',
      ttl: (map['t'] ?? map['ttl'])?.toInt() ?? 0,
      payload: (map['p'] ?? map['payload'])?.toString() ?? '',
      senderDeviceId: (map['d'] ?? map['senderDeviceId'])?.toString() ?? '',
      senderName: (map['n'] ?? map['senderName'])?.toString() ?? '',
      senderHasInternet: (map['h'] ?? map['senderHasInternet']) as bool? ?? false,
      createdAtMillis: (map['c'] ?? map['createdAtMillis'])?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory MeshMessage.fromJson(String source) => MeshMessage.fromMap(json.decode(source));
}
