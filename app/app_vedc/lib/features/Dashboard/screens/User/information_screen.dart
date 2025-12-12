import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  final _nameFocus = FocusNode();
  final _dobFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _emailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _attachFocusListeners();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await _loadFromPrefs();
    await _loadFromFirestoreIfNeeded();
  }

  void _attachFocusListeners() {
    void listener() {
      // If none of the fields have focus, save.
      if (!(_nameFocus.hasFocus ||
          _dobFocus.hasFocus ||
          _addressFocus.hasFocus ||
          _emailFocus.hasFocus)) {
        _saveAllFields();
      }
    }

    _nameFocus.addListener(listener);
    _dobFocus.addListener(listener);
    _addressFocus.addListener(listener);
    _emailFocus.addListener(listener);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final prefName = prefs.getString('user_fullName');
    final prefEmail = prefs.getString('user_email');
    final fallbackName = user?.displayName?.trim();
    final fallbackEmail = user?.email?.trim();

    setState(() {
      _nameController.text = (prefName != null && prefName.trim().isNotEmpty)
          ? prefName
          : (fallbackName?.isNotEmpty == true ? fallbackName! : 'Your name');
      _dobController.text = prefs.getString('user_dob') ?? '';
      _addressController.text = prefs.getString('user_address') ?? '';
      _emailController.text = (prefEmail != null && prefEmail.trim().isNotEmpty)
          ? prefEmail
          : (fallbackEmail ?? '');
    });
  }

  bool _isMeaningful(String? value) => value != null && value.trim().isNotEmpty;

  Future<void> _loadFromFirestoreIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      final remoteName = data['fullName'] as String?;
      final remoteDob = data['dob'] as String?;
      final remoteAddress = data['address'] as String?;
      final remoteEmail = data['email'] as String?;

      final shouldUpdateName =
          !_isMeaningful(_nameController.text) ||
          _nameController.text.trim() == 'Your name';
      final shouldUpdateEmail = !_isMeaningful(_emailController.text);
      final shouldUpdateDob = !_isMeaningful(_dobController.text);
      final shouldUpdateAddress = !_isMeaningful(_addressController.text);

      if (shouldUpdateName ||
          shouldUpdateEmail ||
          shouldUpdateDob ||
          shouldUpdateAddress) {
        setState(() {
          if (shouldUpdateName && _isMeaningful(remoteName)) {
            _nameController.text = remoteName!.trim();
          }
          if (shouldUpdateEmail && _isMeaningful(remoteEmail)) {
            _emailController.text = remoteEmail!.trim();
          }
          if (shouldUpdateDob && remoteDob != null) {
            _dobController.text = remoteDob;
          }
          if (shouldUpdateAddress && _isMeaningful(remoteAddress)) {
            _addressController.text = remoteAddress!.trim();
          }
        });
        // Cache to prefs so subsequent opens are instant.
        final prefs = await SharedPreferences.getInstance();
        if (_isMeaningful(_nameController.text)) {
          await prefs.setString('user_fullName', _nameController.text.trim());
        }
        if (_isMeaningful(_emailController.text)) {
          await prefs.setString('user_email', _emailController.text.trim());
        }
        if (_isMeaningful(_dobController.text)) {
          await prefs.setString('user_dob', _dobController.text.trim());
        }
        if (_isMeaningful(_addressController.text)) {
          await prefs.setString('user_address', _addressController.text.trim());
        }
      }
    } catch (e) {
      // Ignore silently; offline or missing doc should not break UI.
    }
  }

  Future<void> _saveAllFields() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullName', _nameController.text.trim());
    await prefs.setString('user_dob', _dobController.text.trim());
    await prefs.setString('user_address', _addressController.text.trim());
    await prefs.setString('user_email', _emailController.text.trim());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _dobFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
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
        centerTitle: true,
        title: const Text(
          'Information',
          style: TextStyle(color: VedcColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: VedcColors.textPrimary,
          ),
          onPressed: () {
            // Save before leaving
            _saveAllFields();
            Get.back();
          },
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
            child: Container(
              padding: const EdgeInsets.all(VedcSizes.lg),
              decoration: BoxDecoration(
                color: VedcColors.surface,
                borderRadius: BorderRadius.circular(VedcSizes.radiusLg),
                border: Border.all(color: VedcColors.primary.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile information',
                    style:
                        textTheme.headlineSmall?.copyWith(
                          color: VedcColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: VedcSizes.spaceBtwSections),

                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    style: const TextStyle(color: VedcColors.textPrimary),
                    decoration: _decoration('Full name', Icons.person_outline),
                  ),
                  const SizedBox(height: VedcSizes.spaceBtwItems),

                  TextFormField(
                    controller: _dobController,
                    focusNode: _dobFocus,
                    decoration:
                        _decoration(
                          'Date of birth',
                          Icons.calendar_today_outlined,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined),
                            onPressed: () async {
                              // Try to parse existing text as dd/MM/yyyy
                              DateTime initial = DateTime.now();
                              final parts = _dobController.text.split('/');
                              if (parts.length == 3) {
                                final d = int.tryParse(parts[0]);
                                final m = int.tryParse(parts[1]);
                                final y = int.tryParse(parts[2]);
                                if (d != null && m != null && y != null) {
                                  initial = DateTime(y, m, d);
                                }
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                final formatted =
                                    '${picked.day.toString().padLeft(2, "0")}/${picked.month.toString().padLeft(2, "0")}/${picked.year}';
                                _dobController.text = formatted;
                                // save immediately after picking
                                await _saveAllFields();
                              }
                            },
                          ),
                        ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: VedcSizes.spaceBtwItems),

                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocus,
                    decoration: _decoration(
                      'Address',
                      Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: VedcSizes.spaceBtwItems),

                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    decoration: _decoration('Email', Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: VedcSizes.spaceBtwSections),

                  // Hint: saving happens automatically when keyboard dismissed
                  Text(
                    'Any changes will be saved when you dismiss the keyboard.',
                    style: textTheme.bodySmall?.copyWith(
                      color: VedcColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: VedcSizes.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
