import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_service.dart';

/// Singleton ChangeNotifier used as GoRouter's [refreshListenable].
/// When [onUnauthorized] is called (e.g. 401 from interceptor),
/// it clears the token and notifies the router to re-run its guard,
/// which redirects to login.
class AuthStateService extends ChangeNotifier {
  AuthStateService._();
  static final instance = AuthStateService._();

  /// Called when user becomes unauthorized (e.g., 401 response).
  /// Clears token and all cached session data.
  Future<void> onUnauthorized() async {
    await _clearAll();
    notifyListeners();
  }

  /// Performs a complete logout:
  /// - Deletes the authentication token from secure storage
  /// - Clears all cached user data from shared preferences
  /// - Notifies listeners to trigger route guard
  Future<void> logout() async {
    await _clearAll();
    notifyListeners();
  }

  /// Internal method to clear all auth-related data.
  Future<void> _clearAll() async {
    // Delete token from secure storage
    await TokenService.instance.deleteToken();

    // Clear all cached data from shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_me');
    await prefs.remove('token'); // Fallback for old preference location
  }
}
