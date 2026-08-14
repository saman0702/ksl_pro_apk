import 'traceability.dart';

/// Article colis — aligné pickup_items (RelayCompagnieDeposits).
class DraftPickupItem {
  DraftPickupItem({
    this.name = '',
    this.category = 'Autres / Divers',
    this.packageFormat = '',
    this.selectedCategory = 'car',
    this.weight = 0,
    this.quantity = 1,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.weightForCalculation = 0,
    this.volumeForCalculation = 0,
  });

  String name;
  String category;
  String packageFormat;
  String selectedCategory;
  double weight;
  int quantity;
  double length;
  double width;
  double height;
  double weightForCalculation;
  double volumeForCalculation;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'weight': weight,
        'length': length,
        'width': width,
        'height': height,
        'quantity': quantity,
      };
}

/// Brouillon création expédition compagnie TP.
class ExpeditionDraft {
  ExpeditionDraft({
    this.senderFirstName = '',
    this.senderLastName = '',
    this.senderPhone = '',
    this.recipientFirstName = '',
    this.recipientLastName = '',
    this.recipientPhone = '',
    this.originRelayId,
    this.destinationRelayId,
    this.typeService = 'interurbaine',
    this.descriptionColis = '',
    this.valeurDeclaree = 0,
    this.pourcentageApplique = 0,
    this.montant = 0,
    List<DraftPickupItem>? pickupItems,
    this.photoPath,
    this.photoBase64,
  }) : pickupItems = pickupItems ?? [];

  String senderFirstName;
  String senderLastName;
  String senderPhone;
  String recipientFirstName;
  String recipientLastName;
  String recipientPhone;
  int? originRelayId;
  int? destinationRelayId;
  String typeService;
  String descriptionColis;
  double valeurDeclaree;
  double pourcentageApplique;
  double montant;
  List<DraftPickupItem> pickupItems;
  String? photoPath;
  String? photoBase64;

  RelayPointOption? originRelay;
  RelayPointOption? destinationRelay;

  bool get isInternationalService =>
      typeService == 'interurbaine' || typeService == 'sous_regionale';

  double get totalWeight => pickupItems.fold(
        0,
        (sum, item) => sum + item.weight * item.quantity,
      );

  int get totalArticleCount =>
      pickupItems.fold(0, (sum, item) => sum + item.quantity);
}
