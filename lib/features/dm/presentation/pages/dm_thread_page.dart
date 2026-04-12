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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Container(height: 1, color: const Color(0xFF1A1A1A)),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF888888),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFF1D1D1D),
              child: Text(
                _displayName(widget.friend).substring(0, 1).toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  color: const Color(0xFFAAAAAA),
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _displayName(widget.friend),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                color: Color(0xFF2F2F33), size: 42),
            const SizedBox(height: 12),
            Text(
              'No messages yet',
              style: GoogleFonts.bebasNeue(
                color: const Color(0xFF54545A),
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Start your conversation with ${_displayName(widget.friend)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF6D6D70),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildLoadingMore() {
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
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (state.isLoadingMore && index == 0) {
            return buildLoadingMore();
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
        : (isMine ? const Color(0xFF2C6DFE) : const Color(0xFF1A1A1A));

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMine ? 20 : 16),
      bottomRight: Radius.circular(isMine ? 20 : 16),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                border: Border.all(color: const Color(0xFF252525)),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.isDeleted
                          ? 'This message was deleted'
                          : message.content,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontStyle: message.isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeLabel(message.timestamp, pending: message.isPending),
                      style: GoogleFonts.spaceMono(
                        color: isMine
                            ? const Color(0xFFE8EEFF)
                            : const Color(0xFF9A9AA2),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF252525)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.inter(
                  color: enabled
                      ? const Color(0xFFDCDDDE)
                      : const Color(0xFF77777E),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: enabled ? 'Write a message' : 'Connecting...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF4A4A4A),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isSending ? 0.45 : 1,
              child: IconButton(
                onPressed: isSending || !enabled ? null : onSend,
                icon: const Icon(Icons.send_rounded, size: 18),
                color: const Color(0xFFCCCCCC),
              ),
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
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: const [
          Color(0xFF0A0A0A),
          Colors.white,
          Colors.white,
          Color(0xFF0A0A0A),
        ],
        stops: const [0.0, 0.18, 0.82, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: Container(
        height: 32,
        color: const Color(0xFF0A0A0A),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: const Color(0xFF555555),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Connecting...',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFF555555),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
