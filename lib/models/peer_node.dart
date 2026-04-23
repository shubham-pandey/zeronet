enum PeerStatus { online, warning, offline }

class PeerNode {
  final String id;
  final String name;
  final PeerStatus status;
  final String lastSeen;
  final int distanceMeters;
  final int signalBars; // 1–4
  final bool isCurrentDevice;
  final bool canRelayToInternet;
  final bool isPreferredRoute;
  final String capabilityLabel;

  const PeerNode({
    required this.id,
    required this.name,
    required this.status,
    required this.lastSeen,
    required this.distanceMeters,
    required this.signalBars,
    this.isCurrentDevice = false,
    this.canRelayToInternet = false,
    this.isPreferredRoute = false,
    this.capabilityLabel = 'RELAY',
  });

  PeerNode copyWith({
    String? id,
    String? name,
    PeerStatus? status,
    String? lastSeen,
    int? distanceMeters,
    int? signalBars,
    bool? isCurrentDevice,
    bool? canRelayToInternet,
    bool? isPreferredRoute,
    String? capabilityLabel,
  }) {
    return PeerNode(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      signalBars: signalBars ?? this.signalBars,
      isCurrentDevice: isCurrentDevice ?? this.isCurrentDevice,
      canRelayToInternet: canRelayToInternet ?? this.canRelayToInternet,
      isPreferredRoute: isPreferredRoute ?? this.isPreferredRoute,
      capabilityLabel: capabilityLabel ?? this.capabilityLabel,
    );
  }
}
