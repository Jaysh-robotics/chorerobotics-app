import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/signal_bars.dart';
import '../../../core/ble/ble_service.dart';
import '../bloc/onboarding_bloc.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingBloc>().add(StartBleScan());
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
              child: BlocConsumer<OnboardingBloc, OnboardingState>(
                listener: (context, state) {
                  if (state is BleConnected) {
                    context.go('/onboarding/pair');
                  } else if (state is BleScanError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  final robots = state is BleScanning ? state.robots : <DiscoveredRobot>[];
                  final isConnecting = state is BleConnecting;
                  final isScanning = state is BleScanning;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Find Your Robot', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 2),
                        Text(
                          robots.isEmpty && isScanning
                              ? 'Scanning for nearby robots'
                              : '${robots.length} robot${robots.length == 1 ? '' : 's'} nearby',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 32),

                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                for (int i = 0; i < 3; i++)
                                  _PulseRing(delay: i * 500, size: 180.0 - (i * 40)),
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
                              if (isScanning || isConnecting)
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
                              Text(
                                isConnecting
                                    ? 'Connecting...'
                                    : isScanning
                                        ? 'Scanning via Bluetooth...'
                                        : 'Idle',
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Robot list
                        ...robots.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RobotCard(
                                robot: r,
                                onTap: () {
                                  context.read<OnboardingBloc>().add(RobotSelected(r));
                                },
                              ),
                            )),

                        if (robots.isEmpty && isScanning)
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
                                  child: const Icon(Icons.info_outline,
                                      color: AppColors.brandBlue, size: 18),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'How pairing works',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Make sure your robot is powered on and in pairing mode. The LED should be blinking white.',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                            height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Rescan button
                        OutlinedButton(
                          onPressed: isConnecting
                              ? null
                              : () {
                                  context.read<OnboardingBloc>().add(StartBleScan());
                                },
                          child: Text(isScanning ? 'Rescan' : 'Scan Again'),
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Can't find your robot?",
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotCard extends StatelessWidget {
  final DiscoveredRobot robot;
  final VoidCallback onTap;
  const _RobotCard({required this.robot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BrandCard(
        borderColor: AppColors.brandBlue,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgCard, AppColors.brandBlue.withValues(alpha: 0.04)],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.bgSurface,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    robot.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: AppColors.brandBlue),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RSSI ${robot.rssi} dBm',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Signal',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                SignalBars(strength: robot.signalBars),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, duration: 300.ms),
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
