import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/global_chat_provider.dart';
import '../providers/online_users_provider.dart';

class GlobalChatPage extends ConsumerStatefulWidget {
  const GlobalChatPage({super.key, required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  ConsumerState<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends ConsumerState<GlobalChatPage> {
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

  void _showCommunityPanel() {
    ref.invalidate(onlineUsersProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: false,
      builder: (_) => const _CommunityPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(globalChatProvider);

    // Auto-scroll when messages arrive or initial load completes
    ref.listen<GlobalChatState>(globalChatProvider, (prev, next) {
      final prevLen = prev?.messages.length ?? 0;
      final nextLen = next.messages.length;
      if (nextLen > prevLen) _scrollToBottom();
      // Scroll to bottom once when history finishes loading
      if (prev?.isLoading == true && !next.isLoading && nextLen > 0) {
        _scrollToBottom(animate: false);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
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
          // Community button with online count badge
          Consumer(builder: (context, ref, _) {
            final onlineAsync = ref.watch(onlineUsersProvider);
            final count = onlineAsync.valueOrNull?.length ?? 0;
            return GestureDetector(
              onTap: _showCommunityPanel,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.people_alt_rounded,
                          color: Color(0xFF888888), size: 22),
                      onPressed: _showCommunityPanel,
                    ),
                    if (count > 0)
                      Positioned(
                        top: 8,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.online,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
          // Error banner
          if (chat.error != null)
            _ErrorBanner(
              message: chat.error!,
              onRetry: () =>
                  ref.read(globalChatProvider.notifier).reload(),
            ),

          // Message list
          Expanded(child: _buildBody(chat)),

          // Input
          _MessageInput(
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

    if (chat.messages.isEmpty && !chat.isLoading) {
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

    // Build list with date dividers
    final items = _buildItems(chat.messages);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }

  /// Interleaves date dividers between messages.
  List<Widget> _buildItems(List<ChatMessage> messages) {
    final List<Widget> items = [];
    String? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final dateKey = _dateKey(msg.timestamp);

      if (dateKey != lastDate) {
        items.add(_DateDivider(label: _formatDateLabel(msg.timestamp)));
        lastDate = dateKey;
      }

      // Determine if this message should be grouped (same sender, within 5 min)
      final prev = i > 0 ? messages[i - 1] : null;
      final isGrouped = prev != null &&
          prev.senderUserName == msg.senderUserName &&
          _dateKey(prev.timestamp) == dateKey &&
          msg.timestamp.difference(prev.timestamp).inMinutes < 5;

      items.add(_MessageTile(message: msg, isGrouped: isGrouped));
    }
    return items;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return 'Today';
    if (msgDay == yesterday) return 'Yesterday';

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Date Divider ──────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Expanded(
              child: Divider(color: Color(0xFF1E1E1E), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF444444),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          const Expanded(
              child: Divider(color: Color(0xFF1E1E1E), thickness: 1)),
        ],
      ),
    );
  }
}

// ── Message Tile ──────────────────────────────────────────────────────────────

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.isGrouped});

  final ChatMessage message;
  final bool isGrouped;

  @override
  Widget build(BuildContext context) {
    final displayName = message.senderDisplayName.isNotEmpty
        ? message.senderDisplayName
        : message.senderUserName;

    if (isGrouped) {
      // Compact: no avatar/name, just indent + content
      return Padding(
        padding: const EdgeInsets.fromLTRB(56, 1, 16, 1),
        child: Text(
          message.content,
          style: GoogleFonts.inter(
            color: const Color(0xFFDCDDDE),
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
      );
    }

    // Full message with avatar, name, timestamp
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: message.senderAvatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: message.senderAvatar,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _AvatarFallback(name: displayName),
                    )
                  : _AvatarFallback(name: displayName),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + timestamp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF2F2F2),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4F545C),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Content
                Text(
                  message.content,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDCDDDE),
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (msgDay == today) return 'Today at $time';
    final yesterday = today.subtract(const Duration(days: 1));
    if (msgDay == yesterday) return 'Yesterday at $time';
    return '${dt.day}/${dt.month}/${dt.year} $time';
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
          fontSize: 16,
          color: const Color(0xFF666666),
        ),
      ),
    );
  }
}

// ── Message Input ─────────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.isConnected,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isConnected;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: Color(0xFF4A4A4A), size: 20),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(
                  color: const Color(0xFFDCDDDE),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isConnected
                      ? 'Message #general'
                      : 'Connecting…',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF4A4A4A),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isSending ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Color(0xFFCCCCCC), size: 18),
                onPressed: isSending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFCC4444), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: const Color(0xFFCC4444),
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'RETRY',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFCC4444),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Community Panel ───────────────────────────────────────────────────────────

class _CommunityPanel extends ConsumerWidget {
  const _CommunityPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(onlineUsersProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 0),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                usersAsync.when(
                  data: (users) => Text(
                    'ONLINE NOW — ${users.length}',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF888888),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  loading: () => Text(
                    'ONLINE NOW',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF555555),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  error: (_, __) => Text(
                    'ONLINE NOW',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF555555),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
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

          // User list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: usersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF444444),
                    strokeWidth: 1.5,
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Could not load members.',
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFF555555),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No one online right now.',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF444444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (_, i) => _OnlineUserTile(user: users[i]),
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
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
          // Avatar
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
                              _OnlineAvatarFallback(name: user.displayName),
                        )
                      : _OnlineAvatarFallback(name: user.displayName),
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _OnlineAvatarFallback extends StatelessWidget {
  const _OnlineAvatarFallback({required this.name});

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
