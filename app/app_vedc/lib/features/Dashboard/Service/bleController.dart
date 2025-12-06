import 'dart:async';
import 'dart:developer' as dev;
import 'package:app_vedc/features/Dashboard/Service/wearable_mode.dart';
import 'package:app_vedc/utils/helpers/SharedPreferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum StateConnection {
  connected('Disconnect'),
  disconnected('Scan'),
  scanning('Scanning');

  const StateConnection(this.label);
  final String label;
}

class BLEController {
  BLEController._();

  static const String _deviceKey = 'MyoBand';

  /// Persisted device info (index 0 = MyoBand).
  static final List<ScanItem?> dataSaved = List<ScanItem?>.filled(
    1,
    null,
    growable: false,
  );

  /// Track scanning flags per device.
  static final Map<String, bool> isScanning = {_deviceKey: false};

  /// Track BLE connection state per device.
  static final Map<String, BluetoothConnectionState> connectionStates = {
    _deviceKey: BluetoothConnectionState.disconnected,
  };

  static BluetoothDevice? myoBandDevice;

  static StreamSubscription<List<ScanResult>>? scanController;
  static StreamSubscription<BluetoothConnectionState>? myoBandConnection;

  static StateConnection stateConnection = StateConnection.disconnected;
  static final ValueNotifier<WearableMode> wearableModeNotifier =
      ValueNotifier<WearableMode>(WearableMode.none);

  /// Convenience getters/setters --------------------------------------------
  static ScanItem? get savedMyoBand => dataSaved[0];

  static set savedMyoBand(ScanItem? device) => dataSaved[0] = device;

  static bool get isScanningMyoBand => isScanning[_deviceKey] ?? false;

  static set isScanningMyoBand(bool value) => isScanning[_deviceKey] = value;

  static BluetoothConnectionState get myoBandState =>
      connectionStates[_deviceKey] ?? BluetoothConnectionState.disconnected;

  static set myoBandState(BluetoothConnectionState state) =>
      connectionStates[_deviceKey] = state;

  static bool get hasSavedDevice => savedMyoBand != null;

  static WearableMode get wearableMode => wearableModeNotifier.value;

  static void updateWearableMode(WearableMode mode) {
    if (wearableModeNotifier.value != mode) {
      wearableModeNotifier.value = mode;
    }
  }

  /// Persistence helpers ----------------------------------------------------
  static Future<ScanItem?> reloadSavedDevice() async {
    dev.log('loadDeviceSaved');
    savedMyoBand = await DeviceStorage.loadMyoBand();
    dev.log('savedDevice: $savedMyoBand');
    return savedMyoBand;
  }

  /// Backwards compatibility wrapper for legacy callers.
  static Future<List<ScanItem?>> loadSavedDevices() async {
    await reloadSavedDevice();
    return dataSaved;
  }

  static Future<void> deleteDevice(String device) async {
    dev.log('deleteDevice: $device');
    if (device == _deviceKey) {
      await DeviceStorage.clearMyoBand();
      savedMyoBand = null;
    }
  }

  /// Reset runtime state when disconnecting / logging out.
  static Future<void> reset() async {
    await scanController?.cancel();
    await myoBandConnection?.cancel();
    scanController = null;
    myoBandConnection = null;
    myoBandDevice = null;
    stateConnection = StateConnection.disconnected;
    isScanningMyoBand = false;
    myoBandState = BluetoothConnectionState.disconnected;
    updateWearableMode(WearableMode.none);
  }
}
