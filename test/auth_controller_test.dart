import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/auth/application/auth_providers.dart';
import 'package:food_guruji/features/auth/data/auth_repository.dart';
import 'package:food_guruji/features/auth/domain/account.dart';
import 'package:food_guruji/features/log/application/log_providers.dart';
import 'package:food_guruji/features/profile/application/profile_providers.dart';
import 'package:food_guruji/features/profile/data/profile_repository.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

/// A container wired with in-memory stores so the controller can be exercised
/// without the platform.
ProviderContainer _container(AuthRepository repo) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      profileRepositoryProvider.overrideWithValue(InMemoryProfileRepository()),
      databaseConfigProvider.overrideWithValue(memoryDatabase()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AuthState> _read(ProviderContainer c) =>
    c.read(authControllerProvider.future);

void main() {
  group('AuthController', () {
    test('starts with no account on a fresh device', () async {
      final c = _container(InMemoryAuthRepository());
      final state = await _read(c);
      expect(state.hasAccount, isFalse);
      expect(state.signedIn, isFalse);
    });

    test('signUp creates the account and signs in', () async {
      final repo = InMemoryAuthRepository();
      final c = _container(repo);
      await _read(c);

      await c
          .read(authControllerProvider.notifier)
          .signUp(
            email: 'Karan@Example.com',
            password: 'hunter2',
            securityQuestion: 'What is your favourite food?',
            securityAnswer: 'Biryani',
          );

      final state = c.read(authControllerProvider).requireValue;
      expect(state.hasAccount, isTrue);
      expect(state.signedIn, isTrue);
      // Email is normalised for storage.
      expect(state.email, 'karan@example.com');
      expect(repo.account?.passwordHash, isNot('hunter2'));
    });

    test('logIn rejects a wrong password and accepts the right one', () async {
      final repo = InMemoryAuthRepository(
        account: Account.create(
          email: 'karan@example.com',
          password: 'hunter2',
          securityQuestion: 'q',
          securityAnswer: 'a',
        ),
      );
      final c = _container(repo);
      await _read(c);
      final notifier = c.read(authControllerProvider.notifier);

      await expectLater(
        notifier.logIn(email: 'karan@example.com', password: 'wrong'),
        throwsA(isA<AuthException>()),
      );
      expect(c.read(authControllerProvider).requireValue.signedIn, isFalse);

      await notifier.logIn(email: 'KARAN@example.com', password: 'hunter2');
      expect(c.read(authControllerProvider).requireValue.signedIn, isTrue);
    });

    test('logOut clears the session but keeps the account', () async {
      final repo = InMemoryAuthRepository(
        account: Account.create(
          email: 'karan@example.com',
          password: 'hunter2',
          securityQuestion: 'q',
          securityAnswer: 'a',
        ),
        signedIn: true,
      );
      final c = _container(repo);
      await _read(c);

      await c.read(authControllerProvider.notifier).logOut();

      final state = c.read(authControllerProvider).requireValue;
      expect(state.signedIn, isFalse);
      expect(state.hasAccount, isTrue);
    });

    test('securityQuestionFor returns the stored question', () async {
      final repo = InMemoryAuthRepository(
        account: Account.create(
          email: 'karan@example.com',
          password: 'hunter2',
          securityQuestion: 'What is your favourite food?',
          securityAnswer: 'Biryani',
        ),
      );
      final c = _container(repo);
      await _read(c);
      final notifier = c.read(authControllerProvider.notifier);

      expect(
        await notifier.securityQuestionFor('karan@example.com'),
        'What is your favourite food?',
      );
      expect(await notifier.securityQuestionFor('other@example.com'), isNull);
    });

    test('resetPassword needs the right answer and then logs in', () async {
      final repo = InMemoryAuthRepository(
        account: Account.create(
          email: 'karan@example.com',
          password: 'old-pass',
          securityQuestion: 'What is your favourite food?',
          securityAnswer: 'Biryani',
        ),
      );
      final c = _container(repo);
      await _read(c);
      final notifier = c.read(authControllerProvider.notifier);

      await expectLater(
        notifier.resetPassword(
          email: 'karan@example.com',
          securityAnswer: 'Pizza',
          newPassword: 'new-pass',
        ),
        throwsA(isA<AuthException>()),
      );

      // Answer match is case- and space-insensitive.
      await notifier.resetPassword(
        email: 'karan@example.com',
        securityAnswer: '  biryani ',
        newPassword: 'new-pass',
      );

      expect(c.read(authControllerProvider).requireValue.signedIn, isTrue);
      expect(repo.account!.passwordMatches('new-pass'), isTrue);
      expect(repo.account!.passwordMatches('old-pass'), isFalse);
    });

    test('deleteAccount wipes the account and personal data', () async {
      final repo = InMemoryAuthRepository(
        account: Account.create(
          email: 'karan@example.com',
          password: 'hunter2',
          securityQuestion: 'q',
          securityAnswer: 'a',
        ),
        signedIn: true,
      );
      final c = _container(repo);
      // Save a profile so we can prove it is cleared.
      await c.read(profileRepositoryProvider).save(asha);
      await _read(c);

      await c.read(authControllerProvider.notifier).deleteAccount();

      final state = c.read(authControllerProvider).requireValue;
      expect(state.hasAccount, isFalse);
      expect(state.signedIn, isFalse);
      expect(repo.account, isNull);
      expect(await c.read(profileRepositoryProvider).load(), isNull);
    });
  });
}
