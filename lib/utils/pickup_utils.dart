import '../models/models.dart';
import 'parcel_status.dart';

/// Correspondance exacte code_retrait — aligné RelayPackages.js.
KatianExpedition? matchPickupByCode(List<KatianExpedition> list, String code) {
  final q = code.trim().toLowerCase();
  if (q.isEmpty) return null;
  for (final p in list) {
    final pickup = (p.pickupCode ?? '').trim().toLowerCase();
    if (pickup.isNotEmpty && pickup == q) return p;
  }
  return null;
}

bool isPickupEligible(KatianExpedition parcel) {
  if (parcel.isReturn) return false;
  return normalizeParcelStatus(parcel.currentStatus) == 'en_attente_retrait';
}
