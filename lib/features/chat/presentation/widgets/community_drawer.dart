import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/global_stats_provider.dart';
import '../providers/online_users_provider.dart';
import '../../../profile/presentation/providers/public_profile_provider.dart';
import '../../../profile/presentation/widgets/public_profile_dialog.dart';

class CommunityDrawer extends ConsumerStatefulWidget {
  const CommunityDrawer({super.key});

  @override
  ConsumerState<CommunityDrawer> createState() => _CommunityDrawerState();
}

class _CommunityDrawerState extends ConsumerState<CommunityDrawer> {
  static const int _batchSize = 15;

  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _batchSize;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_visibleCount >= _totalUsers) return;

    if (_scrollController.position.extentAfter < 220) {
      setState(() {
        final next = _visibleCount + _batchSize;
        _visibleCount = next > _totalUsers ? _totalUsers : next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allPublicUsersProvider);
    final onlineCount = ref.watch(globalStatsProvider).valueOrNull ?? 0;
    final onlineSet = {
      for (final u in ref.watch(onlineUsersProvider).valueOrNull ?? const <UserEntity>[]) u.id,
    };

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
                    'MEMBERS',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF888888),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (onlineCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$onlineCount',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.online,
                        fontSize: 10,
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.invalidate(allPublicUsersProvider);
                      ref.invalidate(globalStatsProvider);
                      ref.invalidate(onlineUsersProvider);
                    },
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
                  // Deduplicate by ID to handle repeated rows from API.
                  final seen = <String>{};
                  final unique = users
                      .where((u) => seen.add(u.id))
                      .toList(growable: false);
                  _totalUsers = unique.length;

                  if (unique.isEmpty) {
                    return Center(
                      child: Text(
                        'No members found.',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF444444),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }

                  final visible = _visibleCount > unique.length
                      ? unique.length
                      : _visibleCount;
                  final shown = unique.take(visible).toList(growable: false);

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        shown.length + (shown.length < unique.length ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= shown.length) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Text(
                            'Showing ${shown.length} of ${unique.length}',
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFF5B5B60),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      final user = shown[i];
                      return _MemberUserTile(
                        user: user,
                        isOnline: onlineSet.contains(user.id),
                        onTap: () {
                          showPublicProfileDialog(
                            context,
                            userId: user.id,
                            userName: user.userName,
                          );
                        },
                      );
                    },
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

class _MemberUserTile extends StatelessWidget {
  const _MemberUserTile({
    required this.user,
    required this.isOnline,
    required this.onTap,
  });

  final UserEntity user;
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.online,
                        border: Border.all(
                            color: const Color(0xFF111111), width: 2),
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
                    user.displayName.isNotEmpty
                        ? user.displayName
                        : user.userName,
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
          ],
        ),
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
