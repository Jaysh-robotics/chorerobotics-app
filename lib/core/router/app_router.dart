import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/ble_scan_screen.dart';
import '../../features/onboarding/presentation/pairing_screen.dart';
import '../../features/onboarding/presentation/wifi_setup_screen.dart';
import '../../features/onboarding/presentation/setup_complete_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/mowing/presentation/mowing_screen.dart';
import '../../features/snow/presentation/snow_screen.dart';
import '../../features/leaf/presentation/leaf_screen.dart';
import '../../features/scheduling/presentation/scheduling_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/fleet/presentation/fleet_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      // Auth
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      // Onboarding
      GoRoute(path: '/onboarding/scan', name: 'ble-scan', builder: (context, state) => const BleScanScreen()),
      GoRoute(path: '/onboarding/pair', name: 'pair', builder: (context, state) => const PairingScreen()),
      GoRoute(path: '/onboarding/wifi', name: 'wifi-setup', builder: (context, state) => const WifiSetupScreen()),
      GoRoute(path: '/onboarding/complete', name: 'setup-complete', builder: (context, state) => const SetupCompleteScreen()),
      // Dashboard (shell with bottom nav)
      GoRoute(path: '/dashboard', name: 'dashboard', builder: (context, state) => const DashboardShell()),
      // Task screens
      GoRoute(path: '/mowing', name: 'mowing', builder: (context, state) => const MowingScreen()),
      GoRoute(path: '/snow', name: 'snow', builder: (context, state) => const SnowScreen()),
      GoRoute(path: '/leaf', name: 'leaf', builder: (context, state) => const LeafScreen()),
      // Phase 2
      GoRoute(path: '/scheduling', name: 'scheduling', builder: (context, state) => const SchedulingScreen()),
      GoRoute(path: '/settings', name: 'settings', builder: (context, state) => const SettingsScreen()),
      // Profile & Fleet
      GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(path: '/fleet', name: 'fleet', builder: (context, state) => const FleetScreen()),
    ],
  );
}
