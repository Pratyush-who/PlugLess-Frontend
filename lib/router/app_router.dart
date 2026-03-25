import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_state_service.dart';
import '../core/auth/token_service.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: AuthStateService.instance,
    redirect: _guard,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, state) => _fadePage(state, const SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _fadePage(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (_, state) => _fadePage(state, const SignupPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fadePage(state, const OnboardingPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (_, state) => _fadePage(state, const HomePage()),
      ),
    ],
  );

  static Future<String?> _guard(
    BuildContext context,
    GoRouterState state,
  ) async {
    if (state.matchedLocation == AppRoutes.splash) return null;

    final token = await TokenService.instance.getToken();
    final isLoggedIn = token != null;

    final loc = state.matchedLocation;
    final isOnAuth = loc == AppRoutes.login || loc == AppRoutes.signup;
    final isOnOnboarding = loc == AppRoutes.onboarding;

    if (!isLoggedIn && !isOnAuth && !isOnOnboarding) {
      return AppRoutes.login;
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
