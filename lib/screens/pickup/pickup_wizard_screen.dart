import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/parcel_status_colors.dart';
import '../../utils/pickup_utils.dart';
import '../../widgets/katian_flow_bar.dart';
import '../../widgets/parcel_shipping_photo.dart';
import '../../widgets/parcel_status_badge.dart';
import 'pickup_nav_shell.dart';
import 'pickup_search_screen.dart';

enum PickupWizardStep { list, detail, confirm, success }

class PickupWizardScreen extends StatefulWidget {
  const PickupWizardScreen({
    super.key,
    this.embedded = false,
    this.initialStep = PickupWizardStep.list,
    this.initialParcel,
  });

  final bool embedded;
  final PickupWizardStep initialStep;
  final KatianExpedition? initialParcel;

  @override
  State<PickupWizardScreen> createState() => _PickupWizardScreenState();
}

class _PickupWizardScreenState extends State<PickupWizardScreen> {
  late PickupWizardStep _step;
  List<KatianExpedition> _pending = [];
  List<KatianExpedition> _withdrawn = [];
  bool _loadingList = false;

  KatianExpedition? _parcel;
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  bool _viewOnly = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _parcel = widget.initialParcel;
    _phoneCtrl.text = widget.initialParcel?.recipientPhone ?? '';
    _loadLists();
    if (widget.initialParcel != null && widget.initialStep != PickupWizardStep.list) {
      _loadParcelDetail(widget.initialParcel!.id);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() => _loadingList = true);
    try {
      final app = context.read<AppProvider>();
      final pending = await app.expeditions.list(
        mode: 'reception',
        currentStatus: 'EN_ATTENTE_RETRAIT',
      );
      final withdrawn = await app.expeditions.list(
        mode: 'reception',
        currentStatus: 'RETIRE',
      );
      if (mounted) {
        setState(() {
          _pending = pending.where(isPickupEligible).toList();
          _withdrawn = withdrawn;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _confirmWithdraw() async {
    final p = _parcel;
    if (p == null) return;
    if (p.hasPal) {
      _showSnack(
        'Contre-remboursement PAL (${_formatAmount(p.montantPal)}). '
        'Effectuez le paiement PAL avant le retrait.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final app = context.read<AppProvider>();
      final relayId = app.user?.relayPoint?.id;
      await app.expeditions.withdraw(
        p.id,
        recipientPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        relayId: relayId,
      );
      await app.loadDashboardStats();
      await _loadLists();
      if (mounted) setState(() => _step = PickupWizardStep.success);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(amount)} FCFA';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _selectParcel(KatianExpedition p, {bool viewOnly = false}) {
    setState(() {
      _parcel = p;
      _phoneCtrl.text = p.recipientPhone ?? '';
      _step = PickupWizardStep.detail;
      _viewOnly = viewOnly;
    });
    _loadParcelDetail(p.id);
  }

  Future<void> _loadParcelDetail(int id) async {
    try {
      final full = await context.read<AppProvider>().expeditions.detail(id);
      if (mounted && _parcel?.id == id) {
        setState(() => _parcel = full);
      }
    } catch (_) {}
  }

  int get _stepIndex {
    switch (_step) {
      case PickupWizardStep.list:
        return 0;
      case PickupWizardStep.detail:
        return 1;
      case PickupWizardStep.confirm:
        return 2;
      case PickupWizardStep.success:
        return 3;
    }
  }

  void _onBack() {
    switch (_step) {
      case PickupWizardStep.confirm:
        setState(() => _step = PickupWizardStep.detail);
      case PickupWizardStep.detail:
        if (widget.initialStep != PickupWizardStep.list) {
          Navigator.of(context).pop();
        } else {
          setState(() => _step = PickupWizardStep.list);
        }
      case PickupWizardStep.success:
        _finishSuccess();
      case PickupWizardStep.list:
        Navigator.of(context).pop();
    }
  }

  void _finishSuccess() {
    if (widget.embedded) {
      Navigator.of(context).popUntil((route) => route.settings.name == PickupRoutes.hub);
    } else {
      Navigator.of(context).pop(true);
    }
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
              title: Text(
                _stepTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: _onBack,
              ),
            ),
      body: Column(
        children: [
          if (widget.embedded)
            KatianFlowBar(title: _stepTitle, onBack: _onBack),
          _StepBar(step: _stepIndex, compact: widget.embedded),
          Expanded(child: _buildBody(ext)),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case PickupWizardStep.list:
        return 'Colis à retirer';
      case PickupWizardStep.detail:
        return 'Détail du colis';
      case PickupWizardStep.confirm:
        return 'Confirmation retrait';
      case PickupWizardStep.success:
        return 'Retrait validé';
    }
  }

  Widget _buildBody(KatianThemeExtension ext) {
    switch (_step) {
      case PickupWizardStep.list:
        return _buildListStep(ext);
      case PickupWizardStep.detail:
        return _parcel != null ? _buildDetailStep(ext, _parcel!) : const SizedBox.shrink();
      case PickupWizardStep.confirm:
        return _parcel != null ? _buildConfirmStep(ext, _parcel!) : const SizedBox.shrink();
      case PickupWizardStep.success:
        return _buildSuccessStep(ext);
    }
  }

  Widget _buildListStep(KatianThemeExtension ext) {
    return Column(
      children: [
        Expanded(
          child: _loadingList
              ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
              : (_pending.isEmpty && _withdrawn.isEmpty)
                  ? Center(
                      child: Text(
                        'Aucun colis en attente de retrait',
                        style: TextStyle(color: ext.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      color: KatianColors.red,
                      onRefresh: _loadLists,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        children: [
                          // ── Section : en attente ──
                          if (_pending.isNotEmpty) ...[
                            _SectionHeader(
                              ext: ext,
                              label: 'En attente de retrait',
                              count: _pending.length,
                              color: KatianColors.green,
                            ),
                            const SizedBox(height: 8),
                            ..._pending.map((p) => _PickupParcelCard(
                                  parcel: p,
                                  isWithdrawn: false,
                                  onTap: () => _selectParcel(p),
                                )),
                          ],
                          // ── Section : retirés ──
                          if (_withdrawn.isNotEmpty) ...[
                            SizedBox(height: _pending.isNotEmpty ? 16 : 0),
                            _SectionHeader(
                              ext: ext,
                              label: 'Retirés récemment',
                              count: _withdrawn.length,
                              color: ext.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            ..._withdrawn.map((p) => _PickupParcelCard(
                                  parcel: p,
                                  isWithdrawn: true,
                                  onTap: () => _selectParcel(p, viewOnly: true),
                                )),
                          ],
                        ],
                      ),
                    ),
        ),
        _BottomBtn(
          label: 'Saisir un code de retrait',
          icon: Icons.key_rounded,
          onPressed: () {
            if (widget.embedded) {
              Navigator.of(context).pushNamed(PickupRoutes.search);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PickupSearchScreen()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDetailStep(KatianThemeExtension ext, KatianExpedition p) {
    final isViewOnly = _viewOnly;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isViewOnly)
                _InfoBanner(
                  icon: Icons.check_circle_outline,
                  title: 'Colis retiré',
                  subtitle: 'Ce colis a déjà été remis au destinataire. Statut : ${p.statusLabel}.',
                  color: KatianColors.green,
                )
              else
                _InfoBanner(
                  icon: Icons.person_outline,
                  title: 'Remise au destinataire',
                  subtitle: 'Vérifiez l\'identité du client avant de continuer.',
                ),
              const SizedBox(height: 16),
              _FormCard(
                ext: ext,
                children: [
                  Text(
                    p.displayNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: ext.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Statut actuel',
                          style: TextStyle(fontSize: 12, color: ext.textSecondary),
                        ),
                      ),
                      Expanded(child: ParcelStatusBadge.fromParcel(p, compact: true)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (p.pickupCode != null)
                    _InfoRow(label: 'Code retrait', value: p.pickupCode!),
                  _InfoRow(label: 'Destinataire', value: p.recipientName ?? '—'),
                  _InfoRow(label: 'Téléphone', value: p.recipientPhone ?? '—'),
                  _InfoRow(label: 'Provenance', value: p.originRelayName ?? '—'),
                  _InfoRow(label: 'Destination', value: p.destinationRelayName ?? '—'),
                  if (p.amount != null)
                    _InfoRow(label: 'Montant', value: _formatAmount(p.amount)),
                  if (p.hasPal)
                    _InfoRow(label: 'PAL', value: _formatAmount(p.montantPal)),
                ],
              ),
              if (p.hasShippingPhoto) ...[
                const SizedBox(height: 16),
                ParcelShippingPhoto(photoRef: p.shippingPhotoUrl),
              ],
              if (p.hasPal) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KatianColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KatianColors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.payments_outlined, color: KatianColors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ce colis a un contre-remboursement PAL. '
                          'Le paiement PAL doit être effectué avant le retrait.',
                          style: TextStyle(fontSize: 13, color: KatianColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isViewOnly)
          _BottomBtn(
            label: 'Fermer',
            icon: Icons.close_rounded,
            onPressed: () => setState(() => _step = PickupWizardStep.list),
          )
        else
          _BottomBtn(
            label: p.hasPal ? 'PAL à régler d\'abord' : 'Continuer vers la confirmation',
            icon: Icons.arrow_forward_rounded,
            onPressed: p.hasPal ? null : () => setState(() => _step = PickupWizardStep.confirm),
          ),
      ],
    );
  }

  Widget _buildConfirmStep(KatianThemeExtension ext, KatianExpedition p) {
    final relay = context.read<AppProvider>().user?.displayRelayName ?? 'votre gare';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoBanner(
                icon: Icons.verified_outlined,
                title: 'Confirmation du retrait',
                subtitle: 'Le colis passera au statut Retiré (RETIRE).',
              ),
              const SizedBox(height: 16),
              _FormCard(
                ext: ext,
                children: [
                  Text('Récapitulatif', style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary)),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'N° colis', value: p.displayNumber),
                  _InfoRow(label: 'Code retrait', value: p.pickupCode ?? '—'),
                  _InfoRow(label: 'Destinataire', value: p.recipientName ?? '—'),
                  _InfoRow(label: 'Gare', value: relay),
                ],
              ),
              if (p.hasShippingPhoto) ...[
                const SizedBox(height: 16),
                ParcelShippingPhoto(photoRef: p.shippingPhotoUrl, height: 160),
              ],
              const SizedBox(height: 12),
              _StatusTransitionCard(
                ext: ext,
                fromLabel: p.statusLabel,
                toLabel: 'Retiré — livré au destinataire',
                fromColor: parcelStatusColor(p),
                toColor: parcelStatusColorFromNormalized('retire'),
              ),
              const SizedBox(height: 16),
              Text(
                'Téléphone du destinataire (optionnel)',
                style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '07 01 02 03 04',
                  filled: true,
                  fillColor: ext.surface,
                ),
              ),
            ],
          ),
        ),
        _BottomBtn(
          label: 'Confirmer le retrait',
          icon: Icons.check_circle_outline,
          loading: _submitting,
          onPressed: _submitting || !isPickupEligible(p) ? null : _confirmWithdraw,
        ),
      ],
    );
  }

  Widget _buildSuccessStep(KatianThemeExtension ext) {
    final p = _parcel;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KatianColors.green.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: KatianColors.green, size: 52),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Retrait validé avec succès !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KatianColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le colis a été remis au destinataire.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ext.textSecondary, fontSize: 14),
              ),
              if (p != null) ...[
                const SizedBox(height: 24),
                _FormCard(
                  ext: ext,
                  children: [
                    _InfoRow(label: 'N° colis', value: p.displayNumber),
                    _InfoRow(label: 'Destinataire', value: p.recipientName ?? '—'),
                    const _InfoRow(label: 'Statut actuel', value: 'Retiré'),
                  ],
                ),
              ],
            ],
          ),
        ),
        _BottomBtn(
          label: 'Retour',
          icon: Icons.home_outlined,
          filled: false,
          onPressed: _finishSuccess,
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, this.compact = false});
  final int step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, compact ? 6 : 8),
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= step ? KatianColors.green : ext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? KatianColors.green;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: c)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: context.katian.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.ext, required this.children});
  final KatianThemeExtension ext;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 12, color: ext.textSecondary))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary))),
        ],
      ),
    );
  }
}

class _StatusTransitionCard extends StatelessWidget {
  const _StatusTransitionCard({
    required this.ext,
    required this.fromLabel,
    required this.toLabel,
    required this.fromColor,
    required this.toColor,
  });

  final KatianThemeExtension ext;
  final String fromLabel;
  final String toLabel;
  final Color fromColor;
  final Color toColor;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      ext: ext,
      children: [
        Text('Changement de statut', style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: parcelStatusBackgroundColor(fromColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: fromColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  fromLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fromColor,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, color: KatianColors.green, size: 18),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: parcelStatusBackgroundColor(toColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: toColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  toLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: toColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.filled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: filled
            ? FilledButton.icon(
                onPressed: loading ? null : onPressed,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(icon ?? Icons.check),
                label: Text(label),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: KatianTheme.buttonShape,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon ?? Icons.arrow_back, size: 18),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: KatianTheme.buttonShape,
                ),
              ),
      ),
    );
  }
}

// ── En-tête de section ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.ext,
    required this.label,
    required this.count,
    required this.color,
  });

  final KatianThemeExtension ext;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: ext.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carte de colis retrait ────────────────────────────────────────────────────

class _PickupParcelCard extends StatelessWidget {
  const _PickupParcelCard({
    required this.parcel,
    required this.isWithdrawn,
    required this.onTap,
  });

  final KatianExpedition parcel;
  final bool isWithdrawn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final p = parcel;
    final statusColor = parcelStatusColor(p);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône statut
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: parcelStatusBackgroundColor(statusColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isWithdrawn ? Icons.check_circle_outline : Icons.key_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: ext.textPrimary,
                      ),
                    ),
                    if (p.recipientName != null && p.recipientName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: ext.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              p.recipientName!,
                              style: TextStyle(fontSize: 12, color: ext.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    ParcelStatusBadge.fromParcel(p, compact: true),
                  ],
                ),
              ),
              // Badge PAL ou chevron
              if (p.hasPal && !isWithdrawn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: KatianColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: KatianColors.orange,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: ext.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
