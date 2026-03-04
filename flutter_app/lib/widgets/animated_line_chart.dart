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

  static const _chartRightPad = 2.5; // ラベル用右余白
  static const _leftReserved = 48.0;
  static const _bottomReserved = 32.0;
  static const _goldColor = Color(0xFFFFD700);
  static const _playerColors = [
    Color(0xFF4CAF50),   // Green
    Color(0xFF00BCD4),   // Cyan
    Color(0xFF9C27B0),   // Purple
    Color(0xFFFF9800),   // Orange
    Color(0xFF2196F3),   // Blue
    Color(0xFFE91E63),   // Pink
    Color(0xFFF44336),   // Red
    Color(0xFF8BC34A),   // Light Green
    Color(0xFFFF5722),   // Deep Orange
    Color(0xFF607D8B),   // Blue Grey
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

  Color _colorOf(int playerIndex, int firstIdx) => playerIndex == firstIdx
      ? _goldColor
      : _playerColors[playerIndex % _playerColors.length];

  @override
  Widget build(BuildContext context) {
    final players = widget.players;
    final firstIdx = widget.firstPlaceIndex;

    // 全プレイヤーの全スポット（スタート点 + 実データ）を事前計算
    final allSpotsList = players.map((p) {
      return [
        const FlSpot(0, 0),
        ...p.scores.map((s) => FlSpot(s.dayOfMonth.toDouble(), s.cumulative)),
      ];
    }).toList();

    // データの最終X値（全プレイヤー中の最大日）
    final dataMaxX = allSpotsList.fold<double>(1.0, (m, spots) {
      if (spots.isEmpty) return m;
      final last = spots.last.x;
      return last > m ? last : m;
    });

    // 全プレイヤーを dataMaxX まで横ばいで延長（対戦のない人の線を揃える）
    final extendedSpotsList = List.generate(allSpotsList.length, (i) {
      final spots = allSpotsList[i];
      if (spots.isEmpty || spots.last.x >= dataMaxX) return spots;
      return [...spots, FlSpot(dataMaxX, spots.last.y)];
    });

    // チャートのX上限は常に3/31固定（右余白付き）
    // アニメーションの終点 dataMaxX とは別管理
    const chartMaxX = 31.0 + _chartRightPad;

    // Y軸範囲（0を必ず含む）
    final allValues = [
      0.0,
      ...players.expand((p) => p.scores.map((s) => s.cumulative)),
    ];
    final minY = allValues.reduce(min);
    final maxY = allValues.reduce(max);
    final yPad = ((maxY - minY) * 0.15).clamp(15.0, double.infinity);
    final chartMinY = minY - yPad;
    final chartMaxY = maxY + yPad;

    // 凡例：最終スコア降順
    final sortedEntries = [...players.asMap().entries.toList()]
      ..sort((a, b) => b.value.finalScore.compareTo(a.value.finalScore));

    return Column(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              final currentMaxX = _progress.value * dataMaxX;
              // ラベルは92%以降でフェードイン
              final labelOpacity =
                  ((_progress.value - 0.92) / 0.08).clamp(0.0, 1.0);

              final lineBars = players.asMap().entries.map((entry) {
                final i = entry.key;
                final isFirst = i == firstIdx;
                final color = _colorOf(i, firstIdx);
                final spots = _visibleSpots(extendedSpotsList[i], currentMaxX);

                return LineChartBarData(
                  spots: spots,
                  color: color,
                  barWidth: isFirst ? 3 : 2,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) =>
                        barData.spots.isNotEmpty &&
                        spot.x == barData.spots.last.x,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: isFirst ? 4.0 : 3.0,
                      color: color,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.18),
                        color.withOpacity(0.0),
                      ],
                    ),
                  ),
                );
              }).toList();

              return LayoutBuilder(
                builder: (ctx, constraints) {
                  final W = constraints.maxWidth;
                  final H = constraints.maxHeight;
                  final dataW = W - _leftReserved;
                  final dataH = H - _bottomReserved;

                  // データ座標 → ピクセル座標
                  double xPx(double x) =>
                      _leftReserved + x / chartMaxX * dataW;
                  double yPx(double y) =>
                      (1 - (y - chartMinY) / (chartMaxY - chartMinY)) * dataH;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LineChart(
                        duration: Duration.zero,
                        LineChartData(
                          minX: 0,
                          maxX: chartMaxX,
                          minY: chartMinY,
                          maxY: chartMaxY,
                          lineBarsData: lineBars,
                          extraLinesData: ExtraLinesData(
                            verticalLines: [
                              VerticalLine(
                                x: 14,
                                color: Colors.grey.withOpacity(0.35),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                                label: VerticalLineLabel(
                                  show: true,
                                  alignment: Alignment.topCenter,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                  labelResolver: (_) => '応援締め切り',
                                ),
                              ),
                              VerticalLine(
                                x: 31,
                                color: Colors.amber.withOpacity(0.45),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                                label: VerticalLineLabel(
                                  show: true,
                                  alignment: Alignment.topCenter,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                  ),
                                  labelResolver: (_) => '1stラウンド集計',
                                ),
                              ),
                            ],
                          ),
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
                                reservedSize: _leftReserved,
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
                                reservedSize: _bottomReserved,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final d = value.toInt();
                                  const showDays = {0, 7, 14, 21, 28, 31};
                                  if (!showDays.contains(d)) {
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
                                sideTitles: SideTitles(
                                    showTitles: false, reservedSize: 0)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: false, reservedSize: 0)),
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
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.3)),
                          ),
                        ),
                      ),
                      // 最終スコアラベル（アニメーション後フェードイン）
                      if (labelOpacity > 0)
                        ...players.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          if (p.scores.isEmpty) return const SizedBox.shrink();
                          final finalScore = p.finalScore;
                          // 延長後の端点（全員 dataMaxX に揃えた）
                          final finalX = dataMaxX;
                          final color = _colorOf(i, firstIdx);
                          final label = finalScore >= 0
                              ? '+${finalScore.toInt()}'
                              : '${finalScore.toInt()}';

                          return Positioned(
                            left: xPx(finalX) + 5,
                            top: yPx(finalScore) - 7,
                            child: Opacity(
                              opacity: labelOpacity,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // 凡例（最終スコア降順）
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: sortedEntries.map((entry) {
            final i = entry.key;
            final player = entry.value;
            final isFirst = i == firstIdx;
            final color = _colorOf(i, firstIdx);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 18, height: 3, color: color),
                const SizedBox(width: 4),
                Text(
                  isFirst ? '👑 ${player.name}' : player.name,
                  style: TextStyle(
                    color: isFirst ? _goldColor : Colors.grey[300],
                    fontSize: 12,
                    fontWeight:
                        isFirst ? FontWeight.bold : FontWeight.normal,
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
