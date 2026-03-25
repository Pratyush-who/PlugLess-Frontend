import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely managing authentication tokens.
/// Uses flutter_secure_storage to store tokens in platform-specific secure storage.
class TokenService {
  TokenService._();
  static final instance = TokenService._();

  static const String _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();

  /// Saves the token securely.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieves the saved token.
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  /// Deletes the saved token.
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Checks if a token exists.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
