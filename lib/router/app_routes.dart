class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String batteryGate = '/battery-gate';
  static const String home = '/home';

  // Sub-routes under home (for deep linking)
  static const String globalChat = '/home/global-chat';
  static const String dm = '/home/dm';
  static const String profile = '/home/profile';
  static const String friends = '/home/profile/friends';
}
