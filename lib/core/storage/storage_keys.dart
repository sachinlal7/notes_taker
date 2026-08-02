class StorageKeys {
  const StorageKeys._();

  static const String accessToken = 'auth.access_token';
  static const String currentUser = 'user.current';
  static const String appLocale = 'app.locale';
  static const String onboardingCompleted = 'app.onboarding_completed';
  static const String themeMode = 'app.theme_mode';

  static const Set<String> logoutPreservedKeys = {
    appLocale,
    onboardingCompleted,
    themeMode,
  };
}
