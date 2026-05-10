import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  Future<String?> getLocalPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_local_photo');
  }

  Future<void> saveLocalPhoto(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_local_photo', path);
  }
}
