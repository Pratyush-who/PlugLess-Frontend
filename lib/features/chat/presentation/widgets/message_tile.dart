import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/global_chat_provider.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.message,
    required this.isGrouped,
    this.onProfileTap,
  });

  final ChatMessage message;
  final bool isGrouped;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final displayName = message.senderDisplayName.isNotEmpty
        ? message.senderDisplayName
        : message.senderUserName;

    if (isGrouped) {
      // Compact: indent to align with full message text (16 + 36 avatar + 12 gap = 64)
      return Padding(
        padding: const EdgeInsets.fromLTRB(64, 1, 16, 1),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    GestureDetector(
                      onTap: onProfileTap,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        displayName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF2F2F2),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
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
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(local.year, local.month, local.day);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (msgDay == today) return 'Today at $time';
    if (msgDay == yesterday) return 'Yesterday at $time';
    return '${local.day}/${local.month}/${local.year} $time';
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
