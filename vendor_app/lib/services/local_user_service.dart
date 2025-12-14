import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserService {
  static const _keyId = 'vendor_user_id';
  static const _keyName = 'vendor_username';

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyId);
    if (id == null) {
      id = _generateId();
      await prefs.setString(_keyId, id);
    }
    return id;
  }

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    var name = prefs.getString(_keyName);
    if (name == null) {
      name = 'Vendor-${_randomString(4)}';
      await prefs.setString(_keyName, name);
    }
    return name;
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_randomString(6)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
