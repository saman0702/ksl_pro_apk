import 'dart:math';

import '../models/expedition_draft.dart';
import '../models/katian_user.dart';
import '../models/traceability.dart';

/// Construction payload POST /expeditions/compagny/ — aligné RelayCompagnieDeposits.
class ExpeditionPayloadBuilder {
  static String generateExpeditionNumber() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    String part(int len) =>
        List.generate(len, (_) => letters[random.nextInt(letters.length)]).join();
    return 'KSL-${part(3)}-${part(3)}';
  }

  static String generateCodeRetrait() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    final random = Random();
    final l = List.generate(2, (_) => letters[random.nextInt(letters.length)]).join();
    final n = List.generate(4, (_) => numbers[random.nextInt(numbers.length)]).join();
    return '$l$n';
  }

  static String buildPhone(String raw, {String countryCode = '+225'}) {
    final cc = countryCode.startsWith('+') ? countryCode : '+$countryCode';
    final digits = raw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return cc;
    if (raw.trim().startsWith('+')) return raw.trim();
    return '$cc$digits';
  }

  static Map<String, dynamic> buildInternationalPayload({
    required ExpeditionDraft draft,
    required KatianUser? user,
    RelayPointOption? originRelay,
    RelayPointOption? destinationRelay,
  }) {
    final origin = originRelay ?? draft.originRelay;
    final dest = destinationRelay ?? draft.destinationRelay;
    final originCity = origin?.city ?? origin?.name ?? '';
    final destCity = dest?.city ?? dest?.name ?? '';
    final originId = draft.originRelayId ?? user?.relayPoint?.id;
    final destId = draft.destinationRelayId;

    final articles = draft.pickupItems.map((e) => e.toJson()).toList();
    final totalWeight = draft.totalWeight;
    final description = articles.isEmpty
        ? 'Colis'
        : articles
            .map(
              (item) =>
                  '${item['quantity']}x ${item['name']},${item['category']},${item['weight']}kg,${item['length']}cm,${item['width']}cm,${item['height']}cm',
            )
            .join(', ');

    final montant = draft.montant;

    final payload = <String, dynamic>{
      'type_service': draft.typeService,
      'shippingMode': 'relay_point',
      'mode_expedition': 'Point relais',
      'mode_paiement': 'Espèces',
      'delais_livraison': '86H - 2-4 JOURS',
      'type_colis': 'standard',
      'statut_colis': 'Planifié',
      'montant': montant,
      'valeur_declaree': draft.valeurDeclaree,
      'description_colis': draft.descriptionColis,
      'pourcentage_applique': draft.pourcentageApplique,
      'departure_city': originCity,
      'destination_city': destCity,
      'departure_country': "Côte d'Ivoire",
      'destination_country': "Côte d'Ivoire",
      'pointrelais_id': originId,
      'pointrelais': destId,
      'pointrelais_recep': destId,
      'use_relay_point': true,
      'infocolis': articles,
      'poids': totalWeight,
      'weight': totalWeight,
      'description': description,
      'expedition_number': generateExpeditionNumber(),
      'code_retrait': generateCodeRetrait(),
      'payment_confirmation': {
        'status': 'confirmed',
        'method': 'cash',
        'amount': montant,
      },
      'adresse_expediteur': {
        'customer_first_name': draft.senderFirstName.trim(),
        'customer_last_name': draft.senderLastName.trim(),
        'customer_phone_number': buildPhone(draft.senderPhone),
        'customer_email': user?.email ?? '',
        'address': origin?.address ?? origin?.name ?? originCity,
        'departure_city': originCity,
        'departure_country': "Côte d'Ivoire",
      },
      'adresse_destinataire': {
        'recipient_first_name': draft.recipientFirstName.trim(),
        'recipient_last_name': draft.recipientLastName.trim(),
        'pickup_phone_number': buildPhone(draft.recipientPhone),
        'pickup_email': '',
        'address': dest?.address ?? dest?.name ?? destCity,
        'destination_city': destCity,
        'destination_country': "Côte d'Ivoire",
      },
    };

    if (draft.photoBase64 != null && draft.photoBase64!.isNotEmpty) {
      payload['img_en_lenvoi'] = draft.photoBase64;
    }

    return payload;
  }
}
