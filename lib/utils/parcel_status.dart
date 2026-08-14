import '../models/models.dart';

class StatusFilterOption {
  const StatusFilterOption({required this.value, required this.label});

  /// `all` ou valeur `current_status` API.
  final String value;
  final String label;
}

/// Filtres par onglet — RelayPackages.js (7384-7456), hors admin.
List<StatusFilterOption> statusFiltersForTab(ExpeditionTab tab) {
  switch (tab) {
    case ExpeditionTab.reception:
      return const [
        StatusFilterOption(value: 'all', label: 'Tous les statuts'),
        StatusFilterOption(value: 'EN_TRANSIT', label: 'En transit'),
        StatusFilterOption(
          value: 'EN_ATTENTE_RETRAIT',
          label: 'En attente de retrait',
        ),
        StatusFilterOption(value: 'RETIRE', label: 'Retiré / Livré'),
        StatusFilterOption(value: 'RETOURNE', label: 'Retourné'),
        StatusFilterOption(value: 'ANNULE', label: 'Annulé'),
      ];
    case ExpeditionTab.expedition:
      return const [
        StatusFilterOption(value: 'all', label: 'Tous les statuts'),
        StatusFilterOption(
          value: 'A_EXPEDIER',
          label: 'À expédier ou en Stock',
        ),
        StatusFilterOption(value: 'EXPEDIE', label: 'Expédié'),
        StatusFilterOption(value: 'EN_TRANSIT', label: 'En transit'),
        StatusFilterOption(
          value: 'EN_ATTENTE_RETRAIT',
          label: 'En attente de retrait',
        ),
        StatusFilterOption(value: 'RETIRE', label: 'Retiré'),
        StatusFilterOption(value: 'RETOURNE', label: 'Retourné'),
        StatusFilterOption(value: 'LIVRE', label: 'Livré'),
        StatusFilterOption(value: 'EN_LIVRAISON', label: 'En livraison'),
        StatusFilterOption(
          value: 'ECHEC_LIVRAISON',
          label: 'Échec de livraison',
        ),
      ];
    case ExpeditionTab.stock:
      return const [
        StatusFilterOption(value: 'all', label: 'Tous les statuts'),
        StatusFilterOption(
          value: 'A_EXPEDIER',
          label: 'À expédier ou en Stock',
        ),
        StatusFilterOption(value: 'EN_TRANSIT', label: 'En transit'),
        StatusFilterOption(
          value: 'EN_ATTENTE_RETRAIT',
          label: 'En attente de retrait',
        ),
        StatusFilterOption(value: 'RETROUVE', label: 'Retrouvé'),
      ];
  }
}

String normalizeParcelStatus(String? raw) {
  return (raw ?? '')
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll(' ', '_')
      .trim();
}

List<String> userRelayIds(KatianUser? user) {
  if (user == null) return [];
  final ids = <String>{};
  final relais = user.relayIds;
  if (relais is List) {
    for (final id in relais) {
      ids.add('$id');
    }
  } else if (relais != null) {
    ids.add('$relais');
  }
  final rp = user.relayPoint;
  if (rp != null && rp.id > 0) {
    ids.add('${rp.id}');
  }
  return ids.toList();
}

String? relayIdFromRaw(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map) return '${raw['id'] ?? ''}';
  return '$raw';
}

String? destinationRelayId(KatianExpedition parcel) {
  final raw = parcel.raw;
  return relayIdFromRaw(
    raw['pointrelais_recep_id'] ??
        raw['pointrelais_recep'] ??
        raw['point_relais_destinataire'],
  );
}

/// Colis A_EXPEDIER dont la destination finale est le point relais connecté.
bool isShipToYouPending(KatianExpedition parcel, KatianUser? user) {
  if (parcel.isReturn) return false;
  if (normalizeParcelStatus(parcel.currentStatus) != 'a_expedier') {
    return false;
  }
  final destId = destinationRelayId(parcel);
  if (destId == null || destId.isEmpty) return false;
  return userRelayIds(user).contains(destId);
}

/// Destination finale = gare de l'utilisateur connecté.
bool isFinalDestinationForUser(KatianExpedition parcel, KatianUser? user) {
  final relayIds = userRelayIds(user);
  if (relayIds.isEmpty) return false;
  final destId = destinationRelayId(parcel);
  if (destId == null || destId.isEmpty) return false;
  return relayIds.contains(destId);
}

/// Colis physiquement chez le point relais connecté.
bool isAtUserRelay(KatianExpedition parcel, KatianUser? user) {
  final relayIds = userRelayIds(user);
  if (relayIds.isEmpty) return false;

  final currentId = relayIdFromRaw(
    parcel.raw['current_relay_id'] ?? parcel.raw['current_relay_id_id'],
  );
  if (currentId != null &&
      currentId.isNotEmpty &&
      relayIds.contains(currentId)) {
    return true;
  }

  final originId = relayIdFromRaw(
    parcel.raw['pointrelais'] ??
        parcel.raw['pointrelais_id'] ??
        parcel.raw['pointrelais_d_envoi_id'],
  );
  if (originId != null &&
      relayIds.contains(originId) &&
      normalizeParcelStatus(parcel.currentStatus) == 'a_expedier' &&
      (currentId == null || currentId.isEmpty)) {
    return true;
  }

  return false;
}

/// Colis éligibles au wizard Départ — aligné RelayPackages (A_EXPEDIER + EN_TRANSIT intermédiaire).
bool isDepartableParcel(KatianExpedition parcel, KatianUser? user) {
  if (parcel.isReturn) return false;

  final status = normalizeParcelStatus(parcel.currentStatus);
  if (status == 'a_expedier') {
    return isAtUserRelay(parcel, user) || isShipToYouPending(parcel, user);
  }
  if (status == 'en_transit') {
    if (!isAtUserRelay(parcel, user)) return false;
    return !isFinalDestinationForUser(parcel, user);
  }
  return false;
}
