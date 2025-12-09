import 'dart:developer';

import 'package:app_vedc/features/authentication/models/auth_service.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String s) {
    // Try ISO parse first (yyyy-mm-dd)
    try {
      return DateTime.parse(s);
    } catch (_) {}

    // Try dd/mm/yyyy or dd-mm-yyyy
    String? sep;
    if (s.contains('/'))
      sep = '/';
    else if (s.contains('-'))
      sep = '-';
    if (sep == null) return null;

    final parts = s.split(sep);
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    var y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    if (y < 100) y += 1900;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistProfileToLocalAndRemote() async {
    final fullName = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_dob', dob);
      await prefs.setString('user_address', address);
      await prefs.setString('user_email', email);
    } catch (e) {
      log('Failed to save to SharedPreferences: $e');
    }

    // Save to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;
      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'dob': dob,
        'address': address,
        'email': email,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    } catch (e, stack) {
      log('Failed to save Firestore profile: $e', stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu thông tin lên Firestore: $e')),
        );
      }
    }
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await authService.value.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _persistProfileToLocalAndRemote();

      Get.snackbar(
        'Account created',
        'Welcome aboard',
        backgroundColor: VedcColors.primary,
        colorText: VedcColors.black,
      );
      // Pop all routes back to root (AuthLayout) so it can display OnHome.
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      log('Signup error: $e');
      Get.snackbar(
        'Sign up failed',
        e.message ?? 'An unknown error occurred.',
        backgroundColor: VedcColors.danger,
        colorText: VedcColors.black,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          'Create account',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let\'s get started',
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
                ),
                const SizedBox(height: VedcSizes.sm),
                Text(
                  'Create your account to continue.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: VedcColors.textSecondary,
                  ),
                ),
                const SizedBox(height: VedcSizes.spaceBtwSections),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration: _decoration('Họ và tên', Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Họ và tên là bắt buộc';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                TextFormField(
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration: _decoration(
                    'Địa chỉ',
                    Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Địa chỉ là bắt buộc';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration: _decoration('Email', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email là bắt buộc';
                    final email = value.trim();
                    final emailRegex = RegExp(
                      r"^[\w\-.]+@[\w\-]+\.[a-zA-Z]{2,}",
                    );
                    if (!emailRegex.hasMatch(email))
                      return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                // Date of birth field: user can type or pick from calendar
                TextFormField(
                  controller: _dobController,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration:
                      _decoration(
                        'Ngày sinh (yyyy-mm-dd hoặc dd/mm/yyyy)',
                        Icons.calendar_today_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.event,
                            color: VedcColors.textSecondary,
                          ),
                          onPressed: () async {
                            // show date picker
                            final now = DateTime.now();
                            final first = DateTime(now.year - 120, 1, 1);
                            final last = DateTime(now.year, now.month, now.day);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(now.year - 20),
                              firstDate: first,
                              lastDate: last,
                            );
                            if (picked != null) {
                              // store as ISO date yyyy-mm-dd for consistency
                              _dobController.text =
                                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Ngày sinh là bắt buộc';
                    final parsed = _parseDate(value.trim());
                    if (parsed == null) return 'Nhập ngày sinh hợp lệ';
                    final now = DateTime.now();
                    if (parsed.isAfter(now)) return 'Ngày sinh không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: VedcSizes.spaceBtwItems),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration: _decoration('Password', Icons.lock_outline)
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
                const SizedBox(height: VedcSizes.spaceBtwItems),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: VedcColors.textPrimary),
                  decoration:
                      _decoration(
                        'Confirm password',
                        Icons.lock_reset_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: VedcColors.textSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Confirm your password';
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
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
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Đang tạo...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Create account',
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
