import 'package:flutter/material.dart';
import '../../models/hanchan_summary.dart';
import '../../providers/hanchan_summary_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';

class HanchanSummaryScreen extends StatefulWidget {
  const HanchanSummaryScreen({super.key});

  @override
  State<HanchanSummaryScreen> createState() => _HanchanSummaryScreenState();
}

class _HanchanSummaryScreenState extends State<HanchanSummaryScreen> {
  late final ApiService _api;
  late final HanchanSummaryNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _notifier = HanchanSummaryNotifier(_api);
    _notifier.load();
  }

  @override
  void dispose() {
    _notifier.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('半荘サマリ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _notifier.load,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          if (_notifier.isLoading) return const LoadingIndicator();
          if (_notifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('エラー: ${_notifier.error}',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _notifier.load,
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }
          if (_notifier.entries.isEmpty) {
            return const Center(child: Text('データがありません'));
          }
          return _SummaryList(entries: _notifier.entries);
        },
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.entries});

  final List<HanchanSummary> entries;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          columns: const [
            DataColumn(label: Text('日付')),
            DataColumn(label: Text('結果')),
          ],
          rows: entries.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(
                  e.kanriDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )),
                DataCell(Text(e.summary)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
