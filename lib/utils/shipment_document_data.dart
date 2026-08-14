import '../models/models.dart';

/// Données normalisées pour génération PDF — aligné RelayPackages.js shipment.
class ShipmentDocumentData {
  const ShipmentDocumentData({
    required this.trackingNumber,
    required this.amount,
    this.pickupCode,
    this.paymentMethod,
    this.packageType,
    this.descriptionColis,
    this.valeurDeclaree,
    this.pourcentageApplique,
    this.montantPal,
    this.insuranceAmount,
    this.modeExpedition,
    this.originRelayName,
    this.destinationRelayName,
    this.senderName,
    this.senderPhone,
    this.senderAddress,
    this.senderEmail,
    this.expediteurName,
    this.expediteurPrenom,
    this.expediteurPhone,
    this.recipientName,
    this.recipientPrenom,
    this.recipientPhone,
    this.relayEmissionName,
    this.relayReceptionName,
    this.relayTel,
    this.createdAt,
    this.receivedBy,
    this.receivedByShort,
    this.companyName,
    this.logoUrl,
    this.gerantId,
    this.packageContent,
  });

  final String trackingNumber;
  final double amount;
  final String? pickupCode;
  final String? paymentMethod;
  final String? packageType;
  final String? descriptionColis;
  final double? valeurDeclaree;
  final double? pourcentageApplique;
  final double? montantPal;
  final double? insuranceAmount;
  final String? modeExpedition;
  final String? originRelayName;
  final String? destinationRelayName;
  final String? senderName;
  final String? senderPhone;
  final String? senderAddress;
  final String? senderEmail;
  final String? expediteurName;
  final String? expediteurPrenom;
  final String? expediteurPhone;
  final String? recipientName;
  final String? recipientPrenom;
  final String? recipientPhone;
  final String? relayEmissionName;
  final String? relayReceptionName;
  final String? relayTel;
  final String? createdAt;
  final String? receivedBy;
  final String? receivedByShort;
  final String? companyName;
  final String? logoUrl;
  final int? gerantId;
  final String? packageContent;

  bool get hasInsurance => (insuranceAmount ?? 0) > 0;

  double get totalPaid => amount + (hasInsurance ? insuranceAmount! : 0);

  String get packageTypeLabel => packageTypeLabelFor(packageType);

  String get trackingUrl =>
      gerantId == 74 ? 'www.sama.com/tracking' : 'www.katianlogistique.com/tracking';

  String get disclaimerCompany =>
      gerantId == 74 ? 'Sama décline' : 'Nous déclinons';

  factory ShipmentDocumentData.fromParcel(
    KatianExpedition parcel,
    KatianUser? user,
  ) {
    final raw = parcel.raw;
    final dest = raw['adresse_destinataire'] as Map<String, dynamic>?;
    final sender = raw['adresse_expediteur'] as Map<String, dynamic>?;
    final createur = raw['point_relais_createur'] as Map<String, dynamic>?;

    String? relayName(dynamic v) {
      if (v is Map<String, dynamic>) {
        return v['nom'] as String? ?? v['name'] as String?;
      }
      if (v is Map) {
        return v['nom']?.toString() ?? v['name']?.toString();
      }
      return null;
    }

    final origin = parcel.originRelayName ??
        relayName(createur) ??
        relayName(raw['pointrelais']);
    final destination = parcel.destinationRelayName ??
        relayName(raw['point_relais_destinataire']) ??
        relayName(raw['pointrelais_recep']);

    final senderInfo = _senderFromCreateur(createur, parcel, user);
    final infocolis = raw['infocolis'];
    String? content;
    if (infocolis is List && infocolis.isNotEmpty) {
      content = infocolis
          .map((e) {
            if (e is Map) {
              return (e['category'] ?? e['name'] ?? 'Colis').toString();
            }
            return 'Colis';
          })
          .join(', ');
    }

    final gerantRaw = user?.gerant?['id'] ?? user?.gerant?['user_id'];
    final gerantId = gerantRaw is int
        ? gerantRaw
        : int.tryParse('${gerantRaw ?? ''}');

    final receivedByShort = _receivedByShort(user);

    return ShipmentDocumentData(
      trackingNumber: parcel.displayNumber,
      amount: parcel.amount ?? _toDouble(raw['montant']) ?? 0,
      pickupCode: raw['code_retrait'] as String?,
      paymentMethod: raw['mode_paiement'] as String? ?? 'Espèces',
      packageType: raw['type_colis'] as String? ?? 'standard',
      descriptionColis: raw['description_colis'] as String?,
      valeurDeclaree: _toDouble(raw['valeur_declaree']),
      pourcentageApplique: _toDouble(raw['pourcentage_applique']),
      montantPal: _toDouble(raw['montantpal']),
      insuranceAmount: _toDouble(raw['montant_assurance']) ??
          _toDouble(raw['insurance_amount']),
      modeExpedition: raw['mode_expedition'] as String? ?? 'Point relais',
      originRelayName: origin,
      destinationRelayName: destination,
      senderName: senderInfo.name,
      senderPhone: senderInfo.phone,
      senderAddress: senderInfo.address,
      senderEmail: user?.email,
      expediteurName: sender?['customer_first_name'] as String? ?? parcel.senderName,
      expediteurPrenom: sender?['customer_last_name'] as String?,
      expediteurPhone:
          sender?['customer_phone_number'] as String? ?? parcel.senderPhone,
      recipientName: dest?['recipient_last_name'] as String? ?? parcel.recipientName,
      recipientPrenom: dest?['recipient_first_name'] as String?,
      recipientPhone:
          dest?['pickup_phone_number'] as String? ?? parcel.recipientPhone,
      relayEmissionName: raw['pointrelais_d_envoi_name'] as String? ?? origin,
      relayReceptionName: destination,
      relayTel: senderInfo.phone,
      createdAt: raw['created_at'] as String? ?? parcel.updatedAt,
      receivedBy: user?.fullName,
      receivedByShort: receivedByShort,
      companyName: user?.companyName ?? user?.displayRelayName,
      logoUrl: user?.displayLogo,
      gerantId: gerantId,
      packageContent: content,
    );
  }

  static String? _receivedByShort(KatianUser? user) {
    if (user == null) return null;
    final first = user.firstName?.trim();
    final last = user.lastName?.trim();
    if (first != null && first.isNotEmpty && last != null && last.isNotEmpty) {
      return '${first[0]}. $last';
    }
    return user.fullName;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static String packageTypeLabelFor(String? packageType) {
    switch ((packageType ?? '').toLowerCase()) {
      case 'petit':
        return 'Petit format (moins de 5 kg)';
      case 'moyen':
        return 'Moyen format (5-15 kg)';
      case 'grand':
        return 'Grand format (15-30 kg)';
      case 'très_grand':
      case 'tres_grand':
        return 'Très grand format (plus de 30 kg)';
      case 'express':
        return 'Express';
      case 'fragile':
        return 'Fragile';
      default:
        return packageType ?? 'Standard';
    }
  }

  static ({String name, String phone, String address}) _senderFromCreateur(
    Map<String, dynamic>? createur,
    KatianExpedition parcel,
    KatianUser? user,
  ) {
    if (createur != null) {
      final phone = createur['numero_entreprise'] as String? ??
          createur['phone'] as String? ??
          user?.phone ??
          'N/A';
      return (
        name: createur['nom'] as String? ??
            createur['name'] as String? ??
            parcel.originRelayName ??
            'Point relais',
        phone: phone,
        address: createur['adresse'] as String? ??
            createur['address'] as String? ??
            createur['ville'] as String? ??
            '',
      );
    }
    return (
      name: parcel.originRelayName ?? user?.displayRelayName ?? 'Expéditeur',
      phone: user?.phone ?? parcel.senderPhone ?? 'N/A',
      address: parcel.originRelayName ?? '',
    );
  }
}
