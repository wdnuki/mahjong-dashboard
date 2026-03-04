import 'package:flutter/foundation.dart';
import '../models/hanchan_summary.dart';
import '../services/api_service.dart';

/// 半荘サマリデータの状態を管理する ChangeNotifier
class HanchanSummaryNotifier extends ChangeNotifier {
  final ApiService _apiService;

  HanchanSummaryNotifier(this._apiService);

  List<HanchanSummary> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<HanchanSummary> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _apiService.fetchHanchanSummary();
    } catch (e) {
      _error = e.toString();
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
