import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_state_service.dart';
import '../../../../router/app_routes.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../chat/presentation/providers/global_chat_provider.dart';
import '../../../chat/presentation/providers/online_users_provider.dart';
import '../../../profile/presentation/providers/public_profile_provider.dart';
import '../widgets/profile_content.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Timer? _retryTimer;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Shows logout confirmation dialog and performs logout if confirmed.
  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again.',
          style: TextStyle(color: Color(0xFFB6B6BC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF2C6DFE)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  /// Performs comprehensive logout: clears token, all cached data, and invalidates all providers.
  Future<void> _performLogout() async {
    // Clear all cached data and token through AuthStateService
    await AuthStateService.instance.logout();

    // Invalidate all cached providers to clear UI state
    // This prevents old cached data from persisting when switching accounts
    ref.invalidate(currentUserProvider);
    ref.invalidate(allPublicUsersProvider);
    ref.invalidate(onlineUsersProvider);
    ref.invalidate(publicUserByIdProvider);
    ref.invalidate(friendRequestActionsProvider);
    ref.read(globalChatProvider.notifier).reload();

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _retry() {
    _retryTimer?.cancel();
    ref.invalidate(currentUserProvider);
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) ref.invalidate(currentUserProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isConnected =
        ref.watch(globalChatProvider.select((s) => s.isConnected));

    // Auto-retry in background when fetch fails
    ref.listen<AsyncValue<dynamic>>(currentUserProvider, (_, next) {
      if (next is AsyncError) {
        _scheduleRetry();
      } else {
        _retryTimer?.cancel();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD8D8D8),
            strokeWidth: 1.5,
          ),
        ),
        error: (_, __) => ProfileContent(
          user: null,
          onMenuTap: widget.onMenuTap,
          onSignOut: _showLogoutConfirmation,
          onRetry: _retry,
        ),
        data: (user) => ProfileContent(
          user: user.copyWith(isOnline: isConnected),
          onMenuTap: widget.onMenuTap,
          onSignOut: _showLogoutConfirmation,
          onRetry: _retry,
        ),
      ),
    );
  }
}
