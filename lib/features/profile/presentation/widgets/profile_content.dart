import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'dark_card.dart';
import 'profile_settings_item.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
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
                                  image: NetworkImage(user.profileImageUrl!),
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
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.isOnline
                                ? AppColors.online
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
                                  ? AppColors.online
                                  : const Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.inter(
                              color: user.isOnline
                                  ? AppColors.online
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

                DarkCard(
                  label: 'ABOUT ME',
                  child: Text(
                    user.bio?.isNotEmpty == true ? user.bio! : 'no bio yet.',
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
                      child: DarkCard(
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
                      child: DarkCard(
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

                ProfileSettingsItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: () {},
                ),
                ProfileSettingsItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () {},
                ),
                ProfileSettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy & Safety',
                  onTap: () {},
                ),
                ProfileSettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {},
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFF1A1A1A)),
                const SizedBox(height: 8),

                ProfileSettingsItem(
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

// ── Avatar fallback used in drawer ──────────────────────────────────────────

class InitialAvatar extends StatelessWidget {
  const InitialAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.bebasNeue(
          fontSize: 16,
          color: const Color(0xFF666666),
        ),
      ),
    );
  }
}
