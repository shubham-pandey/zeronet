import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';

/// Active incident screen — live camera + streaming status.
class ActiveIncidentScreen extends StatefulWidget {
  const ActiveIncidentScreen({super.key});

  @override
  State<ActiveIncidentScreen> createState() => _ActiveIncidentScreenState();
}

class _ActiveIncidentScreenState extends State<ActiveIncidentScreen> {
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _markResolved() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Camera viewfinder (top 60%)
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ZeronetColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: ZeronetColors.surfaceBorder,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Simulated camera placeholder
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            size: 56,
                            color: ZeronetColors.textTertiary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'LIVE VIEWFINDER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ZeronetColors.textTertiary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // REC indicator
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ZeronetColors.danger.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: ZeronetColors.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'REC',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ZeronetColors.danger,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Live timer
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ZeronetColors.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formattedTime,
                          style: ZeronetTheme.mono.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ZeronetColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status chips + controls (bottom 40%)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Status chips row
                    Row(
                      children: [
                        Expanded(
                          child: StatusChip(
                            label: '28.6139°N 77.2090°E',
                            icon: Icons.gps_fixed,
                            color: ZeronetColors.textSecondary,
                            outlined: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StatusChip(
                            label: 'BLE MESH',
                            icon: Icons.bluetooth,
                            color: ZeronetColors.primary,
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatusChip(
                            label: '24 Kbps',
                            icon: Icons.speed_rounded,
                            color: ZeronetColors.success,
                            outlined: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Transmission status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: ZeronetColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: ZeronetColors.danger.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cell_tower_rounded,
                            size: 16,
                            color: ZeronetColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'INCIDENT ACTIVE — STREAMING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ZeronetColors.danger,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Action buttons
                    Row(
                      children: [
                        // Call 112
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone, size: 20),
                              label: const Text(
                                'Call 112',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ZeronetColors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Mark Resolved
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _markResolved,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: ZeronetColors.textPrimary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Mark Resolved',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: ZeronetColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
