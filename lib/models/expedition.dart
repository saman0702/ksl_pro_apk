import 'dart:convert';

import '../core/config.dart';

class KatianExpedition {
  KatianExpedition({
    required this.id,
    this.trackingNumber,
    this.orderNumber,
    this.currentStatus,
    this.returnStatus,
    this.isReturn = false,
    this.recipientName,
    this.recipientPhone,
    this.senderName,
    this.senderPhone,
    this.originRelayName,
    this.destinationRelayName,
    this.currentRelayName,
    this.carrierName,
    this.amount,
    this.updatedAt,
    this.raw = const {},
  });

  final int id;
  final String? trackingNumber;
  final String? orderNumber;
  final String? currentStatus;
  final String? returnStatus;
  final bool isReturn;
  final String? recipientName;
  final String? recipientPhone;
  final String? senderName;
  final String? senderPhone;
  final String? originRelayName;
  final String? destinationRelayName;
  final String? currentRelayName;
  final String? carrierName;
  final double? amount;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  String get displayNumber =>
      trackingNumber ?? orderNumber ?? 'KSL$id';

  String? get pickupCode {
    final v = raw['code_retrait'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  double? get montantPal {
    final v = raw['montantpal'];
    if (v is num) return v.toDouble();
    return null;
  }

  bool get hasPal => (montantPal ?? 0) > 0;

  /// Photo à l'envoi — champ API `img_en_lenvoi` (URL ou base64).
  String? get shippingPhotoUrl {
    final v = raw['img_en_lenvoi'];
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('data:image')) return s;
    if (s.startsWith('http') || s.startsWith('/')) {
      return AppConfig.resolveMediaUrl(s);
    }
    if (s.length > 80 && !s.contains('/')) {
      return 'data:image/jpeg;base64,$s';
    }
    return AppConfig.resolveMediaUrl(s);
  }

  bool get hasShippingPhoto => shippingPhotoUrl != null;

  String? get paymentMode {
    final v = raw['mode_paiement'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? get packageDescription {
    final v = raw['description_colis'] ?? raw['type_colis'];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String get statusLabel {
    if (isReturn) {
      final rs = _norm(returnStatus);
      switch (rs) {
        case 'return_expedie':
          return 'Retour expédié';
        case 'return_en_transit':
          return 'Retour en transit';
        case 'return_arrived':
          return 'Retour arrivé';
        case 'return_requested':
          return 'Retour demandé';
        default:
          break;
      }
    }
    final s = _norm(currentStatus);
    switch (s) {
      case 'a_expedier':
        return 'À expédier';
      case 'expedie':
        return 'Expédié';
      case 'en_transit':
        return 'En transit';
      case 'en_attente_retrait':
        return 'En attente de retrait';
      case 'retire':
        return 'Retiré';
      case 'perdue':
        return 'Perdue';
      case 'retrouve':
        return 'Retrouvé';
      case 'retourne':
        return 'Retourné';
      case 'annule':
        return 'Annulé';
      default:
        return currentStatus ?? '—';
    }
  }

  bool get canReceive {
    if (isReturn) {
      return _norm(returnStatus) == 'return_expedie';
    }
    return _norm(currentStatus) == 'expedie';
  }

  /// Colis expédiables — aligné RelayStock / RelayPackages (A_EXPEDIER ou EN_TRANSIT).
  bool get canExpedier {
    final s = _norm(currentStatus);
    return s == 'a_expedier' || s == 'en_transit';
  }

  static String _norm(String? v) {
    return (v ?? '')
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .trim();
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static String? _relayName(dynamic v) {
    if (v is Map) {
      return v['nom']?.toString() ?? v['name']?.toString();
    }
    return null;
  }

  static String? _relayNameFromJson(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final name = _relayName(json[key]);
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  static String? _personName(Map<String, dynamic>? addr, {
    List<String> firstKeys = const ['recipient_first_name', 'customer_first_name', 'first_name'],
    List<String> lastKeys = const ['recipient_last_name', 'customer_last_name', 'last_name'],
  }) {
    if (addr == null) return null;
    String first = '';
    for (final k in firstKeys) {
      final v = addr[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        first = v.toString().trim();
        break;
      }
    }
    String last = '';
    for (final k in lastKeys) {
      final v = addr[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        last = v.toString().trim();
        break;
      }
    }
    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;
    final full = addr['name'] ?? addr['nom'];
    if (full != null && full.toString().trim().isNotEmpty) {
      return full.toString().trim();
    }
    return null;
  }

  static String? _phoneFromAddr(Map<String, dynamic>? addr, List<String> keys) {
    if (addr == null) return null;
    for (final k in keys) {
      final v = addr[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  factory KatianExpedition.fromJson(Map<String, dynamic> json) {
    final dest = _asMap(json['adresse_destinataire']);
    final sender = _asMap(json['adresse_expediteur']);
    final transporteur = json['transporteur'];

    String? carrier;
    if (transporteur is Map) {
      carrier = transporteur['nom']?.toString() ?? transporteur['libelle']?.toString();
    } else if (transporteur is num) {
      carrier = null;
    } else if (transporteur != null) {
      carrier = transporteur.toString();
    }

    return KatianExpedition(
      id: json['id'] as int? ?? 0,
      trackingNumber: json['expedition_number']?.toString(),
      orderNumber: json['order_number']?.toString(),
      currentStatus: json['current_status']?.toString(),
      returnStatus: json['return_status']?.toString(),
      isReturn: json['is_return'] == true,
      recipientName: _personName(dest),
      recipientPhone: _phoneFromAddr(dest, const [
        'pickup_phone_number',
        'recipient_phone_number',
        'telephone',
        'phone',
      ]),
      senderName: _personName(
        sender,
        firstKeys: const ['customer_first_name', 'sender_first_name', 'first_name'],
        lastKeys: const ['customer_last_name', 'sender_last_name', 'last_name'],
      ),
      senderPhone: _phoneFromAddr(sender, const [
        'customer_phone_number',
        'sender_phone_number',
        'telephone',
        'phone',
      ]),
      originRelayName: _relayNameFromJson(json, const [
        'point_relais_createur',
        'pointrelais',
      ]),
      destinationRelayName: _relayNameFromJson(json, const [
        'point_relais_destinataire',
        'pointrelais_recep',
      ]),
      currentRelayName: _relayName(json['current_relay_id']),
      carrierName: carrier,
      amount: (json['montant'] is num) ? (json['montant'] as num).toDouble() : null,
      updatedAt: json['updated_at']?.toString(),
      raw: Map<String, dynamic>.from(json),
    );
  }
}

enum ExpeditionTab { reception, expedition, stock }
