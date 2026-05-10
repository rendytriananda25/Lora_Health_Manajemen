import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/update_user_name.dart';
import '../../domain/usecases/save_local_photo.dart';
import '../../domain/usecases/logout_user.dart';

class SettingsProvider extends ChangeNotifier {
  final GetUserProfile _getUserProfile;
  final UpdateUserName _updateUserName;
  final SaveLocalPhoto _saveLocalPhoto;
  final LogoutUser _logoutUser;

  UserProfileEntity? _profile;
  bool _isLoading = false;

  SettingsProvider({
    required GetUserProfile getUserProfile,
    required UpdateUserName updateUserName,
    required SaveLocalPhoto saveLocalPhoto,
    required LogoutUser logoutUser,
  })  : _getUserProfile = getUserProfile,
        _updateUserName = updateUserName,
        _saveLocalPhoto = saveLocalPhoto,
        _logoutUser = logoutUser;

  UserProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> fetchProfileData() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getUserProfile();
    result.fold(
      (failure) => debugPrint("Error fetch profile: ${failure.message}"),
      (data) {
        _profile = data;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> pickAndSaveImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        
        final saveResult = await _saveLocalPhoto(path);
        saveResult.fold(
          (failure) => debugPrint("Error save photo: ${failure.message}"),
          (_) {
            if (_profile != null) {
              _profile = _profile!.copyWith(localPhotoPath: path);
              notifyListeners();
            }
          },
        );
      }
    } catch (e) {
      debugPrint("Error Pick Image: $e");
    }
  }

  Future<void> updateName(String newName) async {
    if (newName.trim().isEmpty) return;
    
    final result = await _updateUserName(newName);
    result.fold(
      (failure) => debugPrint("Error update name: ${failure.message}"),
      (_) {
        if (_profile != null) {
          _profile = _profile!.copyWith(fullName: newName);
          notifyListeners();
        }
      },
    );
  }

  Future<void> logout() async {
    await _logoutUser();
  }
}
