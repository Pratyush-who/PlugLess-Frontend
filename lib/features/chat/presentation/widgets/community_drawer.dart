import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/online_users_provider.dart';

class CommunityDrawer extends ConsumerWidget {
  const CommunityDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(onlineUsersProvider);

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Text(
                    'ONLINE NOW',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF888888),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.invalidate(onlineUsersProvider),
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF444444), size: 16),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFF1A1A1A)),

            Expanded(
              child: usersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF444444),
                    strokeWidth: 1.5,
                  ),
                ),
                error: (_, __) => Center(
                  child: Text(
                    'Could not load members.',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF555555),
                      fontSize: 12,
                    ),
                  ),
                ),
                data: (users) {
                  // Deduplicate by ID (backend may return same session twice)
                  final seen = <String>{};
                  final unique = users
                      .where((u) => seen.add(u.id))
                      .toList(growable: false);
                  if (unique.isEmpty) {
                    return Center(
                      child: Text(
                        'No one online right now.',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF444444),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: unique.length,
                    itemBuilder: (_, i) => _OnlineUserTile(user: unique[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineUserTile extends StatelessWidget {
  const _OnlineUserTile({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: user.profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _AvatarFallback(name: user.displayName),
                        )
                      : _AvatarFallback(name: user.displayName),
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
                    color: AppColors.online,
                    border:
                        Border.all(color: const Color(0xFF111111), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isNotEmpty ? user.displayName : user.userName,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFE0E0E0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${user.userName}',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF555555),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1A3320)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.online,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'online',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.online,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.bebasNeue(
          fontSize: 18,
          color: const Color(0xFF666666),
        ),
      ),
    );
  }
}
