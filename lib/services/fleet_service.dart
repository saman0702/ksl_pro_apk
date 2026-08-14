import '../models/tp_fleet.dart';
import 'api_client.dart';

class FleetService {
  FleetService(this._api);

  final ApiClient _api;

  Future<List<TpCarOption>> listActiveCars() async {
    final res = await _api.dio.get('/fleet/cars/');
    final data = res.data;
    if (data is! List) return [];
    return data
        .map((e) => TpCarOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<TpConvoyeurOption>> listActiveDrivers() async {
    final res = await _api.dio.get('/fleet/drivers/');
    final data = res.data;
    if (data is! List) return [];
    return data
        .map((e) => TpConvoyeurOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
