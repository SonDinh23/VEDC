import 'package:app_vedc/utils/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ECGChart extends StatelessWidget {
  const ECGChart({super.key, required this.buffer, this.maxSamples = 300});

  final List<double> buffer;
  final int maxSamples;

  List<FlSpot> _buildSpots() {
    if (buffer.isEmpty) return const [];
    final length = buffer.length;
    final startIndex = length > maxSamples ? length - maxSamples : 0;
    final latest = buffer.sublist(startIndex);
    return [
      for (var i = 0; i < latest.length; i++) FlSpot(i.toDouble(), latest[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    double minY = -2;
    double maxY = 2;
    if (spots.isNotEmpty) {
      double localMin = spots.first.y;
      double localMax = spots.first.y;
      for (final spot in spots) {
        if (spot.y < localMin) localMin = spot.y;
        if (spot.y > localMax) localMax = spot.y;
      }
      final range = (localMax - localMin).abs();
      final padding = range == 0
          ? (localMax.abs() * 0.1) + 0.5
          : (range * 0.2).clamp(0.2, 50.0);
      minY = localMin - padding;
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
              reservedSize: 34,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            spots: spots,
            isCurved: false,
            color: VedcColors.white,
            barWidth: 1.4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  VedcColors.white.withOpacity(0.12),
                  VedcColors.white.withOpacity(0.02),
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
