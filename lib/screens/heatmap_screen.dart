import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/heatmap_service.dart';
import '../theme/app_theme.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  String _selectedTimeRange = 'week';

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  void _loadHeatmapData() {
    Future.microtask(() {
      final service = context.read<HeatmapService>();
      service.getHeatmapData(timeRange: _selectedTimeRange);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Consumer<HeatmapService>(
          builder: (context, service, _) {
            if (service.isLoading && service.heatmapData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = service.heatmapData;
            final points = data?.points ?? [];
            final stats = data?.stats;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HEATMAP',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: ZeronetColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (service.isLoading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(ZeronetColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Incident hotspots visualization',
                    style: TextStyle(
                      fontSize: 14,
                      color: ZeronetColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Time range selector
                  Row(
                    children: [
                      _buildTimeRangeButton('Day', 'day'),
                      const SizedBox(width: 8),
                      _buildTimeRangeButton('Week', 'week'),
                      const SizedBox(width: 8),
                      _buildTimeRangeButton('Month', 'month'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  if (stats != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ZeronetColors.surface,
                        border: Border.all(color: ZeronetColors.surfaceBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Hotspots',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ZeronetColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stats.totalHotspots.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: ZeronetColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Avg Response Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ZeronetColors.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stats.avgResponseTime,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: ZeronetColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Points list
                  if (points.isEmpty)
                    Center(
                      child: Text(
                        'No hotspots data available',
                        style: TextStyle(color: ZeronetColors.textTertiary),
                      ),
                    )
                  else ...[
                    Text(
                      'Incident Points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ZeronetColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: points.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final point = points[index];
                        return _buildPointCard(point);
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, String value) {
    final isSelected = _selectedTimeRange == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTimeRange = value);
          Future.microtask(() {
            final service = context.read<HeatmapService>();
            service.getHeatmapData(timeRange: value);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ZeronetColors.primary.withValues(alpha: 0.1) : ZeronetColors.surface,
            border: Border.all(
              color: isSelected ? ZeronetColors.primary : ZeronetColors.surfaceBorder,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? ZeronetColors.primary : ZeronetColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointCard(dynamic point) {
    final typeColor = _getTypeColor(point.type);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZeronetColors.surface,
        border: Border.all(color: ZeronetColors.surfaceBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      point.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: ZeronetColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Weight',
                style: TextStyle(
                  fontSize: 10,
                  color: ZeronetColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(point.weight * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ZeronetColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'critical':
        return ZeronetColors.danger;
      case 'moderate':
        return ZeronetColors.warning;
      case 'low':
        return ZeronetColors.success;
      default:
        return ZeronetColors.primary;
    }
  }
}
