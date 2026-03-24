import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_input.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  int _selectedNetwork = 0;
  final _networks = [
    ('HomeWiFi-5G', 4, true),
    ('HomeWiFi-2.4G', 3, true),
    ('Neighbor_Net', 1, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const StepIndicator(totalSteps: 4, currentStep: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connect to Wi-Fi', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 2),
                    Text('Add your robot to your home network', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 20),

                    // Success Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.blueDim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandBlue),
                            child: const Icon(Icons.check, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Paired securely with ChoreBot Alpha',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandBlue),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),

                    // Why Connect
                    BrandCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppColors.blueDim),
                            child: const Icon(Icons.wifi, color: AppColors.brandBlue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Why connect to Wi-Fi?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text(
                                  'Wi-Fi gives you the best experience — faster response, cloud features, and automatic updates. You can always use direct connection as a backup.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Network Picker
                    BrandCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('AVAILABLE NETWORKS', style: Theme.of(context).textTheme.labelSmall),
                              Text('${_networks.length} found', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(_networks.length, (index) {
                            final (name, strength, secured) = _networks[index];
                            final isSelected = index == _selectedNetwork;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedNetwork = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  border: index < _networks.length - 1
                                      ? const Border(bottom: BorderSide(color: AppColors.border))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Radio
                                    Container(
                                      width: 20, height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColors.brandBlue : AppColors.border,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Center(
                                              child: Container(
                                                width: 10, height: 10,
                                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandBlue),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      strength >= 3 ? Icons.wifi : strength >= 2 ? Icons.wifi_2_bar : Icons.wifi_1_bar,
                                      size: 18,
                                      color: isSelected ? AppColors.textSecondary : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    if (secured)
                                      Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 8),

                    // Password
                    BrandCard(
                      child: BrandInput(
                        label: 'Password for ${_networks[_selectedNetwork].$1}',
                        hint: 'Enter Wi-Fi password',
                        initialValue: '••••••••••',
                        obscureText: true,
                        suffixIcon: TextButton(
                          onPressed: () {},
                          child: const Text('Show', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () => context.go('/onboarding/complete'),
                      child: const Text('Connect Robot to Wi-Fi'),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/onboarding/complete'),
                        child: const Text(
                          'Skip — use direct connection only',
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
