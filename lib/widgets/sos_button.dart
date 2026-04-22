import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The SOS button with hold-to-trigger behaviour.
class SosButton extends StatefulWidget {
  final VoidCallback onTriggered;

  const SosButton({super.key, required this.onTriggered});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTriggered();
        _reset();
      }
    });
  }

  void _startHold() {
    setState(() => _holding = true);
    _holdController.forward(from: 0);
  }

  void _reset() {
    setState(() => _holding = false);
    _holdController.reset();
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _reset(),
      onLongPressCancel: () => _reset(),
      child: AnimatedBuilder(
        animation: _holdController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _holding
                    ? ZeronetColors.danger
                    : ZeronetColors.danger.withValues(alpha: 0.5),
                width: 2,
              ),
              color: _holding
                  ? ZeronetColors.danger.withValues(alpha: 0.12 + _holdController.value * 0.15)
                  : Colors.transparent,
            ),
            child: Stack(
              children: [
                // Progress fill
                if (_holding)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _holdController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: ZeronetColors.danger.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                // Label
                Center(
                  child: Text(
                    _holding ? 'HOLD...' : 'HOLD 3S FOR EMERGENCY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ZeronetColors.danger,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
