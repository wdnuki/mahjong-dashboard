import 'package:flutter/material.dart';
import '../../models/ranking_entry.dart';
import '../../providers/ranking_provider.dart';

/// ランキングテーブル
/// ヘッダーをタップするとソート順を切り替える
class RankingTable extends StatelessWidget {
  const RankingTable({
    super.key,
    required this.entries,
    required this.sort,
    required this.onSortChanged,
  });

  final List<RankingEntry> entries;
  final RankingSort sort;
  final ValueChanged<RankingSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortAscending: false,
          sortColumnIndex: _sortColumnIndex,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          columns: [
            const DataColumn(label: Text('順位')),
            DataColumn(
              label: const Text('名前'),
              onSort: (_, __) => onSortChanged(RankingSort.byName),
            ),
            DataColumn(
              label: const Text('得票数'),
              numeric: true,
              onSort: (_, __) => onSortChanged(RankingSort.byVotes),
            ),
            DataColumn(
              label: const Text('ポイント'),
              numeric: true,
              onSort: (_, __) => onSortChanged(RankingSort.byPoints),
            ),
          ],
          rows: entries.map((entry) {
            return DataRow(
              cells: [
                DataCell(Text('${entry.rank}')),
                DataCell(Text(entry.displayName)),
                DataCell(Text('${entry.voteCount}')),
                DataCell(
                  Text(
                    '${entry.pointTotal}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  int? get _sortColumnIndex {
    switch (sort) {
      case RankingSort.byName:
        return 1;
      case RankingSort.byVotes:
        return 2;
      case RankingSort.byPoints:
        return 3;
    }
  }
}
