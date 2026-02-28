import 'package:flutter/foundation.dart';

/// 選択中の年を管理する ChangeNotifier
class YearNotifier extends ChangeNotifier {
  int _selectedYear = DateTime.now().year;

  int get selectedYear => _selectedYear;

  void setYear(int year) {
    if (year == _selectedYear) return;
    _selectedYear = year;
    notifyListeners();
  }

  /// 選択可能な年のリスト (2024〜現在年、新しい順)
  List<int> get availableYears {
    final current = DateTime.now().year;
    return List.generate(current - 2023, (i) => current - i);
  }
}
