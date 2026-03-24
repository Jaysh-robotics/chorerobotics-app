import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/signal_bars.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> with TickerProviderStateMixin {
  bool _robotFound = false;

  @override
  void initState() {
    super.initState();
    // Simulate finding robot after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _robotFound = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const StepIndicator(totalSteps: 4, currentStep: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text('Find Your Robot', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 2),
                    Text('Scanning for nearby robots', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 32),

                    // Scanning Animation
                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse rings
                            for (int i = 0; i < 3; i++)
                              _PulseRing(delay: i * 500, size: 180.0 - (i * 40)),
                            // Center icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.blueDim,
                              ),
                              child: const Icon(
                                Icons.bluetooth_searching,
                                color: AppColors.brandBlue,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandBlue,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .fadeIn(duration: 750.ms)
                              .then()
                              .fadeOut(duration: 750.ms),
                          const SizedBox(width: 8),
                          const Text(
                            'Scanning via Bluetooth...',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Robot Found Card
                    if (_robotFound)
                      BrandCard(
                        borderColor: AppColors.brandBlue,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.bgCard, AppColors.brandBlue.withValues(alpha: 0.04)],
                        ),
                        child: Row(
                          children: [
                            // Robot image placeholder
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.bgSurface,
                              ),
                              child: const Icon(Icons.smart_toy_outlined, color: AppColors.textMuted, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ChoreBot Alpha',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandBlue),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Found nearby',
                                        style: TextStyle(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Signal', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(height: 4),
                                const SignalBars(strength: 4),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.05, duration: 300.ms),

                    const SizedBox(height: 12),

                    // Info card
                    BrandCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColors.blueDim,
                            ),
                            child: const Icon(Icons.info_outline, color: AppColors.brandBlue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How pairing works',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your phone connects directly to the robot over Bluetooth, then sets up a secure link. You\'ll enter a code shown on the robot\'s display.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pair button
                    ElevatedButton(
                      onPressed: _robotFound ? () => context.go('/onboarding/pair') : null,
                      child: const Text('Pair This Robot'),
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Can\'t find your robot?',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
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

class _PulseRing extends StatelessWidget {
  final int delay;
  final double size;
  const _PulseRing({required this.delay, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.brandBlue.withValues(alpha: 0.12),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.3, 1.3),
          duration: 3000.ms,
          delay: Duration(milliseconds: delay),
        )
        .fadeOut(duration: 3000.ms, delay: Duration(milliseconds: delay));
  }
}
