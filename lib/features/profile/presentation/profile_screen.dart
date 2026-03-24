import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/connection_bar.dart';
import '../../../core/widgets/brand_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  children: [
                    // Avatar + Name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.brandBlue, AppColors.brandPurple],
                              ),
                            ),
                            child: const Center(
                              child: Text('JS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Jay Shah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          const Text('jay@chorerobotics.com', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // My Robots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('MY ROBOTS', style: Theme.of(context).textTheme.labelSmall),
                        GestureDetector(
                          onTap: () => context.push('/fleet'),
                          child: Text('Manage Fleet', style: TextStyle(fontSize: 12, color: AppColors.brandMagenta, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Active robot
                    BrandCard(
                      borderColor: AppColors.brandBlue.withValues(alpha: 0.2),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.bgSurface),
                            child: const Icon(PhosphorIconsBold.robot, size: 22, color: AppColors.brandBlue),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ChoreBot Alpha', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('Model X1 · Mower Blade', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.statusGreen)),
                                const SizedBox(width: 4),
                                const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.statusGreen)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Second robot (offline)
                    BrandCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppColors.bgSurface),
                            child: const Icon(PhosphorIconsBold.robot, size: 22, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ChoreBot Beta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                                SizedBox(height: 2),
                                Text('Model X1 Pro · Snow Plow', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text('Offline', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account sections
                    Text('ACCOUNT', style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 8),
                    _ProfileTile(icon: PhosphorIconsBold.user, label: 'Edit Profile'),
                    _ProfileTile(icon: PhosphorIconsBold.bell, label: 'Notifications'),
                    _ProfileTile(icon: PhosphorIconsBold.shieldCheck, label: 'Security & Privacy'),
                    _ProfileTile(icon: PhosphorIconsBold.gear, label: 'App Settings', onTap: () => context.push('/settings')),
                    _ProfileTile(icon: PhosphorIconsBold.question, label: 'Help & Support'),
                    _ProfileTile(icon: PhosphorIconsBold.fileText, label: 'Legal'),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/auth'),
                        icon: Icon(PhosphorIconsBold.signOut, size: 18, color: AppColors.accentRed),
                        label: Text('Sign Out', style: TextStyle(color: AppColors.accentRed)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(child: Text('ChoreRobotics v1.0.0', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
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

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ProfileTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
