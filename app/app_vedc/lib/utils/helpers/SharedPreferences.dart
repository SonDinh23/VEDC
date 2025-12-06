import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScanItem {
  final String advName;
  final String id;
  final int rssi;
  final String serviceUuids;

  ScanItem({
    required this.advName,
    required this.id,
    required this.rssi,
    required this.serviceUuids,
  });

  Map<String, dynamic> toJson() => {
    'advName': advName,
    'id': id,
    'rssi': rssi,
    'serviceUuids': serviceUuids,
  };

  factory ScanItem.fromJson(Map<String, dynamic> json) {
    return ScanItem(
      advName: json['advName'] as String,
      id: json['id'] as String,
      rssi: json['rssi'] as int,
      serviceUuids: json['serviceUuids'] as String,
    );
  }
}

// 1.2 Lớp DeviceStorage: lưu / xoá / đọc từng thiết bị riêng
class DeviceStorage {
  static const _myoKey = 'device_myoband';

  /// Lưu ScanItem cho MYOBAND (thay thế nếu đã có)
  static Future<void> saveMyoBand(ScanItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(item.toJson());
    await prefs.setString(_myoKey, jsonStr);
  }

  /// Đọc MYOBAND (trả về null nếu chưa lưu)
  static Future<ScanItem?> loadMyoBand() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_myoKey);
    if (jsonStr == null) return null;
    return ScanItem.fromJson(jsonDecode(jsonStr));
  }

  /// Xoá MYOBAND
  static Future<void> clearMyoBand() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_myoKey);
  }
}
