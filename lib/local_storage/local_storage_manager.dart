import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum StorageKey { isLogin, userData, authenticationToken }

class SharedPrefManager {
  static final instance = SharedPrefManager();
  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  setData(StorageKey key, dynamic data) async {
    final SharedPreferences pref = await prefs;
    String strData = jsonEncode(data);
    pref.setString(key.toString(), strData);
  }

  fetchData(StorageKey key, {required Function callBack}) async {
    final SharedPreferences pref = await prefs;
    final decodedStr = pref.getString(key.toString());
    if (decodedStr is String) {
      final data = jsonDecode(decodedStr);
      callBack(data);
    } else {
      callBack(false);
    }
  }

  clearAllData() async {
    final SharedPreferences pref = await prefs;
    pref.remove(StorageKey.isLogin.toString());
    pref.remove(StorageKey.authenticationToken.toString());
    pref.remove(StorageKey.userData.toString());
  }
}
