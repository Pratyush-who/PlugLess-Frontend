import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../auth/data/models/auth_response_model.dart';
import '../../../auth/domain/entities/user_entity.dart';

final allPublicUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final response = await ApiClient.instance.dio.get(Endpoints.allUsers);
  final data = response.data;
  if (data is! List) return const [];

  final users = data
      .whereType<Map<String, dynamic>>()
      .map((e) => UserModel.fromJson(e).toEntity())
      .toList(growable: false);

  users.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return users;
});

final publicUserByIdProvider =
    FutureProvider.family<UserEntity, String>((ref, userId) async {
  final response = await ApiClient.instance.dio.get(Endpoints.userById(userId));
  final data = response.data;
  if (data is! Map<String, dynamic>) {
    throw StateError('Invalid public user response');
  }
  return UserModel.fromJson(data).toEntity();
});

final publicUserByUserNameProvider =
    FutureProvider.family<UserEntity?, String>((ref, userName) async {
  final normalized = userName.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  final users = await ref.watch(allPublicUsersProvider.future);
  final match = users.where((u) => u.userName.toLowerCase() == normalized);
  if (match.isEmpty) return null;

  return ref.watch(publicUserByIdProvider(match.first.id).future);
});

class FriendRequestActionsState {
  const FriendRequestActionsState({
    this.pendingIds = const <String>{},
    this.sentIds = const <String>{},
  });

  final Set<String> pendingIds;
  final Set<String> sentIds;

  FriendRequestActionsState copyWith({
    Set<String>? pendingIds,
    Set<String>? sentIds,
  }) {
    return FriendRequestActionsState(
      pendingIds: pendingIds ?? this.pendingIds,
      sentIds: sentIds ?? this.sentIds,
    );
  }
}

class FriendRequestActionsNotifier extends Notifier<FriendRequestActionsState> {
  @override
  FriendRequestActionsState build() => const FriendRequestActionsState();

  Future<void> sendRequest(String targetId) async {
    if (state.pendingIds.contains(targetId) ||
        state.sentIds.contains(targetId)) {
      return;
    }

    state = state.copyWith(pendingIds: {...state.pendingIds, targetId});
    try {
      await ApiClient.instance.dio.post(Endpoints.sendFriendRequest(targetId));
      state = state.copyWith(
        pendingIds: {...state.pendingIds}..remove(targetId),
        sentIds: {...state.sentIds, targetId},
      );
    } catch (_) {
      state =
          state.copyWith(pendingIds: {...state.pendingIds}..remove(targetId));
      rethrow;
    }
  }
}

final friendRequestActionsProvider =
    NotifierProvider<FriendRequestActionsNotifier, FriendRequestActionsState>(
  FriendRequestActionsNotifier.new,
);
