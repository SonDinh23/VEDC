import 'package:app_vedc/features/Dashboard/screens/Home/Home.dart';
import 'package:app_vedc/features/authentication/models/auth_service.dart';
import 'package:app_vedc/features/authentication/screens/login/app_loading_page.dart';
import 'package:app_vedc/features/authentication/screens/login/login_screen.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.pageIfNotConnected});

  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppLoadingPage();
            }

            // If user is signed in -> show dashboard
            if (snapshot.hasData) {
              return const OnHome();
            }

            // If not signed in -> show provided page or default to LoginScreen
            return pageIfNotConnected ?? const LoginScreen();
          },
        );
      },
    );
  }
}
