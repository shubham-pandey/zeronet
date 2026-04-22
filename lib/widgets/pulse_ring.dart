import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated pulse ring that breathes slowly to indicate sensor is active.
class PulseRing extends StatefulWidget {
  final double size;
  final Widget child;
  final bool active;

  const PulseRing({
    super.key,
    this.size = 220,
    this.active = true,
    required this.child,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = widget.active ? (math.sin(_controller.value * 2 * math.pi) + 1) / 2 : 0.0;
        return SizedBox(
          width: widget.size + 60,
          height: widget.size + 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer breathing ring
              Container(
                width: widget.size + 40 + (pulse * 16),
                height: widget.size + 40 + (pulse * 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ZeronetColors.primary.withValues(alpha: 0.06 + pulse * 0.06),
                    width: 1,
                  ),
                ),
              ),
              // Middle ring
              Container(
                width: widget.size + 16 + (pulse * 8),
                height: widget.size + 16 + (pulse * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ZeronetColors.primary.withValues(alpha: 0.10 + pulse * 0.08),
                    width: 1.5,
                  ),
                ),
              ),
              // Inner container
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ZeronetColors.primary.withValues(alpha: 0.04 + pulse * 0.03),
                  border: Border.all(
                    color: ZeronetColors.primary.withValues(alpha: 0.18 + pulse * 0.10),
                    width: 2,
                  ),
                ),
                child: child,
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}
