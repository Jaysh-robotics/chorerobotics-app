import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/step_indicator.dart';
import '../../../core/widgets/brand_card.dart';
import '../../../core/widgets/brand_badge.dart';
import '../bloc/onboarding_bloc.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();
  bool get _isComplete => _code.length == 6 && _code.runes.every((r) => r >= 0x30 && r <= 0x39);

  void _onChanged(int idx, String v) {
    if (v.isNotEmpty && idx < 5) {
      _nodes[idx + 1].requestFocus();
    } else if (v.isEmpty && idx > 0) {
      _nodes[idx - 1].requestFocus();
    }
    setState(() {});
  }

  void _submit() {
    if (!_isComplete) return;
    context.read<OnboardingBloc>().add(PairingCodeEntered(_code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is PairingSuccess) {
              context.go('/onboarding/wifi');
            } else if (state is PairingFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.reason), backgroundColor: AppColors.brandRed),
              );
              for (final c in _ctrls) {
                c.clear();
              }
              _nodes[0].requestFocus();
            } else if (state is BleScanError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.brandRed),
              );
            }
          },
          builder: (context, state) {
            if (state is! BleConnected && state is! PairingInProgress && state is! PairingSuccess) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Not connected. Go back and select a robot.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              );
            }

            final info = switch (state) {
              BleConnected s => s.info,
              PairingInProgress s => s.info,
              PairingSuccess s => s.info,
              _ => null,
            };
            final ledState = switch (state) {
              BleConnected s => s.ledState,
              PairingInProgress s => s.ledState,
              _ => 0,
            };
            final isSending = state is PairingInProgress;

            return Column(
              children: [
                const StepIndicator(totalSteps: 4, currentStep: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Robot Connected', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 2),
                        Text('Enter the code shown on the robot',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 20),

                        BrandCard(
                          borderColor: AppColors.brandBlue,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.bgCard,
                              AppColors.brandBlue.withValues(alpha: 0.04)
                            ],
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
                                child: const Icon(Icons.smart_toy_outlined,
                                    color: AppColors.textMuted, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(info?.name ?? 'Robot',
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Serial: ${info?.serial ?? '-'}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          fontFamily: 'monospace'),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.brandBlue,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: AppColors.brandBlue.withValues(alpha: 0.5),
                                                  blurRadius: 6)
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _ledLabel(ledState),
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
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),

                        const SizedBox(height: 8),

                        BrandCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ATTACHMENT',
                                      style: Theme.of(context).textTheme.labelSmall),
                                  const BrandBadge(
                                      label: 'Detected',
                                      variant: BadgeVariant.blue,
                                      showDot: true),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: AppColors.purpleDim,
                                    ),
                                    child: const Icon(Icons.content_cut,
                                        color: AppColors.brandPurple, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info?.attachment.isNotEmpty == true
                                            ? info!.attachment
                                            : 'None',
                                        style: const TextStyle(
                                            fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Firmware ${info?.firmware ?? '-'}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                            fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 8),

                        BrandCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ENTER PAIRING CODE',
                                  style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: 12),
                              const Text(
                                "Enter the 6-digit code shown on the robot's display:",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(6, (i) => _codeBox(i)),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: (_isComplete && !isSending) ? _submit : null,
                          child: Text(isSending ? 'Verifying...' : 'Pair This Robot'),
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: const Text(
                              "This isn't my robot",
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
            );
          },
        ),
      ),
    );
  }

  Widget _codeBox(int index) {
    final hasValue = _ctrls[index].text.isNotEmpty;
    final isActive = _nodes[index].hasFocus;
    return Container(
      width: 48,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isActive || hasValue) ? AppColors.brandBlue : AppColors.border,
          width: isActive ? 2 : 1.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          // Jump to previous box when backspace is pressed on an empty field.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _ctrls[index].text.isEmpty &&
              index > 0) {
            _ctrls[index - 1].clear();
            _nodes[index - 1].requestFocus();
            setState(() {});
          }
        },
        child: TextField(
          controller: _ctrls[index],
          focusNode: _nodes[index],
          keyboardType: TextInputType.number,
          textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => _onChanged(index, v),
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }

  String _ledLabel(int state) {
    const labels = {
      0: 'Connected',
      1: 'Discoverable',
      2: 'Found',
      3: 'Pairing',
      4: 'Awaiting code',
      5: 'Verifying code',
      6: 'Success',
      7: 'WiFi setup',
      8: 'Complete',
      9: 'Failed',
      10: 'E-STOP',
    };
    return labels[state] ?? 'Connected';
  }
}
