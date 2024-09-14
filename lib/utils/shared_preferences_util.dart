import 'package:shared_preferences/shared_preferences.dart';

class Shared {
  static const String loginSharedPreferenceKey = "LOGGEDINKEY";

  // Save login state
  static Future<bool> saveLoginSharedPreference(bool isLogin) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(loginSharedPreferenceKey, isLogin);
  }

  // Get login state
  static Future<bool> getUserSharedPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(loginSharedPreferenceKey) ?? false;
  }
}
