import 'dart:convert';
import 'dart:developer' as dev;

import 'package:app_vedc/features/Dashboard/Service/MyoBandProcess.dart';
import 'package:app_vedc/features/Dashboard/Service/bleService.dart';
import 'package:app_vedc/features/Dashboard/Service/wearable_mode.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class WearableModeService {
  WearableModeService._();

  static final Guid _sensorServiceUuid = Guid(
    BLEService.servicesRing['SENSOR_SERVICE_UUID']!,
  );
  static final Guid _modeCharacteristicUuid = Guid(
    BLEService.characteristicsRing['MODE_UUID']!,
  );

  static Future<WearableMode> readCurrentMode(BluetoothDevice device) async {
    final characteristic = await _getModeCharacteristic(device);
    final data = await characteristic.read();
    if (data.isEmpty) {
      dev.log(
        'Mode characteristic returned empty payload',
        name: 'WearableModeService',
      );
      return WearableMode.none;
    }
    final payload = ascii.decode(data, allowInvalid: true).trim();
    final numericValue = int.tryParse(payload) ?? data.first;
    final mode = WearableMode.fromValue(numericValue);
    dev.log(
      'Wearable mode value: "$payload" (${data}) -> $mode',
      name: 'WearableModeService',
    );
    return mode;
  }

  static Future<void> writeMode(
    BluetoothDevice device,
    WearableMode mode,
  ) async {
    final characteristic = await _getModeCharacteristic(device);
    final payload = mode.value.toString();
    await characteristic.write(payload.codeUnits);
    dev.log(
      'Write wearable mode -> "$payload" (${mode.label})',
      name: 'WearableModeService',
    );
  }

  static Future<BluetoothCharacteristic> _getModeCharacteristic(
    BluetoothDevice device,
  ) async {
    final cached = MyoBandProcess.findCharacteristic(
      _sensorServiceUuid,
      _modeCharacteristicUuid,
    );
    if (cached != null) return cached;

    final services = await device.discoverServices();
    for (final service in services) {
      if (service.serviceUuid == _sensorServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.characteristicUuid == _modeCharacteristicUuid) {
            return characteristic;
          }
        }
      }
    }

    throw StateError('Không tìm thấy MODE_UUID characteristic trong thiết bị');
  }
}
