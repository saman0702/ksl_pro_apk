import 'package:flutter/material.dart';

import '../../core/katian_theme_extension.dart';
import '../../widgets/katian_convoyeur_bottom_nav.dart';
import 'convoyeur_missions_screen.dart';
import 'convoyeur_profile_screen.dart';

class ConvoyeurShell extends StatefulWidget {
  const ConvoyeurShell({super.key});

  @override
  State<ConvoyeurShell> createState() => _ConvoyeurShellState();
}

class _ConvoyeurShellState extends State<ConvoyeurShell> {
  int _index = 0;

  static const _screens = [
    ConvoyeurMissionsScreen(),
    ConvoyeurProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = context.katian.surface;

    return Scaffold(
      backgroundColor: surface,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: KatianConvoyeurBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
