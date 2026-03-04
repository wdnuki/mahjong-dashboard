import 'package:flutter/material.dart';
import '../../models/cumulative_score.dart';
import '../../models/top_score.dart';
import '../../models/player_model.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/animated_line_chart.dart';
import '../../widgets/ranking_card.dart';

class KawaiCupDashboardScreen extends StatefulWidget {
  const KawaiCupDashboardScreen({super.key});

  @override
  State<KawaiCupDashboardScreen> createState() =>
      _KawaiCupDashboardScreenState();
}

class _KawaiCupDashboardScreenState extends State<KawaiCupDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  List<CumulativeScore> _cumulative = [];
  List<TopScore> _topScores = [];
  String? _lastImportedAt;
  bool _isLoading = true;
  String? _error;

  late final AnimationController _titleController;
  late final Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    );
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
        _api.fetchLastImportedAt(),
      ]);
      setState(() {
        _cumulative = results[0] as List<CumulativeScore>;
        _topScores = results[1] as List<TopScore>;
        _lastImportedAt = results[2] as String?;
      });
      _titleController.forward(from: 0);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// CumulativeScore リストを Player リストに変換
  List<Player> _buildPlayers() {
    final playerNames = _cumulative.map((e) => e.nickName).toSet().toList()
      ..sort();
    return playerNames.map((name) {
      final scores = _cumulative
          .where((e) => e.nickName == name)
          .map((e) => PlayerScore(
                dayOfMonth: int.parse(e.kanriDate.substring(8)),
                cumulative: e.cumPoint,
              ))
          .toList()
        ..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
      return Player(name: name, scores: scores);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カワイカップ特設ダッシュボード'),
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
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final players = _buildPlayers();

    // 最終スコアが最大のプレイヤーのインデックスを求める
    int firstPlaceIndex = 0;
    if (players.isNotEmpty) {
      double maxScore = players[0].finalScore;
      for (int i = 1; i < players.length; i++) {
        if (players[i].finalScore > maxScore) {
          maxScore = players[i].finalScore;
          firstPlaceIndex = i;
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル + 最終更新（フェードイン）
          FadeTransition(
            opacity: _titleFade,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '累積スコア推移',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_lastImportedAt != null)
                  Text(
                    '最終更新: $_lastImportedAt',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 折れ線グラフ（アニメーション付き）
          SizedBox(
            height: 300,
            child: players.isEmpty
                ? const Center(child: Text('データがありません'))
                : AnimatedLineChart(
                    players: players,
                    firstPlaceIndex: firstPlaceIndex,
                  ),
          ),

          const SizedBox(height: 32),

          // ランキングタイトル
          FadeTransition(
            opacity: _titleFade,
            child: const Text(
              '最高得点ベスト3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ランキングカード（遅延フェードイン）
          if (_topScores.isEmpty)
            const Text('データがありません', style: TextStyle(color: Colors.grey))
          else
            ...List.generate(_topScores.length, (i) {
              return RankingCard(
                score: _topScores[i],
                rank: i,
                delay: Duration(milliseconds: 300 + i * 120),
              );
            }),

          const SizedBox(height: 32),

          // Final Round 対戦カード
          FadeTransition(
            opacity: _titleFade,
            child: const Text(
              'Final Round 対戦カード',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (players.isNotEmpty)
            _FinalRoundTable(
              top4: ([...players]
                    ..sort((a, b) => b.finalScore.compareTo(a.finalScore)))
                  .take(4)
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Final Round 対戦カード ─────────────────────────────────────

class _FinalRoundTable extends StatelessWidget {
  const _FinalRoundTable({required this.top4});
  final List<Player> top4;

  /// 累積スコアの半分を [0, 100] でクランプ
  static double _carryOver(double score) => (score / 2.0).clamp(0.0, 100.0);

  static String _fmt(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      color: Colors.grey,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    const valueStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
    );
    const emptyStyle = TextStyle(
      color: Colors.transparent,
      fontSize: 13,
    );

    Widget headerCell(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            style: headerStyle,
            textAlign:
                text == 'プレイヤー' ? TextAlign.left : TextAlign.center,
          ),
        );

    Widget valueCell(String text, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            text,
            style: style ?? valueStyle,
            textAlign: TextAlign.center,
          ),
        );

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.4),
            1: FlexColumnWidth(1.4),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(1.4),
            4: FlexColumnWidth(1.4),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.25), width: 1),
                ),
              ),
              children: [
                headerCell('プレイヤー'),
                headerCell('持越'),
                headerCell('1半荘目'),
                headerCell('2半荘目'),
                headerCell('合計'),
              ],
            ),
            ...top4.asMap().entries.map((entry) {
              final player = entry.value;
              final carry = _carryOver(player.finalScore);
              final carryStr = _fmt(carry);
              return TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.1), width: 1),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(player.name, style: valueStyle),
                  ),
                  valueCell(carryStr),
                  valueCell('', style: emptyStyle),
                  valueCell('', style: emptyStyle),
                  valueCell(carryStr),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
