import 'package:app_vedc/features/authentication/controllers_onboarding/onboarding_controller.dart';
import 'package:app_vedc/features/authentication/screens/onboarding/widgets/onboarding_dot_navigation.dart';
import 'package:app_vedc/features/authentication/screens/onboarding/widgets/onboarding_next_button.dart';
import 'package:app_vedc/features/authentication/screens/onboarding/widgets/onboarding_page.dart';
import 'package:app_vedc/features/authentication/screens/onboarding/widgets/onboarding_skip.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:get/get.dart';
import 'package:app_vedc/utils/constants/image_strings.dart';
import 'package:app_vedc/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());

    return Scaffold(
      backgroundColor: VedcColors.background,
      body: Stack(
        children: [
          /// Horizontal Scrollable Pages
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnboardingPage(
                image: VedcImages.onboardingImage1,
                title: TextStrings.onBoardingTitle1,
                subTitle: TextStrings.onBoardingSubTitle1,
              ),
              OnboardingPage(
                image: VedcImages.onboardingImage2,
                title: TextStrings.onBoardingTitle2,
                subTitle: TextStrings.onBoardingSubTitle2,
              ),
              OnboardingPage(
                image: VedcImages.onboardingImage3,
                title: TextStrings.onBoardingTitle3,
                subTitle: TextStrings.onBoardingSubTitle3,
              ),
            ],
          ),

          /// Skip Button
          OnboardingSkip(),

          /// Dot Navigation SmoothPageIndicator
          OnboardingDotNavigation(),

          /// Next Button
          OnboardingNextButton(),
        ],
      ),
    );
  }
}
