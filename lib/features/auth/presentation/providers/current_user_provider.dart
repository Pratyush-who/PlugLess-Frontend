import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../data/models/auth_response_model.dart';
import '../../domain/entities/user_entity.dart';

final currentUserProvider = FutureProvider<UserEntity>((ref) async {
  final response = await ApiClient.instance.dio.get(Endpoints.me);
  return UserModel.fromJson(response.data as Map<String, dynamic>).toEntity();
});
