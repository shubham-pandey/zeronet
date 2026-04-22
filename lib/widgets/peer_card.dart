import 'package:flutter/material.dart';
import '../models/peer_node.dart';
import '../theme/app_theme.dart';

/// Card for a nearby BLE mesh peer relay node.
class PeerCard extends StatelessWidget {
  final PeerNode peer;

  const PeerCard({super.key, required this.peer});

  Color get _statusColor {
    switch (peer.status) {
      case PeerStatus.online:
        return ZeronetColors.success;
      case PeerStatus.warning:
        return ZeronetColors.warning;
      case PeerStatus.offline:
        return ZeronetColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: ZeronetColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ZeronetColors.surfaceBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Avatar with status dot
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ZeronetColors.surfaceLight,
                child: Icon(
                  Icons.people_alt_rounded,
                  color: ZeronetColors.textSecondary,
                  size: 22,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ZeronetColors.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Name and last seen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ZeronetColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  peer.lastSeen.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ZeronetColors.textTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Distance and signal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${peer.distanceMeters}m',
                style: ZeronetTheme.mono.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ZeronetColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              _buildSignalBars(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < peer.signalBars;
        return Container(
          width: 5,
          height: 8.0 + (index * 4),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            color: isActive
                ? ZeronetColors.primary
                : ZeronetColors.surfaceBorder,
          ),
        );
      }),
    );
  }
}
