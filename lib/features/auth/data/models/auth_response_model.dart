import '../../domain/entities/user_entity.dart';

class AuthResponseModel {
  const AuthResponseModel({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserModel {
  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String?,
      status: json['status'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      lastSeen: json['lastSeen'] as String?,
      isOnline: (json['isOnline'] ?? json['online']) as bool? ?? false,
      friendIds:
          (json['friendIds'] as List?)?.map((e) => e as String).toList() ?? [],
      friendRequestIds: (json['friendRequestIds'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        userName: userName,
        displayName: displayName,
        bio: bio,
        status: status,
        profileImageUrl: profileImageUrl,
        lastSeen: lastSeen,
        isOnline: isOnline,
        friendIds: friendIds,
        friendRequestIds: friendRequestIds,
        createdAt: createdAt,
      );
}
