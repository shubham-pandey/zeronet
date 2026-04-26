import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final service = context.read<DashboardService>();
      service.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Consumer<DashboardService>(
          builder: (context, service, _) {
            if (service.isLoading && service.stats == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = service.stats;
            if (stats == null) {
              return Center(
                child: Text(
                  'Unable to load dashboard',
                  style: TextStyle(color: ZeronetColors.textTertiary),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DASHBOARD',
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
                    'Real-time system status',
                    style: TextStyle(
                      fontSize: 14,
                      color: ZeronetColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Active SOS Alerts
                  _buildStatCard(
                    title: 'Active SOS Alerts',
                    value: stats.activeSosAlerts.count.toString(),
                    subtitle: 'Live incidents requiring response',
                    changePercent: stats.activeSosAlerts.changePercent,
                    changeDirection: stats.activeSosAlerts.changeDirection,
                    icon: Icons.sos,
                    color: ZeronetColors.danger,
                  ),
                  const SizedBox(height: 12),
                  // High Priority Incidents
                  _buildStatCard(
                    title: 'High Priority Incidents',
                    value: stats.highPriorityIncidents.count.toString(),
                    subtitle: stats.highPriorityIncidents.description ?? 'Requiring immediate action',
                    icon: Icons.priority_high,
                    color: ZeronetColors.warning,
                  ),
                  const SizedBox(height: 12),
                  // Responders In Field
                  _buildStatCard(
                    title: 'Responders In Field',
                    value: stats.respondersInField.count.toString(),
                    subtitle:
                        'Connected: ${stats.respondersInField.connectionRate ?? 0}%',
                    icon: Icons.people_alt,
                    color: ZeronetColors.primary,
                  ),
                  const SizedBox(height: 12),
                  // Today Resolved
                  _buildStatCard(
                    title: 'Today Resolved',
                    value: stats.todayResolved.count.toString(),
                    subtitle: 'Successfully closed incidents',
                    icon: Icons.check_circle,
                    color: ZeronetColors.success,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    int? changePercent,
    String? changeDirection,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ZeronetColors.surface,
        border: Border.all(color: ZeronetColors.surfaceBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (changePercent != null && changeDirection != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeDirection == 'up'
                        ? ZeronetColors.danger.withValues(alpha: 0.1)
                        : ZeronetColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${changeDirection == 'up' ? '+' : '-'}$changePercent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: changeDirection == 'up'
                          ? ZeronetColors.danger
                          : ZeronetColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ZeronetColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: ZeronetColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
