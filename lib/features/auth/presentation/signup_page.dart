import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/language_store.dart';
import '../../../core/widgets/surfaces.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

/// Preset security questions, used to reset a forgotten password since there
/// is no email server in this local build.
const List<String> kSecurityQuestions = [
  'What city were you born in?',
  'What was the name of your first school?',
  'What is your favourite food?',
  'What was your childhood nickname?',
];

/// Creates the local account on first run.
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _answer = TextEditingController();
  String _question = kSecurityQuestions.first;
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _email.text,
            password: _password.text,
            securityQuestion: _question,
            securityAnswer: _answer.text,
          );
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
    final s = ref.watch(stringsProvider);
    return AuthScaffold(
      title: s.createAccountTitle,
      subtitle: s.dataStaysOnDevice,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: s.emailLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: AuthValidators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: s.passwordLabel,
                  helperText: s.passwordHelper,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show' : 'Hide',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: AuthValidators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: s.confirmPassword,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == _password.text ? null : s.passwordsDontMatch,
              ),
              const SizedBox(height: 18),
              Text(
                s.securityQuestion,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                s.securityQuestionHint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppPalette.of(context).muted),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _question,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final q in kSecurityQuestions)
                    DropdownMenuItem(value: q, child: Text(q)),
                ],
                onChanged: (v) => setState(() => _question = v ?? _question),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _answer,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: s.yourAnswer,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => AuthValidators.required(v, 'an answer'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(_busy ? s.creating : s.createAccount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
