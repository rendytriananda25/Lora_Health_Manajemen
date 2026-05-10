/// Entity profil user — data inti yang dibutuhkan dashboard.
class UserProfileEntity {
  final String name;
  final String? localPhotoPath;
  final String fitnessLevel;  // NEVER, BEGINNER, INTERMEDIATE, EXPERT
  final String fitnessGoal;   // WEIGHT_LOSS, MUSCLE_GAIN, KEEP_FIT
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
