import 'package:flutter/material.dart';
import '../models/incident.dart';
import '../theme/app_theme.dart';
import '../widgets/incident_card.dart';

class IncidentHistoryScreen extends StatelessWidget {
  const IncidentHistoryScreen({super.key});

  // Demo data
  List<Incident> get _demoIncidents => [
        Incident(
          id: '1',
          type: IncidentType.crash,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          locationName: 'Sector 4, Main Hall',
          maxGForce: 3.2,
          transmissionMode: TransmissionMode.wifi,
          resolved: false,
        ),
        Incident(
          id: '2',
          type: IncidentType.fall,
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 7)),
          locationName: 'Loading Dock B',
          maxGForce: 1.8,
          transmissionMode: TransmissionMode.bleMesh,
          resolved: true,
        ),
        Incident(
          id: '3',
          type: IncidentType.falseAlarm,
          timestamp: DateTime(2025, 10, 12, 11, 0),
          locationName: 'Stairwell C',
          maxGForce: 2.1,
          transmissionMode: TransmissionMode.wifi,
          resolved: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final incidents = _demoIncidents;

    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: incidents.isEmpty ? _buildEmptyState() : _buildList(incidents),
      ),
    );
  }

  Widget _buildList(List<Incident> incidents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'INCIDENT HISTORY',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: ZeronetColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chronological record of events.',
            style: TextStyle(
              fontSize: 14,
              color: ZeronetColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: incidents.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return IncidentCard(incident: incidents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 64,
            color: ZeronetColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No incidents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ZeronetColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay safe out there.',
            style: TextStyle(
              fontSize: 14,
              color: ZeronetColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
