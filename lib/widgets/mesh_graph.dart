import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/peer_node.dart';
import '../theme/app_theme.dart';

class MeshGraph extends StatefulWidget {
  final PeerNode currentDevice;
  final List<PeerNode> peers;
  final double size;

  const MeshGraph({
    super.key,
    required this.currentDevice,
    required this.peers,
    this.size = 300,
  });

  @override
  State<MeshGraph> createState() => _MeshGraphState();
}

class _MeshGraphState extends State<MeshGraph> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: GraphPainter(
            currentDevice: widget.currentDevice,
            peers: widget.peers,
            rotation: _controller.value * 2 * math.pi,
            pulse: (math.sin(_controller.value * 2 * math.pi * 2) + 1) / 2,
          ),
        );
      },
    );
  }
}

class GraphPainter extends CustomPainter {
  final PeerNode currentDevice;
  final List<PeerNode> peers;
  final double rotation;
  final double pulse;

  GraphPainter({
    required this.currentDevice,
    required this.peers,
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..color = ZeronetColors.primary.withValues(alpha: 0.1 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(center, radius * 0.8, glowPaint);

    final linePaint = Paint()
      ..color = ZeronetColors.primary.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = ZeronetColors.surfaceBorder
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw concentric circles (radar style)
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), dashPaint);
    }

    // Draw central node (User)
    final nodePaint = Paint()
      ..color = currentDevice.canRelayToInternet
          ? ZeronetColors.success
          : ZeronetColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, nodePaint);
    canvas.drawCircle(
      center, 
      8 + (10 * pulse), 
      Paint()
        ..color = (currentDevice.canRelayToInternet ? ZeronetColors.success : ZeronetColors.primary)
            .withValues(alpha: 0.2 * (1 - pulse))
        ..style = PaintingStyle.fill
    );

    final centerLabel = TextPainter(
      text: TextSpan(
        text: currentDevice.canRelayToInternet ? 'YOU • ONLINE' : 'YOU',
        style: ZeronetTheme.mono.copyWith(
          fontSize: 9,
          color: ZeronetColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    centerLabel.layout();
    centerLabel.paint(
      canvas,
      center + Offset(-(centerLabel.width / 2), radius * 0.18),
    );

    if (peers.isEmpty) return;

    // Calculate positions for peers
    final List<Offset> positions = [];
    for (var i = 0; i < peers.length; i++) {
        // Deterministic angle based on ID, but offset by rotation
        final idHash = peers[i].id.hashCode;
        final angle = (idHash % 360) * math.pi / 180 + (rotation * 0.2);
        
        // Distance mapped from peer distance, but scaled to fit radius
        // Use peers[i].distanceMeters which we set in SensorService (1-100)
        final scaledDist = (peers[i].distanceMeters / 100.0) * (radius * 0.9);
        final clampedDist = scaledDist.clamp(radius * 0.3, radius * 0.9);

        final x = center.dx + clampedDist * math.cos(angle);
        final y = center.dy + clampedDist * math.sin(angle);
        positions.add(Offset(x, y));
    }

    // Draw connections between peers (simulating mesh)
    for (var i = 0; i < positions.length; i++) {
        // Connection to center
        canvas.drawLine(center, positions[i], linePaint);

        // Connection to some other peers if close
        for (var j = i + 1; j < positions.length; j++) {
            final dist = (positions[i] - positions[j]).distance;
            if (dist < radius * 0.8) {
                final connectionPaint = Paint()
                  ..color = ZeronetColors.primary.withValues(alpha: 0.1)
                  ..strokeWidth = 0.5;
                canvas.drawLine(positions[i], positions[j], connectionPaint);
            }
        }
    }

    // Draw peer nodes
    for (var i = 0; i < positions.length; i++) {
        final peer = peers[i];
        final pColor = peer.isPreferredRoute
            ? ZeronetColors.primary
            : peer.canRelayToInternet
                ? ZeronetColors.success
                : (peer.status == PeerStatus.online
                    ? ZeronetColors.success
                    : ZeronetColors.warning);
        
        final pPaint = Paint()
          ..color = pColor
          ..style = PaintingStyle.fill;

        canvas.drawCircle(positions[i], 5, pPaint);
        if (peer.canRelayToInternet) {
          canvas.drawCircle(
            positions[i],
            8,
            Paint()
              ..color = pColor.withValues(alpha: 0.18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
        
        // Node label highlight
        final textPainter = TextPainter(
          text: TextSpan(
            text: peer.isPreferredRoute ? '${peer.name.split('-').last}*' : peer.name.split('-').last,
            style: ZeronetTheme.mono.copyWith(fontSize: 8, color: ZeronetColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, positions[i] + const Offset(8, -4));
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
