import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../widgets/katian_avatar.dart';
import '../../widgets/katian_scaffold.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';

class ConvoyeurProfileScreen extends StatelessWidget {
  const ConvoyeurProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.user;
    final ext = context.katian;

    return KatianScaffold(
      title: 'Profil',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _UserCard(user: user, ext: ext),
          const SizedBox(height: 16),
          _Section(
            title: 'Permis & véhicule',
            child: Column(
              children: [
                _Row(label: 'N° permis', value: user?.licenseNumber ?? '—'),
                const Divider(height: 20),
                _Row(label: 'Catégories', value: user?.licenseCategoriesLabel ?? '—'),
                const Divider(height: 20),
                _Row(label: 'Expiration', value: user?.licenseExpiry ?? '—'),
                const Divider(height: 20),
                _Row(label: 'Véhicule', value: user?.assignedCarLabel ?? 'Non affecté'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Compte',
            child: Column(
              children: [
                _Row(label: 'Téléphone', value: user?.phone ?? '—'),
                const Divider(height: 20),
                _Row(
                  label: 'Email',
                  value: () {
                    final email = user?.email?.trim() ?? '';
                    return email.isNotEmpty ? email : '—';
                  }(),
                ),
                const Divider(height: 20),
                _Row(label: 'Compagnie', value: user?.companyName ?? '—'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KatianActionButtons.elevated(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChangePasswordScreen(
                    showDefaultHint: user?.mustChangePassword == true,
                    initialOldPassword: app.sessionPassword,
                  ),
                ),
              );
            },
            label: 'Modifier le mot de passe',
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          KatianActionButtons.elevated(
            onPressed: () async {
              await app.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            label: 'Se déconnecter',
            icon: Icons.logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: ext.surface,
              foregroundColor: KatianColors.red,
              side: const BorderSide(color: KatianColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.ext});

  final KatianUser? user;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            KatianAvatar(
              size: 64,
              imageUrl: user?.displayAvatar,
              initial: user?.avatarInitial ?? 'K',
              backgroundColor: KatianColors.redLight,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: ext.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.roleLabel ?? '', style: TextStyle(color: ext.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: TextStyle(color: ext.textSecondary))),
        Expanded(child: Text(value, style: TextStyle(color: ext.textPrimary, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
