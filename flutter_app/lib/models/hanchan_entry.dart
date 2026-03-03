/// 半荘データ（BigQuery: mahjonganalyzer.MM.V_HANCHANS）
class HanchanEntry {
  final String hanchanId;
  final String kanriDate;
  final String lineUserId;
  final String nickName;
  final String lineUserName;
  final double soten;
  final double point;
  final int rank;
  final String deadFlag;
  final int killCnt;

  const HanchanEntry({
    required this.hanchanId,
    required this.kanriDate,
    required this.lineUserId,
    required this.nickName,
    required this.lineUserName,
    required this.soten,
    required this.point,
    required this.rank,
    required this.deadFlag,
    required this.killCnt,
  });

  String get displayName => nickName.isNotEmpty ? nickName : lineUserName;

  factory HanchanEntry.fromJson(Map<String, dynamic> json) => HanchanEntry(
        hanchanId: json['hanchan_id'] as String? ?? '',
        kanriDate: json['kanri_date'] as String? ?? '',
        lineUserId: json['line_user_id'] as String? ?? '',
        nickName: json['nick_name'] as String? ?? '',
        lineUserName: json['line_user_name'] as String? ?? '',
        soten: (json['soten'] as num? ?? 0).toDouble(),
        point: (json['point'] as num? ?? 0).toDouble(),
        rank: (json['rank'] as num? ?? 0).toInt(),
        deadFlag: json['dead_flag'] as String? ?? '',
        killCnt: (json['kill_cnt'] as num? ?? 0).toInt(),
      );
}
