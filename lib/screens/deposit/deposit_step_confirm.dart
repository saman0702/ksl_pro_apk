import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class DepositStepConfirm extends StatelessWidget {
  const DepositStepConfirm({
    super.key,
    required this.draft,
  });

  final ExpeditionDraft draft;

  static final _currency = NumberFormat('#,##0', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final d = draft;
    final sender = '${d.senderFirstName} ${d.senderLastName}'.trim();
    final recipient = '${d.recipientFirstName} ${d.recipientLastName}'.trim();
    final serviceLabel = d.typeService == 'sous_regionale'
        ? 'Sous-régionale'
        : 'Interurbaine';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Confirmation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ext.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez les informations avant de créer l\'expédition.',
          style: TextStyle(color: ext.textSecondary),
        ),
        const SizedBox(height: 16),
        _card(ext, 'Service', serviceLabel),
        _card(ext, 'Expéditeur', '$sender\n${d.senderPhone}'),
        _card(ext, 'Destinataire', '$recipient\n${d.recipientPhone}'),
        _card(
          ext,
          'Trajet',
          '${d.originRelay?.name ?? '—'} → ${d.destinationRelay?.name ?? '—'}',
        ),
        _card(
          ext,
          'Colis',
          '${d.pickupItems.length} article(s)\n${d.descriptionColis}',
        ),
        _card(
          ext,
          'Montant (Espèces)',
          '${_currency.format(d.montant)} FCFA',
          highlight: true,
        ),
        if (d.photoBase64 != null)
          _card(ext, 'Photo', 'Photo jointe'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KatianColors.redLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: KatianColors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le paiement sera enregistré en espèces à la caisse.',
                  style: TextStyle(fontSize: 13, color: ext.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(
    KatianThemeExtension ext,
    String title,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 14,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? KatianColors.red : ext.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
