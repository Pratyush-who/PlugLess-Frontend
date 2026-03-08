import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Signup: email+password staged — onboarding will submit the real API call.
class AuthPendingOnboarding extends AuthState {
  const AuthPendingOnboarding({required this.email, required this.password});

  final String email;
  final String password;
}

/// Sign-in success — user is fully authenticated.
class AuthSuccess extends AuthState {
  const AuthSuccess({required this.user});

  final UserEntity user;
}

class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends Notifier<AuthState> {
  final _repo = const AuthRepositoryImpl();

  @override
  AuthState build() => const AuthInitial();

  /// POST /auth/login → save token → emit AuthSuccess.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repo.signIn(email: email, password: password);
      state = AuthSuccess(user: result.user);
    } catch (e) {
      state = AuthFailure(message: _parseError(e));
    }
  }

  /// Stage email+password for onboarding — no API call yet.
  void stagePendingSignup({required String email, required String password}) {
    state = AuthPendingOnboarding(email: email, password: password);
  }

  void reset() => state = const AuthInitial();

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Invalid email or password.';
    if (msg.contains('409')) return 'An account with this email already exists.';
    return 'Something went wrong. Please try again.';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
