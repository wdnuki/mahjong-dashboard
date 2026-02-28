import 'package:flutter/material.dart';
import '../../providers/ranking_provider.dart';
import '../../providers/year_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/year_selector.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/ranking_bar_chart.dart';
import 'ranking_table.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final ApiService _apiService;
  late final YearNotifier _yearNotifier;
  late final RankingNotifier _rankingNotifier;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _yearNotifier = YearNotifier();
    _rankingNotifier = RankingNotifier(_apiService);
    _yearNotifier.addListener(_loadRanking);
    _loadRanking();
  }

  void _loadRanking() {
    _rankingNotifier.load(_yearNotifier.selectedYear);
  }

  @override
  void dispose() {
    _yearNotifier.removeListener(_loadRanking);
    _yearNotifier.dispose();
    _rankingNotifier.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kawai Cup ランキング'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ListenableBuilder(
              listenable: _yearNotifier,
              builder: (context, _) {
                return YearSelector(
                  selectedYear: _yearNotifier.selectedYear,
                  availableYears: _yearNotifier.availableYears,
                  onChanged: _yearNotifier.setYear,
                );
              },
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _rankingNotifier,
        builder: (context, _) {
          if (_rankingNotifier.isLoading) {
            return const LoadingIndicator();
          }

          if (_rankingNotifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラー: ${_rankingNotifier.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadRanking,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          if (_rankingNotifier.entries.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 棒グラフ (トップ10)
              RankingBarChart(entries: _rankingNotifier.entries),
              const Divider(height: 1),
              // ソート切替
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Text('並び順: ', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    _SortChip(
                      label: 'ポイント',
                      selected: _rankingNotifier.sort == RankingSort.byPoints,
                      onTap: () =>
                          _rankingNotifier.setSort(RankingSort.byPoints),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: '得票数',
                      selected: _rankingNotifier.sort == RankingSort.byVotes,
                      onTap: () =>
                          _rankingNotifier.setSort(RankingSort.byVotes),
                    ),
                    const SizedBox(width: 6),
                    _SortChip(
                      label: '名前',
                      selected: _rankingNotifier.sort == RankingSort.byName,
                      onTap: () =>
                          _rankingNotifier.setSort(RankingSort.byName),
                    ),
                  ],
                ),
              ),
              // テーブル
              Expanded(
                child: RankingTable(
                  entries: _rankingNotifier.entries,
                  sort: _rankingNotifier.sort,
                  onSortChanged: _rankingNotifier.setSort,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}
