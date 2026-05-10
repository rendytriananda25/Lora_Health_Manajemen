class UserProfileEntity {
  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? localPhotoPath;
  final String height;
  final String weight;
  final String gender;
  final String age;

  UserProfileEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.localPhotoPath,
    required this.height,
    required this.weight,
    required this.gender,
    required this.age,
  });

  UserProfileEntity copyWith({
    String? fullName,
    String? email,
    String? photoUrl,
    String? localPhotoPath,
    String? height,
    String? weight,
    String? gender,
    String? age,
  }) {
    return UserProfileEntity(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      age: age ?? this.age,
    );
  }
}
