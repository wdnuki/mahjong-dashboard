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

  Future<List<HanchanSummary>> fetchHanchanSummary() async {
    final response = await _client
        .get(Uri.parse(_apiBaseUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => HanchanSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CumulativeScore>> fetchCumulativeScores() async {
    final url = '$_apiBaseUrl/kawaicup/cumulative';
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => CumulativeScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopScore>> fetchTopScores() async {
    final url = '$_apiBaseUrl/kawaicup/top-score';
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => TopScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> fetchLastImportedAt() async {
    final url = '$_apiBaseUrl/kawaicup/last-imported';
    final response = await _client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['LAST_IMPORTED_AT'] as String?;
  }

  void dispose() => _client.close();
}
