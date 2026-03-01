import 'package:flutter/material.dart';
import '../../models/ranking_entry.dart';
import '../../models/relation.dart';
import '../../providers/participant_history_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/history_line_chart.dart';
import '../../widgets/loading_indicator.dart';

class ParticipantDetailScreen extends StatefulWidget {
  const ParticipantDetailScreen({
    super.key,
    required this.entry,
    required this.year,
  });

  final RankingEntry entry;
  final int year;

  @override
  State<ParticipantDetailScreen> createState() =>
      _ParticipantDetailScreenState();
}

class _ParticipantDetailScreenState extends State<ParticipantDetailScreen> {
  late final ApiService _apiService;
  late final ParticipantHistoryNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _notifier = ParticipantHistoryNotifier(_apiService);
    _notifier.load(widget.entry.participantId, widget.year);
  }

  @override
  void dispose() {
    _notifier.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: () =>
                _notifier.load(widget.entry.participantId, widget.year),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          if (_notifier.isLoading) {
            return const LoadingIndicator();
          }

          if (_notifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラー: ${_notifier.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _notifier.load(
                      widget.entry.participantId,
                      widget.year,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 当年サマリーカード
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: _SummaryCard(entry: widget.entry, year: widget.year),
                ),

                // 年度別推移グラフ
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    '年度別ポイント推移',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_notifier.history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('履歴データがありません'),
                  )
                else
                  HistoryLineChart(history: _notifier.history),

                const Divider(height: 24),

                // 投票者一覧（当年度）
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Text(
                    '${widget.year}年度の投票者',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_notifier.voters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('投票データがありません'),
                  )
                else
                  _VoterList(voters: _notifier.voters),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 当年サマリーカード
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.entry, required this.year});

  final RankingEntry entry;
  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: '$year年度 順位', value: '${entry.rank}位'),
            _Stat(label: '得票数', value: '${entry.voteCount}票'),
            _Stat(label: 'ポイント', value: '${entry.pointTotal}pt'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 投票者リスト（ポイント降順）
class _VoterList extends StatelessWidget {
  const _VoterList({required this.voters});

  final List<Relation> voters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          Theme.of(context).colorScheme.secondaryContainer,
        ),
        columns: const [
          DataColumn(label: Text('投票者ID')),
          DataColumn(label: Text('票数'), numeric: true),
          DataColumn(label: Text('ポイント合計'), numeric: true),
        ],
        rows: voters.map((r) {
          return DataRow(cells: [
            DataCell(Text(r.voterId)),
            DataCell(Text('${r.voteCount}')),
            DataCell(Text(
              '${r.pointSum}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
