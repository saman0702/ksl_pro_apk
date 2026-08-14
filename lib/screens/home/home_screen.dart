import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../deposit/new_expedition_wizard_screen.dart';
import '../parcels/parcel_hub_kind.dart';
import '../parcels/parcel_hub_screen.dart';
import '../../widgets/katian_scaffold.dart';
import '../../widgets/period_filter_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final stats = app.stats;
    final ext = context.katian;

    return KatianScaffold(
      title: 'Tableau de bord',
      body: RefreshIndicator(
        color: KatianColors.red,
        onRefresh: () => context.read<AppProvider>().loadDashboardStats(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              'Tableau de bord',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ext.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            PeriodFilterBar(
              selected: app.periodFilter,
              onChanged: (p) => context.read<AppProvider>().setPeriodFilter(p),
            ),
            if (app.managedRelays.length > 1) ...[
              const SizedBox(height: 10),
              _RelayFilterBar(
                relays: app.managedRelays,
                selectedId: app.selectedRelayId,
                onSelected: (id) => context.read<AppProvider>().setSelectedRelay(id),
              ),
            ],
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardSquareCard(
                  title: 'Nouvelle\nexpédition',
                  color: KatianColors.red,
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewExpeditionWizardScreen(),
                    ),
                  ),
                ),
                _DashboardSquareCard(
                  title: 'Colis à\nexpédier',
                  color: KatianColors.orange,
                  icon: Icons.inventory_2_outlined,
                  count: stats.toShip,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParcelHubScreen(
                        kind: ParcelHubKind.toShip,
                      ),
                    ),
                  ),
                ),
                _DashboardSquareCard(
                  title: 'Colis à\nréceptionner',
                  color: KatianColors.blue,
                  icon: Icons.inbox_outlined,
                  count: stats.toReceive,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParcelHubScreen(
                        kind: ParcelHubKind.toReceive,
                      ),
                    ),
                  ),
                ),
                _DashboardSquareCard(
                  title: 'En transit à\nréexpédier',
                  color: KatianColors.green,
                  icon: Icons.swap_horiz_rounded,
                  count: stats.inTransit,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParcelHubScreen(
                        kind: ParcelHubKind.toReship,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ListTileButton(
              icon: Icons.history,
              label: 'Historique des expéditions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ParcelHubScreen(kind: ParcelHubKind.history),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ListTileButton(
              icon: Icons.qr_code_scanner,
              label: 'Scanner un colis',
              onTap: () => context.read<AppProvider>().openReceptionScanner(),
            ),
            const SizedBox(height: 8),
            _ListTileButton(
              icon: Icons.key_outlined,
              label: 'Retrait colis',
              onTap: () => context.read<AppProvider>().openPickupTab(),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined,
                    color: KatianColors.red),
                title: const Text('Colis en stock'),
                subtitle: const Text(
                  'À expédier, en transit, attente retrait…',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${stats.packagesInStock}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: KatianColors.red,
                  ),
                ),
                onTap: () => context.read<AppProvider>().openStock(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardSquareCard extends StatelessWidget {
  const _DashboardSquareCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    this.count,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;

    return Material(
      color: ext.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ext.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 40,
                ),
                if (count != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ext.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
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

class _ListTileButton extends StatelessWidget {
  const _ListTileButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: KatianColors.red),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ── Barre de filtre par gare (gérant multi-gares) ────────────────────────────

class _RelayFilterBar extends StatelessWidget {
  const _RelayFilterBar({
    required this.relays,
    required this.selectedId,
    required this.onSelected,
  });

  final List<RelayPointOption> relays;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(label: 'Toutes', selected: selectedId == null, onTap: () => onSelected(null), ext: ext),
          ...relays.map(
            (r) => _Chip(
              label: r.name,
              selected: selectedId == r.id,
              onTap: () => onSelected(r.id),
              ext: ext,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, required this.ext});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? KatianColors.red : ext.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? KatianColors.red : ext.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : ext.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
