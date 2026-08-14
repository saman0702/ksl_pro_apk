import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/expedition_payload_builder.dart';
import '../../widgets/katian_action_buttons.dart';
import 'deposit_step_confirm.dart';
import 'deposit_step_parcel.dart';
import 'deposit_step_parties.dart';
import 'deposit_step_photo.dart';
import 'deposit_step_success.dart';

class NewExpeditionWizardScreen extends StatefulWidget {
  const NewExpeditionWizardScreen({super.key});

  @override
  State<NewExpeditionWizardScreen> createState() =>
      _NewExpeditionWizardScreenState();
}

class _NewExpeditionWizardScreenState extends State<NewExpeditionWizardScreen> {
  static const _stepLabels = [
    'Parties',
    'Colis',
    'Photo',
    'Confirmation',
    'Succès',
  ];

  int _step = 0;
  final _draft = ExpeditionDraft();
  List<RelayPointOption> _relays = [];
  bool _loadingRelays = true;
  bool _submitting = false;
  bool _printingLabel = false;
  bool _printingReceipt = false;
  KatianExpedition? _created;

  @override
  void initState() {
    super.initState();
    _loadRelays();
  }

  Future<void> _loadRelays() async {
    setState(() => _loadingRelays = true);
    try {
      final app = context.read<AppProvider>();
      final relays = await app.deposits.loadCompagnieRelays();
      final connectedId = app.user?.relayPoint?.id;
      if (mounted) {
        setState(() {
          _relays = relays;
          _draft.originRelayId = connectedId;
          _draft.originRelay = _relayById(connectedId);
        });
      }
    } catch (e) {
      if (mounted) _snack('Impossible de charger les gares.');
    } finally {
      if (mounted) setState(() => _loadingRelays = false);
    }
  }

  RelayPointOption? _relayById(int? id) {
    if (id == null) return null;
    for (final r in _relays) {
      if (r.id == id) return r;
    }
    return null;
  }

  int _phoneDigits(String raw) =>
      raw.replaceAll(RegExp(r'\D'), '').length;

  List<String> _missingForStep(int step) {
    final missing = <String>[];
    switch (step) {
      case 0:
        if (_draft.senderFirstName.trim().isEmpty &&
            _draft.senderLastName.trim().isEmpty) {
          missing.add('nom expéditeur');
        }
        if (_phoneDigits(_draft.senderPhone) < 8) {
          missing.add('téléphone expéditeur');
        }
        if (_draft.recipientFirstName.trim().isEmpty &&
            _draft.recipientLastName.trim().isEmpty) {
          missing.add('nom destinataire');
        }
        if (_phoneDigits(_draft.recipientPhone) < 8) {
          missing.add('téléphone destinataire');
        }
        if (_draft.originRelayId == null) missing.add('gare de départ');
        if (_draft.destinationRelayId == null) {
          missing.add('destination finale');
        } else if (_draft.destinationRelayId == _draft.originRelayId) {
          missing.add('gares différentes');
        }
      case 1:
        if (_draft.pickupItems.isEmpty) {
          missing.add('au moins un article');
        }
        if (_draft.isInternationalService && _draft.montant <= 0) {
          missing.add('montant de l\'expédition');
        }
      default:
        break;
    }
    return missing;
  }

  bool _canGoNext() => _missingForStep(_step).isEmpty;

  void _onDraftChanged() => setState(() {});

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _next() async {
    final missing = _missingForStep(_step);
    if (missing.isNotEmpty) {
      _snack('Champs manquants : ${missing.join(', ')}');
      return;
    }
    if (_step == 3) {
      await _submit();
      return;
    }
    setState(() => _step++);
  }

  void _back() {
    if (_step <= 0 || _created != null) return;
    setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final app = context.read<AppProvider>();
      _draft.originRelay ??= _relayById(_draft.originRelayId);
      _draft.destinationRelay ??= _relayById(_draft.destinationRelayId);

      final payload = ExpeditionPayloadBuilder.buildInternationalPayload(
        draft: _draft,
        user: app.user,
        originRelay: _draft.originRelay,
        destinationRelay: _draft.destinationRelay,
      );

      final res = await app.deposits.createForCompagnie(payload);
      final expedition = KatianExpedition.fromJson(res);
      await app.loadDashboardStats();
      if (mounted) {
        setState(() {
          _created = expedition;
          _step = 4;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e is DioException
            ? context.read<AppProvider>().formatError(e)
            : 'Erreur lors de la création.';
        _snack(msg);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _printLabel() async {
    final exp = _created;
    if (exp == null) return;
    setState(() => _printingLabel = true);
    try {
      final app = context.read<AppProvider>();
      await app.documents.generateShippingLabel(exp, app.user);
    } catch (e) {
      if (mounted) _snack('Impossible de générer l\'étiquette.');
    } finally {
      if (mounted) setState(() => _printingLabel = false);
    }
  }

  Future<void> _printReceipt() async {
    final exp = _created;
    if (exp == null) return;
    setState(() => _printingReceipt = true);
    try {
      final app = context.read<AppProvider>();
      await app.documents.generateCashReceipt(exp, app.user);
    } catch (e) {
      if (mounted) _snack('Impossible de générer le reçu.');
    } finally {
      if (mounted) setState(() => _printingReceipt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _step >= 4 && _created != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSuccess ? 'Expédition créée' : 'Nouvelle expédition'),
        leading: isSuccess
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          if (!isSuccess) _StepBar(current: _step, labels: _stepLabels),
          Expanded(
            child: _loadingRelays && _step == 0
                ? const Center(
                    child: CircularProgressIndicator(color: KatianColors.red),
                  )
                : _buildStep(),
          ),
          if (!isSuccess) _BottomNav(
            step: _step,
            canNext: _canGoNext(),
            submitting: _submitting,
            onBack: _back,
            onNext: _next,
            nextLabel: _step == 3 ? 'Créer l\'expédition' : 'Suivant',
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return DepositStepParties(
          draft: _draft,
          relays: _relays,
          connectedRelayId: context.read<AppProvider>().user?.relayPoint?.id,
          onChanged: _onDraftChanged,
        );
      case 1:
        return DepositStepParcel(
          draft: _draft,
          onChanged: _onDraftChanged,
        );
      case 2:
        return DepositStepPhoto(
          draft: _draft,
          onChanged: _onDraftChanged,
        );
      case 3:
        return DepositStepConfirm(draft: _draft);
      case 4:
        return DepositStepSuccess(
          expedition: _created!,
          onPrintLabel: _printLabel,
          onPrintReceipt: _printReceipt,
          onFinish: () => Navigator.pop(context, true),
          printingLabel: _printingLabel,
          printingReceipt: _printingReceipt,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final total = labels.length - 1;
    final progress = current / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: ext.border,
              color: KatianColors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${current + 1}/$total — ${labels[current]}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ext.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.step,
    required this.canNext,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  final int step;
  final bool canNext;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  static final _outlinedStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  static final _elevatedStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final showBack = step > 0 && step < 4;
    final showSkip = step == 2;

    Widget backButton() => KatianActionButtons.outlined(
          onPressed: submitting ? null : onBack,
          label: 'Précédent',
          style: _outlinedStyle,
        );

    Widget nextButton() => ElevatedButton.icon(
          style: _elevatedStyle,
          onPressed: (!canNext || submitting) ? null : onNext,
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  step >= 3 ? Icons.check : Icons.arrow_forward,
                  size: 18,
                ),
          label: Text(
            nextLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: showSkip
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (showBack) Expanded(child: backButton()),
                      if (showBack) const SizedBox(width: 12),
                      Expanded(child: nextButton()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  KatianActionButtons.text(
                    onPressed: submitting ? null : onNext,
                    label: 'Passer cette étape',
                    icon: Icons.skip_next_outlined,
                  ),
                ],
              )
            : Row(
                children: [
                  if (showBack) Expanded(child: backButton()),
                  if (showBack) const SizedBox(width: 12),
                  Expanded(child: nextButton()),
                ],
              ),
      ),
    );
  }
}
