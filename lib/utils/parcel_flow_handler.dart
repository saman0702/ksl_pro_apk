import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/departures/departure_wizard_screen.dart';
import '../screens/pickup/pickup_wizard_screen.dart';
import '../screens/reception/reception_scan_screen.dart';
import '../screens/reception/reception_wizard_screen.dart';
import 'parcel_actions.dart';

/// Ouvre directement le wizard dédié (push) — fonctionne depuis les listes du dashboard.
Future<bool> redirectParcelFlowAction(
  BuildContext context,
  ParcelAction action,
  KatianExpedition parcel,
) async {
  switch (action.kind) {
    case ParcelActionKind.receive:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceptionWizardScreen(
            initialStep: ReceptionWizardStep.detail,
            initialParcel: parcel,
            initialTarget: ReceptionScanTarget.parcel,
          ),
        ),
      );
      return true;
    case ParcelActionKind.withdraw:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PickupWizardScreen(
            initialStep: PickupWizardStep.detail,
            initialParcel: parcel,
          ),
        ),
      );
      return true;
    case ParcelActionKind.expedier:
    case ParcelActionKind.reship:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DepartureWizardScreen(
            initialSelectedIds: {parcel.id},
          ),
        ),
      );
      return true;
    default:
      return false;
  }
}
