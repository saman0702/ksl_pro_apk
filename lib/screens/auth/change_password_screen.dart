import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../navigation/app_shell.dart';
import '../../providers/app_provider.dart';
import '../../widgets/password_input_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    this.required = false,
    this.showDefaultHint = false,
    this.initialOldPassword,
  });

  /// Si true, l'écran ne peut pas être fermé sans changer le mot de passe.
  final bool required;

  /// Affiche l'aide pour le mot de passe initial convoyeur.
  final bool showDefaultHint;

  /// Mot de passe actuel connu (ex. celui utilisé à la connexion).
  final String? initialOldPassword;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _prefillLoading = true;
  bool _oldPasswordReadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOldPasswordPrefill());
  }

  Future<void> _loadOldPasswordPrefill() async {
    if (!mounted) return;
    final app = context.read<AppProvider>();
    final prefill = await app.resolveOldPasswordPrefill(
      explicit: widget.initialOldPassword,
      useDefaultHint: widget.showDefaultHint,
    );
    if (!mounted) return;
    setState(() {
      _prefillLoading = false;
      if (prefill != null && prefill.isNotEmpty) {
        _oldPassword.value = TextEditingValue(
          text: prefill,
          selection: TextSelection.collapsed(offset: prefill.length),
        );
        _oldPasswordReadOnly = true;
      }
    });
  }

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_prefillLoading) return;

    final oldPassword = _oldPassword.text.trim();
    if (oldPassword.isEmpty) {
      KatianToast.error(context, 'Saisissez votre mot de passe actuel');
      return;
    }
    if (_newPassword.text.length < 6) {
      KatianToast.error(context, 'Le nouveau mot de passe doit contenir au moins 6 caractères');
      return;
    }
    if (_newPassword.text == oldPassword) {
      KatianToast.error(context, 'Le nouveau mot de passe doit être différent de l\'ancien');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      KatianToast.error(context, 'Les mots de passe ne correspondent pas');
      return;
    }

    final app = context.read<AppProvider>();
    final ok = await app.changePassword(
      oldPassword: oldPassword,
      newPassword: _newPassword.text,
    );
    if (!mounted) return;
    if (ok) {
      final user = app.user;
      if (widget.required && user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => shellForUser(user)),
        );
      } else {
        KatianToast.success(context, 'Mot de passe modifié');
        Navigator.of(context).pop();
      }
    } else {
      KatianToast.error(context, app.error ?? 'Modification impossible');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final loading = context.watch<AppProvider>().loading;

    return PopScope(
      canPop: !widget.required,
      child: Scaffold(
        backgroundColor: ext.background,
        appBar: AppBar(
          title: Text(widget.required ? 'Changer votre mot de passe' : 'Modifier le mot de passe'),
          backgroundColor: KatianColors.red,
          foregroundColor: KatianColors.white,
          automaticallyImplyLeading: !widget.required,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.required)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KatianColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KatianColors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: KatianColors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pour votre sécurité, définissez un nouveau mot de passe '
                        'avant d\'accéder à l\'application.',
                        style: TextStyle(color: ext.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              _oldPasswordReadOnly
                  ? 'Votre mot de passe actuel est déjà renseigné. '
                      'Choisissez un nouveau mot de passe ci-dessous.'
                  : 'Saisissez votre mot de passe actuel, puis choisissez un nouveau mot de passe.',
              style: TextStyle(color: ext.textSecondary, height: 1.45),
            ),
            if (widget.showDefaultHint) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ext.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Mot de passe initial reçu de votre gare : '
                  '${AppConfig.defaultConvoyeurPassword}',
                  style: TextStyle(color: ext.textSecondary, fontSize: 13, height: 1.45),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_prefillLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              PasswordInputField(
                key: ValueKey('old-${_oldPassword.text.hashCode}-$_oldPasswordReadOnly'),
                controller: _oldPassword,
                label: 'Mot de passe actuel',
                readOnly: _oldPasswordReadOnly,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PasswordInputField(
                controller: _newPassword,
                label: 'Nouveau mot de passe',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PasswordInputField(
                controller: _confirmPassword,
                label: 'Confirmation',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!loading && !_prefillLoading) _submit();
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: loading || _prefillLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: KatianTheme.buttonShape,
                ),
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: KatianColors.white),
                      )
                    : const Icon(Icons.lock_outline),
                label: const Text('Enregistrer le nouveau mot de passe'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
