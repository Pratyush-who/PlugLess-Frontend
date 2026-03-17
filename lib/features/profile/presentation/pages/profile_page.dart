import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../router/app_routes.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../chat/presentation/providers/global_chat_provider.dart';
import '../widgets/profile_content.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ref.invalidate(currentUserProvider);
    ref.read(globalChatProvider.notifier).reload();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD8D8D8),
            strokeWidth: 1.5,
          ),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COULD NOT LOAD',
                style: GoogleFonts.bebasNeue(
                  color: const Color(0xFF666666),
                  fontSize: 24,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => ref.invalidate(currentUserProvider),
                child: Text(
                  'tap to retry',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF888888),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (user) => ProfileContent(
          user: user,
          onMenuTap: onMenuTap,
          onSignOut: () => _signOut(context, ref),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }
}
