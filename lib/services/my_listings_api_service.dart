import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/listing_model.dart';
import 'api_service.dart';
import 'auth_local_storage.dart';

class MyListingsApiService {
  MyListingsApiService._();
  static final MyListingsApiService instance = MyListingsApiService._();

  final http.Client _client = http.Client();
  final String _baseUrl = ApiService.baseUrlProd;

  Future<_ApiResult> _post(String path, Map<String, dynamic> data) async {
    final uri = Uri.parse('$_baseUrl/$path');
    final user = await AuthLocalStorage.instance.getUser();
    if (user != null && !data.containsKey('user_id')) {
      data['user_id'] = user.id;
    }
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    map['status'] = res.statusCode;
    return _ApiResult(map);
  }

  Future<_ApiResult> _get(String path, Map<String, dynamic> params) async {
    final user = await AuthLocalStorage.instance.getUser();
    if (user != null && !params.containsKey('user_id')) {
      params['user_id'] = user.id;
    }
    final uri = Uri.parse('$_baseUrl/$path').replace(queryParameters: params.map((k, v) => MapEntry(k, '$v')));
    final res = await _client.get(uri);
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    map['status'] = res.statusCode;
    return _ApiResult(map);
  }

  Future<List<ListingModel>> getMyListings({
    String? status,
    String? type,
    String? search,
    int page = 1,
    int perPage = 20,
    bool? boosted,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (boosted != null) params['boosted'] = boosted ? '1' : '0';

    final res = await _get('my_listings.php', params);
    if (!res.success) throw Exception(res.message ?? 'Erreur lors du chargement');
    final items = res.data['items'] as List<dynamic>? ?? [];
    return items.map((e) => ListingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, int>> getMyListingStats() async {
    final res = await _get('my_listing_stats.php', {});
    if (!res.success) throw Exception(res.message ?? 'Erreur stats');
    final stats = res.data['stats'] as Map<String, dynamic>? ?? {};
    return stats.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<void> updateStatus(int listingId, String status) async {
    final res = await _post('update_listing_status.php', {'listing_id': listingId, 'status': status});
    if (!res.success) throw Exception(res.message ?? 'Impossible de changer le statut');
  }

  Future<void> deleteListing(int listingId) async {
    final res = await _post('delete_listing.php', {'listing_id': listingId});
    if (!res.success) throw Exception(res.message ?? 'Impossible de supprimer');
  }
}

class _ApiResult {
  final Map<String, dynamic> data;
  _ApiResult(this.data);
  bool get success => data['success'] == true;
  String? get message => data['message']?.toString();
}
