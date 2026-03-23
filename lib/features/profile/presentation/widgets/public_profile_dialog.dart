import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/public_profile_provider.dart';
import 'public_profile_atoms.dart';
import 'public_profile_body.dart';

Future<void> showPublicProfileDialog(
  BuildContext context, {
  String? userId,
  String? userName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => PublicProfileDialog(userId: userId, userName: userName),
  );
}

class PublicProfileDialog extends ConsumerWidget {
  const PublicProfileDialog({
    super.key,
    this.userId,
    this.userName,
  }) : assert(userId != null || userName != null);

  final String? userId;
  final String? userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = userId != null
        ? ref.watch(publicUserByIdProvider(userId!))
        : ref.watch(publicUserByUserNameProvider(userName!));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF27272A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: userAsync.when(
            loading: () => const SizedBox(
              height: 240,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
            ),
            error: (_, __) => PublicProfileErrorState(userName: userName),
            data: (user) {
              if (user == null) {
                return PublicProfileErrorState(userName: userName);
              }
              return PublicProfileBody(user: user);
            },
          ),
        ),
      ),
    );
  }
}
