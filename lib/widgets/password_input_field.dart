import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';

class PasswordInputField extends StatefulWidget {
  const PasswordInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      readOnly: widget.readOnly,
      enableInteractiveSelection: !widget.readOnly,
      style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w500),
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        fillColor: widget.readOnly
            ? ext.surfaceVariant.withValues(alpha: 0.5)
            : ext.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, maxWidth: 44, minHeight: 44),
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, maxWidth: 40, minHeight: 40),
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 40, maxWidth: 40, minHeight: 40),
      ),
    );
  }
}

class KatianToast {
  KatianToast._();

  static void success(BuildContext context, String message) {
    _show(context, message, KatianColors.green);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, KatianColors.red);
  }

  static void _show(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final media = MediaQuery.of(context);
    final bottomInset = media.viewPadding.bottom + media.viewInsets.bottom;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
