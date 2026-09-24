import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

/// Resets a forgotten password using the security question. There is no email
/// server in this local build, so the question stands in for a reset link.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  static Route<void> route(String email) => MaterialPageRoute<void>(
    builder: (_) => ForgotPasswordPage(initialEmail: email),
  );

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _answer = TextEditingController();
  final _password = TextEditingController();
  String? _question;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _answer.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _lookUp() async {
    if (AuthValidators.email(_email.text) != null) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() => _busy = true);
    final question = await ref
        .read(authControllerProvider.notifier)
        .securityQuestionFor(_email.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (question == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No account found for this email.')),
        );
      return;
    }
    setState(() => _question = question);
  }

  Future<void> _reset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            email: _email.text,
            securityAnswer: _answer.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      // Reset also signs the user in; leave this screen so the gate shows
      // the app beneath.
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final askingQuestion = _question != null;
    return AuthScaffold(
      showBack: true,
      title: 'Reset password',
      subtitle: askingQuestion
          ? 'Answer your security question'
          : 'Find your account',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                enabled: !askingQuestion,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: AuthValidators.email,
              ),
              if (!askingQuestion) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _lookUp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(_busy ? 'Checking…' : 'Continue'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(_question!, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answer,
                  decoration: const InputDecoration(
                    labelText: 'Your answer',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => AuthValidators.required(v, 'your answer'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 6 characters',
                    border: OutlineInputBorder(),
                  ),
                  validator: AuthValidators.password,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _reset,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(_busy ? 'Saving…' : 'Reset password'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
