import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/parcel_actions.dart';
import '../../utils/parcel_status.dart';
import '../../utils/parcel_status_colors.dart';
import '../../widgets/parcel_status_badge.dart';
import '../../widgets/parcel_thumbnail.dart';
import 'reception_scan_screen.dart';

enum _ReceptionFilter { all, pending, received }

class ReceptionWizardScreen extends StatefulWidget {
  const ReceptionWizardScreen({
    super.key,
    this.initialStep = ReceptionWizardStep.list,
    this.initialParcel,
    this.initialBordereau,
    this.initialTarget,
  });

  final ReceptionWizardStep initialStep;
  final KatianExpedition? initialParcel;
  final BordereauExpedition? initialBordereau;
  final ReceptionScanTarget? initialTarget;

  @override
  State<ReceptionWizardScreen> createState() => _ReceptionWizardScreenState();
}

class _ReceptionWizardScreenState extends State<ReceptionWizardScreen> {
  late ReceptionWizardStep _step;
  _ReceptionFilter _filter = _ReceptionFilter.pending;
  /// Liste élargie (A_EXPEDIER + EXPEDIE) — onglet « Tous ».
  List<KatianExpedition> _incoming = [];
  /// Colis réceptionnables (EXPEDIE uniquement) — onglet « À recevoir ».
  List<KatianExpedition> _receivable = [];
  List<KatianExpedition> _received = [];
  bool _loadingList = false;

  KatianExpedition? _parcel;
  BordereauExpedition? _bordereau;
  ReceptionScanTarget? _target;
  String? _resultStatusLabel;
  int _bulkReceivedCount = 0;
  bool _submitting = false;
  bool _loadingDetail = false;
  bool _viewOnly = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _parcel = widget.initialParcel;
    _bordereau = widget.initialBordereau;
    _target = widget.initialTarget;
    _loadLists();
    if (_parcel != null && _parcel!.id > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshParcelDetail());
    }
  }

  Future<void> _refreshParcelDetail() async {
    final current = _parcel;
    if (current == null || current.id <= 0 || !mounted) return;
    setState(() => _loadingDetail = true);
    try {
      final full = await context.read<AppProvider>().expeditions.detail(current.id);
      if (mounted) setState(() => _parcel = full);
    } catch (e) {
      if (mounted) _showSnack('Impossible de charger le détail du colis.');
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _loadLists() async {
    setState(() => _loadingList = true);
    try {
      final app = context.read<AppProvider>();
      final relayId = app.user?.relayPoint?.id;
      final incoming = await app.expeditions.receptionables(
        relayId: relayId,
        scope: 'pending',
      );
      final receivable = await app.expeditions.receptionables(
        relayId: relayId,
        scope: 'receivable',
      );
      final transit = await app.expeditions.list(
        mode: 'reception',
        currentStatus: 'EN_TRANSIT',
      );
      final attente = await app.expeditions.list(
        mode: 'reception',
        currentStatus: 'EN_ATTENTE_RETRAIT',
      );
      final receivedMap = <int, KatianExpedition>{};
      for (final p in [...transit, ...attente]) {
        receivedMap[p.id] = p;
      }
      if (mounted) {
        setState(() {
          _incoming = incoming;
          _receivable = receivable;
          _received = receivedMap.values.toList();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  List<KatianExpedition> get _filteredList {
    switch (_filter) {
      case _ReceptionFilter.pending:
        return _receivable;
      case _ReceptionFilter.received:
        return _received;
      case _ReceptionFilter.all:
        final map = <int, KatianExpedition>{};
        for (final p in _incoming) {
          map[p.id] = p;
        }
        for (final p in _received) {
          map[p.id] = p;
        }
        return map.values.toList();
    }
  }

  int get _totalListCount {
    final ids = <int>{};
    for (final p in _incoming) {
      ids.add(p.id);
    }
    for (final p in _received) {
      ids.add(p.id);
    }
    return ids.length;
  }

  Future<void> _confirmReception() async {
    setState(() => _submitting = true);
    try {
      final app = context.read<AppProvider>();
      if (_target == ReceptionScanTarget.bordereau && _bordereau != null) {
        final result = await app.bordereaux.receiveBulk(_bordereau!.id);
        _bulkReceivedCount = result.receivedCount;
        _resultStatusLabel = '${result.receivedCount} colis réceptionnés';
        await app.loadDashboardStats();
        await _loadLists();
        setState(() => _step = ReceptionWizardStep.success);
        return;
      }

      if (_parcel != null) {
        if (!_parcel!.canReceive) {
          _showSnack(
            'Réception impossible : le colis doit être au statut Expédié.',
          );
          return;
        }
        final updated = await app.parcelStatus.applyAction(
          _parcel!,
          ParcelActionKind.receive,
        );
        _parcel = updated;
        _resultStatusLabel = _statusAfterReceive(updated.currentStatus);
        await app.loadDashboardStats();
        await _loadLists();
        setState(() => _step = ReceptionWizardStep.success);
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusAfterReceive(String? status) {
    final s = normalizeParcelStatus(status);
    if (s == 'en_attente_retrait') return 'Disponible au retrait';
    if (s == 'en_transit') return 'En transit — réceptionné à la gare';
    return status ?? 'Réceptionné';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _selectParcel(KatianExpedition p, {bool viewOnly = false}) {
    if (!viewOnly && !p.canReceive) {
      _showSnack(
        'Réception impossible : le colis doit être au statut Expédié.',
      );
      return;
    }
    setState(() {
      _parcel = p;
      _bordereau = null;
      _target = ReceptionScanTarget.parcel;
      _step = ReceptionWizardStep.detail;
      _viewOnly = viewOnly;
    });
    _refreshParcelDetail();
  }

  Future<void> _openScan() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReceptionScanScreen()),
    );
    if (ok == true && mounted) await _loadLists();
  }

  int get _stepIndex {
    switch (_step) {
      case ReceptionWizardStep.list:
        return 0;
      case ReceptionWizardStep.detail:
        return 1;
      case ReceptionWizardStep.confirm:
        return 2;
      case ReceptionWizardStep.success:
        return 3;
    }
  }

  void _onBack() {
    switch (_step) {
      case ReceptionWizardStep.confirm:
        setState(() => _step = ReceptionWizardStep.detail);
      case ReceptionWizardStep.detail:
        if (widget.initialStep != ReceptionWizardStep.list) {
          Navigator.of(context).pop();
        } else {
          setState(() => _step = ReceptionWizardStep.list);
        }
      case ReceptionWizardStep.success:
        Navigator.of(context).pop(true);
      case ReceptionWizardStep.list:
        Navigator.of(context).pop();
    }
  }

  String? get _currentRelayName =>
      context.read<AppProvider>().user?.displayRelayName;

  String _parcelNature(KatianExpedition p) {
    final raw = p.raw;
    final typeColis = raw['type_colis']?.toString().trim();
    final infocolisRaw = raw['infocolis'];
    dynamic infocolis = infocolisRaw;
    if (infocolisRaw is String && infocolisRaw.trim().isNotEmpty) {
      try {
        infocolis = jsonDecode(infocolisRaw);
      } catch (_) {}
    }
    if (infocolis is List && infocolis.isNotEmpty) {
      final first = infocolis.first;
      if (first is Map) {
        final cat = first['category']?.toString() ?? typeColis ?? '—';
        final name = first['name']?.toString() ?? '';
        return '$cat${name.isNotEmpty ? ' — $name' : ''}';
      }
    }
    if (p.packageDescription != null) return p.packageDescription!;
    return typeColis?.isNotEmpty == true ? typeColis! : '—';
  }

  String _expectedStatusLabel(KatianExpedition p) {
    if (p.isReturn) return 'Retour réceptionné à la gare';
    final dest = p.destinationRelayName?.trim().toLowerCase();
    final here = _currentRelayName?.trim().toLowerCase();
    if (dest != null && here != null && dest == here) {
      return 'En attente de retrait';
    }
    return 'En transit — disponible à la gare';
  }

  Color _expectedStatusColor(KatianExpedition p) {
    if (p.isReturn) {
      return parcelStatusColorFromNormalized('return_arrived');
    }
    final dest = p.destinationRelayName?.trim().toLowerCase();
    final here = _currentRelayName?.trim().toLowerCase();
    if (dest != null && here != null && dest == here) {
      return parcelStatusColorFromNormalized('en_attente_retrait');
    }
    return parcelStatusColorFromNormalized('en_transit');
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(amount)} FCFA';
  }

  String _bordereauColisStatus(BordereauColisLine c) {
    final raw = c.isReturn ? c.returnStatus : c.currentStatus;
    if (raw == null || raw.isEmpty) return '—';
    switch (raw.toUpperCase().replaceAll(' ', '_')) {
      case 'EXPEDIE':
        return 'Expédié';
      case 'RETURN_EXPEDIE':
        return 'Retour expédié';
      case 'EN_TRANSIT':
        return 'En transit';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  String get _statusActuelLabel => 'Statut actuel';

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
      ),
      body: Column(
        children: [
          _StepBar(step: _stepIndex),
          Expanded(child: _buildBody(ext)),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case ReceptionWizardStep.list:
        return 'Colis à réceptionner';
      case ReceptionWizardStep.detail:
        return _target == ReceptionScanTarget.bordereau
            ? 'Détail du bordereau'
            : 'Détail du colis';
      case ReceptionWizardStep.confirm:
        return 'Confirmation réception';
      case ReceptionWizardStep.success:
        return 'Réception validée';
    }
  }

  Widget _buildBody(KatianThemeExtension ext) {
    switch (_step) {
      case ReceptionWizardStep.list:
        return _buildListStep(ext);
      case ReceptionWizardStep.detail:
        return _buildDetailStep(ext);
      case ReceptionWizardStep.confirm:
        return _buildConfirmStep(ext);
      case ReceptionWizardStep.success:
        return _buildSuccessStep(ext);
    }
  }

  Widget _buildListStep(KatianThemeExtension ext) {
    final list = _filteredList;
    final user = context.read<AppProvider>().user;
    return Column(
      children: [
        _FilterRow(
          filter: _filter,
          total: _totalListCount,
          pending: _receivable.length,
          received: _received.length,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: _loadingList
              ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
              : list.isEmpty
                  ? Center(child: Text('Aucun colis', style: TextStyle(color: ext.textSecondary)))
                  : RefreshIndicator(
                      color: KatianColors.red,
                      onRefresh: _loadLists,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final p = list[i];
                          final isReceived = _received.any((x) => x.id == p.id);
                          final isReceivable =
                              p.canReceive && _receivable.any((x) => x.id == p.id);
                          final shipToYou = !isReceived &&
                              isShipToYouPending(p, user);
                          final trailingLabel = isReceived
                              ? 'Reçu'
                              : (isReceivable
                                  ? 'À recevoir'
                                  : 'À expédier vers vous');
                          final trailingColor = isReceived
                              ? parcelStatusColor(p)
                              : (isReceivable
                                  ? parcelStatusColorFromNormalized('expedie')
                                  : parcelStatusColorFromNormalized('a_expedier'));
                          return _ReceptionParcelCard(
                            parcel: p,
                            trailingLabel: trailingLabel,
                            trailingColor: trailingColor,
                            isReceived: isReceived,
                            onTap: isReceivable
                                ? () => _selectParcel(p)
                                : () => _selectParcel(p, viewOnly: true),
                          );
                        },
                      ),
                    ),
        ),
        _BottomBtn(
          label: 'Scanner un colis',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: _openScan,
        ),
      ],
    );
  }

  Widget _buildDetailStep(KatianThemeExtension ext) {
    if (_target == ReceptionScanTarget.bordereau && _bordereau != null) {
      return _buildBordereauDetail(ext, _bordereau!);
    }
    if (_parcel != null) {
      return _buildParcelDetail(ext, _parcel!);
    }
    return const Center(child: Text('Aucune donnée'));
  }

  Widget _buildConfirmStep(KatianThemeExtension ext) {
    if (_target == ReceptionScanTarget.bordereau && _bordereau != null) {
      return _buildBordereauConfirm(ext, _bordereau!);
    }
    if (_parcel != null) {
      return _buildParcelConfirm(ext, _parcel!);
    }
    return const Center(child: Text('Aucune donnée'));
  }

  Widget _buildParcelDetail(KatianThemeExtension ext, KatianExpedition p) {
    if (_loadingDetail) {
      return const Center(
        child: CircularProgressIndicator(color: KatianColors.red),
      );
    }

    final nature = _parcelNature(p);
    final raw = p.raw;
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
                  title: 'Colis réceptionné',
                  subtitle:
                      'Ce colis a déjà été réceptionné. Statut actuel : ${p.statusLabel}.',
                  color: const Color(0xFF34C759),
                )
              else
                _InfoBanner(
                  icon: Icons.inventory_2_outlined,
                  title: 'Fiche colis',
                  subtitle: 'Vérifiez les informations avant de continuer.',
                ),
              const SizedBox(height: 16),
              _ParcelHeroCard(ext: ext, parcel: p),
              const SizedBox(height: 12),
              _RouteCard(ext: ext, parcel: p),
              const SizedBox(height: 12),
              _PersonCard(
                ext: ext,
                title: 'Destinataire',
                name: p.recipientName ?? '—',
                phone: p.recipientPhone,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _PersonCard(
                ext: ext,
                title: 'Expéditeur',
                name: p.senderName ?? '—',
                phone: p.senderPhone,
                icon: Icons.send_outlined,
              ),
              const SizedBox(height: 12),
              _FormCard(
                ext: ext,
                children: [
                  Text(
                    'Informations colis',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ext.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (p.orderNumber != null && p.orderNumber!.isNotEmpty)
                    _InfoRow(label: 'N° commande', value: p.orderNumber!),
                  _InfoRow(label: 'Nature', value: nature),
                  _InfoRow(label: 'Statut actuel', value: p.statusLabel),
                  _InfoRow(label: 'Montant', value: _formatAmount(p.amount)),
                  if (p.pickupCode != null)
                    _InfoRow(label: 'Code retrait', value: p.pickupCode!),
                  if (p.paymentMode != null)
                    _InfoRow(label: 'Mode paiement', value: p.paymentMode!),
                  if (p.hasPal)
                    _InfoRow(
                      label: 'PAL',
                      value: _formatAmount(p.montantPal),
                    ),
                  if (p.packageDescription != null)
                    _InfoRow(label: 'Description', value: p.packageDescription!),
                  if (p.carrierName != null)
                    _InfoRow(label: 'Transporteur', value: p.carrierName!),
                  if (raw['depart'] != null)
                    _InfoRow(label: 'Ville départ', value: raw['depart'].toString()),
                  if (raw['destination'] != null)
                    _InfoRow(label: 'Ville destination', value: raw['destination'].toString()),
                  if (raw['type_service'] != null)
                    _InfoRow(label: 'Type service', value: raw['type_service'].toString()),
                  if (p.isReturn)
                    _InfoRow(label: 'Type', value: 'Colis retour'),
                  if (p.currentRelayName != null)
                    _InfoRow(label: 'Gare actuelle', value: p.currentRelayName!),
                ],
              ),
              if (!isViewOnly && !p.canReceive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KatianColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: KatianColors.orange.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: KatianColors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ce colis n\'est pas encore expédié. Il apparaît ici car sa destination est votre gare, mais la réception n\'est possible qu\'au statut Expédié.',
                          style: TextStyle(color: KatianColors.orange, fontSize: 13),
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
            onPressed: () => setState(() => _step = ReceptionWizardStep.list),
          )
        else
          _BottomBtn(
            label: p.canReceive
                ? 'Continuer vers la confirmation'
                : 'Réception indisponible',
            icon: p.canReceive ? Icons.arrow_forward_rounded : Icons.block_outlined,
            onPressed: p.canReceive
                ? () => setState(() => _step = ReceptionWizardStep.confirm)
                : null,
          ),
      ],
    );
  }

  Widget _buildParcelConfirm(KatianThemeExtension ext, KatianExpedition p) {
    final relay = _currentRelayName ?? 'votre gare';
    final expected = _expectedStatusLabel(p);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoBanner(
                icon: Icons.verified_outlined,
                title: 'Confirmation de réception',
                subtitle:
                    'Le colis sera enregistré à $relay après validation.',
              ),
              const SizedBox(height: 16),
              _RecapCard(
                ext: ext,
                title: 'Récapitulatif',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KatianColors.redLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.displayNumber,
                    style: const TextStyle(
                      color: KatianColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                rows: [
                  _RecapItem(
                    icon: Icons.trip_origin,
                    label: 'Provenance',
                    value: p.originRelayName ?? '—',
                  ),
                  _RecapItem(
                    icon: Icons.location_on_outlined,
                    label: 'Destination finale',
                    value: p.destinationRelayName ?? '—',
                  ),
                  _RecapItem(
                    icon: Icons.person_outline,
                    label: 'Destinataire',
                    value: p.recipientName ?? '—',
                  ),
                  if (p.recipientPhone != null)
                    _RecapItem(
                      icon: Icons.phone_outlined,
                      label: 'Tél. destinataire',
                      value: p.recipientPhone!,
                    ),
                  if (p.senderName != null)
                    _RecapItem(
                      icon: Icons.send_outlined,
                      label: 'Expéditeur',
                      value: p.senderName!,
                    ),
                  _RecapItem(
                    icon: Icons.info_outline,
                    label: _statusActuelLabel,
                    value: p.statusLabel,
                  ),
                  _RecapItem(
                    icon: Icons.category_outlined,
                    label: 'Nature',
                    value: _parcelNature(p),
                  ),
                  _RecapItem(
                    icon: Icons.store_outlined,
                    label: 'Gare de réception',
                    value: relay,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatusTransitionCard(
                ext: ext,
                fromLabel: p.statusLabel,
                toLabel: expected,
                fromColor: parcelStatusColor(p),
                toColor: _expectedStatusColor(p),
              ),
              if (!p.canReceive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KatianColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: KatianColors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ce colis ne semble pas éligible à la réception (statut incorrect).',
                          style: TextStyle(color: KatianColors.redDark, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _BottomBtn(
          label: 'Confirmer la réception',
          icon: Icons.inventory_2_outlined,
          loading: _submitting,
          onPressed: _submitting || !p.canReceive ? null : _confirmReception,
        ),
      ],
    );
  }

  Widget _buildBordereauDetail(KatianThemeExtension ext, BordereauExpedition b) {
    final eligible = b.colis.where((c) => c.canReceive).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoBanner(
                icon: Icons.receipt_long_outlined,
                title: 'Bordereau d\'expédition',
                subtitle:
                    '${eligible.length} colis éligibles sur ${b.parcelCount} au total.',
              ),
              const SizedBox(height: 16),
              _FormCard(
                ext: ext,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.number,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: ext.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: KatianColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${eligible.length} à recevoir',
                          style: const TextStyle(
                            color: KatianColors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Départ : ${b.departureRelayName ?? '—'}',
                    style: TextStyle(color: ext.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Car', value: b.carNumber ?? '—'),
                  _InfoRow(label: 'Conducteur', value: b.driverName ?? '—'),
                  if (b.driverPhone != null)
                    _InfoRow(label: 'Téléphone', value: b.driverPhone!),
                  _InfoRow(label: 'Date départ', value: b.departureLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Colis du bordereau',
                style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
              ),
              const SizedBox(height: 8),
              ...eligible.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: ext.border),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: KatianColors.redLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: KatianColors.red, size: 18),
                    ),
                    title: Text(
                      c.expeditionNumber ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.recipientName ?? '—'} · ${c.destination ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ParcelStatusBadge.fromLabel(
                          _bordereauColisStatus(c),
                          compact: true,
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.check_circle_outline,
                      color: parcelStatusColorFromLabel(_bordereauColisStatus(c)),
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (eligible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Aucun colis éligible sur ce bordereau.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ext.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        _BottomBtn(
          label: eligible.isEmpty
              ? 'Aucun colis à recevoir'
              : 'Continuer (${eligible.length} colis)',
          icon: Icons.arrow_forward_rounded,
          onPressed: eligible.isEmpty
              ? null
              : () => setState(() => _step = ReceptionWizardStep.confirm),
        ),
      ],
    );
  }

  Widget _buildBordereauConfirm(KatianThemeExtension ext, BordereauExpedition b) {
    final eligible = b.colis.where((c) => c.canReceive).toList();
    final relay = _currentRelayName ?? 'votre gare';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoBanner(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Réception groupée',
                subtitle:
                    'Tous les colis éligibles seront réceptionnés à $relay en une seule action.',
              ),
              const SizedBox(height: 16),
              _RecapCard(
                ext: ext,
                title: 'Récapitulatif bordereau',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KatianColors.redLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    b.number,
                    style: const TextStyle(
                      color: KatianColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                rows: [
                  _RecapItem(
                    icon: Icons.trip_origin,
                    label: 'Gare de départ',
                    value: b.departureRelayName ?? '—',
                  ),
                  _RecapItem(
                    icon: Icons.directions_bus_outlined,
                    label: 'Car / Conducteur',
                    value: '${b.carNumber ?? '—'} · ${b.driverName ?? '—'}',
                  ),
                  _RecapItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date départ',
                    value: b.departureLabel,
                  ),
                  _RecapItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Colis à réceptionner',
                    value: '${eligible.length} sur ${b.parcelCount}',
                  ),
                  _RecapItem(
                    icon: Icons.store_outlined,
                    label: 'Gare de réception',
                    value: relay,
                  ),
                ],
              ),
              if (eligible.isNotEmpty) ...[
                const SizedBox(height: 12),
                _FormCard(
                  ext: ext,
                  children: [
                    Text(
                      'Aperçu des colis',
                      style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    ...eligible.take(5).map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, size: 6, color: KatianColors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${c.expeditionNumber ?? '—'} → ${c.destination ?? '—'}',
                                    style: TextStyle(fontSize: 12, color: ext.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (eligible.length > 5)
                      Text(
                        '+ ${eligible.length - 5} autre(s) colis',
                        style: TextStyle(
                          fontSize: 12,
                          color: ext.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _StatusTransitionCard(
                ext: ext,
                fromLabel: 'Expédié',
                toLabel: 'En transit — réceptionné à la gare',
                fromColor: parcelStatusColorFromNormalized('expedie'),
                toColor: parcelStatusColorFromNormalized('en_transit'),
              ),
            ],
          ),
        ),
        _BottomBtn(
          label: 'Confirmer réception groupée (${eligible.length})',
          icon: Icons.done_all,
          loading: _submitting,
          onPressed: _submitting || eligible.isEmpty ? null : _confirmReception,
        ),
      ],
    );
  }

  Widget _buildSuccessStep(KatianThemeExtension ext) {
    final isBulk = _target == ReceptionScanTarget.bordereau;
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
              Text(
                isBulk ? 'Réception groupée validée !' : 'Colis réceptionné avec succès !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: KatianColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isBulk
                    ? 'Les colis du bordereau sont maintenant à la gare.'
                    : 'Le colis est enregistré à ${_currentRelayName ?? 'la gare'}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: ext.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_resultStatusLabel != null)
                _RecapCard(
                  ext: ext,
                  title: 'Résultat',
                  rows: [
                    if (_parcel != null)
                      _RecapItem(
                        icon: Icons.tag,
                        label: 'N° colis',
                        value: _parcel!.displayNumber,
                      ),
                    if (isBulk && _bordereau != null)
                      _RecapItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Bordereau',
                        value: _bordereau!.number,
                      ),
                    _RecapItem(
                      icon: Icons.info_outline,
                      label: 'Statut',
                      value: _resultStatusLabel!,
                    ),
                    if (isBulk && _bulkReceivedCount > 0)
                      _RecapItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Colis traités',
                        value: '$_bulkReceivedCount',
                      ),
                  ],
                ),
            ],
          ),
        ),
        _BottomBtn(
          label: 'Retour à la liste',
          icon: Icons.list_alt_outlined,
          filled: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= step ? KatianColors.red : ext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.total,
    required this.pending,
    required this.received,
    required this.onChanged,
  });

  final _ReceptionFilter filter;
  final int total;
  final int pending;
  final int received;
  final ValueChanged<_ReceptionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Tab(label: 'Tous ($total)', selected: filter == _ReceptionFilter.all, onTap: () => onChanged(_ReceptionFilter.all)),
          _Tab(label: 'À recevoir ($pending)', selected: filter == _ReceptionFilter.pending, onTap: () => onChanged(_ReceptionFilter.pending)),
          _Tab(label: 'Reçus ($received)', selected: filter == _ReceptionFilter.received, onTap: () => onChanged(_ReceptionFilter.received)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? KatianColors.red : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? KatianColors.red : context.katian.textSecondary,
            ),
          ),
        ),
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
  /// Couleur principale du bandeau (par défaut rouge).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? KatianColors.red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.katian.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParcelHeroCard extends StatelessWidget {
  const _ParcelHeroCard({required this.ext, required this.parcel});

  final KatianThemeExtension ext;
  final KatianExpedition parcel;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      ext: ext,
      children: [
        Row(
          children: [
            ParcelThumbnail(
              parcel: parcel,
              width: 64,
              height: 64,
              borderRadius: 12,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parcel.displayNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: ext.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parcel.isReturn ? 'Colis retour' : 'Colis standard',
                    style: TextStyle(fontSize: 12, color: ext.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: parcelStatusBackgroundColor(parcelStatusColor(parcel)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: parcelStatusColor(parcel).withValues(alpha: 0.25),
                ),
              ),
              child: ParcelStatusBadge.fromParcel(parcel, compact: true, badge: false),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.ext, required this.parcel});

  final KatianThemeExtension ext;
  final KatianExpedition parcel;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      ext: ext,
      children: [
        Text(
          'Itinéraire',
          style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const Icon(Icons.trip_origin, color: KatianColors.red, size: 20),
                Container(width: 2, height: 28, color: ext.border),
                const Icon(Icons.location_on, color: KatianColors.green, size: 20),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Départ', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
                  Text(
                    parcel.originRelayName ?? '—',
                    style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary),
                  ),
                  const SizedBox(height: 18),
                  Text('Destination', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
                  Text(
                    parcel.destinationRelayName ?? '—',
                    style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.ext,
    required this.title,
    required this.name,
    this.phone,
    required this.icon,
  });

  final KatianThemeExtension ext;
  final String title;
  final String name;
  final String? phone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      ext: ext,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: ext.textSecondary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        Text(name, style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary)),
        if (phone != null && phone!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: ext.textSecondary),
              const SizedBox(width: 6),
              Text(phone!, style: TextStyle(fontSize: 13, color: ext.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}

class _RecapItem {
  const _RecapItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({
    required this.ext,
    required this.title,
    required this.rows,
    this.trailing,
  });

  final KatianThemeExtension ext;
  final String title;
  final List<_RecapItem> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      ext: ext,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ext.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(row.icon, size: 18, color: ext.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(fontSize: 12, color: ext.textSecondary),
                      ),
                      Text(
                        row.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ext.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        Text(
          'Changement de statut',
          style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
        ),
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
              child: Icon(Icons.arrow_forward, color: KatianColors.red, size: 18),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
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
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: ext.textPrimary),
            ),
          ),
        ],
      ),
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
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

class _ReceptionParcelCard extends StatelessWidget {
  const _ReceptionParcelCard({
    required this.parcel,
    required this.trailingLabel,
    required this.trailingColor,
    required this.isReceived,
    required this.onTap,
  });

  final KatianExpedition parcel;
  final String trailingLabel;
  final Color trailingColor;
  final bool isReceived;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
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
              ParcelThumbnail(
                parcel: parcel,
                width: 56,
                height: 56,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.displayNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: ext.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            parcel.originRelayName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: ext.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: ext.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            parcel.destinationRelayName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 12,
                              color: ext.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isReceived) ...[
                      const SizedBox(height: 6),
                      ParcelStatusBadge.fromParcel(parcel, compact: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(maxWidth: 90),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: trailingColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: trailingColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  trailingLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trailingColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
