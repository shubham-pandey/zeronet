enum PeerStatus { online, warning, offline }

class PeerNode {
  final String id;
  final String name;
  final PeerStatus status;
  final String lastSeen;
  final int distanceMeters;
  final int signalBars; // 1–4

  const PeerNode({
    required this.id,
    required this.name,
    required this.status,
    required this.lastSeen,
    required this.distanceMeters,
    required this.signalBars,
  });
}
