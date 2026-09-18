import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

/// Persists the logged-in user across app launches so returning users skip
/// straight to their dashboard (doc §4.6 "zero cold-start confusion").
class SessionStore {
  static const _kUser = 'session_user';

  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt/legacy entry → treat as signed out
    }
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
  }
}
