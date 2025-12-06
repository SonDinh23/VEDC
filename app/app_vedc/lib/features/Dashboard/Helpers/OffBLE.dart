import 'dart:developer' show log;
import 'dart:io';

import 'package:app_vedc/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OnScreenOffBLE extends StatefulWidget {
  const OnScreenOffBLE({super.key});

  @override
  State<OnScreenOffBLE> createState() => _OnScreenOffBLEState();
}

class _OnScreenOffBLEState extends State<OnScreenOffBLE> {
  Widget buildBLEOffScreen() {
    return Scaffold(
      backgroundColor: VedcColors.surface,
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 50.0,
                horizontal: 20.0,
              ),
              child: Text(
                "You do not have bluetooth turned on. You need to turn on bluetooth.",
                style: const TextStyle(
                  color: VedcColors.logoBlue,
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.normal,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: VedcColors.primaryLight,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  shadowColor: VedcColors.shadow,
                  backgroundColor: VedcColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 34, vertical: 20),
                ),
                child: Text(
                  'TURN ON',
                  style: TextStyle(
                    color: VedcColors.white,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.normal,
                    fontSize: 20,
                  ),
                ),
                onPressed: () async {
                  try {
                    if (Platform.isAndroid) {
                      await FlutterBluePlus.turnOn();
                    }
                  } catch (e, backtrace) {
                    log("$e");
                    log("backtrace: $backtrace");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: VedcColors.danger,
                        content: Text(
                          "Error can not turn on bluetooth",
                          style: const TextStyle(
                            color: VedcColors.white,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.normal,
                            fontSize: 18,
                          ),
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildBLEOffScreen();
  }
}
