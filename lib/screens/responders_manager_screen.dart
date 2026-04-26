import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/responders_service.dart';
import '../theme/app_theme.dart';

class RespondersScreen extends StatefulWidget {
  const RespondersScreen({super.key});

  @override
  State<RespondersScreen> createState() => _RespondersScreenState();
}

class _RespondersScreenState extends State<RespondersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final service = context.read<RespondersService>();
      service.getResponders(status: 'available');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZeronetColors.background,
      body: SafeArea(
        child: Consumer<RespondersService>(
          builder: (context, service, _) {
            if (service.isLoading && service.responders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final responders = service.responders;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RESPONDERS',
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
                    'Available responders in your organization',
                    style: TextStyle(
                      fontSize: 14,
                      color: ZeronetColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (responders.isEmpty)
                    Center(
                      child: Text(
                        'No responders available',
                        style: TextStyle(color: ZeronetColors.textTertiary),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: responders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final responder = responders[index];
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            responder.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: ZeronetColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            responder.role,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ZeronetColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: responder.status == 'available'
                                            ? ZeronetColors.success.withValues(alpha: 0.1)
                                            : ZeronetColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        responder.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: responder.status == 'available'
                                              ? ZeronetColors.success
                                              : ZeronetColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: ZeronetColors.textTertiary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Lat: ${responder.latitude.toStringAsFixed(4)}, Lng: ${responder.longitude.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ZeronetColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
