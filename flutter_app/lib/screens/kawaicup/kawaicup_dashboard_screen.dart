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
      ]);
      setState(() {
        _cumulative = results[0] as List<CumulativeScore>;
        _topScores = results[1] as List<TopScore>;
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
          // タイトル（フェードイン）
          FadeTransition(
            opacity: _titleFade,
            child: const Text(
              '累積スコア推移',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FadeTransition(
            opacity: _titleFade,
            child: const Text(
              '3/1 スタート',
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
            const Text('データがありません',
                style: TextStyle(color: Colors.grey))
          else
            ...List.generate(_topScores.length, (i) {
              return RankingCard(
                score: _topScores[i],
                rank: i,
                delay: Duration(milliseconds: 300 + i * 120),
              );
            }),
        ],
      ),
    );
  }
}
