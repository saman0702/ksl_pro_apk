import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import 'katian_bottom_nav.dart';

/// Barre de navigation convoyeur — même style que [KatianBottomNav] (sans scanner central).
class KatianConvoyeurBottomNav extends StatelessWidget {
  const KatianConvoyeurBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
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
          KatianBottomNavItem(
            label: 'Missions',
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping_rounded,
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          KatianBottomNavItem(
            label: 'Profil',
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}
