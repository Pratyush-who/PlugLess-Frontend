import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../auth/data/models/auth_response_model.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Fetches online users from /users/online.
/// Not autoDispose so the count badge stays alive across tab switches.
final onlineUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final resp = await ApiClient.instance.dio.get(Endpoints.onlineUsers);
  final data = resp.data;
  if (data is! List) return [];
  return data
      .whereType<Map<String, dynamic>>()
      .map((e) => UserModel.fromJson(e).toEntity())
      .toList();
});
