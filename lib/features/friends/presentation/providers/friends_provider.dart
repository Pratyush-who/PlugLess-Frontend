import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plugless/features/auth/data/models/auth_response_model.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

/// For SENT requests — prefers 'recipient' (the person we sent to).
UserEntity _extractUser(Map<String, dynamic> item) {
  final nested = item['recipient'] ??
      item['requester'] ??
      item['sender'] ??
      item['user'];
  if (nested is Map<String, dynamic>) {
    return UserModel.fromJson(nested).toEntity();
  }
  return UserModel.fromJson(item).toEntity();
}

/// For RECEIVED requests — prefers 'requester' (the person who sent to us).
UserEntity _extractReceivedUser(Map<String, dynamic> item) {
  final nested = item['requester'] ??
      item['sender'] ??
      item['recipient'] ??
      item['user'];
  if (nested is Map<String, dynamic>) {
    return UserModel.fromJson(nested).toEntity();
  }
  return UserModel.fromJson(item).toEntity();
}

// ── Pagination Models ──────────────────────────────────────────────────────
const int _pageSize = 20;

class PaginatedUsersResponse {
  final List<UserEntity> users;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const PaginatedUsersResponse({
    required this.users,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  factory PaginatedUsersResponse.fromJson(
    dynamic raw, {
    UserEntity Function(Map<String, dynamic>) extractor = _extractUser,
  }) {
    // Plain array response: [ {...}, {...} ]
    if (raw is List) {
      final List<UserEntity> users = raw
          .whereType<Map<String, dynamic>>()
          .map(extractor)
          .toList(growable: false);
      return PaginatedUsersResponse(
        users: users,
        currentPage: 0,
        totalPages: 1,
        totalElements: users.length,
      );
    }

    final json = raw as Map<String, dynamic>;

    // Find the list — Spring uses 'content', others use various keys
    final rawList = json['content'] ??
        json['users'] ??
        json['data'] ??
        json['friends'] ??
        json['requests'] ??
        json['sentRequests'] ??
        json['receivedRequests'] ??
        json['pendingRequests'] ??
        [];

    final List<UserEntity> users = (rawList as List)
        .whereType<Map<String, dynamic>>()
        .map(extractor)
        .toList(growable: false);

    final totalPages =
        (json['totalPages'] ?? json['total_pages'] ?? json['pages'] ?? 1)
            as int;

    return PaginatedUsersResponse(
      users: users,
      currentPage:
          (json['number'] ?? json['page'] ?? json['currentPage'] ?? 0) as int,
      totalPages: totalPages < 1 ? 1 : totalPages,
      totalElements:
          (json['totalElements'] ?? json['total'] ?? users.length) as int,
    );
  }
}

// ── Received Friend Requests ──────────────────────────────────────────────
final receivedRequestsProvider = FutureProvider.autoDispose
    .family<PaginatedUsersResponse, int>((ref, page) async {
  final response = await ApiClient.instance.dio.get(
    Endpoints.receivedRequests,
    queryParameters: {'page': page, 'size': _pageSize},
  );
  return PaginatedUsersResponse.fromJson(
    response.data as dynamic,
    extractor: _extractReceivedUser,
  );
});

// ── Sent Friend Requests ──────────────────────────────────────────────────
final sentRequestsProvider = FutureProvider.autoDispose
    .family<PaginatedUsersResponse, int>((ref, page) async {
  final response = await ApiClient.instance.dio.get(
    Endpoints.sentRequests,
    queryParameters: {'page': page, 'size': _pageSize},
  );
  return PaginatedUsersResponse.fromJson(response.data as dynamic);
});

// ── Friends List ──────────────────────────────────────────────────────────
final friendsListProvider = FutureProvider.autoDispose
    .family<PaginatedUsersResponse, int>((ref, page) async {
  final response = await ApiClient.instance.dio.get(
    Endpoints.friendsList,
    queryParameters: {'page': page, 'size': _pageSize},
  );
  return PaginatedUsersResponse.fromJson(response.data as dynamic);
});

// ── Friend Actions State ────────────────────────────────────────────────────
class FriendActionsState {
  final Set<String> processingIds; // IDs currently being processed

  const FriendActionsState({this.processingIds = const <String>{}});

  FriendActionsState copyWith({Set<String>? processingIds}) {
    return FriendActionsState(
        processingIds: processingIds ?? this.processingIds);
  }
}

class FriendActionsNotifier extends Notifier<FriendActionsState> {
  @override
  FriendActionsState build() => const FriendActionsState();

  /// Accept a friend request
  Future<void> acceptRequest(String requesterId) async {
    if (state.processingIds.contains(requesterId)) return;

    state =
        state.copyWith(processingIds: {...state.processingIds, requesterId});
    try {
      await ApiClient.instance.dio.post(
        Endpoints.acceptFriendRequest,
        queryParameters: {'requesterId': requesterId},
      );
      // Invalidate providers to refresh data
      ref.invalidate(currentUserProvider);
      ref.invalidate(receivedRequestsProvider);
      ref.invalidate(friendsListProvider);
      ref.invalidate(sentRequestsProvider);
    } finally {
      state = state.copyWith(
        processingIds: {...state.processingIds}..remove(requesterId),
      );
    }
  }

  /// Reject a friend request
  Future<void> rejectRequest(String requesterId) async {
    if (state.processingIds.contains(requesterId)) return;

    state =
        state.copyWith(processingIds: {...state.processingIds, requesterId});
    try {
      await ApiClient.instance.dio.post(
        Endpoints.rejectFriendRequest,
        queryParameters: {'requesterId': requesterId},
      );
      // Invalidate providers to refresh data
      ref.invalidate(currentUserProvider);
      ref.invalidate(receivedRequestsProvider);
      ref.invalidate(sentRequestsProvider);
    } finally {
      state = state.copyWith(
        processingIds: {...state.processingIds}..remove(requesterId),
      );
    }
  }

  /// Remove a friend
  Future<void> removeFriend(String friendId) async {
    if (state.processingIds.contains(friendId)) return;

    state = state.copyWith(processingIds: {...state.processingIds, friendId});
    try {
      await ApiClient.instance.dio.delete(
        Endpoints.removeFriend(friendId),
      );
      // Invalidate providers to refresh data
      ref.invalidate(currentUserProvider);
      ref.invalidate(friendsListProvider);
      ref.invalidate(receivedRequestsProvider);
    } finally {
      state = state.copyWith(
        processingIds: {...state.processingIds}..remove(friendId),
      );
    }
  }
}

final friendActionsProvider =
    NotifierProvider<FriendActionsNotifier, FriendActionsState>(
  FriendActionsNotifier.new,
);

// ── Convenience Constants ──────────────────────────────────────────────────
const int pageSize = _pageSize;
