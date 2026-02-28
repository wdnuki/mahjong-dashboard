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

class _HanchanTable extends StatelessWidget {
  const _HanchanTable({required this.entries});

  final List<HanchanEntry> entries;

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
            DataColumn(label: Text('順位'), numeric: true),
            DataColumn(label: Text('半荘ID')),
            DataColumn(label: Text('LINE USER ID')),
            DataColumn(label: Text('素点'), numeric: true),
            DataColumn(label: Text('ポイント'), numeric: true),
            DataColumn(label: Text('日時')),
          ],
          rows: entries.map((e) {
            final shortId = e.hanchanId.length > 8
                ? '…${e.hanchanId.substring(e.hanchanId.length - 8)}'
                : e.hanchanId;
            return DataRow(cells: [
              DataCell(Text('${e.rank}')),
              DataCell(Text(shortId)),
              DataCell(Text(e.lineUserId)),
              DataCell(Text('${e.soten.toStringAsFixed(0)}')),
              DataCell(Text(
                e.point.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(Text(e.createdAt)),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
