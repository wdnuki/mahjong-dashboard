import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ranking_entry.dart';
import '../models/participant.dart';
import '../models/participant_history.dart';
import '../models/relation.dart';
import '../models/hanchan_entry.dart';

/// Cloud Functions API との通信を担当するサービス
///
/// API_BASE_URL は --dart-define で注入する:
///   flutter build web --dart-define=API_BASE_URL=https://mahjong-dashboard-e72c9.web.app/api
class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mahjong-dashboard-e72c9.web.app/api',
  );

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> _get(
    String type, [
    int? year,
    Map<String, String> extra = const {},
  ]) async {
    final params = <String, String>{'type': type};
    if (year != null) params['year'] = year.toString();
    params.addAll(extra);
    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    final response = await _client.get(uri, headers: {
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 'ok') {
      throw Exception('API error: ${body['message']}');
    }

    return (body['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<RankingEntry>> fetchRanking(int year) async {
    final data = await _get('ranking', year);
    return data.map(RankingEntry.fromJson).toList();
  }

  Future<List<Participant>> fetchParticipants(int year) async {
    final data = await _get('participants', year);
    return data.map(Participant.fromJson).toList();
  }

  Future<List<Relation>> fetchRelations(int year) async {
    final data = await _get('relations', year);
    return data.map(Relation.fromJson).toList();
  }

  Future<List<HanchanEntry>> fetchHanchans(int year, int month) async {
    final data = await _get('hanchans', year, {'month': month.toString()});
    return data.map(HanchanEntry.fromJson).toList();
  }

  Future<List<ParticipantHistory>> fetchParticipantHistory(
    String participantId,
  ) async {
    final data = await _get('history', null, {'id': participantId});
    return data.map(ParticipantHistory.fromJson).toList();
  }

  void dispose() => _client.close();
}
