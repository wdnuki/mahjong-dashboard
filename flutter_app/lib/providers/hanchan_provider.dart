import 'package:flutter/foundation.dart';
import '../models/hanchan_entry.dart';
import '../services/api_service.dart';

/// 半荘データの状態を管理する ChangeNotifier
class HanchanNotifier extends ChangeNotifier {
  final ApiService _apiService;

  HanchanNotifier(this._apiService);

  List<HanchanEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<HanchanEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _apiService.fetchHanchans();
    } catch (e) {
      _error = e.toString();
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
