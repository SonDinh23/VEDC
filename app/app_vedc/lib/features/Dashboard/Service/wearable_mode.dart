enum WearableMode {
  none(0, 'Unknown'),
  emgImu(1, 'EMG & IMU'),
  ecg(2, 'ECG'),
  ppg(3, 'PPG'),
  all(4, 'Multiple Sensor');

  const WearableMode(this.value, this.label);

  final int value;
  final String label;

  static WearableMode fromValue(int value) {
    for (final mode in WearableMode.values) {
      if (mode.value == value) return mode;
    }
    return WearableMode.none;
  }

  bool supports(WearableMode requiredMode) {
    if (this == WearableMode.none) return false;
    if (this == WearableMode.all) {
      // Multiple sensor mode can access every feature.
      return true;
    }
    return this == requiredMode;
  }

  String get shortLabel => label;
}
