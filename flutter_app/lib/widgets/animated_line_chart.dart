import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player_model.dart';

class AnimatedLineChart extends StatefulWidget {
  const AnimatedLineChart({
    super.key,
    required this.players,
    required this.firstPlaceIndex,
  });

  final List<Player> players;
  final int firstPlaceIndex;

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  static const _maxX = 31.0;
  static const _goldColor = Color(0xFFFFD700);
  static const _playerColors = [
    Color(0xFF4CAF50),
    Color(0xFF00BCD4),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // currentMaxX 以内のスポットのみ返す（境界は補間）
  List<FlSpot> _visibleSpots(List<FlSpot> all, double currentMaxX) {
    final result = <FlSpot>[];
    for (int i = 0; i < all.length; i++) {
      if (all[i].x <= currentMaxX) {
        result.add(all[i]);
      } else {
        if (i > 0) {
          final prev = all[i - 1];
          final curr = all[i];
          final t = (currentMaxX - prev.x) / (curr.x - prev.x);
          result.add(FlSpot(currentMaxX, prev.y + t * (curr.y - prev.y)));
        }
        break;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.players;
    final firstIdx = widget.firstPlaceIndex;

    // 全プレイヤーの全スポット（スタート点 + 実データ）を事前計算
    final allSpotsList = players.map((p) {
      return [
        const FlSpot(0, 0),
        ...p.scores
            .map((s) => FlSpot(s.dayOfMonth.toDouble(), s.cumulative)),
      ];
    }).toList();

    // Y軸範囲（0を必ず含む）
    final allValues = [
      0.0,
      ...players.expand((p) => p.scores.map((s) => s.cumulative)),
    ];
    final minY = allValues.reduce(min);
    final maxY = allValues.reduce(max);
    final yPad = ((maxY - minY) * 0.12).clamp(10.0, double.infinity);

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              // データが存在する最終日を上限にすることで、
              // 日数に関わらず「端に達するまで1秒」に統一される
              final dataMaxX = allSpotsList.fold<double>(1.0, (m, spots) {
                if (spots.isEmpty) return m;
                final last = spots.last.x;
                return last > m ? last : m;
              });
              final currentMaxX = _progress.value * dataMaxX;

              final lineBars =
                  players.asMap().entries.map((entry) {
                final i = entry.key;
                final isFirst = i == firstIdx;
                final color = isFirst
                    ? _goldColor
                    : _playerColors[i % _playerColors.length];
                final spots =
                    _visibleSpots(allSpotsList[i], currentMaxX);

                return LineChartBarData(
                  spots: spots,
                  color: color,
                  barWidth: isFirst ? 4 : 3,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.25),
                        color.withOpacity(0.0),
                      ],
                    ),
                  ),
                );
              }).toList();

              return LineChart(
                duration: Duration.zero,
                LineChartData(
                  minX: 0,
                  maxX: _maxX,
                  minY: minY - yPad,
                  maxY: maxY + yPad,
                  lineBarsData: lineBars,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF2C2C2C),
                      getTooltipItems: (spots) => spots.map((spot) {
                        final name = players[spot.barIndex].name;
                        final sign = spot.y >= 0 ? '+' : '';
                        return LineTooltipItem(
                          '$name\n$sign${spot.y.toStringAsFixed(1)}',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final d = value.toInt();
                          if (d != 0 && d % 5 != 0 && d != 31) {
                            return const SizedBox();
                          }
                          final label = d == 0 ? '開始' : '3/$d';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10)),
                          );
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
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // 凡例
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: players.asMap().entries.map((entry) {
            final i = entry.key;
            final isFirst = i == firstIdx;
            final color = isFirst
                ? _goldColor
                : _playerColors[i % _playerColors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 18, height: 3, color: color),
                const SizedBox(width: 4),
                Text(
                  isFirst ? '👑 ${entry.value.name}' : entry.value.name,
                  style: TextStyle(
                    color: isFirst ? _goldColor : Colors.grey[300],
                    fontSize: 12,
                    fontWeight: isFirst
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
