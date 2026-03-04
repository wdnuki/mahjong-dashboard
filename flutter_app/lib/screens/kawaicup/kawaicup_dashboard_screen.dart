import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/cumulative_score.dart';
import '../../models/top_score.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';

class KawaiCupDashboardScreen extends StatefulWidget {
  const KawaiCupDashboardScreen({super.key});

  @override
  State<KawaiCupDashboardScreen> createState() =>
      _KawaiCupDashboardScreenState();
}

class _KawaiCupDashboardScreenState extends State<KawaiCupDashboardScreen> {
  final ApiService _api = ApiService();

  List<CumulativeScore> _cumulative = [];
  List<TopScore> _topScores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchCumulativeScores(),
        _api.fetchTopScores(),
      ]);
      setState(() {
        _cumulative = results[0] as List<CumulativeScore>;
        _topScores = results[1] as List<TopScore>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カワイカップ特設ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('エラー: $_error',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('再試行')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: '累積スコア推移（3/1以降）'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 300,
                        child: _CumulativeLineChart(data: _cumulative),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: '最高得点ベスト3'),
                      const SizedBox(height: 12),
                      _TopScoreList(scores: _topScores),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ─── 累積スコア折れ線グラフ ──────────────────────────────────────

class _CumulativeLineChart extends StatelessWidget {
  const _CumulativeLineChart({required this.data});
  final List<CumulativeScore> data;

  // X軸: 0(スタート) 〜 31(3/31) 固定
  static const _minX = 0.0;
  static const _maxX = 31.0;

  // "2026/03/05" → 5
  static int _dayOf(String kanriDate) => int.parse(kanriDate.substring(8));

  static const _colors = [
    Color(0xFFE91E8C),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    final players = data.map((e) => e.nickName).toSet().toList()..sort();

    final lineBars = players.asMap().entries.map((entry) {
      final idx = entry.key;
      final player = entry.value;
      // index 0 = スタート(値0)、以降は日付の日部分をそのままX座標に使用
      final spots = [
        const FlSpot(0, 0),
        ...data
            .where((e) => e.nickName == player)
            .map((e) => FlSpot(_dayOf(e.kanriDate).toDouble(), e.cumPoint)),
      ];
      return LineChartBarData(
        spots: spots,
        color: _colors[idx % _colors.length],
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        isCurved: false,
      );
    }).toList();

    // Y軸の範囲（0を必ず含める）
    final allPoints = data.map((e) => e.cumPoint).toList()..add(0);
    final minY = allPoints.reduce((a, b) => a < b ? a : b);
    final maxY = allPoints.reduce((a, b) => a > b ? a : b);
    final yPad = ((maxY - minY) * 0.1).abs().clamp(10.0, double.infinity);

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              minX: _minX,
              maxX: _maxX,
              minY: minY - yPad,
              maxY: maxY + yPad,
              lineBarsData: lineBars,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
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
                      // 0=スタート, 5, 10, 15, 20, 25, 31 のみ表示
                      if (d != 0 && d % 5 != 0 && d != 31) return const SizedBox();
                      final label = d == 0 ? '開始' : '3/$d';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(label, style: const TextStyle(fontSize: 10)),
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
                horizontalInterval: ((maxY - minY) / 4).abs().clamp(10.0, double.infinity),
              ),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 凡例
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: players.asMap().entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 3,
                  color: _colors[entry.key % _colors.length],
                ),
                const SizedBox(width: 4),
                Text(entry.value, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── ベスト3ランキング ────────────────────────────────────────────

class _TopScoreList extends StatelessWidget {
  const _TopScoreList({required this.scores});
  final List<TopScore> scores;

  static const _medals = ['👑', '🥈', '🥉'];
  static const _goldColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Text('データがありません');
    }
    return Card(
      child: Column(
        children: scores.asMap().entries.map((entry) {
          final rank = entry.key;
          final s = entry.value;
          final isFirst = rank == 0;
          return ListTile(
            leading: Text(
              _medals[rank],
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              s.nickName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isFirst ? _goldColor : null,
              ),
            ),
            subtitle: Text(s.kanriDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Text(
              '+${s.point.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isFirst ? _goldColor : Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
