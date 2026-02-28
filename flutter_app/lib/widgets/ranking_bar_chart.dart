import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ranking_entry.dart';

/// ランキングトップ10を棒グラフで表示するウィジェット
class RankingBarChart extends StatelessWidget {
  const RankingBarChart({super.key, required this.entries});

  final List<RankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final top10 = entries.take(10).toList();
    if (top10.isEmpty) return const SizedBox.shrink();

    final maxPoints = top10
        .map((e) => e.pointTotal)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: BarChart(
          BarChartData(
            maxY: maxPoints * 1.2,
            barGroups: top10.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.pointTotal.toDouble(),
                    color: Theme.of(context).colorScheme.primary,
                    width: 20,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i >= top10.length) return const SizedBox.shrink();
                    final name = top10[i].displayName;
                    final label = name.length > 5
                        ? '${name.substring(0, 4)}…'
                        : name;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label,
                          style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }
}
