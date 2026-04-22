import 'dart:convert';

class MeshMessage {
  final String messageId;
  final int ttl;
  final String payload;

  const MeshMessage({
    required this.messageId,
    required this.ttl,
    required this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'ttl': ttl,
      'payload': payload,
    };
  }

  factory MeshMessage.fromMap(Map<String, dynamic> map) {
    return MeshMessage(
      messageId: map['messageId'] ?? '',
      ttl: map['ttl']?.toInt() ?? 0,
      payload: map['payload'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MeshMessage.fromJson(String source) => MeshMessage.fromMap(json.decode(source));
}
