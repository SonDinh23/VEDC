import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:app_vedc/features/Dashboard/Service/bleService.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/helpers/SharedPreferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnScanDevice extends StatefulWidget {
  const OnScanDevice({super.key});

  @override
  State<OnScanDevice> createState() => _OnScanDeviceState();
}

class _OnScanDeviceState extends State<OnScanDevice> {
  final List<Guid> _serviceUUIDs = BLEService.listAdvUUID
      .map((uuid) => Guid(uuid))
      .toList();

  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  StreamSubscription<bool>? _scanStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultSubscription;

  @override
  void initState() {
    super.initState();
    dev.log('Scan screen init');
    _stopScan();
  }

  @override
  void dispose() {
    super.dispose();
    dev.log('Scan screen dispose');
    _stopScan();
  }

  Future<void> _startScan() async {
    dev.log('Start scanning');
    await _scanStateSubscription?.cancel();
    _scanStateSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (!mounted) return;
      setState(() => _isScanning = state);
    });

    await _scanResultSubscription?.cancel();
    _scanResultSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() => _scanResults = results);
    });

    await FlutterBluePlus.startScan(
      withServices: _serviceUUIDs,
      removeIfGone: const Duration(seconds: 4),
      continuousUpdates: true,
      continuousDivisor: 2,
    );
  }

  Future<void> _stopScan() async {
    await _scanStateSubscription?.cancel();
    await _scanResultSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    if (mounted) {
      setState(() => _isScanning = false);
    }
    dev.log('Stop scanning');
  }

  Future<void> _persistScanResult(ScanResult result) async {
    dev.log('Device: ${result.device.platformName}');
    dev.log('ID: ${result.device.remoteId}');
    dev.log('RSSI: ${result.rssi}');
    dev.log('uuids: ${result.advertisementData.serviceUuids}');
    if (result.advertisementData.serviceUuids.toString().contains(
      BLEService.advUUIDRing,
    )) {
      dev.log('MyoBand Service Detected');
      await DeviceStorage.clearMyoBand();
      await DeviceStorage.saveMyoBand(
        ScanItem(
          advName: result.device.platformName,
          id: result.device.remoteId.toString(),
          rssi: result.rssi,
          serviceUuids: result.advertisementData.serviceUuids.toString(),
        ),
      );
    }
  }

  PreferredSizeWidget appBar() {
    return AppBar(
      backgroundColor: VedcColors.primary,
      foregroundColor: VedcColors.white,
      title: const Text(
        'Scan',
        style: TextStyle(
          color: VedcColors.white,
          fontFamily: 'Livvic',
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
          fontSize: 30,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildScanControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ScanControlButton(
            label: 'Start',
            icon: Icons.scanner,
            iconBackground: Colors.white,
            onTap: _startScan,
          ),
          _ScanControlButton(
            label: 'Stop',
            icon: Icons.stop,
            iconBackground: VedcColors.surface,
            onTap: _stopScan,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (!_isScanning) return const SizedBox.shrink();
    return Center(
      child: SizedBox(
        height: 20,
        width: 320,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: const LinearProgressIndicator(
            backgroundColor: VedcColors.primaryLight,
            valueColor: AlwaysStoppedAnimation<Color>(VedcColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          if (result.advertisementData.advName.isEmpty) {
            return const SizedBox.shrink();
          }

          final advName = _sanitizeAdvName(result.advertisementData.advName);

          return Padding(
            padding: const EdgeInsets.all(15),
            child: _ScanResultCard(
              result: result,
              advName: advName,
              onTap: () async {
                await _persistScanResult(result);
                await _stopScan();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
    );
  }

  String _sanitizeAdvName(String advName) {
    final indexEnd = advName.codeUnits.indexWhere((code) => code == 0);
    return indexEnd != -1 ? advName.substring(0, indexEnd) : advName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VedcColors.background,
      appBar: appBar(),
      body: Column(
        children: [
          _buildScanControls(),
          _buildProgressIndicator(),
          _buildDeviceList(),
        ],
      ),
    );
  }
}

class _ScanControlButton extends StatelessWidget {
  const _ScanControlButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.iconBackground,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: VedcColors.surface,
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: VedcColors.primaryLight,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(
                color: VedcColors.textPrimary,
                spreadRadius: 0.5,
                blurRadius: 3,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: VedcColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: VedcColors.textPrimary,
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.normal,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({
    required this.result,
    required this.advName,
    required this.onTap,
  });

  final ScanResult result;
  final String advName;
  final VoidCallback onTap;

  Color get _signalColor =>
      result.rssi > -70 ? VedcColors.success : VedcColors.danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shadowColor: VedcColors.textSecondary,
        color: VedcColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          height: 150,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: VedcColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SvgPicture.asset('assets/icons/Normals/myoband.svg'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        advName.substring(0, min(10, advName.length)),
                        style: const TextStyle(
                          color: VedcColors.textPrimary,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.normal,
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${result.device.remoteId}',
                        style: const TextStyle(
                          color: VedcColors.textSecondary,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${result.rssi} dB',
                              style: const TextStyle(
                                color: VedcColors.textPrimary,
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.normal,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.signal_cellular_alt,
                              color: _signalColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
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
