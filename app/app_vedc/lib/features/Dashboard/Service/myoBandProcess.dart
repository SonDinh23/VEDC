import 'dart:developer' as dev;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Central place to keep track of MyoBand services/characteristics after a
/// successful BLE connection.
class MyoBandProcess {
  MyoBandProcess._();

  static List<BluetoothService> _services = const <BluetoothService>[];
  static List<BluetoothCharacteristic> _characteristics =
      const <BluetoothCharacteristic>[];

  static final Map<Guid, List<BluetoothCharacteristic>>
  _characteristicsByService = <Guid, List<BluetoothCharacteristic>>{};

  static bool _isDiscovering = false;

  /// Unmodifiable list of the most recently discovered services.
  static List<BluetoothService> get services => List.unmodifiable(_services);

  /// Flat list of every characteristic found across all services.
  static List<BluetoothCharacteristic> get characteristics =>
      List.unmodifiable(_characteristics);

  /// Whether at least one discovery has been completed this session.
  static bool get hasDiscovery => _services.isNotEmpty;

  /// All characteristics under the provided [serviceUuid].
  static List<BluetoothCharacteristic> characteristicsForService(
    Guid serviceUuid,
  ) {
    return List.unmodifiable(
      _characteristicsByService[serviceUuid] ??
          const <BluetoothCharacteristic>[],
    );
  }

  /// Helper to find a specific characteristic given its service + characteristic UUIDs.
  static BluetoothCharacteristic? findCharacteristic(
    Guid serviceUuid,
    Guid characteristicUuid,
  ) {
    final serviceChars = _characteristicsByService[serviceUuid];
    if (serviceChars == null) return null;
    for (final characteristic in serviceChars) {
      if (characteristic.characteristicUuid == characteristicUuid) {
        return characteristic;
      }
    }
    return null;
  }

  /// Run BLE discovery once a device reports it is connected.
  static Future<void> discover(BluetoothDevice device) async {
    if (_isDiscovering) {
      dev.log(
        'Discovery already running, skipping duplicate request',
        name: 'MyoBandProcess',
      );
      return;
    }
    _isDiscovering = true;

    try {
      dev.log(
        'Discovering services for ${device.remoteId}',
        name: 'MyoBandProcess',
      );
      final discoveredServices = await device.discoverServices();
      _services = List<BluetoothService>.unmodifiable(discoveredServices);

      final flattened = <BluetoothCharacteristic>[];
      _characteristicsByService.clear();

      for (final service in discoveredServices) {
        final chars = List<BluetoothCharacteristic>.unmodifiable(
          service.characteristics,
        );
        _characteristicsByService[service.serviceUuid] = chars;
        flattened.addAll(chars);
      }

      _characteristics = List<BluetoothCharacteristic>.unmodifiable(flattened);
      dev.log(
        'Discovered ${_services.length} services & ${_characteristics.length} characteristics',
        name: 'MyoBandProcess',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Failed to discover MyoBand services: $e',
        name: 'MyoBandProcess',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isDiscovering = false;
    }
  }

  /// Clear cached services/characteristics when the device disconnects.
  static void clearCache() {
    _services = const <BluetoothService>[];
    _characteristics = const <BluetoothCharacteristic>[];
    _characteristicsByService.clear();
  }

  /// Log the currently cached services & characteristics to help debugging.
  static void logDiscoveredData() {
    if (_services.isEmpty) {
      dev.log(
        'Chưa có dịch vụ nào được lưu. Hãy chắc chắn đã gọi discover().',
        name: 'MyoBandProcess',
      );
      return;
    }

    dev.log(
      'Đang có ${_services.length} service / ${_characteristics.length} characteristic được cache',
      name: 'MyoBandProcess',
    );

    for (final service in _services) {
      dev.log('Service: ${service.serviceUuid}', name: 'MyoBandProcess');
      final chars =
          _characteristicsByService[service.serviceUuid] ??
          const <BluetoothCharacteristic>[];
      for (final characteristic in chars) {
        dev.log(
          '  └─ Characteristic: ${characteristic.characteristicUuid}',
          name: 'MyoBandProcess',
        );
      }
    }
  }
}
