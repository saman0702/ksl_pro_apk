import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';

class KatianBottomNav extends StatelessWidget {
  const KatianBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const int scannerIndex = 2;

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: ext.surface,
      height: 72 + bottom,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 64 + bottom,
              decoration: BoxDecoration(
                color: ext.surface,
                border: Border(
                  top: BorderSide(color: ext.border.withValues(alpha: 0.7)),
                ),
              ),
              padding: EdgeInsets.only(bottom: bottom),
              child: Row(
                children: [
                  _NavItem(
                    label: 'Accueil',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    label: 'Colis',
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2_rounded,
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const Expanded(child: SizedBox()),
                  _NavItem(
                    label: 'Départs',
                    icon: Icons.directions_bus_outlined,
                    activeIcon: Icons.directions_bus_rounded,
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavItem(
                    label: 'Profil',
                    icon: Icons.person_outline,
                    activeIcon: Icons.person_rounded,
                    selected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: _ScannerFab(
              selected: currentIndex == scannerIndex,
              onTap: () => onTap(scannerIndex),
            ),
          ),
        ],
      ),
    );
  }
}

class KatianBottomNavItem extends StatelessWidget {
  const KatianBottomNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final color = selected ? KatianColors.red : ext.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? activeIcon : icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
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

class _NavItem extends KatianBottomNavItem {
  const _NavItem({
    required super.label,
    required super.icon,
    required super.activeIcon,
    required super.selected,
    required super.onTap,
  });
}

class _ScannerFab extends StatelessWidget {
  const _ScannerFab({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const scannerShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(KatianTheme.buttonBorderRadius),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: selected ? 10 : 8,
          shadowColor: KatianColors.red.withValues(alpha: 0.45),
          shape: scannerShape,
          color: KatianColors.red,
          child: InkWell(
            onTap: onTap,
            customBorder: scannerShape,
            borderRadius: BorderRadius.circular(KatianTheme.buttonBorderRadius),
            child: Container(
              width: 68,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KatianTheme.buttonBorderRadius),
                border: Border.all(
                  color: KatianColors.white,
                  width: selected ? 3 : 2,
                ),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: KatianColors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scanner',
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? KatianColors.red : context.katian.textSecondary,
          ),
        ),
      ],
    );
  }
}
