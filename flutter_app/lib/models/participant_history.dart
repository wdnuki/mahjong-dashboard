/// 参加者の年度別履歴データ (type=history)
class ParticipantHistory {
  final int eventYear;
  final String displayName;
  final int voteCount;
  final int pointTotal;

  const ParticipantHistory({
    required this.eventYear,
    required this.displayName,
    required this.voteCount,
    required this.pointTotal,
  });

  factory ParticipantHistory.fromJson(Map<String, dynamic> json) {
    return ParticipantHistory(
      eventYear: (json['event_year'] as num).toInt(),
      displayName: json['display_name'] as String? ?? '',
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
      pointTotal: (json['point_total'] as num? ?? 0).toInt(),
    );
  }
}
