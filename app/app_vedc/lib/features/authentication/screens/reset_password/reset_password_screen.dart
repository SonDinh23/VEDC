import 'package:app_vedc/features/authentication/models/auth_service.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      setState(() => _submitted = true);
      try {
        await authService.value.resetPassword(email: _emailController.text);
      } on FirebaseAuthException catch (e) {
        setState(() => _submitted = false);
        Get.snackbar(
          'Reset password failed',
          e.message ?? 'An unknown error occurred.',
          backgroundColor: VedcColors.danger,
          colorText: VedcColors.black,
        );
        return;
      }
      // TODO: hook into real backend / Firebase Auth
      Get.snackbar(
        'Reset password',
        'If this email exists, we will send reset instructions.',
        backgroundColor: VedcColors.primary,
        colorText: VedcColors.black,
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: VedcColors.textSecondary),
      filled: true,
      fillColor: VedcColors.primary.withValues(alpha: 0.06),
      labelStyle: const TextStyle(color: VedcColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VedcSizes.inputRadius),
        borderSide: BorderSide(
          color: VedcColors.textSecondary.withValues(alpha: 0.25),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VedcSizes.inputRadius),
        borderSide: BorderSide(
          color: VedcColors.textSecondary.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VedcSizes.inputRadius),
        borderSide: const BorderSide(color: VedcColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: VedcColors.background,
      appBar: AppBar(
        backgroundColor: VedcColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: VedcColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          'Reset password',
          style: TextStyle(color: VedcColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: VedcSizes.lg,
            vertical: VedcSizes.spaceBtwSections,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: VedcSizes.spaceBtwSections),
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: VedcColors.primaryDark,
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                Text(
                  'Reset password',
                  style:
                      textTheme.headlineSmall?.copyWith(
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
                const SizedBox(height: VedcSizes.sm),
                Text(
                  'Enter your email and we will send you a reset link.',
                  style:
                      textTheme.bodyMedium?.copyWith(
                        color: VedcColors.textSecondary,
                        height: 1.5,
                      ) ??
                      const TextStyle(
                        color: VedcColors.textSecondary,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VedcSizes.spaceBtwSections),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration: _inputDecoration(
                    'Email address',
                    Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  height: VedcSizes.buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VedcColors.primary,
                      foregroundColor: VedcColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          VedcSizes.buttonRadius,
                        ),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(
                      _submitted ? 'Link sent' : 'Send reset link',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
