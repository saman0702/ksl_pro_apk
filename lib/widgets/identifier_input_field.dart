import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import 'phone_input_field.dart';

enum IdentifierMode { email, phone }

class IdentifierInputField extends StatefulWidget {
  const IdentifierInputField({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.emailController,
    required this.phoneController,
    this.phoneFieldKey,
    this.enabled = true,
  });

  final IdentifierMode mode;
  final ValueChanged<IdentifierMode> onModeChanged;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final GlobalKey<PhoneInputFieldState>? phoneFieldKey;
  final bool enabled;

  @override
  State<IdentifierInputField> createState() => _IdentifierInputFieldState();
}

class _IdentifierInputFieldState extends State<IdentifierInputField> {
  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final inputStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: ext.textPrimary,
          fontWeight: FontWeight.w500,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _ModeChip(
              label: 'Email',
              icon: Icons.email_outlined,
              selected: widget.mode == IdentifierMode.email,
              onTap: widget.enabled
                  ? () => widget.onModeChanged(IdentifierMode.email)
                  : null,
            ),
            const SizedBox(width: 8),
            _ModeChip(
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              selected: widget.mode == IdentifierMode.phone,
              onTap: widget.enabled
                  ? () => widget.onModeChanged(IdentifierMode.phone)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.mode == IdentifierMode.email)
          TextField(
            controller: widget.emailController,
            enabled: widget.enabled,
            keyboardType: TextInputType.emailAddress,
            style: inputStyle,
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              hintText: 'agent@exemple.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          )
        else
          PhoneInputField(
            key: widget.phoneFieldKey,
            controller: widget.phoneController,
            enabled: widget.enabled,
            label: 'Numéro de téléphone',
            hint: '07 XX XX XX XX',
          ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    return Expanded(
      child: Material(
        color: selected
            ? KatianColors.red.withValues(alpha: 0.12)
            : ext.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? KatianColors.red : ext.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? KatianColors.red : ext.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
