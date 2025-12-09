import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_vedc/features/Dashboard/screens/User/onUsers.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _emailController.dispose();
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final current = _currentController.text;
    final next = _newController.text;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'No signed-in user found.',
          backgroundColor: VedcColors.danger,
          colorText: VedcColors.black,
        );
        return;
      }

      if (user.email == null || user.email != email) {
        Get.snackbar(
          'Error',
          'Email does not match the current account.',
          backgroundColor: VedcColors.danger,
          colorText: VedcColors.black,
        );
        return;
      }

      final cred = EmailAuthProvider.credential(
        email: email,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(next);

      Get.snackbar(
        'Change password',
        'Password updated successfully.',
        backgroundColor: VedcColors.primary,
        colorText: VedcColors.black,
      );

      // Try to pop the current route; if that doesn't work, replace with OnUsers.
      var didPop = false;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
        didPop = true;
      }
      if (!didPop) {
        // Ensure the user lands back on OnUsers
        Get.off(() => const OnUsers());
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Change password failed',
        e.message ?? 'An error occurred while changing password.',
        backgroundColor: VedcColors.danger,
        colorText: VedcColors.black,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: VedcColors.danger,
        colorText: VedcColors.black,
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
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
          'Change password',
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
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: VedcColors.primaryDark,
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                Text(
                  'Change password',
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
                  'Update your account password securely.',
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
                  decoration: _decoration('Email', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                TextFormField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration:
                      _decoration(
                        'Current password',
                        Icons.lock_person_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: VedcColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Current password is required';
                    if (value.length < 6)
                      return 'Must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration:
                      _decoration(
                        'New password',
                        Icons.lock_reset_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: VedcColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'New password is required';
                    if (value.length < 6)
                      return 'Must be at least 6 characters';
                    if (value == _currentController.text)
                      return 'Use a different password';
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
                    child: const Text(
                      'Update password',
                      style: TextStyle(
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
