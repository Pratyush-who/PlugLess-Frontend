class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.userName,
    required this.displayName,
    this.bio,
    this.status,
    this.profileImageUrl,
    this.lastSeen,
    this.isOnline = false,
    this.friendIds = const [],
    this.friendRequestIds = const [],
    required this.createdAt,
  });

  final String id;
  final String email;
  final String userName;
  final String displayName;
  final String? bio;
  final String? status;
  final String? profileImageUrl;
  final String? lastSeen;
  final bool isOnline;
  final List<String> friendIds;
  final List<String> friendRequestIds;
  final String createdAt;
}
