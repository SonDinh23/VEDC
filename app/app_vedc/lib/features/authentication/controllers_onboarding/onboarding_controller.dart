import 'package:app_vedc/features/authentication/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnBoardingController extends GetxController {
  /// Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;
  static const int totalPages = 3;

  // Add your controller logic here
  static OnBoardingController get instance => Get.find();

  /// Update Curent Index when Page Scrolls
  void updatePageIndicator(index) => currentPageIndex.value = index;

  /// Jump to the specific dot selected page
  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    if (pageController.hasClients) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Update Current Index & jump to next page
  void nextPage() {
    if (currentPageIndex.value >= totalPages - 1) {
      Get.to(() => const LoginScreen(), transition: Transition.fadeIn);
    } else {
      final page = currentPageIndex.value + 1;
      currentPageIndex.value = page;
      if (pageController.hasClients) {
        pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  /// Update Current Index & skip to last page
  void skipPage() {
    currentPageIndex.value = totalPages - 1;
    if (pageController.hasClients) {
      pageController.animateToPage(
        totalPages - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }
}
