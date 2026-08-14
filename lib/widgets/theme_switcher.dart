import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

/// Widget autonome affichant un sélecteur Clair / Sombre / Système.
/// Peut être placé dans n'importe quelle page.
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final ext = context.katian;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.palette_outlined, size: 20, color: KatianColors.red),
            const SizedBox(width: 8),
            Text(
              'Apparence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ext.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _ThemeOption(
              label: 'Clair',
              icon: Icons.light_mode_outlined,
              mode: ThemeMode.light,
              current: provider.mode,
              onTap: () => provider.setMode(ThemeMode.light),
              ext: ext,
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              label: 'Sombre',
              icon: Icons.dark_mode_outlined,
              mode: ThemeMode.dark,
              current: provider.mode,
              onTap: () => provider.setMode(ThemeMode.dark),
              ext: ext,
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              label: 'Système',
              icon: Icons.brightness_auto_outlined,
              mode: ThemeMode.system,
              current: provider.mode,
              onTap: () => provider.setMode(ThemeMode.system),
              ext: ext,
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.current,
    required this.onTap,
    required this.ext,
  });

  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode current;
  final VoidCallback onTap;
  final KatianThemeExtension ext;

  bool get selected => mode == current;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? KatianColors.red.withValues(alpha: 0.1)
                : ext.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? KatianColors.red : ext.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? KatianColors.red : ext.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? KatianColors.red : ext.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
