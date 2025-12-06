import 'package:app_vedc/utils/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PPGChart extends StatelessWidget {
  const PPGChart({super.key, required this.buffer, this.maxSamples = 360});

  final List<double> buffer;
  final int maxSamples;

  List<FlSpot> _spots() {
    if (buffer.isEmpty) return const [];
    final startIndex = buffer.length > maxSamples
        ? buffer.length - maxSamples
        : 0;
    final view = buffer.sublist(startIndex);
    return [
      for (var i = 0; i < view.length; i++) FlSpot(i.toDouble(), view[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final points = _spots();
    double minY = 0;
    double maxY = 100;
    if (points.isNotEmpty) {
      double localMin = points.first.y;
      double localMax = points.first.y;
      for (final spot in points) {
        if (spot.y < localMin) localMin = spot.y;
        if (spot.y > localMax) localMax = spot.y;
      }
      final range = (localMax - localMin).abs();
      final padding = range == 0
          ? (localMax.abs() * 0.1) + 1
          : (range * 0.2).clamp(0.5, 200.0);
      minY = (localMin - padding).clamp(-1000.0, localMax + padding);
      maxY = localMax + padding;
      if (minY == maxY) {
        minY -= 1;
        maxY += 1;
      }
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
        ),
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
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.transparent),
            right: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
            bottom: BorderSide(color: Colors.transparent),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 1.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.25),
                  VedcColors.background.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: Duration.zero,
      curve: Curves.linear,
    );
  }
}
