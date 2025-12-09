import 'dart:developer' as dev;

import 'package:app_vedc/features/Dashboard/Helpers/OffBLE.dart';
import 'package:app_vedc/features/Dashboard/Service/MyoBandProcess.dart';
import 'package:app_vedc/features/Dashboard/Service/bleController.dart';
import 'package:app_vedc/features/Dashboard/Service/wearable_mode.dart';
import 'package:app_vedc/features/Dashboard/Service/wearable_mode_service.dart';
import 'package:app_vedc/features/Dashboard/screens/Home/scanDevice.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:app_vedc/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnDeviceUser extends StatefulWidget {
  const OnDeviceUser({super.key});

  @override
  State<OnDeviceUser> createState() => _OnDeviceUserState();
}

class _OnDeviceUserState extends State<OnDeviceUser> {
  @override
  void initState() {
    super.initState();
    BLEController.reloadSavedDevice().then((_) {
      if (mounted) setState(() {});
    });
    dev.log('initState');
    FlutterBluePlus.setLogLevel(LogLevel.none);
  }

  @override
  void dispose() {
    // Cancel subscriptions/connections and update BLEController state
    // without calling setState — calling setState inside dispose can
    // cause the `_ElementLifecycle.defunct` assertion.
    BLEController.myoBandConnection?.cancel();
    BLEController.scanController?.cancel();
    BLEController.isScanningMyoBand = false;
    BLEController.stateConnection = StateConnection.disconnected;
    // Best-effort: stop underlying scan (can't await in dispose)
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
    super.dispose();
    dev.log('dispose');
  }

  Future<void> checkFullConnection() async {
    // log('checkFullConnection');
    if (BLEController.myoBandState == BluetoothConnectionState.connected) {
      if (mounted) {
        setState(() {
          BLEController.stateConnection = StateConnection.connected;
        });
      } else {
        BLEController.stateConnection = StateConnection.connected;
      }
      if (BLEController.myoBandDevice != null) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } else {
      if (mounted) {
        setState(() {
          BLEController.stateConnection = StateConnection.disconnected;
        });
      } else {
        BLEController.stateConnection = StateConnection.disconnected;
      }
    }
  }

  Future<void> listenMyoBandConnected(BluetoothDevice device) async {
    BLEController.myoBandConnection?.cancel();
    BLEController.myoBandConnection = device.connectionState.listen((
      state,
    ) async {
      dev.log('Device ${device.platformName} state: $state');
      if (mounted) {
        setState(() {
          BLEController.myoBandState = state;
          if (state == BluetoothConnectionState.connected) {
            BLEController.isScanningMyoBand = false;
          }
        });
      } else {
        BLEController.myoBandState = state;
        if (state == BluetoothConnectionState.connected) {
          BLEController.isScanningMyoBand = false;
        }
      }
      if (state == BluetoothConnectionState.connected) {
        try {
          await MyoBandProcess.discover(device);
          final mode = await WearableModeService.readCurrentMode(device);
          BLEController.updateWearableMode(mode);
        } catch (e, stackTrace) {
          dev.log(
            'Failed to discover services or read mode: $e',
            name: 'deviceUser',
            error: e,
            stackTrace: stackTrace,
          );
        }
      } else if (state == BluetoothConnectionState.disconnected) {
        MyoBandProcess.clearCache();
        BLEController.updateWearableMode(WearableMode.none);
      }
      await checkFullConnection();
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      final savedMyoBand = BLEController.savedMyoBand;
      if (savedMyoBand == null) return;

      if (BLEController.myoBandState == BluetoothConnectionState.disconnected) {
        if (device.remoteId.toString() == savedMyoBand.id) {
          dev.log('MyoBand: connecting.....');
          listenMyoBandConnected(device);
          BLEController.myoBandState = BluetoothConnectionState.connecting;
          await device.connect(
            license: License.free,
            mtu: 512,
            autoConnect: false,
          );
        }
      }

      if (BLEController.myoBandState == BluetoothConnectionState.connected) {
        BLEController.scanController?.cancel();
        BLEController.isScanningMyoBand = false;
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      dev.log('Error connecting to device: $e', name: 'BLE Connect');
    }
  }

  Future<void> startScan() async {
    // Check if the Bluetooth is connected
    if (BLEController.stateConnection == StateConnection.connected) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (BLEController.myoBandDevice != null &&
          BLEController.myoBandState == BluetoothConnectionState.connected) {
        dev.log('Myoband device already connected');
        await BLEController.myoBandDevice?.disconnect();
        if (mounted) {
          setState(() {
            BLEController.isScanningMyoBand = false;
            BLEController.stateConnection = StateConnection.disconnected;
          });
        }
      } else {
        setState(() {
          BLEController.isScanningMyoBand = false;
          BLEController.stateConnection = StateConnection.disconnected;
        });
      }
      return;
    }

    if (BLEController.stateConnection == StateConnection.disconnected) {
      dev.log('Start scanning saved MyoBand');
      final savedDevice = BLEController.savedMyoBand;
      if (savedDevice == null) {
        dev.log('No devices saved to scan');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: VedcColors.logoRed,
            content: Text(
              "No saved MyoBand found. Please add one via the + button first.",
              style: const TextStyle(
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

      BLEController.scanController?.cancel();
      BLEController.scanController = FlutterBluePlus.scanResults.listen((
        event,
      ) async {
        if (event.isEmpty) return;
        for (final device in event) {
          if (device.device.remoteId.toString() == savedDevice.id) {
            BLEController.myoBandDevice = device.device;
            await connectToDevice(BLEController.myoBandDevice!);
            return;
          }
        }
      });

      await FlutterBluePlus.startScan(
        withRemoteIds: [savedDevice.id],
        removeIfGone: const Duration(seconds: 4),
        continuousUpdates: true,
        continuousDivisor: 2,
      );

      if (mounted) {
        setState(() {
          BLEController.stateConnection = StateConnection.scanning;
          BLEController.isScanningMyoBand = true;
        });
      } else {
        BLEController.stateConnection = StateConnection.scanning;
        BLEController.isScanningMyoBand = true;
      }

      return;
    }

    if (BLEController.stateConnection == StateConnection.scanning) {
      dev.log('stop scanning');
      await stopScan();
    }
  }

  Future<void> stopScan() async {
    dev.log('stopScan');
    BLEController.scanController?.cancel();
    // Avoid calling setState when the widget is already disposed.
    if (mounted) {
      setState(() {
        BLEController.isScanningMyoBand = false;
        BLEController.stateConnection = StateConnection.disconnected;
      });
    } else {
      BLEController.isScanningMyoBand = false;
      BLEController.stateConnection = StateConnection.disconnected;
    }

    await FlutterBluePlus.stopScan();
  }

  Future<void> deleteDevice(String device) async {
    dev.log('Device: $device');
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VedcColors.background,
        title: Text(
          'Confirm device delete',
          style: TextStyle(
            color: VedcColors.textPrimary,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.normal,
            fontSize: 21,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this device?',
          style: TextStyle(
            color: VedcColors.textPrimary,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.normal,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No',
              style: TextStyle(
                color: VedcColors.primaryDark,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
                fontSize: 15,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VedcColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Yes',
              style: TextStyle(
                color: VedcColors.primaryDark,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      dev.log('User confirms device deleted');
      await BLEController.deleteDevice(device);
      if (device == 'MyoBand') {
        await BLEController.myoBandDevice?.disconnect();
        setState(() {
          BLEController.myoBandDevice = null;
          BLEController.myoBandState = BluetoothConnectionState.disconnected;
          BLEController.isScanningMyoBand = false;
          BLEController.stateConnection = StateConnection.disconnected;
        });
      }
      await BLEController.reloadSavedDevice();
      setState(() {});
    }
  }

  PreferredSizeWidget buildAppBar() {
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
            'Home',
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

  Widget buildContent() {
    return StreamBuilder<BluetoothAdapterState>(
      stream: FlutterBluePlus.adapterState,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: VedcColors.white);
        }
        return Container(
          child: snapshot.data == BluetoothAdapterState.on
              ? buildBLEOnScreen()
              : const OnScreenOffBLE(),
        );
      },
    );
  }

  Widget buildRingItem() {
    return InkWell(
      splashColor: VedcColors.surface,
      borderRadius: BorderRadius.circular(20.0),
      onLongPress: () async => deleteDevice('MyoBand'),
      onTap: () async => _openModeSelector(),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: Card(
          elevation: 10,
          shadowColor: Colors.black,
          color: VedcColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: 160,
            width: 320,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SizedBox(
                    height: 150,
                    width: 130,
                    child: Container(
                      decoration: BoxDecoration(
                        color: VedcColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SvgPicture.asset(
                          'assets/icons/Normals/myoband.svg',
                        ),
                      ),
                    ),
                  ),
                ),
                Center(child: SizedBox(width: 5)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _deviceDisplayName(),
                        style: const TextStyle(
                          color: VedcColors.textPrimary,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.normal,
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "Status",
                            style: const TextStyle(
                              color: VedcColors.textPrimary,
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.normal,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 30),
                          BLEController.isScanningMyoBand
                              ? CircularProgressIndicator(
                                  color: VedcColors.primaryDark,
                                  strokeWidth: 5.0,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    color:
                                        BLEController.myoBandState ==
                                            BluetoothConnectionState.connected
                                        ? VedcColors.success
                                        : VedcColors.logoRed,
                                  ),
                                  child: SizedBox(width: 20, height: 20),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openModeSelector() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (BLEController.myoBandState != BluetoothConnectionState.connected ||
        BLEController.myoBandDevice == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VedcColors.logoRed,
          content: const Text(
            'Vui lòng kết nối MyoBand trước khi chọn mode.',
            style: TextStyle(
              color: VedcColors.white,
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final currentMode = BLEController.wearableMode;
    final selectedMode = await _showModePicker(currentMode);
    if (selectedMode == null || selectedMode == currentMode) return;

    try {
      await WearableModeService.writeMode(
        BLEController.myoBandDevice!,
        selectedMode,
      );
      BLEController.updateWearableMode(selectedMode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VedcColors.success,
          content: Text(
            'Đã chuyển mode sang ${selectedMode.label}.',
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VedcColors.logoRed,
          content: Text(
            'Không thể ghi mode: $e',
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
  }

  Future<WearableMode?> _showModePicker(WearableMode currentMode) {
    final modes = WearableMode.values
        .where((mode) => mode != WearableMode.none)
        .toList(growable: false);
    return showModalBottomSheet<WearableMode>(
      context: context,
      backgroundColor: VedcColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Chọn mode cảm biến',
                  style: const TextStyle(
                    color: VedcColors.textPrimary,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              for (final mode in modes)
                ListTile(
                  leading: Icon(
                    mode == currentMode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: mode == currentMode
                        ? VedcColors.success
                        : VedcColors.textSecondary,
                  ),
                  title: Text(
                    mode.label,
                    style: const TextStyle(
                      color: VedcColors.textPrimary,
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    mode == WearableMode.all
                        ? 'Kích hoạt toàn bộ cảm biến'
                        : 'Dành cho ${mode.label}',
                    style: const TextStyle(
                      color: VedcColors.textSecondary,
                      fontFamily: 'Quicksand',
                      fontSize: 14,
                    ),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(mode),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget buildDeviceList() {
    return BLEController.hasSavedDevice ? buildRingItem() : Container();
  }

  Widget buildBLEOnScreen() {
    // Use a scrollable column to avoid RenderFlex overflow on small screens
    // or when additional UI (dialogs/overlays) changes available height.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [buildTitle(), buildDeviceList(), buildBtnScan()],
      ),
    );
  }

  Widget buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              'Devices',
              style: const TextStyle(
                color: VedcColors.textPrimary,
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.normal,
                fontSize: 22,
              ),
            ),
          ),
          InkWell(
            splashColor: VedcColors.surface,
            borderRadius: BorderRadius.circular(1.0),
            onTap: () async => startScan(),
            child: Container(
              padding: const EdgeInsets.only(
                right: 15.0,
                left: 10.0,
                top: 10.0,
                bottom: 10.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: VedcColors.primaryDark,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: VedcColors.surface,
                      spreadRadius: 0.5,
                      blurRadius: 3,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: VedcColors.surface,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.link,
                        color: VedcColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        BLEController.stateConnection.label,
                        style: const TextStyle(
                          color: VedcColors.white,
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.normal,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBtnScan() {
    return Padding(
      padding: const EdgeInsets.only(top: 50.0),
      child: InkWell(
        splashColor: VedcColors.surface,
        borderRadius: BorderRadius.circular(10.0),
        onTap: () async {
          await Future.delayed(Duration(milliseconds: 200));
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => OnScanDevice()));
          BLEController.loadSavedDevices();
          setState(() {
            BLEController.dataSaved;
          });
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 130.0,
            right: 130.0,
            top: 10.0,
            bottom: 10.0,
          ),
          child: Container(
            width: 60,
            decoration: BoxDecoration(
              color: VedcColors.accent,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: VedcColors.textSecondary,
                  spreadRadius: 0.5,
                  blurRadius: 3,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: SvgPicture.asset('assets/icons/Normals/add.svg'),
            ),
          ),
        ),
      ),
    );
  }

  String _deviceDisplayName() {
    final advName = BLEController.savedMyoBand?.advName ?? '';
    if (advName.isEmpty) return 'MyoBand';
    final indexEnd = advName.codeUnits.indexWhere((code) => code == 0);
    final cleaned = (indexEnd != -1 ? advName.substring(0, indexEnd) : advName)
        .trim();
    return cleaned.isEmpty ? 'MyoBand' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VedcColors.background,
      appBar: buildAppBar(),
      body: buildContent(),
    );
  }
}
