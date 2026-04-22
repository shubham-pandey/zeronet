import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pulse_ring.dart';
import '../widgets/sos_button.dart';
import '../services/sensor_service.dart';
import '../models/incident.dart';
import 'crash_detected_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensorService = context.watch<SensorService>();

    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Top status bar
              _buildTopBar(context, sensorService),
              const Spacer(flex: 2),
              // Pulse ring + sensor status
              _buildSensorHub(context, sensorService),
              const Spacer(flex: 3),
              // Location card
              _buildLocationCard(context, sensorService),
              const SizedBox(height: 16),
              // SOS button
              SosButton(
                onTriggered: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CrashDetectedScreen(
                        isManual: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, String title, String details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ZeronetColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: ZeronetColors.textPrimary)),
        content: Text(details, style: const TextStyle(color: ZeronetColors.textSecondary, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('GOT IT', style: TextStyle(color: ZeronetColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, SensorService sensorService) {
    return Row(
      children: [
        // Protected badge
        GestureDetector(
          onTap: () => _showDetailDialog(context, 'Security Status', sensorService.isMonitoring ? 'Monitoring Active:\nSensors are actively tracking location and G-force anomalies.' : 'Monitoring Offline:\nSensors and background tracking are disabled.'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ZeronetColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ZeronetColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ZeronetColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  sensorService.isMonitoring ? 'PROTECTED' : 'DISABLED',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: sensorService.isMonitoring 
                        ? ZeronetColors.success 
                        : ZeronetColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Signal bars
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showDetailDialog(context, 'Connectivity Strength', 'Signal Quality: ${sensorService.signalBars}/4 bars\nActive Mode: ${_getTransmissionLabel(sensorService.currentMode)}\n\nThis dictates how far offline mesh packets can be routed seamlessly.'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: _buildSignalIcon(sensorService.signalBars),
          ),
        ),
        const SizedBox(width: 8),
        // BLE peers
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showDetailDialog(context, 'Bluetooth LE Mesh', '${sensorService.blePeerCount} active peers discovered nearby.\n\nThe offline relay loop shares incident broadcasts automatically to devices within 30-80 meters.'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                const Icon(Icons.bluetooth, size: 18, color: ZeronetColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${sensorService.blePeerCount}',
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ZeronetColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Battery
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showDetailDialog(context, 'Device Battery', '${sensorService.batteryPercent}% Remaining.\n\nA minimum amount of battery is preserved dynamically to allow SOS location beaconing before hardware shutdown.'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                Text(
                  '${sensorService.batteryPercent}%',
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sensorService.batteryPercent > 20 
                        ? ZeronetColors.success 
                        : const Color(0xFFFF4444),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _getBatteryIcon(sensorService.batteryPercent),
                  size: 20,
                  color: sensorService.batteryPercent > 20 
                      ? ZeronetColors.success 
                      : const Color(0xFFFF4444),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getBatteryIcon(int percentage) {
    if (percentage > 85) return Icons.battery_full_rounded;
    if (percentage > 50) return Icons.battery_5_bar_rounded;
    if (percentage > 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  Widget _buildSignalIcon(int bars) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return Container(
          width: 4,
          height: 6.0 + (i * 4),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: i < bars ? ZeronetColors.success : ZeronetColors.surfaceLight,
          ),
        );
      }),
    );
  }

  Widget _buildSensorHub(BuildContext context, SensorService sensorService) {
    return GestureDetector(
      onTap: () => _showDetailDialog(context, 'Accelerometer', 'Current g-force reading is ${sensorService.currentGForce.toStringAsFixed(3)} G.\n\nA severe spike implies a fall or collision.'),
      child: PulseRing(
        size: 190,
        active: sensorService.isMonitoring,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_rounded,
              size: 48,
              color: ZeronetColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              sensorService.isMonitoring 
                ? '${sensorService.currentGForce.toStringAsFixed(2)} G' 
                : 'OFFLINE',
              style: ZeronetTheme.mono.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ZeronetColors.primary,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, SensorService sensorService) {
    return GestureDetector(
      onTap: () => _showDetailDialog(context, 'Location Details', 'Raw GPS Coordinates:\nLat: ${sensorService.latitude.toStringAsFixed(6)}\nLng: ${sensorService.longitude.toStringAsFixed(6)}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ZeronetColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ZeronetColors.surfaceBorder.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            // Location pin
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ZeronetColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: ZeronetColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST KNOWN LOCATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: ZeronetColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sensorService.lastLocation,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ZeronetColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'MODE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ZeronetColors.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTransmissionLabel(sensorService.currentMode),
                  style: ZeronetTheme.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ZeronetColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTransmissionLabel(TransmissionMode mode) {
    switch (mode) {
      case TransmissionMode.wifi:
        return 'WIFI';
      case TransmissionMode.satellite:
        return 'CELL';
      case TransmissionMode.bleMesh:
        return 'BLE';
      case TransmissionMode.offlineCached:
        return 'NONE';
      case TransmissionMode.wifiDirect:
        return 'DIRECT';
    }
  }
}
