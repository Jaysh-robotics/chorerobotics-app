import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final List<String> _code = ['4', '7', '2', '9', '', ''];
  final int _activeIndex = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const StepIndicator(totalSteps: 4, currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Robot Found', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 2),
                    Text('Confirm this is your robot', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 20),

                    // Robot Found Card
                    BrandCard(
                      borderColor: AppColors.brandBlue,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.bgCard, AppColors.brandBlue.withValues(alpha: 0.04)],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.bgSurface,
                            ),
                            child: const Icon(Icons.smart_toy_outlined, color: AppColors.textMuted, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ChoreBot Alpha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  'UUID: CHORE-A1B2-C3D4',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'monospace'),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.brandBlue,
                                        boxShadow: [BoxShadow(color: AppColors.brandBlue.withValues(alpha: 0.5), blurRadius: 6)],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('BLE Signal Strong — 3m away', style: TextStyle(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 8),

                    // UUID Verification
                    BrandCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VERIFY DEVICE ID', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 12),
                          const Text(
                            'Check the label on your robot matches this ID:',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderActive, style: BorderStyle.solid),
                            ),
                            child: const Center(
                              child: Text(
                                'CHORE-A1B2-C3D4',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                  color: AppColors.brandBlue,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 8),

                    // Attachment Detected
                    BrandCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ATTACHMENT DETECTED', style: Theme.of(context).textTheme.labelSmall),
                              const BrandBadge(label: 'Connected', variant: BadgeVariant.blue, showDot: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: AppColors.purpleDim,
                                ),
                                child: const Icon(Icons.content_cut, color: AppColors.brandPurple, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Mower Blade Assembly', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text('ATT-7F3E-9A1B', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 8),

                    // Pairing Code
                    BrandCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ENTER PAIRING CODE', style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 12),
                          const Text(
                            'Enter the 6-digit code shown on the robot\'s display:',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              final hasValue = index < _code.length && _code[index].isNotEmpty;
                              final isActive = index == _activeIndex;
                              return Container(
                                width: 48,
                                height: 56,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.brandBlue
                                        : hasValue
                                            ? AppColors.brandBlue
                                            : AppColors.border,
                                    width: isActive ? 2 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    hasValue ? _code[index] : '_',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                      color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () => context.go('/onboarding/wifi'),
                      child: const Text('Pair This Robot'),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text('This isn\'t my robot', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ),
                    ),
                    const SizedBox(height: 40),
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
