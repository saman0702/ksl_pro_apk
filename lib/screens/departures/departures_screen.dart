import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../navigation/flow_navigation.dart';
import '../../providers/app_provider.dart';
import '../../widgets/katian_bottom_sheet.dart';
import '../../widgets/katian_scaffold.dart';
import 'departure_wizard_screen.dart';

class DeparturesScreen extends StatefulWidget {
  const DeparturesScreen({super.key});

  @override
  State<DeparturesScreen> createState() => _DeparturesScreenState();
}

class _DeparturesScreenState extends State<DeparturesScreen> {
  List<BordereauExpedition> _history = [];
  bool _loading = false;
  DepartureFlowRequest? _handledDepartureRequest;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _consumeDepartureFlow(AppProvider app) {
    final request = app.departureFlowRequest;
    if (request == null || identical(request, _handledDepartureRequest)) return;

    _handledDepartureRequest = request;
    app.clearDepartureFlowRequest();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openWizard(preselectedIds: request.parcelIds);
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<AppProvider>().bordereaux.list(limit: 30);
      if (mounted) setState(() => _history = list);
    } catch (_) {
      // silencieux — l'écran reste utilisable
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openWizard({Set<int> preselectedIds = const {}}) async {
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DepartureWizardScreen(
          initialSelectedIds: preselectedIds,
        ),
      ),
    );
    if (refreshed == true) {
      await context.read<AppProvider>().loadAllParcelLists();
      await _loadHistory();
    }
  }

  Future<void> _openDetail(BordereauExpedition b) async {
    await showKatianWhiteBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BordereauDetailSheet(summary: b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final app = context.watch<AppProvider>();
    _consumeDepartureFlow(app);
    return KatianScaffold(
      title: 'Départs',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FilledButton.icon(
              onPressed: _openWizard,
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Préparer un départ'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: KatianTheme.buttonShape,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bordereaux récents',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ext.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
                : _history.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun bordereau enregistré',
                          style: TextStyle(color: ext.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        color: KatianColors.red,
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final b = _history[index];
                            final ext = context.katian;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openDetail(b),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: KatianColors.redLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.description_outlined,
                                          color: KatianColors.red,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b.number,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: ext.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${b.departureLabel} · ${b.parcelCount} colis',
                                              style: TextStyle(fontSize: 12, color: ext.textSecondary),
                                            ),
                                            if (b.driverName != null && b.driverName!.isNotEmpty)
                                              Text(
                                                b.driverName!,
                                                style: TextStyle(fontSize: 12, color: ext.textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: ext.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet détail bordereau ──────────────────────────────────────────

class _BordereauDetailSheet extends StatefulWidget {
  const _BordereauDetailSheet({required this.summary});
  final BordereauExpedition summary;

  @override
  State<_BordereauDetailSheet> createState() => _BordereauDetailSheetState();
}

class _BordereauDetailSheetState extends State<_BordereauDetailSheet> {
  BordereauExpedition? _full;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final full = await context.read<AppProvider>().bordereaux.detail(widget.summary.id);
      if (mounted) setState(() => _full = full);
    } catch (_) {
      if (mounted) setState(() => _full = widget.summary);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _print() async {
    final b = _full ?? widget.summary;
    setState(() => _printing = true);
    try {
      await context.read<AppProvider>().documents.generateBordereau(b);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PDF : $e')),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final b = _full ?? widget.summary;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: maxH,
      child: Column(
        children: [
          // ── Drag handle ──
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KatianColors.redLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: KatianColors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.number,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: ext.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(label: b.departureLabel, icon: Icons.schedule_outlined),
                          const SizedBox(width: 6),
                          _StatusChip(
                            label: '${b.parcelCount} colis',
                            icon: Icons.inventory_2_outlined,
                            color: KatianColors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: ext.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ext.border),
          // ── Body ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SectionLabel(ext: ext, label: 'Itinéraire & logistique'),
                      const SizedBox(height: 8),
                      _LogisticsGrid(ext: ext, bordereau: b),
                      if ((b.driverName != null && b.driverName!.isNotEmpty) ||
                          (b.driverPhone != null && b.driverPhone!.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        _SectionLabel(ext: ext, label: 'Conducteur'),
                        const SizedBox(height: 8),
                        _DriverCard(ext: ext, bordereau: b),
                      ],
                      if (b.comment != null && b.comment!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SectionLabel(ext: ext, label: 'Commentaire'),
                        const SizedBox(height: 8),
                        _CommentCard(ext: ext, comment: b.comment!),
                      ],
                      const SizedBox(height: 12),
                      _SectionLabel(ext: ext, label: 'Colis du bordereau'),
                      const SizedBox(height: 8),
                      _ColisCard(ext: ext, colis: b.colis, total: b.parcelCount),
                    ],
                  ),
          ),
          // ── Bouton imprimer ──
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _printing ? null : _print,
                icon: _printing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_outlined),
                label: Text(_printing ? 'Génération…' : 'Imprimer le bordereau'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: KatianTheme.buttonShape,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chips statut dans le header ──────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon, this.color});
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.katian.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

// ── Titre de section ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.ext, required this.label});
  final KatianThemeExtension ext;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: ext.textSecondary,
      ),
    );
  }
}

// ── Grille logistique (2 colonnes) ───────────────────────────────────────────

class _LogisticsGrid extends StatelessWidget {
  const _LogisticsGrid({required this.ext, required this.bordereau});
  final KatianThemeExtension ext;
  final BordereauExpedition bordereau;

  @override
  Widget build(BuildContext context) {
    final b = bordereau;
    final tiles = <_GridTile>[
      _GridTile(icon: Icons.calendar_today_outlined, label: 'Date départ', value: b.departureLabel),
      _GridTile(icon: Icons.inventory_2_outlined, label: 'Nb. colis', value: '${b.parcelCount}'),
      if (b.departureRelayName != null)
        _GridTile(icon: Icons.store_outlined, label: 'Gare de départ', value: b.departureRelayName!, wide: true),
      if (b.carNumber != null && b.carNumber!.isNotEmpty)
        _GridTile(icon: Icons.directions_car_outlined, label: 'Véhicule', value: b.carNumber!),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tiles.map((t) {
        final width = t.wide
            ? double.infinity
            : (MediaQuery.sizeOf(context).width - 32 - 10) / 2;
        return SizedBox(
          width: t.wide ? double.infinity : width,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ext.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(t.icon, size: 17, color: ext.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.label, style: TextStyle(fontSize: 11, color: ext.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        t.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ext.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GridTile {
  const _GridTile({required this.icon, required this.label, required this.value, this.wide = false});
  final IconData icon;
  final String label;
  final String value;
  final bool wide;
}

// ── Carte conducteur ──────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.ext, required this.bordereau});
  final KatianThemeExtension ext;
  final BordereauExpedition bordereau;

  @override
  Widget build(BuildContext context) {
    final b = bordereau;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ext.background,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, size: 22, color: ext.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.driverName != null && b.driverName!.isNotEmpty)
                  Text(
                    b.driverName!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: ext.textPrimary,
                    ),
                  ),
                if (b.driverPhone != null && b.driverPhone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 13, color: ext.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        b.driverPhone!,
                        style: TextStyle(fontSize: 13, color: ext.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte commentaire ─────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.ext, required this.comment});
  final KatianThemeExtension ext;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_outlined, size: 16, color: ext.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              comment,
              style: TextStyle(fontSize: 13, color: ext.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Liste de colis ────────────────────────────────────────────────────────────

class _ColisCard extends StatelessWidget {
  const _ColisCard({required this.ext, required this.colis, required this.total});
  final KatianThemeExtension ext;
  final List<BordereauColisLine> colis;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (colis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ext.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ext.border),
        ),
        child: Text(
          'Aucun détail de colis disponible.',
          style: TextStyle(fontSize: 13, color: ext.textSecondary),
        ),
      );
    }

    return Column(
      children: colis.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ext.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: KatianColors.redLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: KatianColors.red,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numéro d'expédition
                    Text(
                      c.expeditionNumber ?? '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: ext.textPrimary,
                      ),
                    ),
                    if (c.recipientName != null && c.recipientName!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: ext.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.recipientName!,
                              style: TextStyle(fontSize: 12, color: ext.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (c.destination != null && c.destination!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: ext.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.destination!,
                              style: TextStyle(
                                fontSize: 12,
                                color: ext.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Badge retour si applicable
              if (c.isReturn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Retour',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
