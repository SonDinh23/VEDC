import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:app_vedc/utils/helpers/helper_function.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  final String image, title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VedcSizes.defaultSpace),
      child: Column(
        children: [
          SizedBox(
            width: VedcHelperFunction.screenWidth() * 0.8,
            height: VedcHelperFunction.screenHeight() * 0.55,
            child: Image.asset(
              image,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VedcSizes.spaceBtwItems),
          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
