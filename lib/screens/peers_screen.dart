import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sensor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/peer_card.dart';
import '../widgets/mesh_graph.dart';

class PeersScreen extends StatelessWidget {
  const PeersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensorService = context.watch<SensorService>();
    final peers = sensorService.peers;

    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'BLE MESH',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: ZeronetColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.bluetooth,
                              color: ZeronetColors.primary,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Local network relay status.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ZeronetColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ZeronetColors.surfaceBorder,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.read<SensorService>().stopMonitoring();
                        context.read<SensorService>().startMonitoring();
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: ZeronetColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Graph Visualization
              Center(
                child: MeshGraph(peers: peers, size: 220),
              ),
              const SizedBox(height: 12),
              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ZeronetColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ZeronetColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ZeronetColors.textTertiary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'CONNECTED',
                            style: ZeronetTheme.mono.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ZeronetColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ACTIVE PEERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ZeronetColors.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${peers.length}',
                          style: ZeronetTheme.mono.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: ZeronetColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Nearby relays section
              Text(
                'NEARBY RELAYS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ZeronetColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  itemCount: peers.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return PeerCard(peer: peers[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
