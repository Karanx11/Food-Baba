import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/user_profile.dart';

/// Persistence boundary for the user's profile.
abstract interface class ProfileRepository {
  Future<UserProfile?> load();
  Future<void> save(UserProfile profile);
  Future<void> clear();
}

/// Keeps the profile in memory only. Used in tests.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([this._profile]);

  UserProfile? _profile;

  @override
  Future<UserProfile?> load() async => _profile;

  @override
  Future<void> save(UserProfile profile) async => _profile = profile;

  @override
  Future<void> clear() async => _profile = null;
}

/// Stores the profile as JSON in shared preferences (local storage on web).
class SharedPrefsProfileRepository implements ProfileRepository {
  SharedPrefsProfileRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String key = 'profile.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<UserProfile?> load() async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      // Unreadable data is treated as "no profile" rather than crashing.
      return null;
    }
  }

  @override
  Future<void> save(UserProfile profile) =>
      _prefs.setString(key, jsonEncode(profile.toJson()));

  @override
  Future<void> clear() => _prefs.remove(key);
}
