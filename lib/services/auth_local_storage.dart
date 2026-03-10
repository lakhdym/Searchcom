import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class AuthLocalStorage {
  AuthLocalStorage._();
  static final AuthLocalStorage instance = AuthLocalStorage._();

  static const _kUserKey = 'auth_user';
  static const _kLoggedIn = 'auth_logged_in';
  static const _kToken = 'auth_token';

  Future<void> saveSession(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kToken, token);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  @deprecated
  Future<void> saveUser(UserModel user) async {
    // Compat: sauvegarde sans token
    await saveSession(user, '');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kToken);
  }
}
