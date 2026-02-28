class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.participantId,
    required this.displayName,
    required this.voteCount,
    required this.pointTotal,
  });

  final int rank;
  final String participantId;
  final String displayName;
  final int voteCount;
  final int pointTotal;

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      rank: (json['rank'] as num).toInt(),
      participantId: json['participant_id'] as String,
      displayName: json['display_name'] as String,
      voteCount: (json['vote_count'] as num).toInt(),
      pointTotal: (json['point_total'] as num).toInt(),
    );
  }

  RankingEntry copyWith({int? rank}) {
    return RankingEntry(
      rank: rank ?? this.rank,
      participantId: participantId,
      displayName: displayName,
      voteCount: voteCount,
      pointTotal: pointTotal,
    );
  }
}
