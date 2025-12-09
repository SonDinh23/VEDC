import 'package:app_vedc/features/authentication/screens/login/login_screen.dart';
import 'package:app_vedc/features/authentication/screens/onboarding/onboarding.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _background = VedcColors.background;
  static const _cardColor = VedcColors.surface;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VedcSizes.lg,
            vertical: VedcSizes.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(VedcSizes.radiusLg),
                        border: Border.all(
                          color: VedcColors.primary.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VedcColors.primary.withValues(alpha: 0.14),
                            blurRadius: 28,
                            spreadRadius: 1,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(VedcSizes.radiusLg),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      VedcColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      Colors.white,
                                    ],
                                    center: Alignment.topLeft,
                                    radius: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(VedcSizes.lg),
                                child: Image.asset(
                                  'assets/images/devices/Product_Camera_Side1.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VedcSizes.spaceBtwSections),
              Text(
                'Welcome to VitalX VEDC',
                style: textTheme.headlineSmall?.copyWith(
                  color: VedcColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: VedcSizes.sm),
              Text(
                'This is a health monitoring device',
                style: textTheme.bodyLarge?.copyWith(
                  color: VedcColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: VedcSizes.spaceBtwSections),
              _WelcomeButton(
                label: 'Get started',
                background: VedcColors.primary,
                foreground: VedcColors.black,
                onTap: () => Get.to(
                  () => const OnBoardingScreen(),
                  transition: Transition.fadeIn,
                ),
              ),
              const SizedBox(height: VedcSizes.sm),
              _WelcomeButton(
                label: 'Login',
                background: Colors.transparent,
                foreground: VedcColors.primaryDark,
                outlined: true,
                onTap: () => Get.to(
                  () => const LoginScreen(),
                  transition: Transition.downToUp,
                ),
              ),
              const SizedBox(height: VedcSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final buttonChild = Center(
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );

    return SizedBox(
      width: double.infinity,
      height: VedcSizes.buttonHeight,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: VedcColors.primary.withValues(alpha: 0.5),
                ),
                foregroundColor: foreground,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VedcSizes.buttonRadius),
                ),
              ),
              onPressed: onTap,
              child: buttonChild,
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: background,
                foregroundColor: foreground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VedcSizes.buttonRadius),
                ),
              ),
              onPressed: onTap,
              child: buttonChild,
            ),
    );
  }
}
