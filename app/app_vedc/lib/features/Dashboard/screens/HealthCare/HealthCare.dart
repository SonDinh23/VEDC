import 'dart:developer';

import 'package:app_vedc/features/Dashboard/Service/bleController.dart';
import 'package:app_vedc/features/Dashboard/Service/wearable_mode.dart';
import 'package:app_vedc/features/Dashboard/screens/HealthCare/ECGSensor/ECGSensor.dart';
import 'package:app_vedc/features/Dashboard/screens/HealthCare/EMG_IMUSensor/EMG_IMUSensor.dart';
import 'package:app_vedc/features/Dashboard/screens/HealthCare/MultipleSensor/MultipleSensor.dart';
import 'package:app_vedc/features/Dashboard/screens/HealthCare/PPGSensor/PPGSensor.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OnHealthCare extends StatefulWidget {
  const OnHealthCare({super.key});

  @override
  State<OnHealthCare> createState() => _OnHealthCareState();
}

class _OnHealthCareState extends State<OnHealthCare> {
  late final List<_HealthFeature> _features;

  @override
  void initState() {
    super.initState();
    _features = <_HealthFeature>[
      _HealthFeature(
        title: 'EMG & IMU',
        logLabel: 'Calibrate EMG_IMU Tapped',
        assetPath: 'assets/images/layouts/followHealthy/EMG_IMU.png',
        requiredMode: WearableMode.emgImu,
        destinationBuilder: () => const OnEMG_IMUSensor(),
      ),
      _HealthFeature(
        title: 'ECG',
        logLabel: 'Calibrate ECG Tapped',
        assetPath: 'assets/images/layouts/followHealthy/ECG.png',
        requiredMode: WearableMode.ecg,
        destinationBuilder: () => const OnECGSensor(),
      ),
      _HealthFeature(
        title: 'PPG',
        logLabel: 'Calibrate PPG Tapped',
        assetPath: 'assets/images/layouts/followHealthy/PPG.png',
        requiredMode: WearableMode.ppg,
        destinationBuilder: () => const OnPPGSensor(),
      ),
      _HealthFeature(
        title: 'Multiple Sensor',
        logLabel: 'Calibrate Multiple Sensor Tapped',
        assetPath: 'assets/images/layouts/followHealthy/MultipleSensor.png',
        requiredMode: WearableMode.all,
        destinationBuilder: () => const OnMultipleSensor(),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Precache images asynchronously in parallel so we don't block the
      // first frame or cause layout jank by awaiting sequentially.
      Future.microtask(() async {
        try {
          await Future.wait(
            _features.map((f) => precacheImage(f.imageProvider, context)),
          );
        } catch (_) {
          // Ignore precache errors
        }
      });
    });
  }

  Future<void> _handleFeatureTap(_HealthFeature feature) async {
    log(feature.logLabel);
    await Future.delayed(const Duration(milliseconds: 200));
    if (BLEController.myoBandState == BluetoothConnectionState.disconnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VedcColors.danger,
          content: const Text(
            'Not connected to myoBand',
            style: TextStyle(
              color: VedcColors.white,
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.normal,
              fontSize: 18,
            ),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final currentMode = BLEController.wearableMode;
    if (!feature.isEnabledFor(currentMode)) {
      _showModeMismatch(feature, currentMode);
      return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => feature.destinationBuilder()));
  }

  void _showModeMismatch(_HealthFeature feature, WearableMode currentMode) {
    if (!mounted) return;
    final message = currentMode == WearableMode.none
        ? 'Chưa nhận được mode từ MyoBand. Vui lòng thử lại sau khi thiết bị kết nối ổn định.'
        : 'Thiết bị đang ở mode ${currentMode.label}. Hãy chuyển sang ${feature.requiredMode.label} để dùng chức năng này.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: VedcColors.logoRed,
        content: Text(
          message,
          style: const TextStyle(
            color: VedcColors.white,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFeatureCard(_HealthFeature feature, WearableMode currentMode) {
    final isEnabled = feature.isEnabledFor(currentMode);
    return Card(
      elevation: 3,
      shadowColor: Colors.black,
      color: VedcColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35),
        side: const BorderSide(color: VedcColors.textSecondary, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                feature.title,
                style: const TextStyle(
                  color: VedcColors.textPrimary,
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.normal,
                  fontSize: 30,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                feature.image,
                if (!isEnabled)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock,
                          color: VedcColors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yêu cầu mode: ${feature.requiredMode.label}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: VedcColors.white,
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          InkWell(
            splashColor: VedcColors.surface,
            borderRadius: BorderRadius.circular(20),
            onTap: () => isEnabled
                ? _handleFeatureTap(feature)
                : _showModeMismatch(feature, currentMode),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: VedcColors.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: VedcColors.textSecondary,
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 220,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          'Collection',
                          style: TextStyle(
                            color: VedcColors.textPrimary,
                            fontFamily: 'Livvic',
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            fontSize: 21,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: VedcColors.textPrimary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      backgroundColor: VedcColors.background,
      foregroundColor: VedcColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calibration',
            style: TextStyle(
              color: VedcColors.textPrimary,
              fontFamily: 'Livvic',
              fontWeight: FontWeight.w700,
              fontSize: 30,
            ),
          ),
          SizedBox(height: VedcSizes.xs),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: VedcColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none)),
      ],
    );
  }

  Widget titleCalibrate() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 20, bottom: 10),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          'Find your Calibration',
          style: const TextStyle(
            color: VedcColors.textPrimary,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.normal,
            fontSize: 25,
          ),
        ),
      ),
    );
  }

  Widget contentCalibrate() {
    return ValueListenableBuilder<WearableMode>(
      valueListenable: BLEController.wearableModeNotifier,
      builder: (context, mode, _) {
        return SizedBox(
          width: double.infinity,
          child: CarouselSlider.builder(
            itemCount: _features.length,
            itemBuilder: (context, index, realIndex) =>
                _buildFeatureCard(_features[index], mode),
            options: CarouselOptions(
              aspectRatio: 0.75,
              viewportFraction: 0.80,
              initialPage: 0,
              enableInfiniteScroll: false,
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeCenterPage: true,
              enlargeFactor: 0.3,
              scrollDirection: Axis.horizontal,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VedcColors.background,
      appBar: appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Column(children: [titleCalibrate(), contentCalibrate()]),
      ),
    );
  }
}

class _HealthFeature {
  _HealthFeature({
    required this.title,
    required this.logLabel,
    required this.assetPath,
    required this.requiredMode,
    required this.destinationBuilder,
  }) {
    imageProvider = AssetImage(assetPath);
    image = Image(
      key: ValueKey(assetPath),
      image: imageProvider,
      gaplessPlayback: true,
      fit: BoxFit.contain,
    );
  }

  final String title;
  final String logLabel;
  final String assetPath;
  final WearableMode requiredMode;
  late final AssetImage imageProvider;
  late final Image image;
  final Widget Function() destinationBuilder;

  bool isEnabledFor(WearableMode currentMode) =>
      currentMode.supports(requiredMode);
}
