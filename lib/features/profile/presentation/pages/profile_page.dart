import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../router/app_routes.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../chat/presentation/providers/global_chat_provider.dart';
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

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ref.invalidate(currentUserProvider);
    ref.read(globalChatProvider.notifier).reload();
    if (mounted) context.go(AppRoutes.login);
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
    final isConnected = ref.watch(globalChatProvider.select((s) => s.isConnected));

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
          onSignOut: _signOut,
          onRetry: _retry,
        ),
        data: (user) => ProfileContent(
          user: user.copyWith(isOnline: isConnected),
          onMenuTap: widget.onMenuTap,
          onSignOut: _signOut,
          onRetry: _retry,
        ),
      ),
    );
  }
}
