import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_providers.dart';
import '../../log/application/log_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../data/auth_repository.dart';
import '../domain/account.dart';

/// A readable failure the auth screens can show.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The current auth situation the app gate reacts to.
class AuthState {
  const AuthState({
    required this.hasAccount,
    required this.signedIn,
    this.email,
  });

  static const AuthState none = AuthState(hasAccount: false, signedIn: false);

  /// Whether an account exists on this device.
  final bool hasAccount;

  /// Whether a session is open.
  final bool signedIn;

  /// The account email, when one exists.
  final String? email;
}

/// Where the account is stored. Tests override this with an in-memory store.
final authRepositoryProvider = Provider<AuthRepository>(
  (_) => SharedPrefsAuthRepository(),
);

/// Loads and manages the local account and session.
class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() => _snapshot();

  Future<AuthState> _snapshot() async {
    final account = await _repo.loadAccount();
    if (account == null) return AuthState.none;
    return AuthState(
      hasAccount: true,
      signedIn: await _repo.isSignedIn(),
      email: account.email,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final existing = await _repo.loadAccount();
    final normalized = Account.normalizeEmail(email);
    if (existing != null && existing.email == normalized) {
      throw const AuthException('An account with this email already exists.');
    }
    final account = Account.create(
      email: email,
      password: password,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
    await _repo.saveAccount(account);
    await _repo.setSignedIn(true);
    state = AsyncData(await _snapshot());
  }

  Future<void> logIn({required String email, required String password}) async {
    final account = await _repo.loadAccount();
    if (account == null ||
        account.email != Account.normalizeEmail(email) ||
        !account.passwordMatches(password)) {
      throw const AuthException('Wrong email or password.');
    }
    await _repo.setSignedIn(true);
    state = AsyncData(await _snapshot());
  }

  Future<void> logOut() async {
    await _repo.setSignedIn(false);
    state = AsyncData(await _snapshot());
  }

  /// The security question set at signup, for the reset screen.
  Future<String?> securityQuestionFor(String email) async {
    final account = await _repo.loadAccount();
    if (account == null || account.email != Account.normalizeEmail(email)) {
      return null;
    }
    return account.securityQuestion;
  }

  Future<void> resetPassword({
    required String email,
    required String securityAnswer,
    required String newPassword,
  }) async {
    final account = await _repo.loadAccount();
    if (account == null || account.email != Account.normalizeEmail(email)) {
      throw const AuthException('No account found for this email.');
    }
    if (!account.answerMatches(securityAnswer)) {
      throw const AuthException('That answer does not match.');
    }
    await _repo.saveAccount(account.withPassword(newPassword));
    await _repo.setSignedIn(true);
    state = AsyncData(await _snapshot());
  }

  /// Removes the account and erases all personal data on the device.
  Future<void> deleteAccount() async {
    await ref.read(profileRepositoryProvider).clear();
    await ref.read(foodLogRepositoryProvider).clear();
    await ref.read(weightRepositoryProvider).clear();
    await _repo.deleteAccount();
    // Reset the caches that held the wiped data.
    ref.invalidate(profileProvider);
    state = AsyncData(await _snapshot());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
