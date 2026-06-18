class RankData {
  final int id;
  final String name;
  final int minExp;
  final int maxExp;
  final String assetPath;

  const RankData({
    required this.id,
    required this.name,
    required this.minExp,
    required this.maxExp,
    required this.assetPath,
  });
}

class RankSystem {
  static const List<RankData> ranks = [
    RankData(
      id: 0,
      name: "No Rank",
      minExp: 0,
      maxExp: 4999,
      assetPath: "assets/badges/rank_0.png",
    ),
    RankData(
      id: 1,
      name: "Lemah",
      minExp: 5000,
      maxExp: 13999,
      assetPath: "assets/badges/lemah.png",
    ),
    RankData(
      id: 2,
      name: "Lumayan",
      minExp: 14000,
      maxExp: 24999,
      assetPath: "assets/badges/lumayan.png",
    ),
    RankData(
      id: 3,
      name: "Kuat",
      minExp: 25000,
      maxExp: 36999,
      assetPath: "assets/badges/kuat.png",
    ),
    RankData(
      id: 4,
      name: "Sangat Kuat",
      minExp: 37000,
      maxExp: 44999,
      assetPath: "assets/badges/sangatk.png",
    ),
    RankData(
      id: 5,
      name: "Atlit",
      minExp: 45000,
      maxExp: 64999,
      assetPath: "assets/badges/atlit.png",
    ),
    RankData(
      id: 6,
      name: "Dewa",
      minExp: 65000,
      maxExp: 999999999,
      assetPath: "assets/badges/dewa.png",
    ),
  ];

  static RankData getRank(int exp) {
    return ranks.lastWhere((r) => exp >= r.minExp, orElse: () => ranks[0]);
  }

  static int getNextRankExp(int exp) {
    final current = getRank(exp);
    if (current.id >= 6) return current.minExp;
    final next = ranks[current.id + 1];
    return next.minExp;
  }

  static double getProgressValue(int exp) {
    final current = getRank(exp);
    if (current.id >= 6) return 1.0;

    final next = ranks[current.id + 1];
    int range = next.minExp - current.minExp;
    int currentProgress = exp - current.minExp;

    return (currentProgress / range).clamp(0.0, 1.0);
  }
}
