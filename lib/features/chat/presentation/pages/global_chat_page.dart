import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/plugless_logo.dart';

class GlobalChatPage extends StatefulWidget {
  const GlobalChatPage({super.key});

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {
  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  StompClient? _stompClient;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSocketConnected = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _bootstrapChat();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapChat() async {
    try {
      await _loadHistory();
      await _connectSocket();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Unable to load global chat right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    final response = await ApiClient.instance.dio.get(Endpoints.globalHistory);
    final data = response.data;
    if (data is! List) {
      throw StateError('Invalid chat history response');
    }

    final history = data
        .whereType<Map<String, dynamic>>()
        .map(_ChatMessage.fromJson)
        .toList(growable: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _messages
        ..clear()
        ..addAll(history);
      _errorText = null;
    });
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token');
    }

    final wsUrl = _buildWebSocketUrl(dotenv.env['BASE_URL'] ?? '', token);

    final client = StompClient(
      config: StompConfig(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 3),
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isSocketConnected = true;
            _errorText = null;
          });

          _stompClient?.subscribe(
            destination: Endpoints.stompGlobalTopic,
            callback: (frame) {
              final body = frame.body;
              if (body == null || body.isEmpty) {
                return;
              }

              final decoded = jsonDecode(body);
              if (decoded is! Map<String, dynamic>) {
                return;
              }

              final incoming = _ChatMessage.fromJson(decoded);

              if (!mounted) {
                return;
              }

              final alreadyPresent = _messages.any((m) => m.id == incoming.id);
              if (alreadyPresent) {
                return;
              }

              setState(() {
                _messages.add(incoming);
              });
              _scrollToBottom();
            },
          );

          _scrollToBottom();
        },
        onStompError: (frame) {
          if (!mounted) {
            return;
          }
          setState(() {
            _errorText = 'Socket error: ${frame.body ?? 'Unknown'}';
            _isSocketConnected = false;
          });
        },
        onWebSocketError: (dynamic _) {
          if (!mounted) {
            return;
          }
          setState(() {
            _errorText = 'WebSocket connection failed.';
            _isSocketConnected = false;
          });
        },
        onDisconnect: (frame) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isSocketConnected = false;
          });
        },
      ),
    );

    _stompClient = client;
    client.activate();
  }

  Future<void> _sendMessage() async {
    final raw = _controller.text;
    final text = raw.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    final client = _stompClient;
    if (client == null || !client.connected) {
      setState(() {
        _errorText = 'Not connected to global chat.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorText = null;
    });

    try {
      client.send(
        destination: Endpoints.stompGlobalSend,
        body: jsonEncode({'content': text}),
      );
      _controller.clear();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Failed to send message.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _buildWebSocketUrl(String baseUrl, String token) {
    final base = Uri.parse(baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final normalizedBasePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final endpointPath = Endpoints.wsEndpoint.startsWith('/')
        ? Endpoints.wsEndpoint
        : '/${Endpoints.wsEndpoint}';

    final wsUri = base.replace(
      scheme: scheme,
      path: '$normalizedBasePath$endpointPath',
      queryParameters: {'token': token},
    );

    return wsUri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: Row(
          children: [
            const PluglessLogo(size: 14),
            const SizedBox(width: 12),
            Container(width: 1, height: 28, color: const Color(0xFF3A3A3A)),
            const SizedBox(width: 12),
            const Icon(Icons.tag_rounded, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 4),
            Text(
              'general',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _isSocketConnected ? AppColors.online : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: _bootstrapChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _errorText!,
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          _MessageInput(
            controller: _controller,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blurple),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Start the conversation!',
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _MessageTile(message: msg);
      },
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_rounded,
                  color: AppColors.textMuted, size: 22),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Message #general',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_emotions_rounded,
                  color: AppColors.textMuted, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: AppColors.blurple, size: 22),
              onPressed: isSending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final displayName = message.senderDisplayName.isNotEmpty
        ? message.senderDisplayName
        : message.senderUserName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.blurpleDark,
            foregroundColor: AppColors.textPrimary,
            backgroundImage: message.senderAvatar.isNotEmpty
                ? NetworkImage(message.senderAvatar)
                : null,
            child: message.senderAvatar.isEmpty
                ? Text(
                    displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(message.timestamp),
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ChatMessage {
  const _ChatMessage({
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

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    return _ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderUserName: (json['senderUserName'] ?? '').toString(),
      senderDisplayName: (json['senderDisplayName'] ?? '').toString(),
      senderAvatar: (json['senderAvatar'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
