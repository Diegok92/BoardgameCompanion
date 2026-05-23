class Game {
  final String id;
  final String name;
  final bool isStandard;
  final List<int> validPlayerCounts;
  final String? iconPath;

  const Game({
    required this.id,
    required this.name,
    this.isStandard = false,
    this.validPlayerCounts = const [],
    this.iconPath,
  });
}
