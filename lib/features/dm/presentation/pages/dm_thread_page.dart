import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../providers/dm_provider.dart';

class DmThreadPage extends ConsumerStatefulWidget {
  const DmThreadPage({super.key, required this.friend});

  final UserEntity friend;

  @override
  ConsumerState<DmThreadPage> createState() => _DmThreadPageState();
}

class _DmThreadPageState extends ConsumerState<DmThreadPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(dmThreadProvider(widget.friend).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String _displayName(UserEntity user) {
    final display = user.displayName.trim();
    if (display.isNotEmpty) return display;
    return user.userName;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmThreadProvider(widget.friend));

    ref.listen<DmThreadState>(dmThreadProvider(widget.friend), (prev, next) {
      final prevLen = prev?.messages.length ?? 0;
      final nextLen = next.messages.length;
      if (nextLen > prevLen) {
        _scrollToBottom();
      }
      if (prev?.isLoading == true && !next.isLoading && nextLen > 0) {
        _scrollToBottom(animate: false);
      }
      if (next.liveError != null && next.liveError != prev?.liveError) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(next.liveError!),
              backgroundColor: const Color(0xFF2A1010),
              behavior: SnackBarBehavior.floating,
            ),
          );
        ref.read(dmThreadProvider(widget.friend).notifier).clearLiveError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF1D1D1D),
              child: Text(
                _displayName(widget.friend).substring(0, 1).toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  color: const Color(0xFFAAAAAA),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _displayName(widget.friend),
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: state.isConnected
                    ? AppColors.online
                    : const Color(0xFF5A5A5A),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!state.isConnected && !state.isLoading) const _ReconnectBanner(),
          Expanded(child: _buildMessages(state)),
          _DmInput(
            controller: _textController,
            enabled: state.isConnected,
            isSending: state.isSending,
            onSend: _send,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMessages(DmThreadState state) {
    final me = ref.watch(currentUserProvider).valueOrNull;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.blurple,
          strokeWidth: 1.6,
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Start your conversation with ${_displayName(widget.friend)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF6D6D70),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels <=
            notification.metrics.minScrollExtent + 50) {
          ref.read(dmThreadProvider(widget.friend).notifier).loadOlder();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ),
            );
          }

          final message =
              state.messages[state.isLoadingMore ? index - 1 : index];
          final isMine = me != null && message.senderId == me.id;

          return _DmBubble(
            message: message,
            isMine: isMine,
            onLongPress: isMine && message.canDelete
                ? () {
                    ref
                        .read(dmThreadProvider(widget.friend).notifier)
                        .deleteMessage(message.id);
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _DmBubble extends StatelessWidget {
  const _DmBubble({
    required this.message,
    required this.isMine,
    this.onLongPress,
  });

  final DmMessage message;
  final bool isMine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isDeleted
        ? const Color(0xFF1B1B1E)
        : (isMine ? const Color(0xFF2C6DFE) : const Color(0xFF1C1C1F));

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2D)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.isDeleted
                          ? 'This message was deleted'
                          : message.content,
                      style: GoogleFonts.inter(
                        color: message.isDeleted
                            ? const Color(0xFF9A9AA2)
                            : Colors.white,
                        fontStyle: message.isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLabel(message.timestamp, pending: message.isPending),
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFD6D6D8),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime timestamp, {required bool pending}) {
    final local = timestamp.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    if (pending) return '$h:$m · pending';
    return '$h:$m';
  }
}

class _DmInput extends StatelessWidget {
  const _DmInput({
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.inter(
                  color: const Color(0xFFF3F3F4),
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  hintText: enabled ? 'Write a message' : 'Reconnecting...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF707076),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: isSending || !enabled ? null : onSend,
              icon: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSending ? 0.45 : 1,
                child: const Icon(Icons.send_rounded, size: 18),
              ),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: const Color(0xFF131315),
      alignment: Alignment.center,
      child: Text(
        'Reconnecting...',
        style: GoogleFonts.spaceMono(
          color: const Color(0xFF8D8D95),
          fontSize: 10,
        ),
      ),
    );
  }
}
