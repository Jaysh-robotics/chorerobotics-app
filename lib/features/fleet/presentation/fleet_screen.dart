import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Robot Fleet', style: Theme.of(context).textTheme.headlineLarge),
                        const Text('Manage your robots', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.brandBlue,
                    ),
                    child: const Icon(PhosphorIconsBold.plus, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    // Robot 1 — Active
                    _RobotCard(
                      name: 'ChoreBot Alpha',
                      model: 'Model X1',
                      serial: 'CHORE-A1B2-C3D4',
                      attachment: 'Mower Blade',
                      battery: 78,
                      status: 'Online',
                      isActive: true,
                      firmware: 'v1.0.0',
                      lastSeen: 'Connected now',
                    ).animate().fadeIn(duration: 200.ms),
                    const SizedBox(height: 10),

                    // Robot 2 — Offline
                    _RobotCard(
                      name: 'ChoreBot Beta',
                      model: 'Model X1 Pro',
                      serial: 'CHORE-E5F6-G7H8',
                      attachment: 'Snow Plow',
                      battery: 42,
                      status: 'Offline',
                      isActive: false,
                      firmware: 'v1.0.0',
                      lastSeen: '3 hours ago',
                    ).animate().fadeIn(delay: 100.ms, duration: 200.ms),
                    const SizedBox(height: 10),

                    // Robot 3 — Charging
                    _RobotCard(
                      name: 'ChoreBot Gamma',
                      model: 'Model X2',
                      serial: 'CHORE-I9J0-K1L2',
                      attachment: 'Leaf Collector',
                      battery: 95,
                      status: 'Charging',
                      isActive: false,
                      firmware: 'v1.1.0-beta',
                      lastSeen: '15 min ago',
                    ).animate().fadeIn(delay: 200.ms, duration: 200.ms),

                    const SizedBox(height: 24),

                    // Add robot hint
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.blueDim,
                              ),
                              child: const Icon(PhosphorIconsBold.plus, size: 24, color: AppColors.brandBlue),
                            ),
                            const SizedBox(height: 12),
                            const Text('Add Another Robot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Pair a new ChoreBot to your account', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotCard extends StatelessWidget {
  final String name, model, serial, attachment, firmware, lastSeen, status;
  final int battery;
  final bool isActive;

  const _RobotCard({
    required this.name, required this.model, required this.serial,
    required this.attachment, required this.battery, required this.status,
    required this.isActive, required this.firmware, required this.lastSeen,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      'Online' => AppColors.statusGreen,
      'Charging' => AppColors.brandBlue,
      'Offline' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };

    return BrandCard(
      borderColor: isActive ? AppColors.brandBlue.withValues(alpha: 0.2) : null,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive ? AppColors.blueDim : AppColors.bgSurface,
                ),
                child: Icon(PhosphorIconsBold.robot, size: 24, color: isActive ? AppColors.brandBlue : AppColors.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isActive ? AppColors.textPrimary : AppColors.textSecondary)),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          const BrandBadge(label: 'Active', variant: BadgeVariant.blue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$model · $attachment', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                      const SizedBox(width: 4),
                      Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$battery%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brandBlue, fontFamily: 'monospace')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(serial, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
                Text('FW $firmware · $lastSeen', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
