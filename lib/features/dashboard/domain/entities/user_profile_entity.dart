class UserProfileEntity {
  final String name;
  final String? localPhotoPath;
  final String fitnessLevel;
  final String fitnessGoal;
  final List<String> favoriteSports;
  final int exp;

  const UserProfileEntity({
    required this.name,
    this.localPhotoPath,
    required this.fitnessLevel,
    required this.fitnessGoal,
    required this.favoriteSports,
    required this.exp,
  });

  factory UserProfileEntity.empty() => const UserProfileEntity(
    name: 'User',
    fitnessLevel: 'NEVER',
    fitnessGoal: 'KEEP_FIT',
    favoriteSports: [],
    exp: 0,
  );
}
