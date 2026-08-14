import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/katian_theme_extension.dart';
import '../providers/app_provider.dart';
import '../widgets/katian_bottom_nav.dart';
import 'departures/departures_screen.dart';
import 'expeditions/expeditions_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'scanner/scanner_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _screens = [
    HomeScreen(),
    ExpeditionsScreen(),
    ScannerScreen(),
    DeparturesScreen(),
    ProfileScreen(),
  ];

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = context.watch<AppProvider>().navIndex.clamp(0, 4);
    final surface = context.katian.surface;

    if (_pageController.hasClients &&
        (_pageController.page?.round() ?? index) != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: surface,
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => context.read<AppProvider>().setNavIndex(i),
        children: _screens,
      ),
      bottomNavigationBar: KatianBottomNav(
        currentIndex: index,
        onTap: (i) {
          context.read<AppProvider>().setNavIndex(i);
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
