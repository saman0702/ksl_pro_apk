import 'package:flutter/material.dart';

import '../widgets/katian_action_buttons.dart';
import '../core/theme.dart';

class DriverInfoDialog extends StatefulWidget {
  const DriverInfoDialog({
    super.key,
    this.title = 'Expédier le colis',
  });

  final String title;

  static Future<({String name, String phone})?> show(
    BuildContext context, {
    String title = 'Expédier le colis',
  }) {
    return showDialog<({String name, String phone})?>(
      context: context,
      builder: (_) => DriverInfoDialog(title: title),
    );
  }

  @override
  State<DriverInfoDialog> createState() => _DriverInfoDialogState();
}

class _DriverInfoDialogState extends State<DriverInfoDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nom du livreur',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone ou ID conducteur',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        KatianActionButtons.cancel(onPressed: () => Navigator.pop(context)),
        KatianActionButtons.confirm(
          onPressed: () {
            final name = _name.text.trim();
            final phone = _phone.text.trim();
            if (name.isEmpty || phone.isEmpty) return;
            Navigator.pop(context, (name: name, phone: phone));
          },
          label: 'Expédier',
          backgroundColor: KatianColors.red,
          icon: Icons.local_shipping_outlined,
        ),
      ],
    );
  }
}
