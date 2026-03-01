import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/participant_history.dart';

/// 参加者の年度別ポイント推移を折れ線グラフで表示するウィジェット
class HistoryLineChart extends StatelessWidget {
  const HistoryLineChart({super.key, required this.history});

  final List<ParticipantHistory> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.primary;
    final maxY = history
        .map((h) => h.pointTotal)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.pointTotal.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.25,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= history.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${history[i].eventYear}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == 0) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((s) {
                    final i = s.spotIndex;
                    final h = history[i];
                    return LineTooltipItem(
                      '${h.eventYear}\n${h.pointTotal}pt (${h.voteCount}票)',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
