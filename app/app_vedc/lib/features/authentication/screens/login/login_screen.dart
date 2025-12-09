import 'dart:developer';

import 'package:app_vedc/features/authentication/models/auth_service.dart';
import 'package:app_vedc/features/authentication/screens/reset_password/reset_password_screen.dart';
import 'package:app_vedc/features/authentication/screens/signup/create_account_screen.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await authService.value.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // Pop all routes back to root so AuthLayout can show the dashboard.
        if (Navigator.canPop(context)) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } on FirebaseAuthException catch (e) {
        log('Login error: $e');
        Get.snackbar(
          'Login failed',
          e.message ?? 'An unknown error occurred.',
          backgroundColor: VedcColors.danger,
          colorText: VedcColors.black,
        );
      }
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
        title: const Text(
          'Login',
          style: TextStyle(color: VedcColors.textPrimary),
        ),
        centerTitle: true,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: textTheme.headlineSmall?.copyWith(
                    color: VedcColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: VedcSizes.sm),
                Text(
                  'Enter your credentials to access your dashboard.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: VedcColors.textSecondary,
                  ),
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
                const SizedBox(height: VedcSizes.spaceBtwItems),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration: _inputDecoration('Password', Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: VedcColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Password is required';
                    if (value.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.to(
                      () => const ResetPasswordScreen(),
                      transition: Transition.downToUp,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: VedcColors.primaryDark),
                    ),
                  ),
                ),
                const SizedBox(height: VedcSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  height: VedcSizes.buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VedcColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          VedcSizes.buttonRadius,
                        ),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: VedcSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: textTheme.bodyMedium?.copyWith(
                        color: VedcColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.to(
                        () => const CreateAccountScreen(),
                        transition: Transition.rightToLeft,
                      ),
                      child: const Text(
                        'Create one',
                        style: TextStyle(color: VedcColors.primaryDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VedcSizes.lg),
                Center(
                  child: Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: VedcColors.textSecondary,
                      height: 1.4,
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
