class Participant {
  const Participant({
    required this.participantId,
    required this.displayName,
  });

  final String participantId;
  final String displayName;

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      participantId: json['participant_id'] as String,
      displayName: json['display_name'] as String,
    );
  }
}
