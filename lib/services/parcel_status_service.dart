import '../models/models.dart';
import '../utils/parcel_actions.dart';
import '../utils/parcel_status.dart';
import '../utils/status_update_mapper.dart';
import 'expedition_service.dart';

class ParcelStatusService {
  ParcelStatusService(this._expeditions);

  final ExpeditionService _expeditions;

  Future<KatianExpedition> applyAction(
    KatianExpedition parcel,
    ParcelActionKind action, {
    String? driverName,
    String? driverPhoneOrId,
  }) async {
    final status = normalizeParcelStatus(parcel.currentStatus);
    final returnStatus = normalizeParcelStatus(parcel.returnStatus);

    switch (action) {
      case ParcelActionKind.receive:
        if (!parcel.canReceive) {
          throw ParcelStatusException(
            'Réception impossible : le colis doit être au statut Expédié.',
          );
        }
        return _expeditions.receive(parcel.id, isReturn: parcel.isReturn);

      case ParcelActionKind.expedier:
        if (parcel.isReturn &&
            (returnStatus == 'return_en_transit' ||
                returnStatus == 'return_requested')) {
          final returnStatusToSend =
              returnStatus == 'return_requested' ? 'RETURN_REQUESTED' : 'RETURN_EXPEDIE';
          return _expeditions.update(parcel.id, {
            'return_status': returnStatusToSend,
            if (driverName != null) 'driver_name': driverName,
            if (driverPhoneOrId != null) 'driver_phone_or_id': driverPhoneOrId,
            'type_rammassage': 'bordereau de retour',
          });
        }
        return _expeditions.expedier(
          parcel.id,
          driverName: driverName ?? '',
          driverPhoneOrId: driverPhoneOrId ?? '',
        );

      case ParcelActionKind.cancel:
        _assertAny(status, ['a_expedier', 'en_transit', 'expedie']);
        return _expeditions.update(parcel.id, {'current_status': 'ANNULE'});

      case ParcelActionKind.found:
        _assert(status == 'perdue', 'Colis non déclaré perdu');
        return _expeditions.update(parcel.id, {'current_status': 'RETROUVE'});

      case ParcelActionKind.reship:
        _assert(status == 'retrouve', 'Colis non retrouvé');
        return _expeditions.update(parcel.id, {
          'current_status': 'EXPEDIE',
          'current_relay_id': null,
        });

      case ParcelActionKind.withdraw:
        _assert(status == 'en_attente_retrait', 'Colis non en attente de retrait');
        return _expeditions.withdraw(parcel.id);

      case ParcelActionKind.returnParcel:
        _assert(
          status == 'en_attente_retrait' || status == 'en_transit',
          'Retour impossible pour ce statut',
        );
        return _expeditions.update(parcel.id, {'current_status': 'RETOURNE'});

      case ParcelActionKind.declareLost:
        _assert(
          status == 'en_transit' ||
              status == 'expedie' ||
              status == 'en_attente_retrait',
          'Perte impossible pour ce statut',
        );
        return _expeditions.update(parcel.id, {'current_status': 'PERDUE'});
    }
  }

  Future<KatianExpedition> applyUiStatus(
    KatianExpedition parcel,
    String uiStatus,
    ExpeditionTab tab,
  ) async {
    final payload = StatusUpdateMapper.buildUpdate(
      uiStatus: uiStatus,
      tab: tab,
      parcel: parcel,
    );
    if (payload == null) {
      throw ParcelStatusException('Aucune mise à jour');
    }
    return _expeditions.update(parcel.id, payload);
  }

  Future<KatianExpedition> markDelivered(KatianExpedition parcel) =>
      applyUiStatus(parcel, 'delivered', ExpeditionTab.reception);

  Future<KatianExpedition> markReturned(KatianExpedition parcel) =>
      applyUiStatus(parcel, 'returned', ExpeditionTab.reception);

  Future<KatianExpedition> markLost(KatianExpedition parcel) =>
      applyUiStatus(parcel, 'lost', ExpeditionTab.reception);

  Future<KatianExpedition> assignRelay(
    KatianExpedition parcel,
    int? relayId,
  ) =>
      _expeditions.assignRelay(parcel.id, relayId);

  void _assert(bool condition, String message) {
    if (!condition) throw ParcelStatusException(message);
  }

  void _assertAny(String status, List<String> allowed) {
    if (!allowed.contains(status)) {
      throw ParcelStatusException('Action impossible pour le statut actuel');
    }
  }
}

class ParcelStatusException implements Exception {
  ParcelStatusException(this.message);
  final String message;

  @override
  String toString() => message;
}
