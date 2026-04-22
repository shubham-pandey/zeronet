import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A compact status chip used across the app for inline metadata display.
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool outlined;

  const StatusChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? ZeronetColors.textSecondary;

    if (outlined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: chipColor.withValues(alpha: 0.4)),
          color: chipColor.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: chipColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: ZeronetTheme.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: chipColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: chipColor.withValues(alpha: 0.15),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: chipColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
