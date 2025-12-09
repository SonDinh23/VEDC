import 'package:app_vedc/features/authentication/models/auth_layout.dart';
import 'package:app_vedc/features/authentication/screens/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      // Global builder wraps the whole app so tapping anywhere unfocuses inputs
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: child ?? const SizedBox.shrink(),
      ),
      // If đã đăng nhập thì vào thẳng dashboard, nếu chưa thì ở màn welcome
      home: const AuthLayout(pageIfNotConnected: WelcomeScreen()),
    );
  }
}
