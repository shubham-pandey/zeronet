import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/broadcast_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _messageController = TextEditingController();
  int _selectedType = 0; // 0: Text, 1: Emergency

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleTextBroadcast(
    BroadcastService broadcastService,
    AuthService authService,
  ) async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    if (authService.currentAuth?.user.organizationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization not found')),
      );
      return;
    }

    final result = await broadcastService.sendTextBroadcast(
      organizationId: authService.currentAuth!.user.organizationId!,
      message: _messageController.text,
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent successfully!')),
        );
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(broadcastService.error ?? 'Failed to send broadcast')),
        );
      }
    }
  }

  Future<void> _handleEmergencyBroadcast(
    BroadcastService broadcastService,
    AuthService authService,
  ) async {
    if (authService.currentAuth?.user.organizationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization not found')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ZeronetColors.surface,
        title: Text(
          'Trigger Emergency Broadcast?',
          style: TextStyle(color: ZeronetColors.textPrimary),
        ),
        content: Text(
          'This will send an emergency alert to all users in your organization.',
          style: TextStyle(color: ZeronetColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ZeronetColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: TextStyle(color: ZeronetColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await broadcastService.triggerEmergencyBroadcast(
      organizationId: authService.currentAuth!.user.organizationId!,
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Emergency broadcast triggered! Notified ${result.notifiedCount ?? 0} users',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(broadcastService.error ?? 'Failed to trigger broadcast')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Consumer2<BroadcastService, AuthService>(
          builder: (context, broadcastService, authService, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BROADCAST',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: ZeronetColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send alerts to your organization',
                    style: TextStyle(
                      fontSize: 14,
                      color: ZeronetColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedType == 0
                                      ? ZeronetColors.primary
                                      : ZeronetColors.surfaceBorder,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Text Message',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == 0
                                      ? ZeronetColors.primary
                                      : ZeronetColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedType = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedType == 1
                                      ? ZeronetColors.danger
                                      : ZeronetColors.surfaceBorder,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Emergency SOS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == 1
                                      ? ZeronetColors.danger
                                      : ZeronetColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_selectedType == 0) ...[
                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      style: TextStyle(color: ZeronetColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter your message here...',
                        hintStyle: TextStyle(color: ZeronetColors.textTertiary),
                        filled: true,
                        fillColor: ZeronetColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ZeronetColors.surfaceBorder),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: broadcastService.isLoading
                            ? null
                            : () => _handleTextBroadcast(broadcastService, authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZeronetColors.primary,
                          disabledBackgroundColor:
                              ZeronetColors.primary.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: broadcastService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'SEND MESSAGE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ZeronetColors.danger.withValues(alpha: 0.1),
                        border: Border.all(color: ZeronetColors.danger),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: ZeronetColors.danger,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Emergency SOS Broadcast',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: ZeronetColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This will send an immediate high-priority alert to all users in your organization. Use only in critical emergencies.',
                            style: TextStyle(
                              fontSize: 13,
                              color: ZeronetColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: broadcastService.isLoading
                            ? null
                            : () => _handleEmergencyBroadcast(broadcastService, authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ZeronetColors.danger,
                          disabledBackgroundColor:
                              ZeronetColors.danger.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: broadcastService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'TRIGGER EMERGENCY SOS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                  if (broadcastService.lastBroadcast != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ZeronetColors.success.withValues(alpha: 0.1),
                        border: Border.all(color: ZeronetColors.success),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: ZeronetColors.success,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Broadcast Sent',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: ZeronetColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${broadcastService.lastBroadcast!.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ZeronetColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Status: ${broadcastService.lastBroadcast!.status}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ZeronetColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
}
