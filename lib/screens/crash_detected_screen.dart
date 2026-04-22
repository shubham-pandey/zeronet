import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'active_incident_screen.dart';

/// Full-screen crash detected countdown — the most critical screen.
class CrashDetectedScreen extends StatefulWidget {
  final bool isManual;

  const CrashDetectedScreen({super.key, this.isManual = false});

  @override
  State<CrashDetectedScreen> createState() => _CrashDetectedScreenState();
}

class _CrashDetectedScreenState extends State<CrashDetectedScreen>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 10;
  Timer? _timer;
  late AnimationController _pulseController;
  String _transmissionStatus = 'Connecting to server…';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startCountdown();

    // Simulate transmission status updates
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _transmissionStatus = 'Sending via BLE Mesh…');
      }
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _transmissionStatus = 'Alert relayed to 2 peers');
      }
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _navigateToActiveIncident();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _navigateToActiveIncident() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveIncidentScreen()),
    );
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final pulse = _pulseController.value;
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  ZeronetColors.danger.withValues(alpha: 0.18 + pulse * 0.06),
                  ZeronetColors.background,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Alert icon
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: ZeronetColors.danger.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  widget.isManual ? 'SOS ACTIVATED' : 'CRASH DETECTED',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ZeronetColors.textPrimary,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency alert in progress',
                  style: TextStyle(
                    fontSize: 15,
                    color: ZeronetColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Countdown timer
                Text(
                  '$_secondsRemaining',
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: ZeronetColors.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'seconds until alert is sent',
                  style: TextStyle(
                    fontSize: 14,
                    color: ZeronetColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Transmission status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ZeronetColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            ZeronetColors.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _transmissionStatus,
                        style: ZeronetTheme.mono.copyWith(
                          fontSize: 13,
                          color: ZeronetColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Cancel button — full width, 64px height
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: ZeronetColors.textPrimary,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "I'M OK — CANCEL",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ZeronetColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
