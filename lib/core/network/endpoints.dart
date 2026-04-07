class Endpoints {
  Endpoints._();

  // Auth
  static const String signUp = '/auth/signup';
  static const String signIn = '/auth/login';
  static const String logout = '/auth/logout';

  // Users
  static const String me = '/users/me';
  static const String uploadPhoto = '/users/me/photo';
  static const String allUsers = '/users';
  static const String onlineUsers = '/users/online';
  static const String onlineStats = '/users/online/stats';
  static String userById(String id) => '/users/$id';

  // Friends
  static String sendFriendRequest(String targetId) =>
      '/friends/request/$targetId';
  static const String acceptFriendRequest = '/friends/requests/accept';
  static const String rejectFriendRequest = '/friends/requests/reject';
  static String removeFriend(String friendId) => '/friends/$friendId';
  static const String receivedRequests = '/friends/requests/received';
  static const String sentRequests = '/friends/requests/sent';
  static const String friendsList = '/friends';

  // Global Chat (REST)
  static const String globalHistory = '/chat/global/history';
  static const String globalStats = '/chat/global/stats';

  // Direct Messages (REST)
  static String dmHistory(String friendUserId) =>
      '/api/messages/history/$friendUserId';
  static String dmHistoryFallback(String friendUserId) =>
      '/messages/history/$friendUserId';

  // WebSocket
  static const String wsEndpoint = '/ws';
  static const String stompGlobalSend = '/app/chat.global';
  static const String stompGlobalTopic = '/topic/global';
  static const String stompUserErrors = '/user/queue/errors';
  static const String stompDmSend = '/app/chat/dm/send';
  static const String stompDmDelete = '/app/chat/dm/delete';
  static const String stompDmMessagesQueue = '/user/queue/messages';
  static const String stompDmUpdatesQueue = '/user/queue/message-updates';
}
