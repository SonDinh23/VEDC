import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_vedc/features/authentication/models/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_vedc/features/authentication/screens/reset_password/change_password_screen.dart';
import 'package:app_vedc/features/Dashboard/screens/User/information_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnUsers extends StatelessWidget {
  const OnUsers({super.key});

  Future<Map<String, String?>> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    return {
      'name':
          prefs.getString('user_fullName') ?? user?.displayName ?? user?.email,
      'email': prefs.getString('user_email') ?? user?.email,
    };
  }

  Widget _settingTile({
    required String title,
    required VoidCallback onTap,
    IconData icon = Icons.chevron_right,
  }) {
    return Material(
      color: VedcColors.surface,
      borderRadius: BorderRadius.circular(VedcSizes.radiusMd),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: VedcColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: VedcSizes.fontSizeMd,
          ),
        ),
        trailing: Icon(icon, color: VedcColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      color: VedcColors.textPrimary,
      fontFamily: 'Livvic',
      fontWeight: FontWeight.w700,
      fontSize: 30,
    );

    return Scaffold(
      backgroundColor: VedcColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: VedcSizes.lg,
            vertical: VedcSizes.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Profile', style: titleStyle),
              const SizedBox(height: VedcSizes.xs),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: VedcColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: VedcSizes.spaceBtwSections),

              // Profile card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(VedcSizes.lg),
                decoration: BoxDecoration(
                  color: VedcColors.surface,
                  borderRadius: BorderRadius.circular(VedcSizes.radiusLg),
                  border: Border.all(
                    color: VedcColors.primary.withOpacity(0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VedcColors.shadow.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    FutureBuilder<Map<String, String?>>(
                      future: _loadProfile(),
                      builder: (context, snapshot) {
                        final name = snapshot.data?['name'] ?? 'Flutter Pro';
                        final email =
                            snapshot.data?['email'] ?? 'Flutter@pro.com';
                        final initials = name
                            .split(' ')
                            .where((s) => s.isNotEmpty)
                            .map((s) => s[0])
                            .take(2)
                            .join()
                            .toUpperCase();
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: VedcColors.primary.withOpacity(
                                0.12,
                              ),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: VedcColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: VedcSizes.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: VedcColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: VedcSizes.fontSizeMd,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: VedcColors.textSecondary,
                                    fontSize: VedcSizes.fontSizeSm,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: VedcSizes.spaceBtwSections),
              Text(
                'Settings',
                style: TextStyle(
                  color: VedcColors.textPrimary,
                  fontSize: VedcSizes.fontSizeLg,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: VedcSizes.md),

              // Settings list inside a subtle card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: VedcSizes.sm),
                decoration: BoxDecoration(color: VedcColors.background),
                child: Column(
                  children: [
                    _settingTile(
                      title: 'Information',
                      onTap: () => Get.to(() => const InformationScreen()),
                    ),
                    const SizedBox(height: VedcSizes.sm),
                    _settingTile(
                      title: 'Change password',
                      onTap: () => Get.to(() => const ChangePasswordScreen()),
                    ),
                    const SizedBox(height: VedcSizes.sm),
                    _settingTile(title: 'Delete my account', onTap: () {}),
                    const SizedBox(height: VedcSizes.sm),
                    _settingTile(title: 'About this app', onTap: () {}),
                  ],
                ),
              ),

              const SizedBox(height: VedcSizes.spaceBtwSections),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VedcColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          VedcSizes.buttonRadius,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed ?? false) {
                        try {
                          await authService.value.signOut();
                          // Do not manually navigate here; AuthLayout listens
                          // to authStateChanges and will update the displayed page.
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e')),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
