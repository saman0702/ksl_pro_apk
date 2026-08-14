import 'package:flutter/material.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../models/models.dart';

class DepositStepSuccess extends StatelessWidget {
  const DepositStepSuccess({
    super.key,
    required this.expedition,
    required this.onPrintLabel,
    required this.onPrintReceipt,
    required this.onFinish,
    this.printingLabel = false,
    this.printingReceipt = false,
  });

  final KatianExpedition expedition;
  final VoidCallback onPrintLabel;
  final VoidCallback onPrintReceipt;
  final VoidCallback onFinish;
  final bool printingLabel;
  final bool printingReceipt;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final number = expedition.displayNumber;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: KatianColors.green, size: 72),
          const SizedBox(height: 16),
          Text(
            'Expédition créée',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: KatianColors.red,
            ),
          ),
          if (expedition.pickupCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Code retrait : ${expedition.pickupCode}',
              style: TextStyle(fontSize: 15, color: ext.textSecondary),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: printingLabel ? null : onPrintLabel,
              icon: printingLabel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.local_shipping_outlined),
              label: const Text('Imprimer étiquette'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: printingReceipt ? null : onPrintReceipt,
              icon: printingReceipt
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              label: const Text('Imprimer reçu'),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: KatianActionButtons.text(
              onPressed: onFinish,
              label: 'Terminer',
              icon: Icons.home_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
