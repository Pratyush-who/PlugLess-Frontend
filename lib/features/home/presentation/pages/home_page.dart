import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/plugless_logo.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../auth/presentation/widgets/auth_dot_grid.dart';
import '../../../chat/presentation/pages/global_chat_page.dart';
import '../../../dm/presentation/pages/dm_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _switchTab(int i) {
    setState(() => _currentIndex = i);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: _AppDrawer(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GlobalChatPage(onMenuTap: _openDrawer),
          DmPage(onMenuTap: _openDrawer),
          ProfilePage(onMenuTap: _openDrawer),
        ],
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _navItems = [
    _NavItem(icon: Icons.public_rounded, label: 'Global Chat'),
    _NavItem(icon: Icons.forum_rounded, label: 'Messages'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: const Color(0xFF0D0D0D),
      width: 280,
      child: Stack(
        children: [
          // Dot grid texture
          const Positioned.fill(child: AuthDotGrid()),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Branding ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PluglessLogo(size: 24),
                      const SizedBox(height: 10),
                      Text(
                        'Meet Your People.',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF333333),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Separator ─────────────────────────────────────────────
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: const Color(0xFF1A1A1A),
                ),
                const SizedBox(height: 12),

                // ── Nav section label ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 6),
                  child: Text(
                    'CHANNELS',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF333333),
                      fontSize: 9,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                // ── Nav items ─────────────────────────────────────────────
                ...List.generate(_navItems.length, (i) {
                  return _DrawerNavItem(
                    icon: _navItems[i].icon,
                    label: _navItems[i].label,
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  );
                }),

                const Spacer(),

                // ── Separator ─────────────────────────────────────────────
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 0),
                  color: const Color(0xFF141414),
                ),

                // ── User tile ─────────────────────────────────────────────
                userAsync.when(
                  loading: () => const _DrawerUserShimmer(),
                  error: (_, __) => const SizedBox(height: 64),
                  data: (user) => _DrawerUserTile(user: user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: Colors.transparent,
        highlightColor: const Color(0xFF151515),
        child: Row(
          children: [
            // Active indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 3,
              height: isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF1C1C1C)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isActive
                          ? const Color(0xFFF2F2F2)
                          : const Color(0xFF4A4A4A),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: isActive
                            ? const Color(0xFFF2F2F2)
                            : const Color(0xFF555555),
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerUserTile extends StatelessWidget {
  const _DrawerUserTile({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                ),
                child: ClipOval(
                  child: user.profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _InitialAvatar(
                            name: user.displayName,
                          ),
                        )
                      : _InitialAvatar(name: user.displayName),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE0E0E0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${user.userName}',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF444444),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerUserShimmer extends StatelessWidget {
  const _DrawerUserShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 90, height: 12, color: const Color(0xFF1A1A1A)),
              const SizedBox(height: 4),
              Container(
                  width: 60, height: 9, color: const Color(0xFF141414)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

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

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
