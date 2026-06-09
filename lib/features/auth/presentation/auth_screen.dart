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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go(state.hasRobotPaired ? '/dashboard' : '/onboarding/scan');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.brandRed),
            );
          } else if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Reset email sent to ${state.email}')),
            );
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
                    Image.asset(
                      'assets/logo/chore-robotics-full-dark.png',
                      width: 240,
                      fit: BoxFit.contain,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutCubic),

                    const SizedBox(height: 20),
                    Text(
                      'Autonomous lawn care, snow clearing & more',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                    const SizedBox(height: 40),

                    BrandInput(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                    const SizedBox(height: 16),

                    BrandInput(
                      label: 'Password',
                      hint: 'Enter password',
                      controller: _passwordCtrl,
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
                                  border: Border.all(color: AppColors.brandBlue, width: 1.5),
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
                        Builder(builder: (context) {
                          return GestureDetector(
                            onTap: () {
                              final email = _emailCtrl.text.trim();
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Enter your email first.')),
                                );
                                return;
                              }
                              context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ],
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 24),

                    // Sign In
                    Builder(builder: (context) {
                      return BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final loading = state is AuthLoading;
                          return ElevatedButton(
                            onPressed: loading ? null : () => _submitLogin(context),
                            child: loading
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
                    }).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05),

                    const SizedBox(height: 12),

                    Builder(builder: (context) {
                      return OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthGoogleRequested());
                        },
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('Continue with Google'),
                      );
                    }).animate().fadeIn(delay: 650.ms),

                    const SizedBox(height: 12),

                    Builder(builder: (context) {
                      return TextButton(
                        onPressed: () => _submitSignUp(context),
                        child: const Text('Create Account'),
                      );
                    }).animate().fadeIn(delay: 675.ms),

                    const SizedBox(height: 16),

                    Builder(builder: (context) {
                      return GestureDetector(
                        onTap: () {
                          context.read<AuthBloc>().add(AuthGuestRequested());
                        },
                        child: const Text(
                          'Continue as Guest',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      );
                    }).animate().fadeIn(delay: 700.ms),

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

  void _submitLogin(BuildContext context) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password.')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthLoginRequested(
          email: email,
          password: password,
          rememberMe: _rememberMe,
        ));
  }

  void _submitSignUp(BuildContext context) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and a password (min 6 chars).')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthSignUpRequested(email: email, password: password));
  }
}
