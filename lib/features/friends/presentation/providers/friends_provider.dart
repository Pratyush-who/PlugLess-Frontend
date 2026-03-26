import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:plugless/features/auth/data/models/auth_response_model.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

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

  factory PaginatedUsersResponse.fromJson(Map<String, dynamic> json) {
    final content =
        (json['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return PaginatedUsersResponse(
      users: content.map((e) => UserModel.fromJson(e).toEntity()).toList(),
      currentPage: json['number'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      totalElements: json['totalElements'] ?? 0,
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
  return PaginatedUsersResponse.fromJson(response.data);
});

// ── Sent Friend Requests ──────────────────────────────────────────────────
final sentRequestsProvider = FutureProvider.autoDispose
    .family<PaginatedUsersResponse, int>((ref, page) async {
  final response = await ApiClient.instance.dio.get(
    Endpoints.sentRequests,
    queryParameters: {'page': page, 'size': _pageSize},
  );
  return PaginatedUsersResponse.fromJson(response.data);
});

// ── Friends List ──────────────────────────────────────────────────────────
final friendsListProvider = FutureProvider.autoDispose
    .family<PaginatedUsersResponse, int>((ref, page) async {
  final response = await ApiClient.instance.dio.get(
    Endpoints.friendsList,
    queryParameters: {'page': page, 'size': _pageSize},
  );
  return PaginatedUsersResponse.fromJson(response.data);
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
        Endpoints.acceptFriendRequest(requesterId),
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
        Endpoints.rejectFriendRequest(requesterId),
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
