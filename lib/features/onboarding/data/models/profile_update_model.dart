class ProfileUpdateModel {
  const ProfileUpdateModel({
    this.username,
    this.displayName,
    this.bio,
  });

  final String? username;
  final String? displayName;
  final String? bio;

  Map<String, dynamic> toJson() => {
        if (username != null) 'username': username,
        if (displayName != null) 'display_name': displayName,
        if (bio != null) 'bio': bio,
      };
}
