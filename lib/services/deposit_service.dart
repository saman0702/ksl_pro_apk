import '../models/models.dart';
import 'api_client.dart';

class DepositService {
  DepositService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> createForCompagnie(Map<String, dynamic> payload) async {
    final res = await _api.dio.post('/expeditions/compagny/', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<RelayPointOption>> loadCompagnieRelays() async {
    final res = await _api.dio.get('/relay-points/');
    final list = res.data is List ? res.data as List : const [];
    return list
        .whereType<Map>()
        .map((e) => RelayPointOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  KatianExpedition parseCreatedExpedition(Map<String, dynamic> data) {
    return KatianExpedition.fromJson(data);
  }
}
