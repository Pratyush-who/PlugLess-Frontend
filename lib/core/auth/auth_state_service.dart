import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton ChangeNotifier used as GoRouter's [refreshListenable].
/// When [onUnauthorized] is called (e.g. 401 from interceptor),
/// it clears the token and notifies the router to re-run its guard,
/// which redirects to login.
class AuthStateService extends ChangeNotifier {
  AuthStateService._();
  static final instance = AuthStateService._();

  Future<void> onUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
