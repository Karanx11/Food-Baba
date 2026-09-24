import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/loaders/burger_loader.dart';
import '../../shell/home_shell.dart';
import '../application/auth_providers.dart';
import 'login_page.dart';
import 'signup_page.dart';

/// Decides what the app shows based on the auth state: the shell when signed
/// in, the login screen when an account exists, or signup on first run.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: BurgerLoader(size: 72))),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not start.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (state) {
        if (state.signedIn) return const HomeShell();
        if (state.hasAccount) return const LoginPage();
        return const SignupPage();
      },
    );
  }
}
