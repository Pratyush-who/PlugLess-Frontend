import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../../core/auth/auth_state_service.dart';
import '../../../../core/auth/token_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../profile/presentation/providers/public_profile_provider.dart';

class DmMessage {
  const DmMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    required this.isDeleted,
    this.isPending = false,
  });

  final String id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime timestamp;
  final bool isDeleted;
  final bool isPending;

  bool belongsToThread({required String meId, required String friendId}) {
    return (senderId == meId && recipientId == friendId) ||
        (senderId == friendId && recipientId == meId);
  }

  bool get canDelete => !isDeleted && !isPending;

  DmMessage copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? content,
    DateTime? timestamp,
    bool? isDeleted,
    bool? isPending,
  }) {
    return DmMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      isPending: isPending ?? this.isPending,
    );
  }

  factory DmMessage.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
      }
      return '';
    }

    DateTime pickTimestamp() {
      final raw = json['timestamp'] ?? json['createdAt'] ?? json['sentAt'];
      if (raw is int) {
        final millis = raw > 9999999999 ? raw : raw * 1000;
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      final asString = raw?.toString() ?? '';
      if (asString.isNotEmpty) {
        final asInt = int.tryParse(asString);
        if (asInt != null) {
          final millis = asInt > 9999999999 ? asInt : asInt * 1000;
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }
      return DateTime.tryParse(asString) ?? DateTime.now();
    }

    bool pickDeleted() {
      final raw = json['isDeleted'] ?? json['deleted'] ?? false;
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      final text = raw.toString().toLowerCase();
      return text == 'true' || text == '1';
    }

    return DmMessage(
      id: pickString(['id', 'messageId']),
      senderId: pickString([
        'senderId',
        'senderUserId',
        'fromUserId',
        'sender_id',
      ]),
      recipientId: pickString([
        'recipientId',
        'recipientUserId',
        'receiverId',
        'toUserId',
        'recipient_id',
      ]),
      content: pickString(['content', 'message', 'text']),
      timestamp: pickTimestamp(),
      isDeleted: pickDeleted(),
    );
  }
}

class DmPreview {
  const DmPreview({required this.text, required this.timestamp});

  final String text;
  final DateTime timestamp;
}

class DmHistoryPage {
  const DmHistoryPage({
    required this.messages,
    required this.last,
  });

  final List<DmMessage> messages;
  final bool last;
}

class DmThreadState {
  const DmThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isConnected = false,
    this.isSending = false,
    this.error,
    this.liveError,
    this.hasMore = true,
  });

  final List<DmMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isConnected;
  final bool isSending;
  final String? error;
  final String? liveError;
  final bool hasMore;

  DmThreadState copyWith({
    List<DmMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isConnected,
    bool? isSending,
    String? error,
    bool clearError = false,
    String? liveError,
    bool clearLiveError = false,
    bool? hasMore,
  }) {
    return DmThreadState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      liveError: clearLiveError ? null : (liveError ?? this.liveError),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class DmThreadNotifier extends StateNotifier<DmThreadState> {
  DmThreadNotifier(this.ref, this.friend) : super(const DmThreadState()) {
    ref.onDispose(() {
      _stompClient?.deactivate();
      _stompClient = null;
    });
    Future.microtask(_bootstrap);
  }

  final Ref ref;
  final UserEntity friend;

  StompClient? _stompClient;
  String? _meId;
  int _nextPage = 1;

  Future<void> _bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final me = await ref.read(currentUserProvider.future);
      _meId = me.id;
      final page = await _fetchHistory(friendId: friend.id, page: 0, size: 50);
      final sorted = [...page.messages]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      state = state.copyWith(
        isLoading: false,
        messages: sorted,
        hasMore: !page.last,
        clearError: true,
      );
      _nextPage = 1;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load message history.',
      );
    }

    _connectSocket();
  }

  Future<void> reload() async {
    _stompClient?.deactivate();
    _stompClient = null;
    _nextPage = 1;
    await _bootstrap();
  }

  Future<void> loadOlder() async {
    final meId = _meId;
    if (meId == null || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page =
          await _fetchHistory(friendId: friend.id, page: _nextPage, size: 50);
      final older = page.messages
          .where((m) =>
              m.belongsToThread(meId: meId, friendId: friend.id) &&
              !state.messages.any((existing) => existing.id == m.id))
          .toList();
      older.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingMore: false,
        hasMore: !page.last,
      );
      _nextPage += 1;
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Could not load older messages.',
      );
    }
  }

  void clearLiveError() {
    state = state.copyWith(clearLiveError: true);
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    final meId = _meId;
    final client = _stompClient;

    if (trimmed.isEmpty || state.isSending || meId == null) return;
    if (client == null || !client.connected) {
      state = state.copyWith(error: 'Not connected. Reconnecting...');
      return;
    }

    final optimistic = DmMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderId: meId,
      recipientId: friend.id,
      content: trimmed,
      timestamp: DateTime.now(),
      isDeleted: false,
      isPending: true,
    );

    state = state.copyWith(
      isSending: true,
      clearError: true,
      messages: [...state.messages, optimistic],
    );

    try {
      client.send(
        destination: Endpoints.stompDmSend,
        body: jsonEncode({'recipientId': friend.id, 'content': trimmed}),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to send message.');
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  void deleteMessage(String messageId) {
    final meId = _meId;
    final client = _stompClient;
    if (meId == null || client == null || !client.connected) return;

    DmMessage? message;
    for (final m in state.messages) {
      if (m.id == messageId) {
        message = m;
        break;
      }
    }
    if (message == null || message.senderId != meId || !message.canDelete) {
      return;
    }

    state = state.copyWith(
      messages: state.messages
          .map(
            (m) => m.id == messageId
                ? m.copyWith(
                    isDeleted: true,
                    content: 'This message was deleted',
                    isPending: false,
                  )
                : m,
          )
          .toList(growable: false),
    );

    try {
      client.send(
        destination: Endpoints.stompDmDelete,
        body: jsonEncode({'messageId': messageId}),
      );
    } catch (_) {
      state = state.copyWith(error: 'Could not delete message.');
    }
  }

  Future<void> _connectSocket() async {
    final token = await TokenService.instance.getToken();
    if (token == null || token.isEmpty) return;

    final wsUrl = _buildWsUrl(dotenv.env['BASE_URL'] ?? '', token);

    final client = StompClient(
      config: StompConfig(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (_) {
          state = state.copyWith(isConnected: true, clearError: true);
          _subscribeQueues();
        },
        onStompError: (frame) {
          final msg = (frame.headers['message'] ?? '').toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('forbidden')) {
            AuthStateService.instance.onUnauthorized();
            return;
          }
          state =
              state.copyWith(isConnected: false, error: 'DM connection error.');
        },
        onWebSocketError: (error) {
          final errStr = error.toString().toLowerCase();
          if (errStr.contains('401') || errStr.contains('unauthorized')) {
            AuthStateService.instance.onUnauthorized();
            return;
          }
          state = state.copyWith(
            isConnected: false,
            error: 'Disconnected. Reconnecting...',
          );
        },
        onDisconnect: (_) => state = state.copyWith(isConnected: false),
      ),
    );

    _stompClient = client;
    client.activate();
  }

  void _subscribeQueues() {
    _stompClient?.subscribe(
      destination: Endpoints.stompDmMessagesQueue,
      callback: (frame) {
        final body = frame.body;
        final meId = _meId;
        if (body == null || body.isEmpty || meId == null) return;

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) return;

        final incoming = DmMessage.fromJson(decoded);

        final pendingIndex = state.messages.indexWhere(
          (m) =>
              m.isPending &&
              m.senderId == meId &&
              m.recipientId == friend.id &&
              m.content == incoming.content &&
              incoming.timestamp.difference(m.timestamp).abs().inSeconds <= 60,
        );

        if (pendingIndex >= 0) {
          final updated = [...state.messages];
          updated[pendingIndex] = incoming.copyWith(
            id: incoming.id.isEmpty
                ? updated[pendingIndex].id
                : incoming.id,
            senderId: incoming.senderId.isEmpty ? meId : incoming.senderId,
            recipientId: incoming.recipientId.isEmpty
                ? friend.id
                : incoming.recipientId,
            isPending: false,
          );
          state = state.copyWith(messages: updated);
          return;
        }

        if (!incoming.belongsToThread(meId: meId, friendId: friend.id)) {
          return;
        }

        if (incoming.id.isNotEmpty &&
            state.messages.any((m) => m.id == incoming.id)) {
          return;
        }

        final appendable = incoming.id.isEmpty
            ? incoming.copyWith(
                id: 'srv-${incoming.timestamp.microsecondsSinceEpoch}',
              )
            : incoming;

        state = state.copyWith(messages: [...state.messages, appendable]);
      },
    );

    _stompClient?.subscribe(
      destination: Endpoints.stompDmUpdatesQueue,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) return;

        final type = (decoded['type'] ?? '').toString().toUpperCase();
        final messageId = (decoded['messageId'] ?? '').toString();
        if (type != 'DELETED' || messageId.isEmpty) return;

        state = state.copyWith(
          messages: state.messages
              .map(
                (m) => m.id == messageId
                    ? m.copyWith(
                        isDeleted: true,
                        content: 'This message was deleted',
                        isPending: false,
                      )
                    : m,
              )
              .toList(growable: false),
        );
      },
    );

    _stompClient?.subscribe(
      destination: Endpoints.stompUserErrors,
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        state = state.copyWith(liveError: body);
      },
    );
  }

  Future<DmHistoryPage> _fetchHistory({
    required String friendId,
    required int page,
    required int size,
  }) async {
    Response<dynamic> response;
    try {
      response = await ApiClient.instance.dio.get(
        Endpoints.dmHistoryFallback(friendId),
        queryParameters: {'page': page, 'size': size},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      response = await ApiClient.instance.dio.get(
        Endpoints.dmHistory(friendId),
        queryParameters: {'page': page, 'size': size},
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final raw = data['content'];
      final list = raw is List ? raw : const [];
      final messages = list
          .whereType<Map<String, dynamic>>()
          .map(DmMessage.fromJson)
          .toList(growable: false);
      final isLast = data['last'] == true;
      return DmHistoryPage(messages: messages, last: isLast);
    }

    if (data is List) {
      final messages = data
          .whereType<Map<String, dynamic>>()
          .map(DmMessage.fromJson)
          .toList(growable: false);
      return DmHistoryPage(messages: messages, last: messages.length < size);
    }

    throw StateError('Invalid DM history response');
  }

  String _buildWsUrl(String baseUrl, String token) {
    final base = Uri.parse(baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final ep = Endpoints.wsEndpoint.startsWith('/')
        ? Endpoints.wsEndpoint
        : '/${Endpoints.wsEndpoint}';
    return base.replace(
      scheme: scheme,
      path: '$basePath$ep',
      queryParameters: {'token': token},
    ).toString();
  }
}

final dmThreadProvider = StateNotifierProvider.autoDispose
    .family<DmThreadNotifier, DmThreadState, UserEntity>((ref, friend) {
  return DmThreadNotifier(ref, friend);
});

final dmFriendsProvider = FutureProvider<List<UserEntity>>((ref) async {
  final me = await ref.watch(currentUserProvider.future);
  final allUsers = await ref.watch(allPublicUsersProvider.future);

  final friends = allUsers.where((u) => me.friendIds.contains(u.id)).toList()
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

  return friends;
});

final dmPreviewProvider = FutureProvider.autoDispose
    .family<DmPreview?, String>((ref, friendId) async {
  try {
    final response = await ApiClient.instance.dio.get(
      Endpoints.dmHistoryFallback(friendId),
      queryParameters: {'page': 0, 'size': 1},
    );
    final data = response.data;
    final list = data is Map<String, dynamic>
        ? (data['content'] as List? ?? const [])
        : (data is List ? data : const []);
    if (list.isEmpty) return null;

    final msg = DmMessage.fromJson((list.first as Map).cast<String, dynamic>());
    return DmPreview(
      text: msg.isDeleted ? 'This message was deleted' : msg.content,
      timestamp: msg.timestamp,
    );
  } on DioException catch (e) {
    if (e.response?.statusCode != 404) return null;
    final fallback = await ApiClient.instance.dio.get(
      Endpoints.dmHistory(friendId),
      queryParameters: {'page': 0, 'size': 1},
    );
    final data = fallback.data;
    final list = data is Map<String, dynamic>
        ? (data['content'] as List? ?? const [])
        : (data is List ? data : const []);
    if (list.isEmpty) return null;

    final msg = DmMessage.fromJson((list.first as Map).cast<String, dynamic>());
    return DmPreview(
      text: msg.isDeleted ? 'This message was deleted' : msg.content,
      timestamp: msg.timestamp,
    );
  } catch (_) {
    return null;
  }
});
