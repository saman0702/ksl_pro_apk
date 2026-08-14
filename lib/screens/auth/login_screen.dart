import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../widgets/katian_logo.dart';
import '../../widgets/password_input_field.dart';
import 'forgot_password_screen.dart';
import '../../navigation/post_auth_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _goHome([String? currentPassword]) {
    final user = context.read<AppProvider>().user;
    if (user == null) return;
    navigateAfterAuth(context, user, currentPassword: currentPassword);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Scaffold(
      backgroundColor: ext.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(child: KatianLogo(height: 52, showTagline: true)),
              const SizedBox(height: 32),
              Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ext.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez à Katian Expédition Transporteur',
                style: TextStyle(color: ext.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: ext.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: ext.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: KatianColors.red,
                  unselectedLabelColor: ext.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Mot de passe'),
                    Tab(text: 'OTP'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _tabs,
                builder: (context, _) {
                  return _tabs.index == 0
                      ? _PasswordLoginTab(onSuccess: _goHome)
                      : _OtpLoginTab(onSuccess: _goHome);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordLoginTab extends StatefulWidget {
  const _PasswordLoginTab({required this.onSuccess});

  final void Function(String? currentPassword) onSuccess;

  @override
  State<_PasswordLoginTab> createState() => _PasswordLoginTabState();
}

class _PasswordLoginTabState extends State<_PasswordLoginTab> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppProvider>();
    final ok = await app.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      widget.onSuccess(_password.text);
    } else {
      KatianToast.error(context, app.error ?? 'Connexion impossible');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AppProvider>().loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email ou téléphone',
            hintText: 'Entrez votre email ou téléphone',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        PasswordInputField(
          controller: _password,
          label: 'Mot de passe',
          hint: 'Entrez votre mot de passe',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!loading) _submit();
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: KatianActionButtons.text(
            onPressed: loading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
            label: 'Mot de passe oublié ?',
            icon: Icons.lock_reset,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: loading ? null : _submit,
          icon: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: KatianColors.white,
                  ),
                )
              : const Icon(Icons.login_rounded, size: 18),
          label: const Text('Se connecter'),
        ),
      ],
    );
  }
}

class _OtpLoginTab extends StatefulWidget {
  const _OtpLoginTab({required this.onSuccess});

  final void Function(String? currentPassword) onSuccess;

  @override
  State<_OtpLoginTab> createState() => _OtpLoginTabState();
}

class _OtpLoginTabState extends State<_OtpLoginTab> {
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  String? _maskedDestination;

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final app = context.read<AppProvider>();
    final result = await app.sendOtp(_identifier.text.trim());
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _codeSent = true;
        _maskedDestination = result.destinationMasked;
      });
      KatianToast.success(context, result.message);
    } else {
      KatianToast.error(context, app.error ?? 'Envoi impossible');
    }
  }

  Future<void> _loginOtp() async {
    final app = context.read<AppProvider>();
    final ok = await app.loginWithOtp(
      identifier: _identifier.text.trim(),
      code: _code.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      widget.onSuccess(null);
    } else {
      KatianToast.error(context, app.error ?? 'Code invalide');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AppProvider>().loading;
    final ext = context.katian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _identifier,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email ou téléphone',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        if (_codeSent) ...[
          const SizedBox(height: 16),
          if (_maskedDestination != null)
            Text(
              'Code envoyé à $_maskedDestination',
              style: TextStyle(color: ext.textSecondary, fontSize: 13),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Code OTP',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (!_codeSent)
          ElevatedButton.icon(
            onPressed: loading ? null : _sendCode,
            icon: const Icon(Icons.sms_outlined, size: 18),
            label: const Text('Recevoir le code'),
          )
        else
          ElevatedButton.icon(
            onPressed: loading ? null : _loginOtp,
            icon: const Icon(Icons.verified_outlined, size: 18),
            label: const Text('Valider le code'),
          ),
      ],
    );
  }
}
