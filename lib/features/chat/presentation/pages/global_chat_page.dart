import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/global_chat_provider.dart';
import '../providers/global_stats_provider.dart';
import '../providers/online_users_provider.dart';
import '../widgets/community_drawer.dart';
import '../widgets/date_divider.dart';
import '../widgets/error_banner.dart';
import '../widgets/message_input.dart';
import '../widgets/message_tile.dart';
import '../../../profile/presentation/widgets/public_profile_dialog.dart';

class GlobalChatPage extends ConsumerStatefulWidget {
  const GlobalChatPage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  ConsumerState<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends ConsumerState<GlobalChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _handleSend() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(globalChatProvider.notifier).sendMessage(text);
  }

  void _openMembersDrawer() {
    ref.invalidate(onlineUsersProvider);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openPublicProfileByUserName(String userName) {
    return showPublicProfileDialog(context, userName: userName);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(globalChatProvider);

    ref.listen<GlobalChatState>(globalChatProvider, (prev, next) {
      final prevLen = prev?.messages.length ?? 0;
      final nextLen = next.messages.length;
      if (nextLen > prevLen) _scrollToBottom();
      if (prev?.isLoading == true && !next.isLoading && nextLen > 0) {
        _scrollToBottom(animate: false);
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0A0A0A),
      endDrawer: const CommunityDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(height: 1, color: const Color(0xFF1A1A1A)),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: Color(0xFF888888), size: 22),
          onPressed: widget.onMenuTap,
        ),
        title: Row(
          children: [
            const Icon(Icons.tag_rounded, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 4),
            Text(
              'general',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: chat.isConnected
                    ? AppColors.online
                    : const Color(0xFF555555),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(builder: (context, ref, _) {
            final total = ref.watch(globalStatsProvider).valueOrNull ?? 0;
            if (total <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$total',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Consumer(builder: (context, ref, _) {
            final count =
                ref.watch(onlineUsersProvider).valueOrNull?.length ?? 0;
            return GestureDetector(
              onTap: _openMembersDrawer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_alt_rounded,
                          color: Color(0xFF888888), size: 22),
                      onPressed: _openMembersDrawer,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          if (chat.error != null)
            ErrorBanner(
              message: chat.error!,
              onRetry: () => ref.read(globalChatProvider.notifier).reload(),
            ),
          Expanded(child: _buildBody(chat)),
          MessageInput(
            controller: _controller,
            isSending: chat.isSending,
            isConnected: chat.isConnected,
            onSend: _handleSend,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildBody(GlobalChatState chat) {
    if (chat.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.blurple,
          strokeWidth: 1.5,
        ),
      );
    }

    if (chat.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF2A2A2A), size: 48),
            const SizedBox(height: 16),
            Text(
              'NO MESSAGES YET',
              style: GoogleFonts.bebasNeue(
                color: const Color(0xFF333333),
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to say something.',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF333333),
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    final items = _buildItems(chat.messages);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }

  List<Widget> _buildItems(List<ChatMessage> messages) {
    final List<Widget> items = [];
    String? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final dateKey = _dateKey(msg.timestamp);

      if (dateKey != lastDate) {
        items.add(DateDivider(label: _formatDateLabel(msg.timestamp)));
        lastDate = dateKey;
      }

      final prev = i > 0 ? messages[i - 1] : null;
      final isGrouped = prev != null &&
          prev.senderUserName == msg.senderUserName &&
          _dateKey(prev.timestamp) == dateKey &&
          msg.timestamp.difference(prev.timestamp).inMinutes < 5;

      items.add(
        MessageTile(
          message: msg,
          isGrouped: isGrouped,
          onProfileTap: () => _openPublicProfileByUserName(msg.senderUserName),
        ),
      );
    }
    return items;
  }

  String _dateKey(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  String _formatDateLabel(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(local.year, local.month, local.day);

    if (msgDay == today) return 'Today';
    if (msgDay == yesterday) return 'Yesterday';

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}
