import 'package:flutter/material.dart';
import '../../models/hanchan_entry.dart';
import '../../providers/hanchan_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';

class HanchanScreen extends StatefulWidget {
  const HanchanScreen({super.key});

  @override
  State<HanchanScreen> createState() => _HanchanScreenState();
}

class _HanchanScreenState extends State<HanchanScreen> {
  late final ApiService _apiService;
  late final HanchanNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _notifier = HanchanNotifier(_apiService);
    _notifier.load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('半荘一覧'),
        actions: [
          ListenableBuilder(
            listenable: _notifier,
            builder: (context, _) => _YearMonthSelector(
              year: _notifier.year,
              month: _notifier.month,
              onChanged: (y, m) => _notifier.load(year: y, month: m),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _notifier.load,
            tooltip: '再読み込み',
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
                    onPressed: _notifier.load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          if (_notifier.entries.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          return _HanchanTable(entries: _notifier.entries);
        },
      ),
    );
  }
}

class _YearMonthSelector extends StatelessWidget {
  const _YearMonthSelector({
    required this.year,
    required this.month,
    required this.onChanged,
  });

  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(3, (i) => now.year - i);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<int>(
          value: year,
          underline: const SizedBox(),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text('$y年')))
              .toList(),
          onChanged: (y) => onChanged(y!, month),
        ),
        const SizedBox(width: 4),
        DropdownButton<int>(
          value: month,
          underline: const SizedBox(),
          items: List.generate(12, (i) => i + 1)
              .map((m) => DropdownMenuItem(value: m, child: Text('$m月')))
              .toList(),
          onChanged: (m) => onChanged(year, m!),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _HanchanTable extends StatelessWidget {
  const _HanchanTable({required this.entries});

  final List<HanchanEntry> entries;

  @override
  Widget build(BuildContext context) {
    final hanchanIds = entries.map((e) => e.hanchanId).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          columns: const [
            DataColumn(label: Text('日付')),
            DataColumn(label: Text('順位'), numeric: true),
            DataColumn(label: Text('名前')),
            DataColumn(label: Text('素点'), numeric: true),
            DataColumn(label: Text('ポイント'), numeric: true),
            DataColumn(label: Text('飛び')),
            DataColumn(label: Text('キル'), numeric: true),
          ],
          rows: List.generate(entries.length, (i) {
            final e = entries[i];
            final isNewHanchan =
                i == 0 || hanchanIds[i - 1] != e.hanchanId;

            // 半荘ごとに交互に背景色を変えて区別しやすくする
            final hanchanIndex = entries
                .take(i + 1)
                .map((e) => e.hanchanId)
                .toSet()
                .length - 1;
            final rowColor = hanchanIndex.isEven
                ? Theme.of(context).colorScheme.surfaceContainerLow
                : null;

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              cells: [
                DataCell(Text(
                  isNewHanchan ? e.kanriDate : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )),
                DataCell(Text('${e.rank}')),
                DataCell(Text(
                  e.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                DataCell(Text(e.soten.toStringAsFixed(0))),
                DataCell(Text(
                  e.point.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: e.point >= 0
                        ? Colors.blue[700]
                        : Colors.red[700],
                  ),
                )),
                DataCell(Text(
                  e.deadFlag,
                  style: TextStyle(
                    color: e.deadFlag == '飛び' ? Colors.red[600] : null,
                  ),
                )),
                DataCell(Text(e.killCnt > 0 ? '${e.killCnt}' : '')),
              ],
            );
          }),
        ),
      ),
    );
  }
}
