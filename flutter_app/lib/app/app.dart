import 'package:flutter/material.dart';
import '../screens/hanchan/hanchan_summary_screen.dart';

class KawaiCupApp extends StatelessWidget {
  const KawaiCupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kawai Cup Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E8C),
        ),
        useMaterial3: true,
      ),
      home: const HanchanSummaryScreen(),
    );
  }
}
