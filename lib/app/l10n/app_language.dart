/// The languages Food Guruji speaks. Hinglish is romanised Hindi mixed with
/// English — the way many people actually text in India.
enum AppLanguage {
  english('English'),
  hindi('हिन्दी'),
  hinglish('Hinglish');

  const AppLanguage(this.label);

  /// The name shown in the picker, always in its own script.
  final String label;
}
