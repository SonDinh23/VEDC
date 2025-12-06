import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:app_vedc/features/Dashboard/Service/MyoBandProcess.dart';
import 'package:app_vedc/features/Dashboard/Service/bleController.dart';
import 'package:app_vedc/features/Dashboard/Service/bleService.dart';
import 'package:app_vedc/features/Dashboard/screens/HealthCare/ECGSensor/widgets/ecg_chart.dart';
import 'package:app_vedc/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OnECGSensor extends StatefulWidget {
  const OnECGSensor({super.key});

  @override
  State<OnECGSensor> createState() => _OnECGSensorState();
}

class _OnECGSensorState extends State<OnECGSensor> {
  static const _valueLabels = <String>[
    'Lead Off +',
    'Lead Off -',
    'Analog',
    'Heart Rate',
  ];
  static const int _loPositiveIndex = 0;
  static const int _loNegativeIndex = 1;
  static const int _analogIndex = 2;
  static const int _heartRateIndex = 3;
  static const int _maxSamples = 600;
  static const Duration _uiUpdateInterval = Duration(milliseconds: 40);
  static const double _analogSmoothingFactor = 0.25;
  static const _metricStyles = <String, _MetricCardStyle>{
    'Lead Off +': _MetricCardStyle(
      icon: Icons.arrow_circle_up,
      gradient: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    'Lead Off -': _MetricCardStyle(
      icon: Icons.arrow_circle_down,
      gradient: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
    ),
    'Analog': _MetricCardStyle(
      icon: Icons.monitor_heart,
      gradient: [Color(0xFF6366F1), Color(0xFF3B82F6)],
    ),
    'Heart Rate': _MetricCardStyle(
      icon: Icons.favorite,
      gradient: [Color(0xFFF97316), Color(0xFFEF4444)],
    ),
  };

  BluetoothCharacteristic? _characteristic;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final List<double> _analogBuffer = <double>[];
  final ValueNotifier<List<double>> _chartSamples = ValueNotifier<List<double>>(
    <double>[],
  );
  final ValueNotifier<List<double>> _metricValues = ValueNotifier<List<double>>(
    List<double>.filled(_valueLabels.length, 0),
  );
  final List<List<double>> _recordedSamples = <List<double>>[];
  String _status = 'Đang chuẩn bị kết nối...';
  bool _isInitializing = false;
  bool _isRecording = false;
  Duration _recordDuration = const Duration(seconds: 30);
  Duration _recordElapsed = Duration.zero;
  Timer? _recordTimer;
  Timer? _uiTicker;
  double? _smoothedAnalog;
  List<double>? _pendingMetrics;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _listenConnectionUpdates();
    _uiTicker = Timer.periodic(
      _uiUpdateInterval,
      (_) => _publishRealtimeFrame(),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _recordTimer?.cancel();
    _uiTicker?.cancel();
    _chartSamples.dispose();
    _metricValues.dispose();
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
            'ECG notify error: $error',
            name: 'ECG',
            error: error,
            stackTrace: stackTrace,
          );
          setState(() => _status = 'Lỗi đọc dữ liệu: $error');
        },
      );
      await characteristic.read();

      setState(() {
        _characteristic = characteristic;
        _status = 'Đang nhận dữ liệu ECG realtime';
      });
    } catch (e, stackTrace) {
      dev.log(
        'Không thể khởi tạo ECG stream: $e',
        name: 'ECG',
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
    final charUuid = Guid(BLEService.characteristicsRing['ECG_CHAR_UUID']!);

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

    throw StateError('Không tìm thấy ECG_CHAR_UUID trong dịch vụ cảm biến');
  }

  void _handleIncomingPacket(List<int> payload) {
    if (payload.isEmpty) return;

    final values = List<double>.filled(_valueLabels.length, 0);
    if (payload.isNotEmpty) {
      values[_loPositiveIndex] = payload[0] > 0 ? 1 : 0;
    }
    if (payload.length > 1) {
      values[_loNegativeIndex] = payload[1] > 0 ? 1 : 0;
    }
    if (payload.length > 3) {
      final analogHalf = payload[2] | (payload[3] << 8);
      values[_analogIndex] = _halfToFloat(analogHalf);
    }
    if (payload.length > 5) {
      final hrHalf = payload[4] | (payload[5] << 8);
      values[_heartRateIndex] = _halfToFloat(hrHalf);
    }

    // dev.log(
    //   'ECG packet -> ${values.map((v) => v.toStringAsFixed(4)).join(', ')}',
    //   name: 'ECG',
    // );

    final analog = values[_analogIndex];
    if (analog.isFinite) {
      final previous = _smoothedAnalog ?? analog;
      final smoothed = previous + (analog - previous) * _analogSmoothingFactor;
      _smoothedAnalog = smoothed;
      _analogBuffer.add(smoothed);
      if (_analogBuffer.length > _maxSamples) {
        _analogBuffer.removeRange(0, _analogBuffer.length - _maxSamples);
      }
      _chartSamples.value = List<double>.from(_analogBuffer);
    }
    if (_isRecording) {
      _recordedSamples.add(List<double>.from(values));
    }

    _pendingMetrics = List<double>.from(values);
  }

  void _publishRealtimeFrame() {
    if (!mounted) return;
    if (_analogBuffer.isNotEmpty) {
      _chartSamples.value = List<double>.from(_analogBuffer);
    }
    if (_pendingMetrics != null) {
      _metricValues.value = List<double>.from(_pendingMetrics!);
    }
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
          "ECG Realtime",
          style: const TextStyle(
            color: VedcColors.white,
            fontFamily: 'Livvic',
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.normal,
            fontSize: 30,
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
                      color: const Color(0xFF081A3E),
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
                                'Analog ECG',
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
                              child: RepaintBoundary(
                                child: ValueListenableBuilder<List<double>>(
                                  valueListenable: _chartSamples,
                                  builder: (context, samples, _) {
                                    return ECGChart(
                                      buffer: samples,
                                      maxSamples: _maxSamples,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dữ liệu hiển thị từ cảm biến analog theo thời gian thực',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 12,
                                fontFamily: 'Quicksand',
                              ),
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
                  ValueListenableBuilder<List<double>>(
                    valueListenable: _metricValues,
                    builder: (context, values, _) {
                      return _buildMetricGrid(constraints.maxWidth, values);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricGrid(double maxWidth, List<double> values) {
    final crossAxisCount = maxWidth > 900
        ? 4
        : maxWidth > 600
        ? 3
        : 2;
    final aspectRatio = maxWidth > 900
        ? 1.4
        : maxWidth > 600
        ? 1.2
        : 0.9;

    final hr = values[_heartRateIndex];
    final analog = values[_analogIndex];
    final cards = <_MetricCardData>[
      _MetricCardData(
        label: 'Lead Off +',
        valueText: values[_loPositiveIndex] > 0.5 ? 'Mất tiếp xúc' : 'Ổn định',
        style: _metricStyles['Lead Off +']!,
      ),
      _MetricCardData(
        label: 'Lead Off -',
        valueText: values[_loNegativeIndex] > 0.5 ? 'Mất tiếp xúc' : 'Ổn định',
        style: _metricStyles['Lead Off -']!,
      ),
      _MetricCardData(
        label: 'Analog',
        valueText: analog.isFinite ? analog.toStringAsFixed(3) : '--',
        style: _metricStyles['Analog']!,
        unit: 'mV',
      ),
      _MetricCardData(
        label: 'Heart Rate',
        valueText: hr > 0 && hr.isFinite ? hr.toStringAsFixed(1) : '--',
        style: _metricStyles['Heart Rate']!,
        unit: 'bpm',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _ValueCard(data: cards[index]);
      },
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.style.gradient,
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
                child: Icon(data.style.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              if (data.unit != null)
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
                    data.unit!,
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
            data.valueText,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Livvic',
              fontWeight: FontWeight.w900,
              fontSize: 28,
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

class _MetricCardStyle {
  const _MetricCardStyle({required this.icon, required this.gradient});

  final IconData icon;
  final List<Color> gradient;
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.valueText,
    required this.style,
    this.unit,
  });

  final String label;
  final String valueText;
  final _MetricCardStyle style;
  final String? unit;
}
