import 'package:flutter/material.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../widgets/katian_dashed_frame.dart';
import '../../widgets/katian_scaffold.dart';
import '../reception/reception_scan_screen.dart';
import '../reception/reception_wizard_screen.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  Future<void> _openScan(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReceptionScanScreen()),
    );
  }

  Future<void> _openList(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ReceptionWizardScreen(
          initialStep: ReceptionWizardStep.list,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return KatianScaffold(
      title: 'Réception',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Colis venant d\'autres gares',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ext.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: KatianHubSquareButton(
                color: KatianColors.red,
                icon: Icons.qr_code_scanner_rounded,
                label: 'SCAN',
                onTap: () => _openScan(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scanner code-barres',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ext.textPrimary,
              ),
            ),
            Text(
              'Code-barres étiquette ou QR bordereau',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ext.textSecondary),
            ),
            const SizedBox(height: 28),
            Text(
              'La liste n\'affiche que les colis destinés à votre gare (destination finale).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 12),
            KatianHubListRow(
              ext: ext,
              accentColor: KatianColors.red,
              icon: Icons.list_alt_rounded,
              title: 'Liste des colis à recevoir',
              subtitle: 'Expéditions en attente à la gare',
              onTap: () => _openList(context),
            ),
          ],
        ),
      ),
    );
  }
}
