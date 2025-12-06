import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:app_vedc/features/Dashboard/Service/MyoBandProcess.dart';
import 'package:app_vedc/features/Dashboard/Service/bleController.dart';
import 'package:app_vedc/features/Dashboard/Service/bleService.dart';
import 'package:app_vedc/features/Dashboard/screens/HealthCare/EMG_IMUSensor/widgets/emg_chart.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OnEMG_IMUSensor extends StatefulWidget {
  const OnEMG_IMUSensor({super.key});

  @override
  State<OnEMG_IMUSensor> createState() => _OnEMG_IMUSensorState();
}

class _OnEMG_IMUSensorState extends State<OnEMG_IMUSensor> {
  static const _valueLabels = <String>['EMG', 'Roll', 'Pitch', 'Yaw', 'Time'];
  static const _imuLabels = <String>['Roll', 'Pitch', 'Yaw'];
  static const _emgIndex = 0;
  static const _timeIndex = 4;
  static const int _maxSamples = 300;
  static const double _maxEmgVisualValue = 1000;
  static const _imuStyles = <String, _ImuCardStyle>{
    'Roll': _ImuCardStyle(
      icon: Icons.screen_rotation_alt,
      gradient: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
      unit: 'deg',
    ),
    'Pitch': _ImuCardStyle(
      icon: Icons.swap_calls,
      gradient: [Color(0xFF9333EA), Color(0xFFF43F5E)],
      unit: 'deg',
    ),
    'Yaw': _ImuCardStyle(
      icon: Icons.navigation_outlined,
      gradient: [Color(0xFF0EA5E9), Color(0xFF10B981)],
      unit: 'deg',
    ),
    'Time': _ImuCardStyle(
      icon: Icons.schedule,
      gradient: [Color(0xFF1F2937), Color(0xFF4B5563)],
      unit: 'ms',
    ),
  };

  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  List<double> _latestValues = List<double>.filled(_valueLabels.length, 0);
  final List<double> _emgBuffer = <double>[];
  final List<List<double>> _recordedSamples = <List<double>>[];
  String _status = 'Đang chuẩn bị kết nối...';
  bool _isInitializing = false;
  bool _isRecording = false;
  Duration _recordDuration = const Duration(seconds: 30);
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _listenConnectionUpdates();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _recordTimer?.cancel();
    _teardownStream();
    super.dispose();
  }

  Future<void> _listenConnectionUpdates() async {
    final device = BLEController.myoBandDevice;
    _connectionSubscription?.cancel();
    if (device == null) return;

    _connectionSubscription = device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.connected) {
        await _initializeStream(force: true);
      } else if (state == BluetoothConnectionState.disconnected) {
        await _teardownStream('MyoBand đã ngắt kết nối');
      }
    });
  }

  Future<void> _initializeStream({bool force = false}) async {
    if (_isInitializing) return;

    final device = BLEController.myoBandDevice;
    if (device == null ||
        BLEController.myoBandState != BluetoothConnectionState.connected) {
      setState(() {
        _status = 'MyoBand chưa kết nối';
      });
      return;
    }

    if (_subscription != null && !force) {
      return;
    }

    _isInitializing = true;
    await _teardownStream();

    try {
      final characteristic = await _resolveCharacteristic(device);
      await characteristic.setNotifyValue(true);
      _subscription = characteristic.onValueReceived.listen(
        _handleIncomingPacket,
        onError: (Object error, StackTrace stackTrace) {
          dev.log(
            'EMG notify error: $error',
            name: 'EMG_IMU',
            error: error,
            stackTrace: stackTrace,
          );
          setState(() => _status = 'Lỗi đọc dữ liệu: $error');
        },
      );
      await characteristic.read();

      setState(() {
        _characteristic = characteristic;
        _status = 'Đang nhận dữ liệu realtime';
      });
    } catch (e, stackTrace) {
      dev.log(
        'Không thể khởi tạo EMG stream: $e',
        name: 'EMG_IMU',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _status = 'Không thể nhận dữ liệu: $e';
      });
    }
    _isInitializing = false;
  }

  Future<void> _teardownStream([String? reason]) async {
    await _subscription?.cancel();
    _subscription = null;
    if (_characteristic != null) {
      try {
        await _characteristic!.setNotifyValue(false);
      } catch (_) {}
    }
    _characteristic = null;
    if (_isRecording) {
      _stopRecording();
    }
    if (reason != null && mounted) {
      setState(() {
        _status = reason;
      });
    }
  }

  Future<BluetoothCharacteristic> _resolveCharacteristic(
    BluetoothDevice device,
  ) async {
    final serviceUuid = Guid(BLEService.servicesRing['SENSOR_SERVICE_UUID']!);
    final charUuid = Guid(BLEService.characteristicsRing['EMG_IMU_UUID']!);

    final cached = MyoBandProcess.findCharacteristic(serviceUuid, charUuid);
    if (cached != null) return cached;

    final services = await device.discoverServices();
    for (final service in services) {
      if (service.serviceUuid == serviceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.characteristicUuid == charUuid) {
            return characteristic;
          }
        }
      }
    }

    throw StateError('Không tìm thấy EMG_IMU_UUID trong dịch vụ cảm biến');
  }

  void _handleIncomingPacket(List<int> payload) {
    if (payload.isEmpty) return;
    final values = <double>[];
    for (
      var i = 0;
      i + 1 < payload.length && values.length < _valueLabels.length;
      i += 2
    ) {
      final half = payload[i] | (payload[i + 1] << 8);
      values.add(_halfToFloat(half));
    }
    if (values.length < _valueLabels.length) {
      values.addAll(
        List<double>.filled(_valueLabels.length - values.length, 0),
      );
    }

    // dev.log(
    //   'EMG packet -> ${values.map((v) => v.toStringAsFixed(4)).join(', ')}',
    //   name: 'EMG_IMU',
    // );

    if (!mounted) return;
    setState(() {
      _latestValues = values;
      if (values.length > _emgIndex) {
        final clamped = values[_emgIndex]
            .clamp(0, _maxEmgVisualValue)
            .toDouble();
        _emgBuffer.add(clamped);
        if (_emgBuffer.length > _maxSamples) {
          _emgBuffer.removeRange(0, _emgBuffer.length - _maxSamples);
        }
      }
      if (_isRecording) {
        _recordedSamples.add(List<double>.from(values));
      }
    });
  }

  void _startRecording() {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
      _recordElapsed = Duration.zero;
      _recordedSamples.clear();
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordElapsed = Duration(seconds: timer.tick);
      });
      if (_recordElapsed >= _recordDuration) {
        _stopRecording(autoComplete: true);
      }
    });
  }

  void _stopRecording({bool autoComplete = false}) {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _recordTimer = null;
    setState(() {
      _isRecording = false;
      if (!autoComplete) {
        _recordElapsed = Duration.zero;
      }
    });
    if (autoComplete && mounted) {
      final samples = _recordedSamples.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thu $samples mẫu trong ${_formatDuration(_recordDuration)}',
          ),
        ),
      );
    }
  }

  void _updateRecordDuration(double seconds) {
    if (_isRecording) return;
    setState(() {
      _recordDuration = Duration(seconds: seconds.round());
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double _halfToFloat(int half) {
    final int sign = (half & 0x8000) << 16;
    final int exponent = half & 0x7C00;
    final int mantissa = half & 0x03FF;

    int value;
    if (exponent == 0) {
      if (mantissa == 0) {
        value = sign;
      } else {
        int exp = 0x1C400;
        int man = mantissa;
        while ((man & 0x0400) == 0) {
          man <<= 1;
          exp -= 0x400;
        }
        man &= 0x03FF;
        value = sign | ((exp - 0x400) << 13) | (man << 13);
      }
    } else if (exponent == 0x7C00) {
      value = sign | 0x7F800000 | (mantissa << 13);
    } else {
      value = sign | ((exponent + 0x1C000) << 13) | (mantissa << 13);
    }

    final byteData = ByteData(4)..setUint32(0, value);
    return byteData.getFloat32(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VedcColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "EMG & IMU Realtime",
          style: const TextStyle(
            color: VedcColors.white,
            fontFamily: 'Livvic',
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.normal,
            fontSize: 25,
          ),
        ),
        backgroundColor: VedcColors.primary,
        foregroundColor: VedcColors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _status,
                    style: const TextStyle(
                      color: VedcColors.textSecondary,
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: Card(
                      color: const Color(0xFF052049),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: Text(
                                'EMG',
                                style: TextStyle(
                                  color: VedcColors.white,
                                  fontFamily: 'Livvic',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: EMGChart(
                                buffer: List<double>.from(_emgBuffer),
                                maxSamples: _maxSamples,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Signal',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FractionallySizedBox(
                                    widthFactor: 0.20,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white70,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RecordingPanel(
                    duration: _recordDuration,
                    elapsed: _recordElapsed,
                    samples: _recordedSamples.length,
                    isRecording: _isRecording,
                    onDurationChanged: _updateRecordDuration,
                    onStart: _startRecording,
                    onStop: () => _stopRecording(),
                    formatDuration: _formatDuration,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricGrid(constraints.maxWidth),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricGrid(double maxWidth) {
    final crossAxisCount = maxWidth > 900
        ? 4
        : maxWidth > 600
        ? 3
        : 2;
    final aspectRatio = maxWidth > 900
        ? 1.4
        : maxWidth > 600
        ? 1.2
        : 0.95;
    final cards = [
      ..._imuLabels.map(
        (label) => _MetricCardData(
          label: label,
          value: _latestValues[_valueLabels.indexOf(label)],
          style: _imuStyles[label] ?? _ImuCardStyle.defaultStyle,
        ),
      ),
      _MetricCardData(
        label: 'Time',
        value: _latestValues[_timeIndex],
        style: _imuStyles['Time'] ?? _ImuCardStyle.defaultStyle,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: aspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _ValueCard(
          label: card.label,
          value: card.value,
          style: card.style,
        );
      },
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.label,
    required this.value,
    required this.style,
  });

  final String label;
  final double value;
  final _ImuCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              if (style.unit != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    style.unit!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Livvic',
              fontWeight: FontWeight.w900,
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    required this.duration,
    required this.elapsed,
    required this.samples,
    required this.isRecording,
    required this.onDurationChanged,
    required this.onStart,
    required this.onStop,
    required this.formatDuration,
  });

  final Duration duration;
  final Duration elapsed;
  final int samples;
  final bool isRecording;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return Card(
      color: VedcColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_rounded, color: VedcColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Thu dữ liệu',
                  style: TextStyle(
                    fontFamily: 'Livvic',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  isRecording ? 'Đang thu' : 'Sẵn sàng',
                  style: TextStyle(
                    color: isRecording
                        ? Colors.orangeAccent
                        : VedcColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Thời lượng mục tiêu: ${formatDuration(duration)}',
              style: const TextStyle(
                fontFamily: 'Quicksand',
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              min: 5,
              max: 180,
              divisions: 35,
              value: duration.inSeconds.toDouble().clamp(5, 180),
              label: '${duration.inSeconds}s',
              onChanged: isRecording ? null : onDurationChanged,
            ),
            if (isRecording)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    'Đã thu: ${formatDuration(elapsed)} / ${formatDuration(duration)}',
                    style: const TextStyle(fontFamily: 'Quicksand'),
                  ),
                ],
              )
            else
              Text(
                'Mẫu đã lưu: $samples',
                style: const TextStyle(fontFamily: 'Quicksand'),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRecording ? onStop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Dừng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isRecording ? null : onStart,
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Bắt đầu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImuCardStyle {
  const _ImuCardStyle({required this.icon, required this.gradient, this.unit});

  final IconData icon;
  final List<Color> gradient;
  final String? unit;

  static const defaultStyle = _ImuCardStyle(
    icon: Icons.sensors,
    gradient: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
    unit: null,
  );
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.style,
  });

  final String label;
  final double value;
  final _ImuCardStyle style;
}
