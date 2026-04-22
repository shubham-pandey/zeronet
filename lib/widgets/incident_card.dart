import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/incident.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

/// Expandable card for the Incident History list.
class IncidentCard extends StatefulWidget {
  final Incident incident;

  const IncidentCard({super.key, required this.incident});

  @override
  State<IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<IncidentCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return 'Today,  ${DateFormat('HH:mm').format(dt)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday,  ${DateFormat('HH:mm').format(dt)}';
    } else {
      return DateFormat('MMM d,  HH:mm').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final dimOpacity = incident.resolved ? 0.6 : 1.0;

    return Opacity(
      opacity: dimOpacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: ZeronetColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ZeronetColors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Header — always visible
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    StatusChip(
                      label: incident.typeLabel,
                      color: incident.typeColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTimestamp(incident.timestamp),
                            style: ZeronetTheme.mono.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ZeronetColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: ZeronetColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                incident.locationName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: ZeronetColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ZeronetColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded detail
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildDetail(context, incident),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Incident incident) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Video clip placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: ZeronetColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ZeronetColors.surfaceBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  size: 36,
                  color: ZeronetColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Buffered Clip',
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 12,
                    color: ZeronetColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _statCard(
                context,
                'MAX FORCE',
                '${incident.maxGForce.toStringAsFixed(1)}G',
                Icons.show_chart_rounded,
                ZeronetColors.warning,
              ),
              const SizedBox(width: 10),
              _statCard(
                context,
                'TRANSMISSION',
                incident.transmissionLabel,
                Icons.wifi,
                ZeronetColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ZeronetColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ZeronetColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
