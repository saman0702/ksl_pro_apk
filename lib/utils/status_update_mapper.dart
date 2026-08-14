import '../models/models.dart';
import 'parcel_status.dart';

/// Mapping handleUpdateStatus (RelayPackages.js) → payload PATCH expedition.
class StatusUpdateMapper {
  static Map<String, dynamic>? buildUpdate({
    required String uiStatus,
    required ExpeditionTab tab,
    required KatianExpedition parcel,
  }) {
    final status = normalizeParcelStatus(parcel.currentStatus);
    final isReturn = parcel.isReturn;
    final returnStatus = normalizeParcelStatus(parcel.returnStatus);

    if (uiStatus == 'received') {
      if (isReturn) {
        if (returnStatus != 'return_expedie') {
          throw StatusUpdateException(
            'Ce colis en retour doit être en statut RETURN_EXPEDIE pour être réceptionné.',
          );
        }
        return {
          'type_de_receptions': 'depot_transporteur',
          'return_status': 'RETURN_EXPEDIE',
        };
      }
      if (status != 'expedie') {
        throw StatusUpdateException(
          'Ce colis doit être expédié (EXPEDIE) pour être réceptionné.',
        );
      }
      return {
        'current_status': 'EN_TRANSIT',
        'type_de_receptions': 'depot_transporteur',
      };
    }

    if (tab == ExpeditionTab.reception || tab == ExpeditionTab.expedition) {
      return _mapForReceptionOrExpedition(uiStatus, status);
    }
    return _mapForReceptionOrExpedition(uiStatus, status);
  }

  static Map<String, dynamic>? _mapForReceptionOrExpedition(
    String uiStatus,
    String status,
  ) {
    switch (uiStatus) {
      case 'pending':
        return {'current_status': 'A_EXPEDIER'};
      case 'pickup_transit':
        return {'current_status': 'EXPEDIE'};
      case 'in_transit':
        return {'current_status': 'EXPEDIE', 'current_relay_id': null};
      case 'delivered':
        if (status != 'en_attente_retrait') {
          throw StatusUpdateException(
            'Le retrait ne peut se faire que pour un colis en attente de retrait.',
          );
        }
        return {'current_status': 'RETIRE'};
      case 'returned':
        if (status != 'en_attente_retrait' && status != 'en_transit') {
          throw StatusUpdateException(
            'Le retour ne peut se faire que pour un colis en attente de retrait ou en transit.',
          );
        }
        return {'current_status': 'RETOURNE'};
      case 'cancelled':
        if (!['a_expedier', 'en_transit', 'expedie'].contains(status)) {
          throw StatusUpdateException(
            'L\'annulation ne peut se faire que pour un colis à expédier, en transit ou expédié.',
          );
        }
        return {'current_status': 'ANNULE'};
      case 'lost':
        if (!['en_transit', 'expedie', 'en_attente_retrait'].contains(status)) {
          throw StatusUpdateException(
            'La perte ne peut être déclarée que pour un colis en transit, expédié ou en attente de retrait.',
          );
        }
        return {'current_status': 'PERDUE'};
      case 'found':
        if (status != 'perdue') {
          throw StatusUpdateException(
            'Le colis ne peut être retrouvé que s\'il était déclaré perdu.',
          );
        }
        return {'current_status': 'RETROUVE'};
      case 'reship':
        if (status != 'retrouve') {
          throw StatusUpdateException(
            'La réexpédition ne peut se faire que pour un colis retrouvé.',
          );
        }
        return {'current_status': 'EXPEDIE', 'current_relay_id': null};
      default:
        throw StatusUpdateException('Statut non pris en charge');
    }
  }
}

class StatusUpdateException implements Exception {
  StatusUpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}
