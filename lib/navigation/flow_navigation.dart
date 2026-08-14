import '../models/models.dart';

/// Demande d'ouverture du flux retrait (wizard).
class PickupFlowRequest {
  const PickupFlowRequest({
    this.parcel,
    this.openDetail = true,
  });

  final KatianExpedition? parcel;
  final bool openDetail;
}

/// Demande d'ouverture du wizard départ.
class DepartureFlowRequest {
  const DepartureFlowRequest({this.parcelIds = const {}});

  final Set<int> parcelIds;
}
