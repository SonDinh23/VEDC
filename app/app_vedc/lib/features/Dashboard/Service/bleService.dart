import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static const String advUUIDRing = "514bd5a1-1ef9-49c8-b569-127a84896d20";

  static List<String> listAdvUUID = [advUUIDRing];

  static Map<String, String> servicesRing = {
    "RING_SERVICE_UUID": "514bd5a1-1ef9-49c8-b569-127a84896d20",
    "SENSOR_SERVICE_UUID": "f7df671a-cc50-4e73-a3d2-314e53895150",
  };

  static Map<String, String> characteristicsRing = {
    "OTA_UUID": "514bd5a1-1ef9-49c8-b569-127a84896d21",
    "Name_UUID": "514bd5a1-1ef9-49c8-b569-127a84896d22",
    "Hardware_UUID": "514bd5a1-1ef9-49c8-b569-127a84896d23",
    "MODE_UUID": "f7df671a-cc50-4e73-a3d2-314e53895151",
    "EMG_IMU_UUID": "f7df671a-cc50-4e73-a3d2-314e53895152",
    "ECG_CHAR_UUID": "f7df671a-cc50-4e73-a3d2-314e53895153",
    "PPG_CHAR_UUID": "f7df671a-cc50-4e73-a3d2-314e53895154",
    "ALL_SENSORS_CHAR_UUID": "f7df671a-cc50-4e73-a3d2-314e53895155",
    "BATTERY_CHAR_UUID": "f7df671a-cc50-4e73-a3d2-314e53895156",
  };
}
