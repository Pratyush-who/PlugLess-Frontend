import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plugless/features/profile/presentation/widgets/public_profile_atoms.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../profile/presentation/widgets/public_profile_dialog.dart';
import '../providers/friends_provider.dart';

enum FriendItemAction { accept, reject, remove }

class FriendRequestItem extends ConsumerWidget {
  const FriendRequestItem({
    super.key,
    required this.user,
    required this.action,
    this.isProcessing = false,
    this.onAction,
  });

  final UserEntity user;
  final FriendItemAction action;
  final bool isProcessing;
  final VoidCallback? onAction;

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
                onTap: () => showPublicProfileDialog(context, userId: user.id),
                child: PublicProfileAvatar(user: user, size: 56),
              ),
              const SizedBox(width: 12),
              // Name and Username
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      showPublicProfileDialog(context, userId: user.id),
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
                      Text(
                        '@${user.userName}',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF8B8B91),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          // Action Buttons
          const SizedBox(height: 14),
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    switch (action) {
      case FriendItemAction.accept:
        return _buildAcceptRejectButtons(context, ref);
      case FriendItemAction.reject:
        return SizedBox.shrink(); // Handled in accept case
      case FriendItemAction.remove:
        return _buildRemoveButton(context, ref);
    }
  }

  Widget _buildAcceptRejectButtons(BuildContext context, WidgetRef ref) {
    final friendActions = ref.watch(friendActionsProvider);
    final isProcessing = friendActions.processingIds.contains(user.id);

    return Row(
      children: [
        // Accept Button
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isProcessing
                    ? const Color(0xFF2A2A2D)
                    : const Color(0xFF2C6DFE),
                foregroundColor:
                    isProcessing ? const Color(0xFF8A8A8F) : Colors.white,
                disabledBackgroundColor: const Color(0xFF2A2A2D),
                disabledForegroundColor: const Color(0xFF8A8A8F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(friendActionsProvider.notifier)
                            .acceptRequest(user.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${user.displayName} added to friends.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to accept request: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Accept',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Reject Button
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isProcessing
                    ? const Color(0xFF2A2A2D)
                    : const Color(0xFF37373C),
                foregroundColor: isProcessing
                    ? const Color(0xFF8A8A8F)
                    : const Color(0xFFB5BAC1),
                disabledBackgroundColor: const Color(0xFF2A2A2D),
                disabledForegroundColor: const Color(0xFF8A8A8F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(friendActionsProvider.notifier)
                            .rejectRequest(user.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request declined.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to reject request: $e'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: Text(
                'Reject',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoveButton(BuildContext context, WidgetRef ref) {
    final friendActions = ref.watch(friendActionsProvider);
    final isProcessing = friendActions.processingIds.contains(user.id);

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isProcessing ? const Color(0xFF2A2A2D) : const Color(0xFF37373C),
          foregroundColor:
              isProcessing ? const Color(0xFF8A8A8F) : const Color(0xFFB5BAC1),
          disabledBackgroundColor: const Color(0xFF2A2A2D),
          disabledForegroundColor: const Color(0xFF8A8A8F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: isProcessing
            ? null
            : () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                      'Remove Friend?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFF2F2F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to remove ${user.displayName} from your friends?',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB5BAC1),
                        fontSize: 14,
                      ),
                    ),
                    backgroundColor: const Color(0xFF141416),
                    surfaceTintColor: Colors.transparent,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF5865F2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Remove',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7C7C82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await ref
                        .read(friendActionsProvider.notifier)
                        .removeFriend(user.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${user.displayName} removed from friends.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to remove friend: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
        icon: const Icon(Icons.person_remove_rounded, size: 18),
        label: Text(
          'Remove Friend',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
