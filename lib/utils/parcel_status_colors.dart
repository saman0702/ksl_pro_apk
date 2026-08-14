import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/expedition.dart';
import 'parcel_status.dart';

/// Couleur principale associée à un statut colis (texte, icône, bordure).
Color parcelStatusColorFromNormalized(String? normalized) {
  switch (normalizeParcelStatus(normalized)) {
    case 'a_expedier':
      return KatianColors.orange;
    case 'expedie':
      return KatianColors.blue;
    case 'en_transit':
      return KatianColors.purple;
    case 'en_attente_retrait':
      return KatianColors.amber;
    case 'retire':
    case 'livre':
      return KatianColors.green;
    case 'en_livraison':
      return KatianColors.teal;
    case 'retourne':
      return KatianColors.brown;
    case 'annule':
      return KatianColors.statusGrey;
    case 'perdue':
      return KatianColors.redDark;
    case 'retrouve':
      return KatianColors.teal;
    case 'echec_livraison':
      return KatianColors.red;
    case 'return_expedie':
      return KatianColors.blue;
    case 'return_en_transit':
      return KatianColors.purple;
    case 'return_arrived':
      return KatianColors.amber;
    case 'return_requested':
      return KatianColors.orange;
    default:
      return KatianColors.statusGrey;
  }
}

Color parcelStatusColorFromRaw({
  String? currentStatus,
  String? returnStatus,
  bool isReturn = false,
}) {
  if (isReturn) {
    final rs = normalizeParcelStatus(returnStatus);
    if (rs.isNotEmpty) {
      return parcelStatusColorFromNormalized(rs);
    }
  }
  return parcelStatusColorFromNormalized(currentStatus);
}

Color parcelStatusColor(KatianExpedition parcel) {
  return parcelStatusColorFromRaw(
    currentStatus: parcel.currentStatus,
    returnStatus: parcel.returnStatus,
    isReturn: parcel.isReturn,
  );
}

/// Fond léger pour badge / chip de statut.
Color parcelStatusBackgroundColor(Color color) {
  return color.withValues(alpha: 0.12);
}

/// Couleur à partir du libellé affiché (ex. « Expédié », « En transit »).
Color parcelStatusColorFromLabel(String label) {
  final key = label
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll(' ', '_')
      .trim();
  switch (key) {
    case 'a_expedier':
    case 'à_expedier':
      return KatianColors.orange;
    case 'expedie':
    case 'expédié':
      return KatianColors.blue;
    case 'en_transit':
      return KatianColors.purple;
    case 'en_attente_de_retrait':
      return KatianColors.amber;
    case 'retire':
    case 'retiré':
    case 'livre':
    case 'livré':
      return KatianColors.green;
    case 'retour_expedie':
    case 'retour_expédié':
      return KatianColors.blue;
    case 'retourne':
    case 'retourné':
      return KatianColors.brown;
    case 'annule':
    case 'annulé':
      return KatianColors.statusGrey;
    case 'perdue':
      return KatianColors.redDark;
    case 'retrouve':
    case 'retrouvé':
      return KatianColors.teal;
    default:
      return parcelStatusColorFromNormalized(key);
  }
}
