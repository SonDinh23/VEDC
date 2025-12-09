import 'package:app_vedc/features/authentication/controllers_onboarding/onboarding_controller.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class OnboardingSkip extends StatelessWidget {
  const OnboardingSkip({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kTextTabBarHeight,
      right: VedcSizes.defaultSpace,
      child: TextButton(
        onPressed: () => OnBoardingController.instance.skipPage(),
        child: const Text(
          'Skip',
          style: TextStyle(
            color: VedcColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
