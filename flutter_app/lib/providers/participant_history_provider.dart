import 'package:flutter/foundation.dart';
import '../models/participant_history.dart';
import '../models/relation.dart';
import '../services/api_service.dart';

/// 個人詳細ページのデータ（年度別推移 + 当年度の投票者）を管理する ChangeNotifier
class ParticipantHistoryNotifier extends ChangeNotifier {
  final ApiService _apiService;

  ParticipantHistoryNotifier(this._apiService);

  List<ParticipantHistory> _history = [];
  List<Relation> _voters = []; // 当該参加者への投票者リスト（selectedYear 分）
  bool _isLoading = false;
  String? _error;

  List<ParticipantHistory> get history => _history;
  List<Relation> get voters => _voters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(String participantId, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.fetchParticipantHistory(participantId),
        _apiService.fetchRelations(year),
      ]);

      _history = results[0] as List<ParticipantHistory>;

      // 当該参加者への投票のみに絞り込み、ポイント降順
      _voters = (results[1] as List<Relation>)
          .where((r) => r.targetId == participantId)
          .toList()
        ..sort((a, b) => b.pointSum.compareTo(a.pointSum));
    } catch (e) {
      _error = e.toString();
      _history = [];
      _voters = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
