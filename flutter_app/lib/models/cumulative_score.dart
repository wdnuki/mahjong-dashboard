class CumulativeScore {
  final String kanriDate;
  final String nickName;
  final double cumPoint;

  const CumulativeScore({
    required this.kanriDate,
    required this.nickName,
    required this.cumPoint,
  });

  factory CumulativeScore.fromJson(Map<String, dynamic> json) =>
      CumulativeScore(
        kanriDate: json['KANRI_DATE'] as String? ?? '',
        nickName: json['NICK_NAME'] as String? ?? '',
        cumPoint: (json['CUM_POINT'] as num? ?? 0).toDouble(),
      );
}
