import 'package:flutter/material.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../widgets/katian_dashed_frame.dart';
import '../../widgets/katian_scaffold.dart';
import 'pickup_nav_shell.dart';
import 'pickup_wizard_screen.dart';

/// Hub retrait autonome (hors onglet Colis) — préférer [PickupHubBody] + [PickupNavShell].
class PickupHubScreen extends StatelessWidget {
  const PickupHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const KatianScaffold(
      title: 'Retrait',
      body: PickupNavShell(),
    );
  }
}

/// Contenu hub — utilisé dans l'onglet Colis > Retrait.
class PickupHubBody extends StatelessWidget {
  const PickupHubBody({super.key});

  void _openSearch(BuildContext context) {
    Navigator.of(context).pushNamed(PickupRoutes.search);
  }

  void _openList(BuildContext context) {
    Navigator.of(context).pushNamed(
      PickupRoutes.wizard,
      arguments: PickupWizardStep.list,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Remise au destinataire',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Colis en attente de retrait à votre gare',
            style: TextStyle(fontSize: 13, color: ext.textSecondary),
          ),
          const SizedBox(height: 24),
          Center(
            child: KatianHubSquareButton(
              color: KatianColors.green,
              icon: Icons.key_rounded,
              label: 'CODE',
              onTap: () => _openSearch(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Code de retrait',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary),
          ),
          Text(
            'Saisie du code fourni au client',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: ext.textSecondary),
          ),
          const SizedBox(height: 28),
          KatianHubListRow(
            ext: ext,
            accentColor: KatianColors.green,
            icon: Icons.inventory_outlined,
            title: 'Colis à retirer',
            subtitle: 'En attente de retrait à la gare',
            onTap: () => _openList(context),
          ),
        ],
      ),
    );
  }
}
