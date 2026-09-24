import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/account.dart';

/// Stores the local account and whether a session is open.
abstract interface class AuthRepository {
  Future<Account?> loadAccount();
  Future<void> saveAccount(Account account);
  Future<void> deleteAccount();

  Future<bool> isSignedIn();
  Future<void> setSignedIn(bool value);
}

/// Persists the account as JSON in shared preferences (local storage on web).
class SharedPrefsAuthRepository implements AuthRepository {
  SharedPrefsAuthRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String accountKey = 'auth.account.v1';
  static const String sessionKey = 'auth.session.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<Account?> loadAccount() async {
    final raw = await _prefs.getString(accountKey);
    if (raw == null) return null;
    try {
      return Account.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveAccount(Account account) =>
      _prefs.setString(accountKey, jsonEncode(account.toJson()));

  @override
  Future<void> deleteAccount() async {
    await _prefs.remove(accountKey);
    await _prefs.remove(sessionKey);
  }

  @override
  Future<bool> isSignedIn() async =>
      (await _prefs.getBool(sessionKey)) ?? false;

  @override
  Future<void> setSignedIn(bool value) => _prefs.setBool(sessionKey, value);
}

/// Keeps the account and session in memory only. Used in tests.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({this.account, this.signedIn = false});

  Account? account;
  bool signedIn;

  @override
  Future<Account?> loadAccount() async => account;

  @override
  Future<void> saveAccount(Account account) async => this.account = account;

  @override
  Future<void> deleteAccount() async {
    account = null;
    signedIn = false;
  }

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<void> setSignedIn(bool value) async => signedIn = value;
}
