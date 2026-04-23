import 'package:flutter/material.dart';
import '../config/emergency_dispatch_config.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _crashThreshold = 0.5; // 0=Low, 0.5=Medium, 1=High
  bool _bleMeshActive = true;
  bool _satelliteFallback = false;
  bool get _dispatchConfigured => EmergencyDispatchConfig.isConfigured;

  String get _thresholdLabel {
    if (_crashThreshold < 0.33) return 'LOW';
    if (_crashThreshold < 0.66) return 'MEDIUM';
    return 'HIGH';
  }

  Color get _thresholdColor {
    if (_crashThreshold < 0.33) return ZeronetColors.success;
    if (_crashThreshold < 0.66) return ZeronetColors.primary;
    return ZeronetColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: ZeronetColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Configure device parameters.',
                style: TextStyle(
                  fontSize: 14,
                  color: ZeronetColors.textTertiary,
                ),
              ),
              const SizedBox(height: 32),

              // ─── Sensor Sensitivity ───
              _sectionHeader('SENSOR SENSITIVITY'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Crash Threshold',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ZeronetColors.textPrimary,
                          ),
                        ),
                        Text(
                          _thresholdLabel,
                          style: ZeronetTheme.mono.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _thresholdColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _crashThreshold,
                      onChanged: (v) => setState(() => _crashThreshold = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ─── Emergency Contacts ───
              _sectionHeader('EMERGENCY CONTACTS'),
              const SizedBox(height: 12),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _contactRow(
                      name: 'Dispatch Center',
                      phone: '+1 800 555 0199',
                      filled: true,
                    ),
                    _divider(),
                    _contactRow(
                      name: 'Add Contact 2',
                      filled: false,
                    ),
                    _divider(),
                    _contactRow(
                      name: 'Add Contact 3',
                      filled: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ─── Emergency Backend ───
              _sectionHeader('EMERGENCY BACKEND'),
              const SizedBox(height: 12),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _toggleRow(
                      icon: _dispatchConfigured
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      iconColor: _dispatchConfigured
                          ? ZeronetColors.success
                          : ZeronetColors.warning,
                      title: _dispatchConfigured
                          ? 'Dispatch Endpoint Configured'
                          : 'Dispatch Endpoint Missing',
                      subtitle: _dispatchConfigured
                          ? EmergencyDispatchConfig.endpoint
                          : 'Set ZERONET_EMERGENCY_ENDPOINT with --dart-define to enable real emergency uploads.',
                      value: _dispatchConfigured,
                      enabled: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ─── Transmission Network ───
              _sectionHeader('TRANSMISSION NETWORK'),
              const SizedBox(height: 12),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _toggleRow(
                      icon: Icons.bluetooth,
                      iconColor: ZeronetColors.primary,
                      title: 'BLE Mesh Active',
                      subtitle: 'Relay alerts via nearby peers',
                      value: _bleMeshActive,
                      onChanged: (v) =>
                          setState(() => _bleMeshActive = v),
                    ),
                    _divider(),
                    _toggleRow(
                      icon: Icons.satellite_alt_rounded,
                      iconColor: ZeronetColors.warning,
                      title: 'Satellite Fallback',
                      subtitle: 'Requires unobstructed sky view',
                      value: _satelliteFallback,
                      onChanged: (v) =>
                          setState(() => _satelliteFallback = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ZeronetColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: ZeronetColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: ZeronetColors.surfaceBorder.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: ZeronetColors.surfaceBorder.withValues(alpha: 0.3),
      indent: 60,
    );
  }

  Widget _contactRow({
    required String name,
    String? phone,
    required bool filled,
  }) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: ZeronetColors.surfaceLight,
              child: Icon(
                Icons.person_outline_rounded,
                color: ZeronetColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: filled
                          ? ZeronetColors.textPrimary
                          : ZeronetColors.primary,
                    ),
                  ),
                  if (phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: ZeronetTheme.mono.copyWith(
                        fontSize: 13,
                        color: ZeronetColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ZeronetColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ZeronetColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: ZeronetColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
