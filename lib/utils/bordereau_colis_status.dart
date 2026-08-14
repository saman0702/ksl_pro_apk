import '../models/bordereau.dart';

String bordereauColisStatusLabel(BordereauColisLine colis) {
  final raw = colis.isReturn ? colis.returnStatus : colis.currentStatus;
  if (raw == null || raw.isEmpty) return '—';
  switch (raw.toUpperCase().replaceAll(' ', '_')) {
    case 'A_EXPEDIER':
      return 'À expédier';
    case 'EXPEDIE':
      return 'Expédié';
    case 'RETURN_EXPEDIE':
      return 'Retour expédié';
    case 'EN_TRANSIT':
      return 'En transit';
    case 'RETIRE':
      return 'Retiré';
    case 'LIVRE':
      return 'Livré';
    case 'ANNULE':
      return 'Annulé';
    default:
      return raw.replaceAll('_', ' ');
  }
}

String bordereauStatusLabel(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'CONFIRMED':
      return 'Confirmé';
    case 'PLANNED':
      return 'Planifié';
    case 'DRAFT':
      return 'Brouillon';
    case 'RECEIVED':
      return 'Reçu';
    default:
      return status ?? '—';
  }
}

class BordereauColisStats {
  BordereauColisStats(this.colis);

  final List<BordereauColisLine> colis;

  int get total => colis.length;

  int get expedie => colis.where((c) {
        final raw = c.isReturn ? c.returnStatus : c.currentStatus;
        final s = (raw ?? '').toUpperCase();
        return s == 'EXPEDIE' || s == 'RETURN_EXPEDIE';
      }).length;

  int get enTransit => colis.where((c) {
        final raw = c.isReturn ? c.returnStatus : c.currentStatus;
        final s = (raw ?? '').toUpperCase();
        return s == 'EN_TRANSIT';
      }).length;

  int get recuDestination => colis.where((c) {
        final raw = c.isReturn ? c.returnStatus : c.currentStatus;
        final s = (raw ?? '').toUpperCase();
        return s != 'EXPEDIE' &&
            s != 'RETURN_EXPEDIE' &&
            s != 'A_EXPEDIER' &&
            s.isNotEmpty;
      }).length;
}
