import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/splash/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static GoRouter get router => GoRouter(
        initialLocation: AppRoutes.splash,
        debugLogDiagnostics: false,
        redirect: _guard,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            pageBuilder: (_, state) =>
                _fadePage(state, const SplashPage()),
          ),
          GoRoute(
            path: AppRoutes.auth,
            pageBuilder: (_, state) =>
                _fadePage(state, const AuthPage()),
          ),
          GoRoute(
            path: AppRoutes.onboarding,
            pageBuilder: (_, state) =>
                _fadePage(state, const OnboardingPage()),
          ),
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (_, state) =>
                _fadePage(state, const HomePage()),
          ),
        ],
      );

  static Future<String?> _guard(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Splash handles its own redirect; skip guarding while on splash
    if (state.matchedLocation == AppRoutes.splash) return null;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLoggedIn = token != null;

    final isOnAuth = state.matchedLocation == AppRoutes.auth;
    final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;

    if (!isLoggedIn && !isOnAuth && !isOnOnboarding) {
      return AppRoutes.auth;
    }
    if (isLoggedIn && isOnAuth) {
      return AppRoutes.home;
    }
    return null;
  }

  static CustomTransitionPage _fadePage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
