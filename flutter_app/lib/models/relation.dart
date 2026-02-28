class Relation {
  const Relation({
    required this.voterId,
    required this.targetId,
    required this.voteCount,
    required this.pointSum,
  });

  final String voterId;
  final String targetId;
  final int voteCount;
  final int pointSum;

  factory Relation.fromJson(Map<String, dynamic> json) {
    return Relation(
      voterId: json['voter_id'] as String,
      targetId: json['target_id'] as String,
      voteCount: (json['vote_count'] as num).toInt(),
      pointSum: (json['point_sum'] as num).toInt(),
    );
  }
}
