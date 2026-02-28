import 'package:flutter/material.dart';

class YearSelector extends StatelessWidget {
  const YearSelector({
    super.key,
    required this.selectedYear,
    required this.availableYears,
    required this.onChanged,
  });

  final int selectedYear;
  final List<int> availableYears;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: selectedYear,
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      iconEnabledColor: Colors.white,
      underline: const SizedBox.shrink(),
      items: availableYears.map((year) {
        return DropdownMenuItem(
          value: year,
          child: Text('$year年'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
