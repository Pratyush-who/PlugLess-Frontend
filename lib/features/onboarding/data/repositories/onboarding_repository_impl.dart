import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../auth/data/models/auth_response_model.dart';
import '../../../auth/domain/entities/user_entity.dart';

class OnboardingRepositoryImpl {
  const OnboardingRepositoryImpl();

  /// POST /auth/signup (multipart) — creates account, saves token, returns user.
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String userName,
    required String displayName,
    String? bio,
    File? photo,
  }) async {
    final fields = <String, dynamic>{
      'email': email,
      'password': password,
      'userName': userName,
      'displayName': displayName,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      if (photo != null)
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'avatar.jpg',
        ),
    };

    final response = await ApiClient.instance.dio.post(
      Endpoints.signUp,
      data: FormData.fromMap(fields),
    );

    final model = AuthResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', model.token);
    return model.user.toEntity();
  }

  /// PUT /users/me — update profile for an already-authenticated user.
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? status,
  }) async {
    await ApiClient.instance.dio.put(
      Endpoints.me,
      data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (status != null) 'status': status,
      },
    );
  }

  /// POST /users/me/photo — upload a new profile photo.
  Future<String?> uploadPhoto(File imageFile) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'avatar.jpg',
      ),
    });
    final response = await ApiClient.instance.dio.post(
      Endpoints.uploadPhoto,
      data: formData,
    );
    return response.data['profileImageUrl'] as String?;
  }
}
