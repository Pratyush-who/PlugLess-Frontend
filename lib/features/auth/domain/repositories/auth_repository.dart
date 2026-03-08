import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// POST /auth/login — returns user + token, saves token to prefs.
  Future<({UserEntity user, String token})> signIn({
    required String email,
    required String password,
  });
}
