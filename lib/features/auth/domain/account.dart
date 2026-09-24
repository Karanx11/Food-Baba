import 'password_hash.dart';

/// A local user account. The password and the security answer are stored only
/// as salted PBKDF2 hashes, never in plain text.
class Account {
  const Account({
    required this.email,
    required this.passwordHash,
    required this.securityQuestion,
    required this.securityAnswerHash,
  });

  final String email;
  final String passwordHash;
  final String securityQuestion;
  final String securityAnswerHash;

  /// Normalises an email for storage and comparison.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// Normalises a security answer so "Delhi" and " delhi " match.
  static String normalizeAnswer(String answer) => answer.trim().toLowerCase();

  /// Builds an account, hashing the password and answer.
  factory Account.create({
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) => Account(
    email: normalizeEmail(email),
    passwordHash: PasswordHash.hash(password),
    securityQuestion: securityQuestion.trim(),
    securityAnswerHash: PasswordHash.hash(normalizeAnswer(securityAnswer)),
  );

  bool passwordMatches(String password) =>
      PasswordHash.verify(password, passwordHash);

  bool answerMatches(String answer) =>
      PasswordHash.verify(normalizeAnswer(answer), securityAnswerHash);

  Account withPassword(String password) => Account(
    email: email,
    passwordHash: PasswordHash.hash(password),
    securityQuestion: securityQuestion,
    securityAnswerHash: securityAnswerHash,
  );

  Map<String, Object?> toJson() => {
    'email': email,
    'passwordHash': passwordHash,
    'securityQuestion': securityQuestion,
    'securityAnswerHash': securityAnswerHash,
  };

  factory Account.fromJson(Map<String, Object?> json) => Account(
    email: json['email'] as String,
    passwordHash: json['passwordHash'] as String,
    securityQuestion: json['securityQuestion'] as String? ?? '',
    securityAnswerHash: json['securityAnswerHash'] as String? ?? '',
  );
}
