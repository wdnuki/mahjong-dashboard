class PlayerScore {
  final int dayOfMonth; // 1–31
  final double cumulative;

  const PlayerScore({required this.dayOfMonth, required this.cumulative});
}

class Player {
  final String name;
  final List<PlayerScore> scores; // dayOfMonth 昇順

  const Player({required this.name, required this.scores});

  double get finalScore => scores.isEmpty ? 0 : scores.last.cumulative;
}
