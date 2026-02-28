/// 半荘データ（BigQuery: mahjonganalyzer.MM.J_HANCHANS_D）
class HanchanEntry {
  final String hanchanId;
  final String lineUserId;
  final double soten;
  final double point;
  final double pointZone;
  final int rank;
  final String createdAt;

  const HanchanEntry({
    required this.hanchanId,
    required this.lineUserId,
    required this.soten,
    required this.point,
    required this.pointZone,
    required this.rank,
    required this.createdAt,
  });

  factory HanchanEntry.fromJson(Map<String, dynamic> json) => HanchanEntry(
        hanchanId: json['hanchan_id'] as String? ?? '',
        lineUserId: json['line_user_id'] as String? ?? '',
        soten: (json['soten'] as num? ?? 0).toDouble(),
        point: (json['point'] as num? ?? 0).toDouble(),
        pointZone: (json['point_zone'] as num? ?? 0).toDouble(),
        rank: (json['rank'] as num? ?? 0).toInt(),
        createdAt: json['created_at'] as String? ?? '',
      );
}
