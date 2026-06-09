import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      // Firebase auth is paused — route straight into the app so the new
      // visual design is reachable without sign-in.
      if (mounted) context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Soft brand glow behind logo
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    AppColors.accentOrange.withValues(alpha: 0.08),
                    AppColors.bgPrimary,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo/chore-robotics-full-dark.png',
                  width: 260,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 18),
                _ScanLine()
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms),
              ],
            ),
          ),
          // Version tag at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Text(
                'AUTONOMOUS · OUTDOOR · OPS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 3,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.statusGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.statusGreen.withValues(alpha: 0.0),
                    AppColors.statusGreen,
                    AppColors.statusGreen.withValues(alpha: 0.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .slideX(
                  begin: -1.2,
                  end: 2.2,
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    );
  }
}
