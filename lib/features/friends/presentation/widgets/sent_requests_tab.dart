import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../profile/presentation/widgets/public_profile_dialog.dart';
import '../providers/friends_provider.dart';
import 'friend_request_item.dart';

class SentRequestsTab extends ConsumerStatefulWidget {
  const SentRequestsTab({super.key});

  @override
  ConsumerState<SentRequestsTab> createState() => _SentRequestsTabState();
}

class _SentRequestsTabState extends ConsumerState<SentRequestsTab> {
  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  void _fetchPage(int pageKey) async {
    try {
      final newPage = await ref.read(sentRequestsProvider(pageKey).future);
      final isLastPage = newPage.currentPage >= newPage.totalPages - 1;
      if (isLastPage) {
        _pagingController.appendLastPage(newPage.users);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newPage.users, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _pagingController.refresh();
      },
      child: PagedListView<int, dynamic>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<dynamic>(
          itemBuilder: (context, item, index) =>
              SentRequestCard(user: item as UserEntity),
          noItemsFoundIndicatorBuilder: (_) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 48,
                    color: const Color(0xFF55555A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB5BAC1),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          firstPageErrorIndicatorBuilder: (_) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: const Color(0xFF55555A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load pending requests',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB5BAC1),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _pagingController.refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C6DFE),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          newPageErrorIndicatorBuilder: (_) => Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error loading more items',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB5BAC1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _pagingController.retryLastFailedRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C6DFE),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          firstPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2C6DFE),
              ),
            ),
          ),
          newPageProgressIndicatorBuilder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2C6DFE),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Wrapper widget for sent requests showing "Pending" state
class SentRequestCard extends ConsumerWidget {
  const SentRequestCard({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F1F23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name/Username
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _showPublicProfile(context, user),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: ClipOval(
                    child: user.profileImageUrl != null &&
                            user.profileImageUrl!.isNotEmpty
                        ? Image.network(
                            user.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarFallback(user),
                          )
                        : _buildAvatarFallback(user),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Username with Pending Badge
              Expanded(
                child: GestureDetector(
                  onTap: () => _showPublicProfile(context, user),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF2F2F3),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '@${user.userName}',
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFF8B8B91),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F23),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: Color(0xFF7C7C82),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pending',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF7C7C82),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Status (if present)
          if ((user.status ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              user.status!.trim(),
              style: GoogleFonts.inter(
                color: const Color(0xFFB6B6BC),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(UserEntity user) {
    return Container(
      color: const Color(0xFF202025),
      alignment: Alignment.center,
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
        style: GoogleFonts.bebasNeue(
          color: const Color(0xFF9B9BA1),
          fontSize: 24,
        ),
      ),
    );
  }

  void _showPublicProfile(BuildContext context, UserEntity user) {
    showPublicProfileDialog(context, userId: user.id);
  }
}
