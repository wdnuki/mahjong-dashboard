import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hanchan_summary.dart';
import '../models/cumulative_score.dart';
import '../models/top_score.dart';

class ApiService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'MAHJONG_API_BASE_URL',
    defaultValue:
        'https://asia-northeast1-mahjong-dashboard-e72c9.cloudfunctions.net/mahjong-api',
  );

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, String visitorName) {
    return Uri.parse('$_apiBaseUrl$path')
        .replace(queryParameters: {'visitor': visitorName});
  }

  Future<List<HanchanSummary>> fetchHanchanSummary(String visitorName) async {
    final response = await _client
        .get(_uri('', visitorName))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => HanchanSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CumulativeScore>> fetchCumulativeScores(String visitorName) async {
    final response = await _client
        .get(_uri('/kawaicup/cumulative', visitorName))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CumulativeScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopScore>> fetchTopScores(String visitorName) async {
    final response = await _client
        .get(_uri('/kawaicup/top-score', visitorName))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => TopScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> fetchLastImportedAt(String visitorName) async {
    final response = await _client
        .get(_uri('/kawaicup/last-imported', visitorName))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['LAST_IMPORTED_AT'] as String?;
  }

  void dispose() => _client.close();
}
