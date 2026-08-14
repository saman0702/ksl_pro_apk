import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../utils/pickup_utils.dart';
import '../../widgets/katian_flow_bar.dart';
import 'pickup_nav_shell.dart';
import 'pickup_wizard_screen.dart';

/// Recherche par code de retrait — aligné RelayPackages searchParcelByPickupCode.
class PickupSearchScreen extends StatefulWidget {
  const PickupSearchScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PickupSearchScreen> createState() => _PickupSearchScreenState();
}

class _PickupSearchScreenState extends State<PickupSearchScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String raw) async {
    if (_busy) return;
    final code = raw.trim();
    if (code.length < 3) {
      _snack('Saisissez au moins 3 caractères.');
      return;
    }

    setState(() => _busy = true);
    try {
      final app = context.read<AppProvider>();
      final list = await app.expeditions.searchPickup(code);
      final match = matchPickupByCode(list, code);

      if (match == null) {
        _snack('Aucun colis trouvé pour ce code de retrait.');
        return;
      }
      if (!isPickupEligible(match)) {
        _snack('Ce colis n\'est pas encore en attente de retrait.');
        return;
      }
      if (!mounted) return;

      if (widget.embedded) {
        await Navigator.of(context).pushNamed(
          PickupRoutes.wizard,
          arguments: {
            'step': PickupWizardStep.detail,
            'parcel': match,
          },
        );
        return;
      }

      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PickupWizardScreen(
            initialStep: PickupWizardStep.detail,
            initialParcel: match,
          ),
        ),
      );
      if (ok == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Scaffold(
      backgroundColor: ext.background,
      appBar: widget.embedded
          ? null
          : AppBar(
              toolbarHeight: 44,
              title: const Text(
                'Code de retrait',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedded)
            KatianFlowBar(
              title: 'Code de retrait',
              onBack: () => Navigator.of(context).pop(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KatianColors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KatianColors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: KatianColors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Saisissez le code de retrait fourni au client. '
                            'Seuls les colis en attente de retrait peuvent être remis.',
                            style: TextStyle(fontSize: 13, color: ext.textSecondary, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Code de retrait',
                      hintText: 'Ex. RET-2024-XXXXX',
                      filled: true,
                      fillColor: ext.surface,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: KatianColors.red),
                        onPressed: _busy ? null : () => _search(_codeCtrl.text),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _search(_codeCtrl.text),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Rechercher le colis'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: KatianTheme.buttonShape,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
