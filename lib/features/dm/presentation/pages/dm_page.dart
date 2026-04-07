import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../providers/dm_provider.dart';
import 'dm_thread_page.dart';
import '../../../../core/constants/app_colors.dart';

class DmPage extends ConsumerWidget {
  const DmPage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(dmFriendsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(height: 1, color: const Color(0xFF1A1A1A)),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: Color(0xFF888888), size: 22),
          onPressed: onMenuTap,
        ),
        title: Text(
          'Direct Messages',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: () => ref.invalidate(dmFriendsProvider),
          ),
        ],
      ),
      body: friendsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.blurple,
            strokeWidth: 1.6,
          ),
        ),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFF6E6E73), size: 30),
              const SizedBox(height: 8),
              Text(
                'Could not load your friends.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9A9AA2),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        data: (friends) {
          if (friends.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.forum_outlined,
                      color: Color(0xFF3C3C42), size: 44),
                  const SizedBox(height: 12),
                  Text(
                    'No friends yet',
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFF5E5E66),
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send friend requests to start messaging.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6E6E75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, i) {
              final friend = friends[i];
              return _DmTile(
                user: friend,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DmThreadPage(friend: friend),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DmTile extends StatelessWidget {
  const _DmTile({
    required this.user,
    required this.onTap,
  });

  final UserEntity user;
  final VoidCallback onTap;

  String _displayName() {
    final display = user.displayName.trim();
    if (display.isNotEmpty) return display;
    return user.userName;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFF888888),
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: user.isOnline
                          ? AppColors.online
                          : const Color(0xFF555555),
                      border:
                          Border.all(color: const Color(0xFF0A0A0A), width: 2),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final previewAsync =
                              ref.watch(dmPreviewProvider(user.id));
                          final preview = previewAsync.valueOrNull;
                          final label = preview == null
                              ? ''
                              : _timeAgo(preview.timestamp);
                          return Text(
                            label,
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFF555555),
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Consumer(
                    builder: (context, ref, _) {
                      final previewAsync =
                          ref.watch(dmPreviewProvider(user.id));
                      final text = previewAsync.valueOrNull?.text ??
                          'Tap to start messaging';
                      return Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF77777E),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts.toLocal());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${ts.month}/${ts.day}';
  }
}
