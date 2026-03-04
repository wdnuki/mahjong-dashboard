import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hanchan_summary.dart';

class ApiService {
  static const String _summaryApiUrl = String.fromEnvironment(
    'SUMMARY_API_URL',
    defaultValue:
        'https://asia-northeast1-mahjong-dashboard-e72c9.cloudfunctions.net/mahjong-api',
  );

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HanchanSummary>> fetchHanchanSummary() async {
    final response = await _client
        .get(Uri.parse(_summaryApiUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => HanchanSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void dispose() => _client.close();
}
