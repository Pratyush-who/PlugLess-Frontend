import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../dm/presentation/pages/dm_thread_page.dart';
import '../providers/public_profile_provider.dart';
import 'public_profile_atoms.dart';

class PublicProfileBody extends ConsumerWidget {
  const PublicProfileBody({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    final actionState = ref.watch(friendRequestActionsProvider);
    final button = _friendButtonConfig(
      me: me,
      target: user,
      pending: actionState.pendingIds.contains(user.id),
      sentThisSession: actionState.sentIds.contains(user.id),
    );

    Future<void> sendFriendRequest() async {
      if (!button.enabled) return;
      try {
        await ref
            .read(friendRequestActionsProvider.notifier)
            .sendRequest(user.id);
        ref.invalidate(currentUserProvider);
        ref.invalidate(allPublicUsersProvider);
        ref.invalidate(publicUserByIdProvider(user.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request sent.')),
          );
        }
      } on DioException catch (e) {
        final msg = e.response?.data is Map<String, dynamic>
            ? (e.response?.data['message']?.toString() ??
                'Could not send request.')
            : 'Could not send request.';
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send request.')),
          );
        }
      }
    }

    void openDm() {
      if (!button.enabled) return;
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      rootNavigator.pop();
      rootNavigator.push(
        MaterialPageRoute(
          builder: (_) => DmThreadPage(friend: user),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PublicProfileHeader(),
          const SizedBox(height: 8),
          Row(
            children: [
              PublicProfileAvatar(user: user, size: 74),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(
                        color: AppColors.profileTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.userName}',
                      style: GoogleFonts.spaceMono(
                        color: AppColors.profileTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if ((user.status ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        user.status!.trim(),
                        style: GoogleFonts.inter(
                          color: AppColors.profileTextTertiary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PublicProfileMetaRow(
              label: 'Friends', value: '${user.friendIds.length}'),
          PublicProfileMetaRow(
              label: 'Member Since', value: _dateOnly(user.createdAt)),
          if ((user.lastSeen ?? '').trim().isNotEmpty)
            PublicProfileMetaRow(
                label: 'Last Seen', value: _dateOnly(user.lastSeen!)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.profileBioBg,
              border: Border.all(color: const Color(0xFF1F1F23)),
            ),
            child: Text(
              user.bio?.trim().isNotEmpty == true
                  ? user.bio!.trim()
                  : 'No bio yet.',
              style: GoogleFonts.inter(
                color: AppColors.profileTextTertiary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: button.enabled
                    ? const Color(0xFF2C6DFE)
                    : const Color(0xFF2A2A2D),
                foregroundColor:
                    button.enabled ? Colors.white : const Color(0xFF8A8A8F),
                disabledBackgroundColor: const Color(0xFF2A2A2D),
                disabledForegroundColor: const Color(0xFF8A8A8F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: button.enabled
                  ? (button.action == _ProfilePrimaryAction.message
                      ? openDm
                      : sendFriendRequest)
                  : null,
              child: Text(
                button.label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _FriendButtonConfig _friendButtonConfig({
    required UserEntity? me,
    required UserEntity target,
    required bool pending,
    required bool sentThisSession,
  }) {
    if (pending) {
      return const _FriendButtonConfig(
        enabled: false,
        label: 'Sending...',
        action: _ProfilePrimaryAction.friendRequest,
      );
    }
    if (me == null) {
      return const _FriendButtonConfig(
        enabled: false,
        label: 'Loading...',
        action: _ProfilePrimaryAction.friendRequest,
      );
    }
    if (me.id == target.id) {
      return const _FriendButtonConfig(
        enabled: false,
        label: 'This is you',
        action: _ProfilePrimaryAction.friendRequest,
      );
    }
    if (me.friendIds.contains(target.id)) {
      return const _FriendButtonConfig(
        enabled: true,
        label: 'Message',
        action: _ProfilePrimaryAction.message,
      );
    }
    if (me.friendRequestIds.contains(target.id)) {
      return const _FriendButtonConfig(
        enabled: false,
        label: 'Request received',
        action: _ProfilePrimaryAction.friendRequest,
      );
    }
    if (target.friendRequestIds.contains(me.id) || sentThisSession) {
      return const _FriendButtonConfig(
        enabled: false,
        label: 'Request sent',
        action: _ProfilePrimaryAction.friendRequest,
      );
    }
    return const _FriendButtonConfig(
      enabled: true,
      label: 'Send Friend Request',
      action: _ProfilePrimaryAction.friendRequest,
    );
  }

  String _dateOnly(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }
}

class _FriendButtonConfig {
  const _FriendButtonConfig({
    required this.enabled,
    required this.label,
    required this.action,
  });

  final bool enabled;
  final String label;
  final _ProfilePrimaryAction action;
}

enum _ProfilePrimaryAction {
  message,
  friendRequest,
}
