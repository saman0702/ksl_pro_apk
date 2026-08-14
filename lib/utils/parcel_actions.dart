import 'package:flutter/material.dart';

import '../models/models.dart';
import 'parcel_status.dart';

enum ParcelActionKind {
  receive,
  expedier,
  cancel,
  found,
  reship,
  withdraw,
  returnParcel,
  declareLost,
}

class ParcelAction {
  const ParcelAction({
    required this.kind,
    required this.label,
    this.needsDriver = false,
    this.destructive = false,
  });

  final ParcelActionKind kind;
  final String label;
  final bool needsDriver;
  final bool destructive;
}

IconData iconForParcelAction(ParcelActionKind kind) {
  return switch (kind) {
    ParcelActionKind.receive => Icons.move_to_inbox_outlined,
    ParcelActionKind.expedier => Icons.local_shipping_outlined,
    ParcelActionKind.cancel => Icons.cancel_outlined,
    ParcelActionKind.found => Icons.search_outlined,
    ParcelActionKind.reship => Icons.replay_outlined,
    ParcelActionKind.withdraw => Icons.handshake_outlined,
    ParcelActionKind.returnParcel => Icons.reply_outlined,
    ParcelActionKind.declareLost => Icons.report_problem_outlined,
  };
}

/// Actions visibles — aligné RelayPackages.js (shouldShow* + handleUpdateStatus).
List<ParcelAction> parcelActionsFor({
  required KatianExpedition parcel,
  required ExpeditionTab tab,
  KatianUser? user,
}) {
  final actions = <ParcelAction>[];
  final status = normalizeParcelStatus(parcel.currentStatus);
  final returnStatus = normalizeParcelStatus(parcel.returnStatus);
  final relayIds = userRelayIds(user);

  if (parcel.canReceive && tab == ExpeditionTab.reception) {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.receive,
      label: 'Réceptionner',
    ));
  }

  if (_shouldShowExpedier(parcel, tab, relayIds)) {
    final isReturnShip = parcel.isReturn &&
        (returnStatus == 'return_en_transit' ||
            returnStatus == 'return_requested');
    actions.add(ParcelAction(
      kind: ParcelActionKind.expedier,
      label: isReturnShip ? 'Expédier le retour' : 'Expédier',
    ));
  }

  if (status == 'a_expedier') {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.cancel,
      label: 'Annuler',
      destructive: true,
    ));
  }

  if (status == 'perdue') {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.found,
      label: 'Colis retrouvé',
    ));
  }

  if (status == 'retrouve') {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.reship,
      label: 'Réexpédier',
    ));
  }

  if (status == 'en_attente_retrait') {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.withdraw,
      label: 'Retirer / Livrer',
    ));
  }

  if (status == 'en_attente_retrait' || status == 'en_transit') {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.returnParcel,
      label: 'Retour',
      destructive: true,
    ));
  }

  if (status == 'en_transit' ||
      status == 'expedie' ||
      status == 'en_attente_retrait') {
    actions.add(const ParcelAction(
      kind: ParcelActionKind.declareLost,
      label: 'Déclarer perdu',
      destructive: true,
    ));
  }

  return actions;
}

bool _shouldShowExpedier(
  KatianExpedition parcel,
  ExpeditionTab tab,
  List<String> relayIds,
) {
  final status = normalizeParcelStatus(parcel.currentStatus);
  final returnStatus = normalizeParcelStatus(parcel.returnStatus);
  final isEnTransit = status == 'en_transit';
  final isAExpedier = status == 'a_expedier';
  final isReturn = parcel.isReturn;
  final isReturnEnTransit = isReturn && returnStatus == 'return_en_transit';
  final isReturnRequested = isReturn && returnStatus == 'return_requested';
  final canShowTransit =
      (isEnTransit && !isReturn) || isReturnEnTransit || isReturnRequested;

  if (tab == ExpeditionTab.reception) {
    if (!canShowTransit) return false;
    final currentRelayId = relayIdFromRaw(parcel.raw['current_relay_id']);
    final destRelayId = relayIdFromRaw(
      parcel.raw['pointrelais_recep'] ?? parcel.raw['pointrelais_recep_id'],
    );
  final returnDestId = relayIdFromRaw(
    parcel.raw['return_destination_id'] ??
        parcel.raw['return_destination_id_id'],
  );
    final isFinalDest = isReturn
        ? (returnDestId != null &&
            relayIds.isNotEmpty &&
            relayIds.contains(returnDestId))
        : (destRelayId != null &&
            relayIds.isNotEmpty &&
            relayIds.contains(destRelayId));
    if (isFinalDest) return false;
    if (currentRelayId == null || currentRelayId.isEmpty) return false;
    if (relayIds.isEmpty) return isEnTransit || isReturnEnTransit;
    return relayIds.contains(currentRelayId);
  }

  if (tab == ExpeditionTab.expedition) {
    return isAExpedier || (isReturn && isReturnRequested);
  }

  if (tab == ExpeditionTab.stock) {
    return isAExpedier || canShowTransit || (isReturn && isReturnRequested);
  }

  return false;
}
