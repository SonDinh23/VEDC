import 'package:app_vedc/features/authentication/controllers_onboarding/onboarding_controller.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class OnboardingNextButton extends StatelessWidget {
  const OnboardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnBoardingController.instance;

    return Positioned(
      right: VedcSizes.defaultSpace,
      bottom: 50,
      child: Obx(() {
        final isLastPage =
            controller.currentPageIndex.value >=
            OnBoardingController.totalPages - 1;

        return ElevatedButton(
          onPressed: controller.nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: VedcColors.primaryDark,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLastPage
                ? const Icon(
                    Iconsax.login_1,
                    key: ValueKey('login'),
                    color: Colors.white,
                  )
                : const Icon(
                    Iconsax.arrow_right_3,
                    key: ValueKey('next'),
                    color: Colors.white,
                  ),
          ),
        );
      }),
    );
  }
}
