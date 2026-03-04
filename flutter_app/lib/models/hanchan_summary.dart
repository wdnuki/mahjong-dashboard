class HanchanSummary {
  final String kanriDate;
  final String summary;

  const HanchanSummary({required this.kanriDate, required this.summary});

  factory HanchanSummary.fromJson(Map<String, dynamic> json) => HanchanSummary(
        kanriDate: json['KANRI_DATE'] as String? ?? '',
        summary: json['SUMMARY'] as String? ?? '',
      );
}
