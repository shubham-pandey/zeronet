import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../models/api_response_models.dart';
import '../services/incidents_service.dart';
import '../theme/app_theme.dart';
import '../widgets/incident_card.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch incidents from API when screen loads
    Future.microtask(() {
      final service = context.read<IncidentsService>();
      service.getIncidents();
    });
  }

  // Demo data fallback
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

  Incident _apiIncidentToIncident(ApiIncident apiIncident) {
    return Incident(
      id: apiIncident.id,
      type: IncidentType.manual,
      timestamp: apiIncident.createdAt,
      locationName: apiIncident.location,
      maxGForce: 2.0,
      transmissionMode: TransmissionMode.wifi,
      resolved: apiIncident.status == 'resolved',
      latitude: apiIncident.latitude,
      longitude: apiIncident.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Consumer<IncidentsService>(
          builder: (context, incidentsService, _) {
            final apiIncidents = incidentsService.incidents;
            final incidents = apiIncidents.isNotEmpty
                ? apiIncidents.map(_apiIncidentToIncident).toList()
                : _demoIncidents;

            if (incidentsService.isLoading && apiIncidents.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return incidents.isEmpty ? _buildEmptyState() : _buildList(incidents, incidentsService);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: ZeronetColors.textTertiary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No incidents yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ZeronetColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your incident history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: ZeronetColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Incident> incidents, IncidentsService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HISTORY',
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
            'All reported and resolved incidents',
            style: TextStyle(
              fontSize: 14,
              color: ZeronetColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: incidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return IncidentCard(incident: incident);
              },
            ),
          ),
        ],
      ),
    );
  }
}
