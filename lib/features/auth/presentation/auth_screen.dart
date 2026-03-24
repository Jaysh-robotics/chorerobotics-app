import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_input.dart';
import '../bloc/auth_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go(state.hasRobotPaired ? '/dashboard' : '/onboarding/scan');
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo/chore-robots-logo.png',
                      width: 180,
                      height: 124,
                      fit: BoxFit.contain,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 600.ms),

                    const SizedBox(height: 4),
                    Text(
                      'Autonomous lawn care,\nsnow clearing & more',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 48),

                    // Email
                    const BrandInput(
                      label: 'Email',
                      hint: 'you@example.com',
                      initialValue: 'jay@chorerobotics.com',
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                    const SizedBox(height: 16),

                    // Password
                    BrandInput(
                      label: 'Password',
                      hint: 'Enter password',
                      initialValue: '••••••••••',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                    const SizedBox(height: 16),

                    // Remember me + Forgot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.brandBlue,
                                    width: 1.5,
                                  ),
                                  color: _rememberMe ? AppColors.blueDim : Colors.transparent,
                                ),
                                child: _rememberMe
                                    ? const Icon(Icons.check, size: 12, color: AppColors.brandBlue)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember me',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 24),

                    // Sign In Button
                    Builder(
                      builder: (context) {
                        return BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      context.read<AuthBloc>().add(
                                            const AuthLoginRequested(
                                              email: 'jay@chorerobotics.com',
                                              password: 'password',
                                            ),
                                          );
                                    },
                              child: state is AuthLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign In'),
                            );
                          },
                        );
                      },
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05),

                    const SizedBox(height: 12),

                    // Create Account
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Create Account'),
                    ).animate().fadeIn(delay: 650.ms),

                    const SizedBox(height: 32),

                    // Guest
                    GestureDetector(
                      onTap: () => context.go('/onboarding/scan'),
                      child: const Text(
                        'Continue as Guest',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
