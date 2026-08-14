import '../models/bordereau.dart';
import 'api_client.dart';

class BordereauService {
  BordereauService(this._api);

  final ApiClient _api;

  Future<List<BordereauExpedition>> list({int limit = 50}) async {
    final res = await _api.dio.get('/bordereaux/', queryParameters: {'limit': limit});
    final data = res.data;
    if (data is! List) return [];
    return data
        .map((e) => BordereauExpedition.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<BordereauExpedition> detail(int id) async {
    final res = await _api.dio.get('/bordereaux/$id/');
    return BordereauExpedition.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<BordereauExpedition> byNumber(String number) async {
    final encoded = Uri.encodeComponent(number.trim());
    final res = await _api.dio.get('/bordereaux/by-number/$encoded/');
    return BordereauExpedition.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<BordereauReceiveResult> receiveBulk(int bordereauId) async {
    final res = await _api.dio.post('/bordereaux/$bordereauId/receive/');
    return BordereauReceiveResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Étape 2 — planification (bordereau PLANNED, données date/heure/commentaire stockées).
  Future<BordereauExpedition> planDeparture({
    required List<int> parcelIds,
    required DateTime departureDate,
    String? departureTime,
    String? comment,
  }) {
    return _create(
      parcelIds: parcelIds,
      departureDate: departureDate,
      departureTime: departureTime,
      comment: comment,
      confirm: false,
    );
  }

  /// Création + expédition en une fois (alternative).
  Future<BordereauExpedition> createAndShip({
    required List<int> parcelIds,
    required DateTime departureDate,
    String? departureTime,
    String? comment,
    required String carNumber,
    required String driverName,
    required String driverPhone,
  }) {
    return _create(
      parcelIds: parcelIds,
      departureDate: departureDate,
      departureTime: departureTime,
      comment: comment,
      carNumber: carNumber,
      driverName: driverName,
      driverPhone: driverPhone,
      confirm: true,
    );
  }

  /// Étape 3 — confirmation avec infos car/conducteur.
  Future<BordereauExpedition> confirm({
    required int bordereauId,
    required String carNumber,
    required String driverName,
    required String driverPhone,
    int? carId,
    int? convoyeurId,
    String? departureTime,
    String? comment,
  }) async {
    final res = await _api.dio.patch('/bordereaux/$bordereauId/confirm/', data: {
      'car_number': carNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      if (carId != null) 'car_id': carId,
      if (convoyeurId != null) 'convoyeur_id': convoyeurId,
      if (departureTime != null) 'departure_time': departureTime,
      if (comment != null) 'comment': comment,
    });
    return BordereauExpedition.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<BordereauExpedition> _create({
    required List<int> parcelIds,
    required DateTime departureDate,
    String? departureTime,
    String? comment,
    String? carNumber,
    String? driverName,
    String? driverPhone,
    required bool confirm,
  }) async {
    final res = await _api.dio.post('/bordereaux/', data: {
      'parcel_ids': parcelIds,
      'departure_date': _formatDate(departureDate),
      if (departureTime != null && departureTime.isNotEmpty) 'departure_time': departureTime,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (carNumber != null) 'car_number': carNumber,
      if (driverName != null) 'driver_name': driverName,
      if (driverPhone != null) 'driver_phone': driverPhone,
      'confirm': confirm,
    });
    return BordereauExpedition.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
