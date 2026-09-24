import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/auth/data/auth_repository.dart';
import 'package:food_baba/features/auth/domain/account.dart';
import 'package:food_baba/features/auth/presentation/auth_gate.dart';
import 'package:food_baba/features/auth/presentation/login_page.dart';
import 'package:food_baba/features/auth/presentation/signup_page.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

void main() {
  // A tall surface so the shell's lazy lists lay out without overflow.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // Bounded pumps: the loaders animate forever, so pumpAndSettle would hang.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Account existingAccount() => Account.create(
    email: 'karan@example.com',
    password: 'hunter2',
    securityQuestion: 'What is your favourite food?',
    securityAnswer: 'Biryani',
  );

  testWidgets(
    'first run shows signup, and creating an account enters the app',
    (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(
        testApp(
          home: const AuthGate(),
          authRepository: InMemoryAuthRepository(),
        ),
      );
      await settle(tester);

      expect(find.byType(SignupPage), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'karan@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'hunter2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'hunter2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Your answer'),
        'Biryani',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await settle(tester);

      expect(find.byType(HomeShell), findsOneWidget);
    },
  );

  testWidgets('an existing account starts at login and signs in', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      testApp(
        home: const AuthGate(),
        authRepository: InMemoryAuthRepository(account: existingAccount()),
      ),
    );
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    // Email is prefilled; just enter the password.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'hunter2',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle(tester);

    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('a wrong password keeps the user on the login screen', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      testApp(
        home: const AuthGate(),
        authRepository: InMemoryAuthRepository(account: existingAccount()),
      ),
    );
    await settle(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong-pass',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('forgot password resets via the security question', (
    tester,
  ) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      testApp(
        home: const AuthGate(),
        authRepository: InMemoryAuthRepository(account: existingAccount()),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Forgot password?'));
    await settle(tester);

    // Email is carried over; look up the account.
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
    expect(find.text('What is your favourite food?'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Your answer'),
      'biryani',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'New password'),
      'brand-new',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reset password'));
    await settle(tester);

    // Reset signs the user in, so the gate shows the shell.
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('logging out returns to the login screen', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      testApp(
        home: const AuthGate(),
        authRepository: InMemoryAuthRepository(
          account: existingAccount(),
          signedIn: true,
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(HomeShell), findsOneWidget);

    // Go to the Profile tab and log out.
    await tester.tap(find.byKey(const Key('nav-3')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('log-out')));
    await settle(tester);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('deleting the account returns to signup', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(
      testApp(
        home: const AuthGate(),
        authRepository: InMemoryAuthRepository(
          account: existingAccount(),
          signedIn: true,
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.byKey(const Key('nav-3')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('delete-account')));
    await settle(tester);
    // Confirm in the dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(find.byType(SignupPage), findsOneWidget);
  });
}
