import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class OnboardingState {
  const OnboardingState();
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial({this.avatarFile});

  final File? avatarFile;
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingSuccess extends OnboardingState {
  const OnboardingSuccess();
}

class OnboardingFailure extends OnboardingState {
  const OnboardingFailure({required this.message});

  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class OnboardingNotifier extends Notifier<OnboardingState> {
  final _repo = const OnboardingRepositoryImpl();
  File? _avatarFile;

  @override
  OnboardingState build() => const OnboardingInitial();

  void pickAvatar(File file) {
    _avatarFile = file;
    state = OnboardingInitial(avatarFile: _avatarFile);
  }

  void removeAvatar() {
    _avatarFile = null;
    state = const OnboardingInitial();
  }

  /// Submits POST /auth/signup with all collected fields.
  /// Reads staged email+password from [authProvider].
  Future<void> submit({
    required String userName,
    required String displayName,
    String? bio,
  }) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthPendingOnboarding) {
      state = const OnboardingFailure(message: 'Session expired. Please sign up again.');
      return;
    }

    state = const OnboardingLoading();
    try {
      await _repo.signUp(
        email: authState.email,
        password: authState.password,
        userName: userName,
        displayName: displayName,
        bio: bio,
        photo: _avatarFile,
      );
      state = const OnboardingSuccess();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('409')) {
        state = const OnboardingFailure(
          message: 'An account with this email already exists.',
        );
      } else if (msg.contains('userName') || msg.contains('400')) {
        state = const OnboardingFailure(
          message: 'Invalid username or display name. Please check and retry.',
        );
      } else {
        state = const OnboardingFailure(message: 'Failed to create account. Try again.');
      }
    }
  }

  /// Skip — auto-generate a username from the staged email.
  Future<void> skip() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthPendingOnboarding) {
      state = const OnboardingFailure(message: 'Session expired. Please sign up again.');
      return;
    }

    final emailPrefix = authState.email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final userName = emailPrefix.length >= 3 ? emailPrefix : '${emailPrefix}_user';
    final displayName = emailPrefix;

    state = const OnboardingLoading();
    try {
      await _repo.signUp(
        email: authState.email,
        password: authState.password,
        userName: userName,
        displayName: displayName,
      );
      state = const OnboardingSuccess();
    } catch (_) {
      state = const OnboardingFailure(message: 'Failed to create account. Try again.');
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
