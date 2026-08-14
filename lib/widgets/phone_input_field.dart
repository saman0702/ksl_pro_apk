import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/phone_countries.dart';
import '../core/theme.dart';

class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.label = 'Téléphone',
    this.hint = '07 XX XX XX XX',
    this.initialCountry = PhoneCountry.defaultCountry,
    this.onCountryChanged,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final PhoneCountry initialCountry;
  final ValueChanged<PhoneCountry>? onCountryChanged;
  final VoidCallback? onChanged;

  @override
  State<PhoneInputField> createState() => PhoneInputFieldState();
}

class PhoneInputFieldState extends State<PhoneInputField> {
  late PhoneCountry _country;

  PhoneCountry get country => _country;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry;
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final inputStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w500,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ext.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CountryPrefixButton(
              country: _country,
              enabled: widget.enabled,
              onSelected: (c) {
                setState(() => _country = c);
                widget.onCountryChanged?.call(c);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                style: inputStyle,
                onChanged: (_) => widget.onChanged?.call(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountryPrefixButton extends StatelessWidget {
  const _CountryPrefixButton({
    required this.country,
    required this.enabled,
    required this.onSelected,
  });

  final PhoneCountry country;
  final bool enabled;
  final ValueChanged<PhoneCountry> onSelected;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final picked = await showModalBottomSheet<PhoneCountry>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Indicatif pays',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: PhoneCountry.all.map((c) {
                    return ListTile(
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(c.name),
                      trailing: Text(
                        c.dialCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: KatianColors.red,
                        ),
                      ),
                      selected: c.dialCode == country.dialCode,
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    return Material(
      color: ext.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ext.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                country.dialCode,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ext.textPrimary,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: ext.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
