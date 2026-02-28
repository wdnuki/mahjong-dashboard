import 'package:flutter/foundation.dart';
import '../models/ranking_entry.dart';
import '../services/api_service.dart';

enum RankingSort { byPoints, byVotes, byName }

/// ランキングデータと並び順の状態を管理する ChangeNotifier
class RankingNotifier extends ChangeNotifier {
  final ApiService _apiService;

  RankingNotifier(this._apiService);

  List<RankingEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  RankingSort _sort = RankingSort.byPoints;

  List<RankingEntry> get entries => _sortedEntries();
  bool get isLoading => _isLoading;
  String? get error => _error;
  RankingSort get sort => _sort;

  Future<void> load(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _apiService.fetchRanking(year);
    } catch (e) {
      _error = e.toString();
      _entries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSort(RankingSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  List<RankingEntry> _sortedEntries() {
    final list = List<RankingEntry>.from(_entries);
    switch (_sort) {
      case RankingSort.byPoints:
        list.sort((a, b) => b.pointTotal.compareTo(a.pointTotal));
      case RankingSort.byVotes:
        list.sort((a, b) => b.voteCount.compareTo(a.voteCount));
      case RankingSort.byName:
        list.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
    return list.asMap().entries.map((e) {
      return e.value.copyWith(rank: e.key + 1);
    }).toList();
  }
}
