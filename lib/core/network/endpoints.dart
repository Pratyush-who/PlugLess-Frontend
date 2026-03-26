class Endpoints {
  Endpoints._();

  // Auth
  static const String signUp = '/auth/signup';
  static const String signIn = '/auth/login';

  // Users
  static const String me = '/users/me';
  static const String uploadPhoto = '/users/me/photo';
  static const String allUsers = '/users';
  static const String onlineUsers = '/users/online';
  static const String onlineStats = '/users/online/stats';
  static String userById(String id) => '/users/$id';

  // Friends
  static String sendFriendRequest(String targetId) => '/friends/request/$targetId';
  static String acceptFriendRequest(String requesterId) => '/friends/requests/$requesterId/accept';
  static String rejectFriendRequest(String requesterId) => '/friends/requests/$requesterId/reject';
  static String removeFriend(String friendId) => '/friends/$friendId';
  static const String receivedRequests = '/friends/requests/received';
  static const String sentRequests = '/friends/requests/sent';
  static const String friendsList = '/friends/list';

  // Global Chat (REST)
  static const String globalHistory = '/chat/global/history';
  static const String globalStats = '/chat/global/stats';

  // WebSocket
  static const String wsEndpoint = '/ws';
  static const String stompGlobalSend = '/app/chat.global';
  static const String stompGlobalTopic = '/topic/global';
}
