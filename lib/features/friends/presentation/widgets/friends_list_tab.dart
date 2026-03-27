import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../providers/friends_provider.dart';
import 'friend_request_item.dart';

class FriendsListTab extends ConsumerStatefulWidget {
  const FriendsListTab({super.key});

  @override
  ConsumerState<FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends ConsumerState<FriendsListTab> {
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
      final newPage = await ref.read(friendsListProvider(pageKey).future);
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
          itemBuilder: (context, item, index) => FriendRequestItem(
            user: item,
            action: FriendItemAction.remove,
          ),
          noItemsFoundIndicatorBuilder: (_) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 48,
                    color: const Color(0xFF55555A),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB5BAC1),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send friend requests to get started',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7C7C82),
                      fontSize: 13,
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
                    'Failed to load friends',
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
                    'Error loading more friends',
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
