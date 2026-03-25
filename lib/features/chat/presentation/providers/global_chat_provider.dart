import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../../core/auth/auth_state_service.dart';
import '../../../../core/auth/token_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUserName,
    required this.senderDisplayName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String senderUserName;
  final String senderDisplayName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderUserName: (json['senderUserName'] ?? '').toString(),
      senderDisplayName: (json['senderDisplayName'] ?? '').toString(),
      senderAvatar: (json['senderAvatar'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderUserName': senderUserName,
        'senderDisplayName': senderDisplayName,
        'senderAvatar': senderAvatar,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

// ── State ─────────────────────────────────────────────────────────────────────

class GlobalChatState {
  const GlobalChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isConnected;
  final bool isSending;
  final String? error;

  GlobalChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isConnected,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return GlobalChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Cache key ─────────────────────────────────────────────────────────────────

const _kCachedHistory = 'cached_global_history';

// ── Notifier ──────────────────────────────────────────────────────────────────

class GlobalChatNotifier extends Notifier<GlobalChatState> {
  StompClient? _stompClient;
  bool _isBootstrapping = false;

  @override
  GlobalChatState build() {
    ref.onDispose(() {
      _stompClient?.deactivate();
      _stompClient = null;
    });
    Future.microtask(_bootstrap);
    return const GlobalChatState(isLoading: true);
  }

  Future<void> reload() async {
    if (_isBootstrapping) return;
    _stompClient?.deactivate();
    _stompClient = null;
    state = const GlobalChatState(isLoading: true);
    await _bootstrap();
  }

  Future<void> _bootstrap() async {
    _isBootstrapping = true;
    // Load history: network first, cache fallback — never blocks showing content
    await _loadHistory();
    // Connect socket: best-effort, failures shown as banner but don't clear messages
    _connectSocket().catchError((_) {
      state = state.copyWith(isConnected: false);
    });
    _isBootstrapping = false;
  }

  Future<void> _loadHistory() async {
    try {
      final resp = await ApiClient.instance.dio.get(Endpoints.globalHistory);
      final data = resp.data;
      if (data is! List) throw StateError('Bad history response');
      final msgs = data
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(growable: false);
      state =
          state.copyWith(messages: msgs, isLoading: false, clearError: true);
      _saveHistoryCache(msgs);
    } catch (_) {
      await _loadCachedHistory();
    }
  }

  Future<void> _loadCachedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedHistory);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        final msgs = list
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList(growable: false);
        state = state.copyWith(messages: msgs, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _saveHistoryCache(List<ChatMessage> msgs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kCachedHistory, jsonEncode(msgs.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _connectSocket() async {
    final token = await TokenService.instance.getToken();
    if (token == null || token.isEmpty) throw StateError('No auth token');

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
          _stompClient?.subscribe(
            destination: Endpoints.stompGlobalTopic,
            callback: (frame) {
              final body = frame.body;
              if (body == null || body.isEmpty) return;
              final decoded = jsonDecode(body);
              if (decoded is! Map<String, dynamic>) return;
              final msg = ChatMessage.fromJson(decoded);
              if (!state.messages.any((m) => m.id == msg.id)) {
                state = state.copyWith(messages: [...state.messages, msg]);
              }
            },
          );
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
              state.copyWith(isConnected: false, error: 'Connection error.');
        },
        onWebSocketError: (error) {
          final errStr = error.toString().toLowerCase();
          if (errStr.contains('401') || errStr.contains('unauthorized')) {
            AuthStateService.instance.onUnauthorized();
            return;
          }
          state = state.copyWith(
              isConnected: false, error: 'WebSocket disconnected.');
        },
        onDisconnect: (_) => state = state.copyWith(isConnected: false),
      ),
    );
    _stompClient = client;
    client.activate();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;
    final client = _stompClient;
    if (client == null || !client.connected) {
      state = state.copyWith(error: 'Not connected. Try reconnecting.');
      return;
    }
    state = state.copyWith(isSending: true, clearError: true);
    try {
      client.send(
        destination: Endpoints.stompGlobalSend,
        body: jsonEncode({'content': trimmed}),
      );
    } catch (_) {
      state = state.copyWith(error: 'Failed to send message.');
    } finally {
      state = state.copyWith(isSending: false);
    }
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

// ── Provider ──────────────────────────────────────────────────────────────────

final globalChatProvider =
    NotifierProvider<GlobalChatNotifier, GlobalChatState>(
  GlobalChatNotifier.new,
);
