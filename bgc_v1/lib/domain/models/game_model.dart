class Game {
  final String id;
  final String name;
  final bool isStandard;
  final List<int> validPlayerCounts;

  const Game({
    required this.id,
    required this.name,
    this.isStandard = false,
    required this.validPlayerCounts,
  });
}
