import '../models/models.dart';
import 'api_client.dart';

class ExpeditionService {
  ExpeditionService(this._api);

  final ApiClient _api;

  Future<List<KatianExpedition>> list({
    required String mode,
    String? currentStatus,
    String? search,
    String? period,
    int? relayId,
  }) async {
    final params = <String, dynamic>{'mode': mode};
    if (currentStatus != null && currentStatus.isNotEmpty) {
      params['current_status'] = currentStatus;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (period != null && period.isNotEmpty) {
      params['period'] = period;
    }
    if (relayId != null && relayId > 0) {
      params['id_pointrelais'] = relayId;
    }
    final res = await _api.dio.get('/expeditions/', queryParameters: params);
    return _parseList(res.data);
  }

  Future<List<KatianExpedition>> stock({
    int? relayId,
    String? period,
  }) async {
    final params = <String, dynamic>{};
    if (relayId != null) {
      params['relay_id'] = relayId;
    }
    if (period != null && period.isNotEmpty) {
      params['period'] = period;
    }
    final res = await _api.dio.get(
      '/expeditions/stock/',
      queryParameters: params.isEmpty ? null : params,
    );
    return _parseList(res.data);
  }

  Future<List<KatianExpedition>> receptionables({
    String? search,
    int? relayId,
    /// `pending` = liste « À réceptionner » (A_EXPEDIER + EXPEDIE).
    /// `receivable` = action scan (EXPEDIE uniquement).
    String scope = 'receivable',
    String? period,
  }) async {
    final params = <String, dynamic>{'scope': scope};
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (relayId != null && relayId > 0) {
      params['relay_id'] = relayId;
    }
    if (period != null && period.isNotEmpty) {
      params['period'] = period;
    }
    final res = await _api.dio.get(
      '/expeditions/receptionables/',
      queryParameters: params,
    );
    return _parseList(res.data);
  }

  Future<KatianExpedition> detail(int id) async {
    final res = await _api.dio.get('/expeditions/$id/');
    return KatianExpedition.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<KatianExpedition> update(int id, Map<String, dynamic> data) async {
    final res = await _api.dio.patch('/expeditions/$id/update/', data: data);
    return KatianExpedition.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<KatianExpedition> receive(int id, {required bool isReturn}) {
    final data = <String, dynamic>{
      'type_de_receptions': 'depot_transporteur',
    };
    if (isReturn) {
      data['return_status'] = 'RETURN_EXPEDIE';
    } else {
      data['current_status'] = 'EN_TRANSIT';
    }
    return update(id, data);
  }

  /// Recherche retrait — aligné RelayPackages searchParcelByPickupCode (mode réception).
  Future<List<KatianExpedition>> searchPickup(String code) {
    return list(mode: 'reception', search: code.trim());
  }

  /// Retrait destinataire — aligné handlePickup (RelayPackages.js).
  Future<KatianExpedition> withdraw(
    int id, {
    String? recipientPhone,
    int? relayId,
  }) {
    final data = <String, dynamic>{
      'current_status': 'RETIRE',
      'pickup_date': DateTime.now().toUtc().toIso8601String(),
      'pickup_method': 'code_retrait',
    };
    if (recipientPhone != null && recipientPhone.trim().isNotEmpty) {
      data['recipient_phone'] = recipientPhone.trim();
    }
    if (relayId != null && relayId > 0) {
      data['current_relay_id'] = relayId;
    }
    return update(id, data);
  }

  Future<KatianExpedition> expedier(
    int id, {
    required String driverName,
    required String driverPhoneOrId,
  }) {
    // Comme RelayStock.js : "Expédier" → DEPART (EXPEDIE), pas EN_TRANSIT
    return update(id, {
      'current_status': 'EXPEDIE',
      'current_relay_id': null,
      'driver_name': driverName,
      'driver_phone_or_id': driverPhoneOrId,
      'type_rammassage': 'bordereau de transit',
    });
  }

  Future<TraceabilityData> traceability(int id) async {
    final res = await _api.dio.get('/expeditions/$id/traceability/');
    return TraceabilityData.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<RelayPointOption>> relayPoints() async {
    final res = await _api.dio.get('/relay-points/');
    final list = res.data is List ? res.data as List : const [];
    return list
        .whereType<Map>()
        .map((e) => RelayPointOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<KatianExpedition> assignRelay(int id, int? relayId) {
    return update(id, {'pointrelais': relayId});
  }

  List<KatianExpedition> _parseList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map ? (data['results'] as List?) : null);
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => KatianExpedition.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
