import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/auth/token_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl();

  @override
  Future<({UserEntity user, String token})> signIn({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.dio.post(
      Endpoints.signIn,
      data: {'email': email, 'password': password},
    );
    final model = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    await TokenService.instance.saveToken(model.token);
    return (user: model.user.toEntity(), token: model.token);
  }
}
