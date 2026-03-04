import 'package:flutter/material.dart';
import '../screens/kawaicup/kawaicup_dashboard_screen.dart';

class KawaiCupApp extends StatelessWidget {
  const KawaiCupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カワイカップ特設ダッシュボード',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
        ),
      ),
      home: const KawaiCupDashboardScreen(),
    );
  }
}
