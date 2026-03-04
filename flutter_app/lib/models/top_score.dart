class TopScore {
  final String kanriDate;
  final String nickName;
  final double point;

  const TopScore({
    required this.kanriDate,
    required this.nickName,
    required this.point,
  });

  factory TopScore.fromJson(Map<String, dynamic> json) => TopScore(
        kanriDate: json['KANRI_DATE'] as String? ?? '',
        nickName: json['NICK_NAME'] as String? ?? '',
        point: (json['POINT'] as num? ?? 0).toDouble(),
      );
}
