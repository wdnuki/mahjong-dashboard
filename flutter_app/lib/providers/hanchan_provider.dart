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
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  List<HanchanEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get year => _year;
  int get month => _month;

  Future<void> load({int? year, int? month}) async {
    if (year != null) _year = year;
    if (month != null) _month = month;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _apiService.fetchHanchans(_year, _month);
    } catch (e) {
      _error = e.toString();
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
