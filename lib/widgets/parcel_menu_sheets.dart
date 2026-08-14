import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../utils/parcel_status_colors.dart';
import 'parcel_status_badge.dart';
import 'parcel_sheet_hero.dart';
import 'traceability_timeline.dart';
import '../utils/parcel_menu.dart';
import 'katian_action_buttons.dart';
import 'katian_bottom_sheet.dart';

class ParcelMenuSheet extends StatelessWidget {
  const ParcelMenuSheet({
    super.key,
    required this.items,
    required this.onSelected,
  });

  final List<ParcelMenuItem> items;
  final ValueChanged<ParcelMenuItem> onSelected;

  static Future<ParcelMenuItem?> show(
    BuildContext context, {
    required List<ParcelMenuItem> items,
  }) {
    return showKatianWhiteBottomSheet<ParcelMenuItem>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.75;
        return SizedBox(
          width: double.infinity,
          height: maxH,
          child: ParcelMenuSheet(
            items: items,
            onSelected: (item) => Navigator.pop(ctx, item),
          ),
        );
      },
    );
  }

  IconData _icon(ParcelMenuKind kind) {
    switch (kind) {
      case ParcelMenuKind.tracking:
        return Icons.navigation_outlined;
      case ParcelMenuKind.viewDetails:
        return Icons.visibility_outlined;
      case ParcelMenuKind.changeStatus:
        return Icons.edit_outlined;
      case ParcelMenuKind.assignRelay:
        return Icons.archive_outlined;
      case ParcelMenuKind.markDelivered:
        return Icons.check_circle_outline;
      case ParcelMenuKind.manageReturn:
        return Icons.rotate_left;
      case ParcelMenuKind.manageDispute:
        return Icons.warning_amber_outlined;
      case ParcelMenuKind.printLabel:
        return Icons.print_outlined;
      case ParcelMenuKind.generateInvoice:
        return Icons.description_outlined;
      case ParcelMenuKind.reprintReceipt:
        return Icons.receipt_long_outlined;
      case ParcelMenuKind.editAmount:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return ColoredBox(
      color: ext.surface,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Actions',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: ext.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 56,
                  color: ext.border,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    tileColor: ext.surface,
                    leading: Icon(
                      _icon(item.kind),
                      color: ext.textPrimary,
                      size: 24,
                      weight: 700,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: ext.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TraceabilitySheet extends StatelessWidget {
  const TraceabilitySheet({
    super.key,
    required this.data,
    this.scrollController,
  });

  final TraceabilityData data;
  final ScrollController? scrollController;

  static Future<void> show(BuildContext context, TraceabilityData data) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final ext = Theme.of(ctx).extension<KatianThemeExtension>() ??
            KatianThemeExtension.light;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) => DecoratedBox(
            decoration: BoxDecoration(
              color: ext.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: TraceabilitySheet(data: data, scrollController: scrollController),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final steps = buildTimelineSteps(data.events);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ext.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: KatianColors.redLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route_outlined, color: KatianColors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suivi colis',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ext.textPrimary,
                    ),
                  ),
                  Text(
                    data.expeditionNumber ?? '—',
                    style: const TextStyle(
                      color: KatianColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (data.currentStatus != null) ...[
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final statusColor =
                  parcelStatusColorFromNormalized(data.currentStatus);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: parcelStatusBackgroundColor(statusColor),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Statut actuel : ${data.currentStatus}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        if (data.createdByRelayName != null ||
            data.currentRelayName != null ||
            data.destinationRelayName != null) ...[
          const SizedBox(height: 12),
          _RelayRouteBar(
            origin: data.createdByRelayName,
            current: data.currentRelayName,
            destination: data.destinationRelayName,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Historique (${steps.length})',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: ext.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TraceabilityTimeline(events: steps),
      ],
    );
  }
}

class _RelayRouteBar extends StatelessWidget {
  const _RelayRouteBar({
    this.origin,
    this.current,
    this.destination,
  });

  final String? origin;
  final String? current;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          if (origin != null) Expanded(child: _stop('Départ', origin!, KatianColors.blue)),
          if (origin != null && (current != null || destination != null))
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded, size: 18, color: KatianColors.orange),
            ),
          if (current != null) Expanded(child: _stop('Actuel', current!, KatianColors.orange)),
          if (current != null && destination != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded, size: 18, color: KatianColors.orange),
            ),
          if (destination != null)
            Expanded(child: _stop('Destination', destination!, Colors.green)),
        ],
      ),
    );
  }

  Widget _stop(String label, String name, Color color) {
    return Builder(
      builder: (context) {
        final ext = context.katian;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ext.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ParcelDetailSheet extends StatelessWidget {
  const ParcelDetailSheet({super.key, required this.parcel});

  final KatianExpedition parcel;

  static Future<void> show(BuildContext context, KatianExpedition parcel) {
    return showKatianWhiteBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ParcelDetailSheet(parcel: parcel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final raw = parcel.raw;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              parcel.displayNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ext.textPrimary,
              ),
            ),
            ParcelStatusBadge.fromParcel(parcel),
            ParcelSheetHeroImage(parcel: parcel),
            const SizedBox(height: 4),
            _row('Destinataire', parcel.recipientName),
            _row('Téléphone dest.', parcel.recipientPhone),
            _row('Expéditeur', parcel.senderName),
            _row('Téléphone exp.', parcel.senderPhone),
            _row('Origine', parcel.originRelayName),
            _row('Destination', parcel.destinationRelayName),
            _row('Relais actuel', parcel.currentRelayName),
            _row('Transporteur', parcel.carrierName),
            _row('Montant', parcel.amount?.toStringAsFixed(0)),
            _row('Code retrait', raw['code_retrait'] as String?),
            _row('Mode paiement', raw['mode_paiement'] as String?),
            if (parcel.isReturn)
              _row('Statut retour', parcel.returnStatus),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Builder(
      builder: (context) {
        final ext = context.katian;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: ext.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 12, color: ext.textPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// En-tête + actions communs pour les formulaires en bottom sheet.
class _FormSheetLayout extends StatelessWidget {
  const _FormSheetLayout({
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: ext.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(child: body),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChangeDialog extends StatefulWidget {
  const StatusChangeDialog({
    super.key,
    required this.parcel,
    required this.tab,
  });

  final KatianExpedition parcel;
  final ExpeditionTab tab;

  static Future<String?> show(
    BuildContext context, {
    required KatianExpedition parcel,
    required ExpeditionTab tab,
  }) {
    return showKatianWhiteBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: StatusChangeDialog(parcel: parcel, tab: tab),
      ),
    );
  }

  @override
  State<StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  String? _selected;
  late final List<StatusChangeOption> _options;

  @override
  void initState() {
    super.initState();
    _options = statusChangeOptionsFor(widget.tab);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return _FormSheetLayout(
      title: 'Modifier le statut',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.parcel.displayNumber,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'Nouveau statut',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _options
                .map(
                  (o) => DropdownMenuItem(value: o.uiKey, child: Text(o.label)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
        ],
      ),
      actions: [
        KatianActionButtons.cancel(onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        KatianActionButtons.confirm(
          onPressed: _selected == null
              ? null
              : () => Navigator.pop(context, _selected),
          label: 'Confirmer',
          backgroundColor: KatianColors.red,
        ),
      ],
    );
  }
}

class AssignRelayDialog extends StatefulWidget {
  const AssignRelayDialog({super.key, required this.relays});

  final List<RelayPointOption> relays;

  static Future<int?> show(BuildContext context, List<RelayPointOption> relays) {
    return showKatianWhiteBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: AssignRelayDialog(relays: relays),
      ),
    );
  }

  @override
  State<AssignRelayDialog> createState() => _AssignRelayDialogState();
}

class _AssignRelayDialogState extends State<AssignRelayDialog> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    return _FormSheetLayout(
      title: 'Assigner à un point relais',
      body: widget.relays.isEmpty
          ? const Text('Aucun point relais disponible')
          : DropdownButtonFormField<int>(
              initialValue: _selected,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Point relais',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.relays
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        r.city != null ? '${r.name} (${r.city})' : r.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
      actions: [
        KatianActionButtons.cancel(onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        KatianActionButtons.confirm(
          onPressed: _selected == null ? null : () => Navigator.pop(context, _selected),
          label: 'Assigner',
          backgroundColor: KatianColors.red,
          icon: Icons.store_outlined,
        ),
      ],
    );
  }
}

class ReturnDialog extends StatefulWidget {
  const ReturnDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final ok = await showKatianWhiteBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const ReturnDialog(),
      ),
    );
    return ok == true;
  }

  @override
  State<ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<ReturnDialog> {
  String? _reason;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetLayout(
      title: 'Gérer le retour',
      body: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(
              labelText: 'Raison du retour',
              border: OutlineInputBorder(),
            ),
            items: returnReasonOptions
                .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                .toList(),
            onChanged: (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Détails (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        KatianActionButtons.cancel(onPressed: () => Navigator.pop(context, false)),
        const SizedBox(width: 8),
        KatianActionButtons.confirm(
          onPressed: _reason == null
              ? null
              : () => Navigator.pop(context, true),
          label: 'Confirmer le retour',
          backgroundColor: Colors.orange,
          icon: Icons.reply_outlined,
        ),
      ],
    );
  }
}

class LitigeDialog extends StatefulWidget {
  const LitigeDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final ok = await showKatianWhiteBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const LitigeDialog(),
      ),
    );
    return ok == true;
  }

  @override
  State<LitigeDialog> createState() => _LitigeDialogState();
}

class _LitigeDialogState extends State<LitigeDialog> {
  String _type = 'perte';
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetLayout(
      title: 'Gérer le litige',
      body: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'perte', child: Text('Perte')),
              DropdownMenuItem(value: 'dommage', child: Text('Dommage')),
              DropdownMenuItem(value: 'retard', child: Text('Retard')),
              DropdownMenuItem(value: 'autre', child: Text('Autre')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'perte'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Description du problème',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        KatianActionButtons.cancel(onPressed: () => Navigator.pop(context, false)),
        const SizedBox(width: 8),
        KatianActionButtons.confirm(
          onPressed: () {
            if (_description.text.trim().isEmpty) return;
            Navigator.pop(context, true);
          },
          label: 'Créer le litige',
          backgroundColor: KatianColors.red,
          icon: Icons.gavel_outlined,
        ),
      ],
    );
  }
}

class EditAmountDialog extends StatefulWidget {
  const EditAmountDialog({super.key, required this.parcel});

  final KatianExpedition parcel;

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    KatianExpedition parcel,
  ) {
    return showKatianWhiteBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: EditAmountDialog(parcel: parcel),
      ),
    );
  }

  @override
  State<EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<EditAmountDialog> {
  late final TextEditingController _montant;
  late final TextEditingController _valeur;
  late final TextEditingController _pct;

  @override
  void initState() {
    super.initState();
    final raw = widget.parcel.raw;
    _montant = TextEditingController(text: '${raw['montant'] ?? ''}');
    _valeur = TextEditingController(text: '${raw['valeur_declaree'] ?? ''}');
    _pct = TextEditingController(text: '${raw['pourcentage_applique'] ?? ''}');
  }

  @override
  void dispose() {
    _montant.dispose();
    _valeur.dispose();
    _pct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return _FormSheetLayout(
      title: 'Modifier le montant',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.parcel.displayNumber,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _montant,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _valeur,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valeur déclarée',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pct,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Pourcentage appliqué',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        KatianActionButtons.cancel(onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        KatianActionButtons.confirm(
          onPressed: () {
            final mont = double.tryParse(_montant.text.trim());
            if (mont == null || mont < 0) return;
            Navigator.pop(context, {
              'montant': mont,
              if (double.tryParse(_valeur.text.trim()) != null)
                'valeur_declaree': double.parse(_valeur.text.trim()),
              if (double.tryParse(_pct.text.trim()) != null)
                'pourcentage_applique': double.parse(_pct.text.trim()),
            });
          },
          label: 'Enregistrer',
          backgroundColor: KatianColors.red,
          icon: Icons.save_outlined,
        ),
      ],
    );
  }
}
