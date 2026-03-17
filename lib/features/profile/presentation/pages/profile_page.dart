import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../router/app_routes.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../chat/presentation/providers/global_chat_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    ref.invalidate(currentUserProvider);
    // Reload chat so it cleanly resets for the next login
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
        data: (user) => _ProfileContent(
          user: user,
          onMenuTap: onMenuTap,
          onSignOut: () => _signOut(context, ref),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.onMenuTap,
    required this.onSignOut,
    required this.onRetry,
  });

  final UserEntity user;
  final VoidCallback onMenuTap;
  final VoidCallback onSignOut;
  final VoidCallback onRetry;

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Banner ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: const Color(0xFF0A0A0A),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: Colors.white70, size: 22),
            onPressed: onMenuTap,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(height: 1, color: const Color(0xFF1A1A1A)),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/profile-bg.jpg',
                  fit: BoxFit.cover,
                ),
                // Bottom fade for readability
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xDD0A0A0A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1.0],
                    ),
                  ),
                ),
                // Avatar
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(
                            color: const Color(0xFF0A0A0A),
                            width: 3,
                          ),
                          image: user.profileImageUrl != null
                              ? DecorationImage(
                                  image:
                                      NetworkImage(user.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.profileImageUrl == null
                            ? Center(
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 36,
                                    color: const Color(0xFF888888),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // Online dot
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.isOnline
                                ? const Color(0xFF23A55A)
                                : const Color(0xFF555555),
                            border: Border.all(
                                color: const Color(0xFF0A0A0A), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: Colors.white70, size: 20),
              onPressed: () {},
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ──────────────────────────────────────────────────
                Text(
                  user.displayName,
                  style: GoogleFonts.bebasNeue(
                    color: const Color(0xFFF2F2F2),
                    fontSize: 34,
                    letterSpacing: 1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '@${user.userName}',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF999999),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Online status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: user.isOnline
                            ? const Color(0xFF0D1F12)
                            : const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: user.isOnline
                              ? const Color(0xFF1A3320)
                              : const Color(0xFF1E1E1E),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user.isOnline
                                  ? const Color(0xFF23A55A)
                                  : const Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.inter(
                              color: user.isOnline
                                  ? const Color(0xFF23A55A)
                                  : const Color(0xFF666666),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF555555),
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 24),

                _DarkCard(
                  label: 'ABOUT ME',
                  child: Text(
                    user.bio?.isNotEmpty == true
                        ? user.bio!
                        : 'no bio yet.',
                    style: GoogleFonts.spaceMono(
                      color: user.bio?.isNotEmpty == true
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF444444),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _DarkCard(
                        label: 'MEMBER SINCE',
                        child: Text(
                          _formatDate(user.createdAt),
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFCCCCCC),
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DarkCard(
                        label: 'FRIENDS',
                        child: Text(
                          '${user.friendIds.length}',
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFCCCCCC),
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                Text(
                  'SETTINGS',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF444444),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),

                _DarkSettingsItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
                _DarkSettingsItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () {},
                ),
                _DarkSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy & Safety',
                  onTap: () {},
                ),
                _DarkSettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {},
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFF1A1A1A)),
                const SizedBox(height: 8),

                _DarkSettingsItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  onTap: onSignOut,
                  color: const Color(0xFFCC4444),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF555555),
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DarkSettingsItem extends StatelessWidget {
  const _DarkSettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFDDDDDD);
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: const Color(0xFF141414),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.spaceMono(
                  color: c,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (color == null)
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF444444), size: 16),
          ],
        ),
      ),
    );
  }
}
