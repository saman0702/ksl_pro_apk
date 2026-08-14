import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/parcel_flow_handler.dart';
import '../../utils/parcel_menu.dart';
import '../../utils/parcel_actions.dart';
import '../../utils/parcel_status.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../widgets/driver_info_dialog.dart';
import '../../widgets/katian_scaffold.dart';
import '../../widgets/katian_bottom_sheet.dart';
import '../../widgets/parcel_card.dart';
import '../../widgets/parcel_menu_sheets.dart';
import '../../widgets/parcel_status_badge.dart';
import '../../widgets/parcel_sheet_hero.dart';
import '../../widgets/password_input_field.dart';
import '../../widgets/period_filter_bar.dart';
import '../pickup/pickup_nav_shell.dart';

class ExpeditionsScreen extends StatefulWidget {
  const ExpeditionsScreen({super.key});

  @override
  State<ExpeditionsScreen> createState() => _ExpeditionsScreenState();
}

class _ExpeditionsScreenState extends State<ExpeditionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _search = TextEditingController();
  ExpeditionTab? _syncedExpeditionTab;
  int? _syncedColisTabIndex;
  static const _pickupTabIndex = 3;

  String? _syncedStockFilter;
  String? _syncedPeriodFilter;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final initial = app.colisTabIndex.clamp(0, _pickupTabIndex);
    _syncedColisTabIndex = initial;
    _syncedPeriodFilter = app.periodFilter;
    if (initial < _pickupTabIndex) {
      _syncedExpeditionTab = ExpeditionTab.values[initial];
    }
    _tabs = TabController(length: 4, vsync: this, initialIndex: initial);
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentTab());
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
    if (_tabs.indexIsChanging) return;

    final index = _tabs.index;
    _syncedColisTabIndex = index;
    if (index < _pickupTabIndex) {
      _syncedExpeditionTab = ExpeditionTab.values[index];
    }

    context.read<AppProvider>().setColisTabIndex(index);
    if (index < _pickupTabIndex) {
      _loadCurrentTab();
    }
  }

  bool get _isPickupTab => _tabs.index == _pickupTabIndex;

  ExpeditionTab get _currentTab => ExpeditionTab.values[_tabs.index.clamp(0, 2)];

  Future<void> _loadCurrentTab() async {
    final app = context.read<AppProvider>();
    switch (_currentTab) {
      case ExpeditionTab.reception:
        await app.loadReceptionParcels(search: _search.text);
      case ExpeditionTab.expedition:
        await app.loadExpeditionParcels(search: _search.text);
      case ExpeditionTab.stock:
        await app.loadStockParcels();
    }
  }

  List<KatianExpedition> _listForTab(AppProvider app, ExpeditionTab tab) {
    switch (tab) {
      case ExpeditionTab.reception:
        return app.receptionParcels;
      case ExpeditionTab.expedition:
        return app.expeditionParcels;
      case ExpeditionTab.stock:
        return app.stockParcels;
    }
  }

  List<ParcelAction> _actionsFor(
    KatianExpedition parcel,
    AppProvider app,
    ExpeditionTab tab,
  ) {
    return parcelActionsFor(
      parcel: parcel,
      tab: tab,
      user: app.user,
    );
  }

  Widget _buildParcelList(ExpeditionTab tab) {
    final app = context.watch<AppProvider>();
    final ext = context.katian;
    final list = _listForTab(app, tab);

    return RefreshIndicator(
      color: KatianColors.red,
      onRefresh: _loadCurrentTab,
      child: app.parcelsLoading && list.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: KatianColors.red),
            )
          : list.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.2,
                    ),
                    Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: ext.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun colis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ext.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final parcel = list[i];
                    final actions = _actionsFor(parcel, app, tab);
                    final shipToYou = tab == ExpeditionTab.reception &&
                        isShipToYouPending(parcel, app.user);
                    return ParcelCard(
                      parcel: parcel,
                      showShipToYou: shipToYou,
                      onTap: () => _openParcelSheet(
                        parcel,
                        actions,
                        shipToYou: shipToYou,
                      ),
                      onMenuTap: () => _openParcelMenu(parcel, tab),
                    );
                  },
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ext = context.katian;
    final statusOptions = statusFiltersForTab(_currentTab);
    final currentFilter = app.statusFilterFor(_currentTab);

    if (app.navIndex == 1 && app.colisTabIndex != _syncedColisTabIndex) {
      _syncedColisTabIndex = app.colisTabIndex;
      if (app.colisTabIndex < _pickupTabIndex) {
        _syncedExpeditionTab = app.expeditionTab;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabs.index != app.colisTabIndex) {
          _tabs.animateTo(app.colisTabIndex);
        }
        if (app.colisTabIndex < _pickupTabIndex) {
          _loadCurrentTab();
        }
      });
    } else if (app.navIndex == 1 &&
        app.colisTabIndex < _pickupTabIndex &&
        app.expeditionTab != _syncedExpeditionTab) {
      _syncedExpeditionTab = app.expeditionTab;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabs.index != app.expeditionTab.index) {
          _tabs.animateTo(app.expeditionTab.index);
        }
        _loadCurrentTab();
      });
    }

    if (app.navIndex == 1 &&
        app.expeditionTab == ExpeditionTab.stock &&
        app.stockStatusFilter != _syncedStockFilter) {
      _syncedStockFilter = app.stockStatusFilter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_currentTab == ExpeditionTab.stock) {
          _loadCurrentTab();
        }
      });
    }

    if (app.navIndex == 1 && app.periodFilter != _syncedPeriodFilter) {
      _syncedPeriodFilter = app.periodFilter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_isPickupTab) {
          _loadCurrentTab();
        }
      });
    }

    return KatianScaffold(
      title: 'Colis',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Material(
              color: ext.surface,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              child: TabBar(
                controller: _tabs,
                indicatorColor: KatianColors.red,
                indicatorWeight: 3,
                labelColor: KatianColors.red,
                unselectedLabelColor: ext.textSecondary,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'Réception (${app.stats.toReceive})'),
                  Tab(text: 'Expédition (${app.stats.toShip})'),
                  Tab(text: 'Stock (${app.stats.packagesInStock})'),
                  const Tab(text: 'Retrait'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PeriodFilterBar(
              selected: app.periodFilter,
              onChanged: (p) => context.read<AppProvider>().setPeriodFilter(p),
            ),
          ),
          if (app.managedRelays.length > 1 && !_isPickupTab)
            _RelayFilterBar(
              relays: app.managedRelays,
              selectedId: app.selectedRelayId,
              onSelected: (id) => context.read<AppProvider>().setSelectedRelay(id),
            ),
          if (!_isPickupTab)
            Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un n° de suivi…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _loadCurrentTab(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 148,
                  child: DropdownButtonFormField<String>(
                    value: statusOptions.any((o) => o.value == currentFilter)
                        ? currentFilter
                        : 'all',
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: statusOptions
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.value,
                            child: Text(
                              o.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<AppProvider>().setStatusFilter(_currentTab, value);
                      _loadCurrentTab();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildParcelList(ExpeditionTab.reception),
                _buildParcelList(ExpeditionTab.expedition),
                _buildParcelList(ExpeditionTab.stock),
                const PickupNavShell(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openParcelSheet(
    KatianExpedition parcel,
    List<ParcelAction> actions, {
    bool shipToYou = false,
  }) async {
    await showKatianWhiteBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final ext = ctx.katian;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ext.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ParcelSheetHeroImage(parcel: parcel),
              Text(
                parcel.displayNumber,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ext.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (shipToYou)
                const Row(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: KatianColors.orange,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'À expédier vers vous',
                      style: TextStyle(
                        color: KatianColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                ParcelStatusBadge.fromParcel(parcel),
              if (parcel.recipientName != null) ...[
                const SizedBox(height: 12),
                _infoRow('Destinataire', parcel.recipientName!),
              ],
              if (parcel.recipientPhone != null)
                _infoRow('Téléphone', parcel.recipientPhone!),
              if (parcel.destinationRelayName != null)
                _infoRow('Destination', parcel.destinationRelayName!),
              if (parcel.originRelayName != null)
                _infoRow('Origine', parcel.originRelayName!),
              if (parcel.carrierName != null)
                _infoRow('Transporteur', parcel.carrierName!),
              if (actions.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Aucune action disponible pour ce statut',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ext.textSecondary, fontSize: 13),
                ),
              ] else ...[
                const SizedBox(height: 16),
                ...actions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _actionButton(action, parcel),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton(ParcelAction action, KatianExpedition parcel) {
    Color? bg;
    switch (action.kind) {
      case ParcelActionKind.receive:
        bg = KatianColors.blue;
      case ParcelActionKind.expedier:
      case ParcelActionKind.reship:
        bg = KatianColors.orange;
      case ParcelActionKind.found:
        bg = Colors.green;
      case ParcelActionKind.withdraw:
        bg = KatianColors.blue;
      case ParcelActionKind.cancel:
      case ParcelActionKind.returnParcel:
      case ParcelActionKind.declareLost:
        bg = action.destructive ? Colors.red.shade700 : KatianColors.red;
    }

    return FilledButton.icon(
      onPressed: () => _runAction(action, parcel),
      icon: Icon(iconForParcelAction(action.kind), size: 18),
      label: Text(action.label),
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _runAction(ParcelAction action, KatianExpedition parcel) async {
    if (action.destructive) {
      final confirmed = await _confirmDestructive(action);
      if (!confirmed || !mounted) return;
    }

    Navigator.pop(context);

    if (await redirectParcelFlowAction(context, action, parcel)) {
      if (!mounted) return;
      await _loadCurrentTab();
      await context.read<AppProvider>().loadDashboardStats();
      return;
    }

    String? driverName;
    String? driverPhone;
    if (action.needsDriver) {
      final driver = await DriverInfoDialog.show(context);
      if (driver == null || !mounted) return;
      driverName = driver.name;
      driverPhone = driver.phone;
    }

    final ok = await context.read<AppProvider>().applyParcelAction(
          parcel,
          action.kind,
          driverName: driverName,
          driverPhoneOrId: driverPhone,
        );
    if (!mounted) return;
    if (ok) {
      KatianToast.success(context, _successMessage(action));
    } else {
      KatianToast.error(
        context,
        context.read<AppProvider>().error ?? 'Action impossible',
      );
    }
  }

  Future<bool> _confirmDestructive(ParcelAction action) async {
    final (title, body) = switch (action.kind) {
      ParcelActionKind.cancel => (
          'Annuler le colis ?',
          'Cette action marquera le colis comme annulé.',
        ),
      ParcelActionKind.returnParcel => (
          'Marquer en retour ?',
          'Le colis sera marqué comme retourné.',
        ),
      ParcelActionKind.declareLost => (
          'Déclarer perdu ?',
          'Le colis sera marqué comme perdu.',
        ),
      _ => ('Confirmer ?', 'Voulez-vous continuer ?'),
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          KatianActionButtons.no(onPressed: () => Navigator.pop(ctx, false)),
          KatianActionButtons.yes(onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    return result == true;
  }

  String _successMessage(ParcelAction action) {
    return switch (action.kind) {
      ParcelActionKind.receive => 'Colis réceptionné',
      ParcelActionKind.expedier => 'Colis expédié',
      ParcelActionKind.cancel => 'Colis annulé',
      ParcelActionKind.found => 'Colis marqué retrouvé',
      ParcelActionKind.reship => 'Colis réexpédié',
      ParcelActionKind.withdraw => 'Colis retiré',
      ParcelActionKind.returnParcel => 'Colis retourné',
      ParcelActionKind.declareLost => 'Colis déclaré perdu',
    };
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Future<void> _openParcelMenu(
    KatianExpedition parcel,
    ExpeditionTab tab,
  ) async {
    final items = parcelMenuItemsFor(
      parcel: parcel,
      tab: tab,
      canAssignRelay: context.read<AppProvider>().user?.canAssignRelay ?? false,
    );
    final selected = await ParcelMenuSheet.show(context, items: items);
    if (selected == null || !mounted) return;
    await _handleMenuItem(parcel, selected, tab);
  }

  Future<void> _handleMenuItem(
    KatianExpedition parcel,
    ParcelMenuItem item,
    ExpeditionTab tab,
  ) async {
    final app = context.read<AppProvider>();

    switch (item.kind) {
      case ParcelMenuKind.tracking:
        final data = await app.fetchTraceability(parcel.id);
        if (!mounted) return;
        if (data != null) {
          await TraceabilitySheet.show(context, data);
        } else {
          KatianToast.error(
            context,
            app.error ?? 'Impossible de charger le suivi',
          );
        }
      case ParcelMenuKind.viewDetails:
        await ParcelDetailSheet.show(context, parcel);
      case ParcelMenuKind.changeStatus:
        final uiStatus = await StatusChangeDialog.show(
          context,
          parcel: parcel,
          tab: tab,
        );
        if (uiStatus == null || !mounted) return;
        final ok = await app.applyUiStatus(parcel, uiStatus, tab);
        if (!mounted) return;
        if (ok) {
          KatianToast.success(context, 'Statut mis à jour');
        } else {
          KatianToast.error(context, app.error ?? 'Échec mise à jour');
        }
      case ParcelMenuKind.assignRelay:
        final relays = await app.fetchRelayPoints();
        if (!mounted) return;
        final relayId = await AssignRelayDialog.show(context, relays);
        if (relayId == null || !mounted) return;
        final ok = await app.assignParcelRelay(parcel, relayId);
        if (!mounted) return;
        if (ok) {
          KatianToast.success(context, 'Point relais assigné');
        } else {
          KatianToast.error(context, app.error ?? 'Échec assignation');
        }
      case ParcelMenuKind.markDelivered:
        final confirmed = await _confirmSimple(
          'Marquer comme livré ?',
          'Le colis sera marqué comme retiré (RETIRE).',
        );
        if (!confirmed || !mounted) return;
        final ok = await app.markParcelDelivered(parcel);
        if (!mounted) return;
        if (ok) {
          KatianToast.success(context, 'Colis marqué comme livré');
        } else {
          KatianToast.error(context, app.error ?? 'Action impossible');
        }
      case ParcelMenuKind.manageReturn:
        final confirmed = await ReturnDialog.show(context);
        if (!confirmed || !mounted) return;
        final ok = await app.markParcelReturned(parcel);
        if (!mounted) return;
        if (ok) {
          KatianToast.success(context, 'Colis marqué comme retourné');
        } else {
          KatianToast.error(context, app.error ?? 'Échec retour');
        }
      case ParcelMenuKind.manageDispute:
        final confirmed = await LitigeDialog.show(context);
        if (!confirmed || !mounted) return;
        final ok = await app.markParcelLost(parcel);
        if (!mounted) return;
        if (ok) {
          KatianToast.success(context, 'Litige enregistré — colis déclaré perdu');
        } else {
          KatianToast.error(context, app.error ?? 'Échec litige');
        }
      case ParcelMenuKind.printLabel:
        try {
          await app.documents.generateShippingLabel(parcel, app.user);
          if (!mounted) return;
          KatianToast.success(context, 'Étiquette générée');
        } catch (e) {
          if (!mounted) return;
          KatianToast.error(context, 'Impossible de générer l\'étiquette');
        }
      case ParcelMenuKind.generateInvoice:
        try {
          await app.generateParcelInvoice(parcel);
          if (!mounted) return;
          KatianToast.success(context, 'Facture générée');
        } catch (e) {
          if (!mounted) return;
          KatianToast.error(
            context,
            app.error ?? 'Erreur lors de la génération de la facture',
          );
        }
      case ParcelMenuKind.reprintReceipt:
        try {
          await app.generateParcelReceipt(parcel);
          if (!mounted) return;
          KatianToast.success(context, 'Reçu généré');
        } catch (e) {
          if (!mounted) return;
          KatianToast.error(
            context,
            app.error ?? 'Erreur lors de la génération du reçu',
          );
        }
      case ParcelMenuKind.editAmount:
        final data = await EditAmountDialog.show(context, parcel);
        if (data == null || !mounted) return;
        final ok = await app.updateParcelAmount(parcel, data);
        if (!mounted) return;
        if (ok) {
          KatianToast.success(context, 'Montant mis à jour');
        } else {
          KatianToast.error(context, app.error ?? 'Échec modification');
        }
    }
  }

  Future<bool> _confirmSimple(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          KatianActionButtons.cancel(onPressed: () => Navigator.pop(ctx, false)),
          KatianActionButtons.confirm(
            onPressed: () => Navigator.pop(ctx, true),
            label: 'Confirmer',
            backgroundColor: KatianColors.red,
          ),
        ],
      ),
    );
    return result == true;
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
      height: 38,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        scrollDirection: Axis.horizontal,
        children: [
          // Chip "Toutes"
          _RelayChip(
            label: 'Toutes',
            selected: selectedId == null,
            onTap: () => onSelected(null),
            ext: ext,
          ),
          ...relays.map(
            (r) => _RelayChip(
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

class _RelayChip extends StatelessWidget {
  const _RelayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.ext,
  });

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
            border: Border.all(
              color: selected
                  ? KatianColors.red
                  : ext.border,
            ),
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
