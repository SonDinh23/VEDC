import 'package:app_vedc/utils/constants/colors.dart';
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
              style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: VedcColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: VedcColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VedcSizes.spaceBtwItems),
            Text(
              subTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: VedcColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
