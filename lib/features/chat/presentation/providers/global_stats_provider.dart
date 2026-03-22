import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

/// Fetches total active users from GET /chat/global/stats
final globalStatsProvider = FutureProvider<int>((ref) async {
  final resp = await ApiClient.instance.dio.get(Endpoints.globalStats);
  final data = resp.data;
  if (data is! Map) return 0;
  final map = Map<String, dynamic>.from(data);
  if (map.isEmpty) return 0;
  // Sum all numeric values (e.g. {"online": 5} or {"total": 5})
  return map.values
      .whereType<num>()
      .fold<int>(0, (sum, v) => sum + v.toInt());
});
