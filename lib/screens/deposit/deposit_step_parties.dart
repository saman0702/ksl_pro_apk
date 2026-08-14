import 'package:flutter/material.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/phone_input_field.dart';

class DepositStepParties extends StatefulWidget {
  const DepositStepParties({
    super.key,
    required this.draft,
    required this.relays,
    required this.connectedRelayId,
    required this.onChanged,
  });

  final ExpeditionDraft draft;
  final List<RelayPointOption> relays;
  final int? connectedRelayId;
  final VoidCallback onChanged;

  @override
  State<DepositStepParties> createState() => _DepositStepPartiesState();
}

class _DepositStepPartiesState extends State<DepositStepParties> {
  late final TextEditingController _senderFirst;
  late final TextEditingController _senderLast;
  late final TextEditingController _senderPhone;
  late final TextEditingController _recipientFirst;
  late final TextEditingController _recipientLast;
  late final TextEditingController _recipientPhone;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _senderFirst = TextEditingController(text: d.senderFirstName);
    _senderLast = TextEditingController(text: d.senderLastName);
    _senderPhone = TextEditingController(text: d.senderPhone);
    _recipientFirst = TextEditingController(text: d.recipientFirstName);
    _recipientLast = TextEditingController(text: d.recipientLastName);
    _recipientPhone = TextEditingController(text: d.recipientPhone);
  }

  @override
  void dispose() {
    _senderFirst.dispose();
    _senderLast.dispose();
    _senderPhone.dispose();
    _recipientFirst.dispose();
    _recipientLast.dispose();
    _recipientPhone.dispose();
    super.dispose();
  }

  void _sync() {
    final d = widget.draft;
    d.senderFirstName = _senderFirst.text.trim();
    d.senderLastName = _senderLast.text.trim();
    d.senderPhone = _senderPhone.text.trim();
    d.recipientFirstName = _recipientFirst.text.trim();
    d.recipientLastName = _recipientLast.text.trim();
    d.recipientPhone = _recipientPhone.text.trim();
    widget.onChanged();
  }

  RelayPointOption? _findRelay(int? id) {
    if (id == null) return null;
    for (final r in widget.relays) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final relays = widget.relays;
    final originId = widget.draft.originRelayId ?? widget.connectedRelayId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _sectionTitle('Type de service', ext),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          style: SegmentedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KatianTheme.buttonBorderRadius),
            ),
          ),
          segments: const [
            ButtonSegment(value: 'interurbaine', label: Text('Interurbaine')),
            ButtonSegment(value: 'sous_regionale', label: Text('Sous-régionale')),
          ],
          selected: {widget.draft.typeService},
          onSelectionChanged: (s) {
            widget.draft.typeService = s.first;
            _sync();
          },
        ),
        const SizedBox(height: 20),
        _sectionTitle('Expéditeur', ext),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _senderFirst,
                decoration: const InputDecoration(labelText: 'Prénom'),
                onChanged: (_) => _sync(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _senderLast,
                decoration: const InputDecoration(labelText: 'Nom'),
                onChanged: (_) => _sync(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PhoneInputField(
          controller: _senderPhone,
          label: 'Téléphone expéditeur',
          onChanged: _sync,
        ),
        const SizedBox(height: 20),
        _sectionTitle('Destinataire', ext),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _recipientFirst,
                decoration: const InputDecoration(labelText: 'Prénom'),
                onChanged: (_) => _sync(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _recipientLast,
                decoration: const InputDecoration(labelText: 'Nom'),
                onChanged: (_) => _sync(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PhoneInputField(
          controller: _recipientPhone,
          label: 'Téléphone destinataire',
          onChanged: _sync,
        ),
        const SizedBox(height: 20),
        _sectionTitle('Gares', ext),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: originId != null && relays.any((r) => r.id == originId)
              ? originId
              : null,
          decoration: const InputDecoration(labelText: 'Gare de départ'),
          items: relays
              .map(
                (r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (id) {
            widget.draft.originRelayId = id;
            widget.draft.originRelay = _findRelay(id);
            _sync();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: widget.draft.destinationRelayId != null &&
                  relays.any((r) => r.id == widget.draft.destinationRelayId)
              ? widget.draft.destinationRelayId
              : null,
          decoration: const InputDecoration(labelText: 'Destination finale'),
          items: relays
              .map(
                (r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(r.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (id) {
            widget.draft.destinationRelayId = id;
            widget.draft.destinationRelay = _findRelay(id);
            _sync();
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, KatianThemeExtension ext) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: ext.textPrimary,
      ),
    );
  }
}
