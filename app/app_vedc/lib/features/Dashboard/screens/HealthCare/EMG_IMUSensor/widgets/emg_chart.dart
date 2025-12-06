import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:app_vedc/utils/constants/colors.dart';

class EMGChart extends StatelessWidget {
  const EMGChart({super.key, required this.buffer, this.maxSamples = 300});

  final List<double> buffer;
  final int maxSamples;

  double get _yMax {
    if (buffer.isEmpty) return 60;
    final maxVal = buffer.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return 60;
    return (maxVal * 1.15).clamp(20, 1000);
  }

  List<FlSpot> get _spots {
    final length = buffer.length;
    final start = length > maxSamples ? length - maxSamples : 0;
    final data = buffer.sublist(start);
    return [
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: _yMax,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.transparent),
            bottom: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
            right: BorderSide(color: Colors.transparent),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            color: VedcColors.white,
            barWidth: 1.2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
      duration: Duration.zero,
      curve: Curves.linear,
    );
  }
}
