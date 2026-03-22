import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../data/models/auth_response_model.dart';
import '../../domain/entities/user_entity.dart';

const _kCachedUser = 'cached_user_me';

final currentUserProvider = FutureProvider<UserEntity>((ref) async {
  try {
    final response = await ApiClient.instance.dio.get(Endpoints.me);
    final data = response.data as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedUser, jsonEncode(data));
    return UserModel.fromJson(data).toEntity();
  } catch (_) {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kCachedUser);
    if (cached != null) {
      return UserModel.fromJson(
              jsonDecode(cached) as Map<String, dynamic>)
          .toEntity();
    }
    rethrow;
  }
});
