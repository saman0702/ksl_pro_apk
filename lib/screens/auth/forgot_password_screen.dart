import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/phone_countries.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../widgets/identifier_input_field.dart';
import '../../widgets/katian_logo.dart';
import '../../widgets/password_input_field.dart';
import '../../widgets/phone_input_field.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _phoneFieldKey = GlobalKey<PhoneInputFieldState>();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  IdentifierMode _mode = IdentifierMode.email;
  bool _codeSent = false;
  String? _verifiedIdentifier;
  String? _destinationMasked;
  String _channel = 'email';

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String _identifier() {
    if (_mode == IdentifierMode.email) {
      return _email.text.trim();
    }
    final country =
        _phoneFieldKey.currentState?.country ?? PhoneCountry.defaultCountry;
    return PhoneUtils.normalize(country, _phone.text.trim());
  }

  Future<void> _sendCode() async {
    final id = _identifier();
    if (id.isEmpty) {
      KatianToast.error(
        context,
        _mode == IdentifierMode.email
            ? 'Entrez votre adresse email'
            : 'Entrez votre numéro de téléphone',
      );
      return;
    }

    final app = context.read<AppProvider>();
    final result = await app.requestPasswordReset(id);
    if (!mounted) return;
    if (result == null) {
      KatianToast.error(context, app.error ?? 'Envoi impossible');
      return;
    }

    setState(() {
      _codeSent = true;
      _verifiedIdentifier = result.identifier;
      _destinationMasked = result.destinationMasked;
      _channel = result.channel;
    });
    KatianToast.success(context, result.message);
  }

  Future<void> _resetPassword() async {
    final id = _verifiedIdentifier ?? _identifier();
    final code = _otp.text.trim();

    if (id.isEmpty || code.isEmpty) {
      KatianToast.error(context, 'Entrez le code reçu');
      return;
    }
    if (_password.text.length < 6) {
      KatianToast.error(
        context,
        'Le mot de passe doit contenir au moins 6 caractères',
      );
      return;
    }
    if (_password.text != _confirmPassword.text) {
      KatianToast.error(context, 'Les mots de passe ne correspondent pas');
      return;
    }

    final app = context.read<AppProvider>();
    final ok = await app.resetPassword(
      identifier: id,
      code: code,
      password: _password.text,
    );
    if (!mounted) return;
    if (!ok) {
      KatianToast.error(context, app.error ?? 'Réinitialisation impossible');
      return;
    }

    KatianToast.success(context, 'Mot de passe réinitialisé — connectez-vous');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final loading = context.watch<AppProvider>().loading;

    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: KatianColors.red,
        foregroundColor: KatianColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: KatianLogo(height: 40, showTagline: false)),
              const SizedBox(height: 24),
              Text(
                _codeSent
                    ? 'Nouveau mot de passe'
                    : 'Réinitialiser votre mot de passe',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ext.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Saisissez le code reçu et choisissez un nouveau mot de passe.'
                    : 'Entrez votre email ou numéro de téléphone. '
                        'Nous vous enverrons un code de vérification.',
                style: TextStyle(color: ext.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                IdentifierInputField(
                  mode: _mode,
                  onModeChanged: (m) => setState(() => _mode = m),
                  emailController: _email,
                  phoneController: _phone,
                  phoneFieldKey: _phoneFieldKey,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: loading ? null : _sendCode,
                  icon: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KatianColors.white,
                          ),
                        )
                      : Icon(
                          _mode == IdentifierMode.email
                              ? Icons.email_outlined
                              : Icons.sms_outlined,
                          size: 18,
                        ),
                  label: Text(
                    _mode == IdentifierMode.email
                        ? 'Envoyer le code par email'
                        : 'Envoyer le code par SMS',
                  ),
                ),
              ] else ...[
                if (_destinationMasked != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KatianColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _channel == 'email'
                              ? Icons.email_outlined
                              : Icons.sms_outlined,
                          color: KatianColors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _channel == 'email'
                                ? 'Code envoyé à $_destinationMasked'
                                : 'Code envoyé par SMS au $_destinationMasked',
                            style: const TextStyle(
                              fontSize: 13,
                              color: KatianColors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Code OTP',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                PasswordInputField(
                  controller: _password,
                  label: 'Nouveau mot de passe',
                  hint: 'Au moins 6 caractères',
                ),
                const SizedBox(height: 16),
                PasswordInputField(
                  controller: _confirmPassword,
                  label: 'Confirmer le mot de passe',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!loading) _resetPassword();
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: KatianActionButtons.text(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _otp.clear();
                              _password.clear();
                              _confirmPassword.clear();
                              _verifiedIdentifier = null;
                              _destinationMasked = null;
                            });
                          },
                    label: 'Changer de compte',
                    icon: Icons.swap_horiz,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: loading ? null : _resetPassword,
                  icon: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KatianColors.white,
                          ),
                        )
                      : const Icon(Icons.lock_reset, size: 18),
                  label: const Text('Réinitialiser le mot de passe'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: loading ? null : _sendCode,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Renvoyer le code'),
                ),
              ],
              const SizedBox(height: 16),
              KatianActionButtons.text(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                label: 'Retour à la connexion',
                icon: Icons.login_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
