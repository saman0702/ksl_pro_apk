import 'package:flutter_test/flutter_test.dart';
import 'package:katian_pro_compagnietp_app/models/expedition_draft.dart';
import 'package:katian_pro_compagnietp_app/models/traceability.dart';
import 'package:katian_pro_compagnietp_app/utils/deposit_item_logic.dart';
import 'package:katian_pro_compagnietp_app/utils/expedition_payload_builder.dart';

void main() {
  test('buildInternationalPayload calcule montant et champs clés', () {
    final draft = ExpeditionDraft(
      senderFirstName: 'Jean',
      senderLastName: 'Dupont',
      senderPhone: '0700000000',
      recipientFirstName: 'Marie',
      recipientLastName: 'Kouassi',
      recipientPhone: '0100000000',
      originRelayId: 1,
      destinationRelayId: 2,
      descriptionColis: 'Carton',
      valeurDeclaree: 10000,
      pourcentageApplique: 5,
      montant: 500,
      pickupItems: [
        DraftPickupItem(
          name: 'Colis',
          category: 'Autres / Divers',
          packageFormat: 'xs',
          weight: 1,
          quantity: 1,
        ),
      ],
    );

    final payload = ExpeditionPayloadBuilder.buildInternationalPayload(
      draft: draft,
      user: null,
      originRelay: const RelayPointOption(id: 1, name: 'Gare A', city: 'Abidjan'),
      destinationRelay: const RelayPointOption(id: 2, name: 'Gare B', city: 'Bouaké'),
    );

    expect(payload['type_service'], 'interurbaine');
    expect(payload['mode_paiement'], 'Espèces');
    expect(payload['montant'], 500);
    expect(payload['pointrelais_id'], 1);
    expect(payload['pointrelais'], 2);
    expect(payload['infocolis'], isA<List>());
    expect(payload['payment_confirmation']['method'], 'cash');
    expect(payload['adresse_expediteur']['customer_first_name'], 'Jean');
    expect(payload['adresse_destinataire']['recipient_last_name'], 'Kouassi');
    expect(payload['expedition_number'], startsWith('KSL-'));
    expect(payload['code_retrait'], isNotEmpty);
  });

  test('validateAddItem exige nom et format', () {
    final current = CurrentDraftItem();
    expect(
      DepositItemLogic.validateAddItem(current: current, existingItems: []),
      contains('nom et le format'),
    );
  });

  test('generateExpeditionNumber respecte le format KSL-XXX-XXX', () {
    final n = ExpeditionPayloadBuilder.generateExpeditionNumber();
    expect(n, matches(RegExp(r'^KSL-[A-Z]{3}-[A-Z]{3}$')));
  });
}
