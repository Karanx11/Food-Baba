import 'app_language.dart';

/// User-facing text, one getter per string. Each language provides its own
/// implementation. Look strings up with `ref.watch(stringsProvider)`.
///
/// The security questions and form-validator messages are intentionally left in
/// English elsewhere: the question text is stored with the account, so it must
/// stay stable across a language switch.
abstract class AppStrings {
  const AppStrings();

  static AppStrings of(AppLanguage language) => switch (language) {
    AppLanguage.english => const EnStrings(),
    AppLanguage.hindi => const HiStrings(),
    AppLanguage.hinglish => const HinglishStrings(),
  };

  // Splash + common
  String get tagline;
  String get languageLabel;
  String get appearanceLabel;
  String get themeLight;
  String get themeDark;
  String get themeSystem;

  // Bottom navigation tooltips
  String get navHome;
  String get navLog;
  String get navSnap;
  String get navProgress;
  String get navProfile;

  // Login
  String get welcomeBack;
  String get signInSubtitle;
  String get emailLabel;
  String get passwordLabel;
  String get forgotPassword;
  String get logIn;
  String get signingIn;
  String get enterPassword;

  // Signup
  String get createAccountTitle;
  String get dataStaysOnDevice;
  String get passwordHelper;
  String get confirmPassword;
  String get passwordsDontMatch;
  String get securityQuestion;
  String get securityQuestionHint;
  String get yourAnswer;
  String get createAccount;
  String get creating;

  // Forgot password
  String get resetTitle;
  String get findYourAccount;
  String get answerYourQuestion;
  String get continueLabel;
  String get checking;
  String get newPassword;
  String get resetPasswordButton;
  String get saving;
  String get noAccountForEmail;
  String get wrongCredentials;

  // Profile
  String get yourProfile;
  String get profileNamePlaceholder;
  String get setUpProfile;
  String get setUpProfileHint;
  String get getStarted;
  String get editProfile;
  String get account;
  String get logOut;
  String get deleteAccount;
  String get deleteConfirmTitle;
  String get deleteConfirmBody;
  String get cancel;
  String get delete;
  String get couldNotLoadProfile;
}

class EnStrings extends AppStrings {
  const EnStrings();

  @override
  String get tagline => 'Snap. Track. Thrive.';
  @override
  String get languageLabel => 'Language';
  @override
  String get appearanceLabel => 'Appearance';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System';

  @override
  String get navHome => 'Home';
  @override
  String get navLog => 'Food log';
  @override
  String get navSnap => 'Snap food';
  @override
  String get navProgress => 'Progress';
  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeBack => 'Welcome back';
  @override
  String get signInSubtitle => 'Sign in to Food Guruji';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Password';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get logIn => 'Log in';
  @override
  String get signingIn => 'Signing in…';
  @override
  String get enterPassword => 'Enter your password';

  @override
  String get createAccountTitle => 'Create your account';
  @override
  String get dataStaysOnDevice => 'Your data stays on this device';
  @override
  String get passwordHelper => 'At least 6 characters';
  @override
  String get confirmPassword => 'Confirm password';
  @override
  String get passwordsDontMatch => 'Passwords do not match';
  @override
  String get securityQuestion => 'Security question';
  @override
  String get securityQuestionHint =>
      'Used to reset your password if you forget it.';
  @override
  String get yourAnswer => 'Your answer';
  @override
  String get createAccount => 'Create account';
  @override
  String get creating => 'Creating…';

  @override
  String get resetTitle => 'Reset password';
  @override
  String get findYourAccount => 'Find your account';
  @override
  String get answerYourQuestion => 'Answer your security question';
  @override
  String get continueLabel => 'Continue';
  @override
  String get checking => 'Checking…';
  @override
  String get newPassword => 'New password';
  @override
  String get resetPasswordButton => 'Reset password';
  @override
  String get saving => 'Saving…';
  @override
  String get noAccountForEmail => 'No account found for this email.';
  @override
  String get wrongCredentials => 'Wrong email or password.';

  @override
  String get yourProfile => 'Your Profile';
  @override
  String get profileNamePlaceholder => 'Your profile';
  @override
  String get setUpProfile => 'Set up your profile';
  @override
  String get setUpProfileHint =>
      'Get calorie and macro targets tailored to you.';
  @override
  String get getStarted => 'Get started';
  @override
  String get editProfile => 'Edit profile';
  @override
  String get account => 'Account';
  @override
  String get logOut => 'Log out';
  @override
  String get deleteAccount => 'Delete account';
  @override
  String get deleteConfirmTitle => 'Delete account?';
  @override
  String get deleteConfirmBody =>
      'This erases your account, profile, food log and weight history on this '
      'device. This cannot be undone.';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get couldNotLoadProfile => 'Could not load your profile.';
}

class HiStrings extends AppStrings {
  const HiStrings();

  @override
  String get tagline => 'क्लिक करें. ट्रैक करें. आगे बढ़ें.';
  @override
  String get languageLabel => 'भाषा';
  @override
  String get appearanceLabel => 'दिखावट';
  @override
  String get themeLight => 'लाइट';
  @override
  String get themeDark => 'डार्क';
  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get navHome => 'होम';
  @override
  String get navLog => 'फूड लॉग';
  @override
  String get navSnap => 'फोटो लें';
  @override
  String get navProgress => 'प्रगति';
  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';
  @override
  String get signInSubtitle => 'फूड गुरुजी में साइन इन करें';
  @override
  String get emailLabel => 'ईमेल';
  @override
  String get passwordLabel => 'पासवर्ड';
  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';
  @override
  String get logIn => 'लॉग इन';
  @override
  String get signingIn => 'साइन इन हो रहा है…';
  @override
  String get enterPassword => 'अपना पासवर्ड डालें';

  @override
  String get createAccountTitle => 'अपना खाता बनाएँ';
  @override
  String get dataStaysOnDevice => 'आपका डेटा इसी डिवाइस पर रहता है';
  @override
  String get passwordHelper => 'कम से कम 6 अक्षर';
  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';
  @override
  String get passwordsDontMatch => 'पासवर्ड मेल नहीं खाते';
  @override
  String get securityQuestion => 'सुरक्षा प्रश्न';
  @override
  String get securityQuestionHint => 'पासवर्ड भूलने पर उसे रीसेट करने के लिए।';
  @override
  String get yourAnswer => 'आपका उत्तर';
  @override
  String get createAccount => 'खाता बनाएँ';
  @override
  String get creating => 'बन रहा है…';

  @override
  String get resetTitle => 'पासवर्ड रीसेट करें';
  @override
  String get findYourAccount => 'अपना खाता खोजें';
  @override
  String get answerYourQuestion => 'अपने सुरक्षा प्रश्न का उत्तर दें';
  @override
  String get continueLabel => 'आगे बढ़ें';
  @override
  String get checking => 'जाँच हो रही है…';
  @override
  String get newPassword => 'नया पासवर्ड';
  @override
  String get resetPasswordButton => 'पासवर्ड रीसेट करें';
  @override
  String get saving => 'सहेजा जा रहा है…';
  @override
  String get noAccountForEmail => 'इस ईमेल के लिए कोई खाता नहीं मिला।';
  @override
  String get wrongCredentials => 'गलत ईमेल या पासवर्ड।';

  @override
  String get yourProfile => 'आपकी प्रोफ़ाइल';
  @override
  String get profileNamePlaceholder => 'आपकी प्रोफ़ाइल';
  @override
  String get setUpProfile => 'अपनी प्रोफ़ाइल सेट करें';
  @override
  String get setUpProfileHint => 'अपने अनुसार कैलोरी और मैक्रो लक्ष्य पाएँ।';
  @override
  String get getStarted => 'शुरू करें';
  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';
  @override
  String get account => 'खाता';
  @override
  String get logOut => 'लॉग आउट';
  @override
  String get deleteAccount => 'खाता हटाएँ';
  @override
  String get deleteConfirmTitle => 'खाता हटाएँ?';
  @override
  String get deleteConfirmBody =>
      'इससे इस डिवाइस पर आपका खाता, प्रोफ़ाइल, फूड लॉग और वज़न का इतिहास मिट '
      'जाएगा। इसे वापस नहीं लाया जा सकता।';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get delete => 'हटाएँ';
  @override
  String get couldNotLoadProfile => 'आपकी प्रोफ़ाइल लोड नहीं हो सकी।';
}

class HinglishStrings extends AppStrings {
  const HinglishStrings();

  @override
  String get tagline => 'Snap karo. Track karo. Aage badho.';
  @override
  String get languageLabel => 'Bhasha';
  @override
  String get appearanceLabel => 'Look';
  @override
  String get themeLight => 'Light';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeSystem => 'System';

  @override
  String get navHome => 'Home';
  @override
  String get navLog => 'Food log';
  @override
  String get navSnap => 'Photo khecho';
  @override
  String get navProgress => 'Progress';
  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeBack => 'Wapas aa gaye!';
  @override
  String get signInSubtitle => 'Food Guruji me sign in karo';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Password';
  @override
  String get forgotPassword => 'Password bhool gaye?';
  @override
  String get logIn => 'Log in karo';
  @override
  String get signingIn => 'Sign in ho raha hai…';
  @override
  String get enterPassword => 'Apna password daalo';

  @override
  String get createAccountTitle => 'Apna account banao';
  @override
  String get dataStaysOnDevice => 'Aapka data isi device par rehta hai';
  @override
  String get passwordHelper => 'Kam se kam 6 characters';
  @override
  String get confirmPassword => 'Password confirm karo';
  @override
  String get passwordsDontMatch => 'Password match nahi ho raha';
  @override
  String get securityQuestion => 'Security question';
  @override
  String get securityQuestionHint =>
      'Password bhoolne par reset karne ke liye.';
  @override
  String get yourAnswer => 'Aapka jawaab';
  @override
  String get createAccount => 'Account banao';
  @override
  String get creating => 'Ban raha hai…';

  @override
  String get resetTitle => 'Password reset karo';
  @override
  String get findYourAccount => 'Apna account dhoondo';
  @override
  String get answerYourQuestion => 'Apne security question ka jawaab do';
  @override
  String get continueLabel => 'Aage badho';
  @override
  String get checking => 'Check ho raha hai…';
  @override
  String get newPassword => 'Naya password';
  @override
  String get resetPasswordButton => 'Password reset karo';
  @override
  String get saving => 'Save ho raha hai…';
  @override
  String get noAccountForEmail => 'Is email ke liye koi account nahi mila.';
  @override
  String get wrongCredentials => 'Galat email ya password.';

  @override
  String get yourProfile => 'Aapki Profile';
  @override
  String get profileNamePlaceholder => 'Aapki Profile';
  @override
  String get setUpProfile => 'Apni profile set karo';
  @override
  String get setUpProfileHint =>
      'Apne hisaab se calorie aur macro targets pao.';
  @override
  String get getStarted => 'Shuru karo';
  @override
  String get editProfile => 'Profile edit karo';
  @override
  String get account => 'Account';
  @override
  String get logOut => 'Log out karo';
  @override
  String get deleteAccount => 'Account delete karo';
  @override
  String get deleteConfirmTitle => 'Account delete karein?';
  @override
  String get deleteConfirmBody =>
      'Isse is device par aapka account, profile, food log aur weight history '
      'mit jaayega. Ye wapas nahi aayega.';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get couldNotLoadProfile => 'Aapki profile load nahi ho saki.';
}
