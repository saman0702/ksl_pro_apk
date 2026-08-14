import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/bordereau_colis_status.dart';
import '../../utils/parcel_status_colors.dart';
import '../../widgets/bordereau_qr_card.dart';
import '../../widgets/parcel_menu_sheets.dart';
import '../../widgets/parcel_status_badge.dart';

class ConvoyeurBordereauDetailScreen extends StatefulWidget {
  const ConvoyeurBordereauDetailScreen({super.key, required this.bordereauId});

  final int bordereauId;

  @override
  State<ConvoyeurBordereauDetailScreen> createState() =>
      _ConvoyeurBordereauDetailScreenState();
}

class _ConvoyeurBordereauDetailScreenState extends State<ConvoyeurBordereauDetailScreen> {
  BordereauExpedition? _bordereau;
  bool _loading = true;
  String? _error;
  int? _trackingColisId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await context.read<AppProvider>().bordereaux.detail(widget.bordereauId);
      if (mounted) setState(() => _bordereau = detail);
    } catch (e) {
      if (mounted) {
        setState(() => _error = context.read<AppProvider>().formatError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openColisTracking(BordereauColisLine colis) async {
    if (_trackingColisId == colis.expeditionId) return;
    setState(() => _trackingColisId = colis.expeditionId);
    final data = await context.read<AppProvider>().fetchTraceability(colis.expeditionId);
    if (!mounted) return;
    setState(() => _trackingColisId = null);
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de charger le suivi du colis'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await TraceabilitySheet.show(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final b = _bordereau;

    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        title: Text(b?.number ?? 'Bordereau'),
        backgroundColor: KatianColors.red,
        foregroundColor: KatianColors.white,
        actions: [
          if (b != null)
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: ext.textSecondary)),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : b == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: KatianColors.red,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          BordereauQrCard(
                            number: b.number,
                            subtitle: 'Présentez ce QR à la gare de destination pour la réception',
                          ),
                          const SizedBox(height: 16),
                          _SummaryCard(bordereau: b, ext: ext),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Colis du bordereau (${b.colis.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: ext.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                'Appuyez pour le suivi',
                                style: TextStyle(color: ext.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (b.colis.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Aucun colis sur ce bordereau.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: ext.textSecondary),
                              ),
                            )
                          else
                            ...b.colis.map((c) => _ColisTile(
                                  colis: c,
                                  loading: _trackingColisId == c.expeditionId,
                                  onTap: () => _openColisTracking(c),
                                )),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.bordereau, required this.ext});

  final BordereauExpedition bordereau;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    final stats = BordereauColisStats(bordereau.colis);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bordereau.number,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: ext.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KatianColors.redLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bordereauStatusLabel(bordereau.status),
                    style: const TextStyle(
                      color: KatianColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Départ', value: bordereau.departureLabel),
            _InfoRow(label: 'Gare', value: bordereau.departureRelayName ?? '—'),
            _InfoRow(label: 'Véhicule', value: bordereau.carNumber ?? '—'),
            _InfoRow(label: 'Conducteur', value: bordereau.driverName ?? '—'),
            if (bordereau.comment?.trim().isNotEmpty == true)
              _InfoRow(label: 'Commentaire', value: bordereau.comment!),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Total', value: '${stats.total}', color: KatianColors.blue),
                _StatChip(label: 'Expédiés', value: '${stats.expedie}', color: KatianColors.orange),
                _StatChip(label: 'En transit', value: '${stats.enTransit}', color: KatianColors.teal),
                _StatChip(label: 'Reçus', value: '${stats.recuDestination}', color: KatianColors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _ColisTile extends StatelessWidget {
  const _ColisTile({
    required this.colis,
    required this.onTap,
    this.loading = false,
  });

  final BordereauColisLine colis;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final status = bordereauColisStatusLabel(colis);
    final statusColor = parcelStatusColorFromLabel(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ext.border),
      ),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KatianColors.redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: KatianColors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colis.expeditionNumber ?? colis.orderNumber ?? 'Colis #${colis.expeditionId}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ext.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colis.recipientName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ext.textSecondary, fontSize: 13),
                    ),
                    Text(
                      colis.destination ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ext.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ParcelStatusBadge.fromLabel(status, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: KatianColors.red),
                )
              else
                Column(
                  children: [
                    Icon(Icons.route_outlined, color: statusColor, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      'Suivi',
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: ext.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
