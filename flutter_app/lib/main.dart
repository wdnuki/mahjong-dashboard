import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const apiUrl = String.fromEnvironment('API_BASE_URL');
  if (apiUrl.isEmpty) {
    debugPrint(
      '[Main] WARNING: API_BASE_URL is not set. '
      'Pass --dart-define=API_BASE_URL=https://... when running or building.',
    );
  } else {
    debugPrint('[Main] API_BASE_URL: $apiUrl');
  }

  runApp(const KawaiCupApp());
}
