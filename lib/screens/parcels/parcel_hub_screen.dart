import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/parcel_actions.dart';
import '../../utils/parcel_flow_handler.dart';
import '../../utils/parcel_menu.dart';
import '../../utils/parcel_status.dart';
import '../../widgets/katian_action_buttons.dart';
import '../../widgets/driver_info_dialog.dart';
import '../../widgets/katian_bottom_sheet.dart';
import '../../widgets/parcel_card.dart';
import '../../widgets/parcel_menu_sheets.dart';
import '../../widgets/parcel_status_badge.dart';
import '../../widgets/parcel_sheet_hero.dart';
import '../../widgets/password_input_field.dart';
import 'parcel_hub_kind.dart';

class ParcelHubScreen extends StatefulWidget {
  const ParcelHubScreen({super.key, required this.kind});

  final ParcelHubKind kind;

  @override
  State<ParcelHubScreen> createState() => _ParcelHubScreenState();
}

class _ParcelHubScreenState extends State<ParcelHubScreen> {
  late final ParcelHubConfig _config;
  late String _statusFilter;
  final _search = TextEditingController();

  List<KatianExpedition> _parcels = [];
  bool _loading = false;

  ExpeditionTab get _tab => _config.tab;

  @override
  void initState() {
    super.initState();
    _config = ParcelHubConfig.forKind(widget.kind);
    _statusFilter = _config.initialStatusFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadParcels());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadParcels() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final app = context.read<AppProvider>();
    final filter = _config.lockStatusFilter
        ? _config.initialStatusFilter
        : _statusFilter;

    try {
      final List<KatianExpedition> list;
      switch (widget.kind) {
        case ParcelHubKind.toReceive:
          list = await app.queryReceptionableParcels(search: _search.text);
        case ParcelHubKind.toShip:
          list = await app.queryToShipParcels();
        case ParcelHubKind.toReship:
        case ParcelHubKind.inTransit:
          list = await app.queryToReshipParcels();
        case ParcelHubKind.reception:
          list = await app.queryReceptionParcels(
            statusFilter: filter,
            search: _search.text,
          );
        case ParcelHubKind.expedition:
        case ParcelHubKind.history:
          list = await app.queryExpeditionParcels(
            statusFilter: filter,
            search: _search.text,
          );
        case ParcelHubKind.stock:
          list = await app.queryStockParcels(statusFilter: filter);
      }
      if (!mounted) return;
      setState(() {
        _parcels = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _reloadAfterSuccess() async {
    await _loadParcels();
    if (!mounted) return;
    await context.read<AppProvider>().loadDashboardStats();
  }

  List<ParcelAction> _actionsFor(KatianExpedition parcel, AppProvider app) {
    return parcelActionsFor(
      parcel: parcel,
      tab: _tab,
      user: app.user,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ext = context.katian;
    final statusOptions = _config.filters();
    final showStatusDropdown = !_config.lockStatusFilter;

    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        backgroundColor: KatianColors.red,
        foregroundColor: KatianColors.white,
        iconTheme: const IconThemeData(color: KatianColors.white),
        title: Text(
          _config.title,
          style: const TextStyle(
            color: KatianColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_config.subtitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: ext.surfaceVariant,
              child: Text(
                _config.subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: ext.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
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
                    onSubmitted: (_) => _loadParcels(),
                  ),
                ),
                if (showStatusDropdown) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 148,
                    child: DropdownButtonFormField<String>(
                      value: statusOptions.any((o) => o.value == _statusFilter)
                          ? _statusFilter
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
                        setState(() => _statusFilter = value);
                        _loadParcels();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: KatianColors.red,
              onRefresh: _loadParcels,
              child: _loading && _parcels.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: KatianColors.red),
                    )
                  : _parcels.isEmpty
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
                              _config.emptyMessage,
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
                          itemCount: _parcels.length,
                          itemBuilder: (_, i) {
                            final parcel = _parcels[i];
                            final actions = _actionsFor(parcel, app);
                            final shipToYou = _tab == ExpeditionTab.reception &&
                                isShipToYouPending(parcel, app.user);
                            return ParcelCard(
                              parcel: parcel,
                              showShipToYou: shipToYou,
                              onTap: () => _openParcelSheet(
                                parcel,
                                actions,
                                shipToYou: shipToYou,
                              ),
                              onMenuTap: () => _openParcelMenu(parcel),
                            );
                          },
                        ),
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
                ...actions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _actionButton(action, parcel),
                  ),
                ),
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
      await _reloadAfterSuccess();
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
      await _reloadAfterSuccess();
      if (!mounted) return;
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

  Future<void> _openParcelMenu(KatianExpedition parcel) async {
    final items = parcelMenuItemsFor(
      parcel: parcel,
      tab: _tab,
      canAssignRelay: context.read<AppProvider>().user?.canAssignRelay ?? false,
    );
    final selected = await ParcelMenuSheet.show(context, items: items);
    if (selected == null || !mounted) return;
    await _handleMenuItem(parcel, selected);
  }

  Future<void> _handleMenuItem(
    KatianExpedition parcel,
    ParcelMenuItem item,
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
          tab: _tab,
        );
        if (uiStatus == null || !mounted) return;
        final ok = await app.applyUiStatus(parcel, uiStatus, _tab);
        if (!mounted) return;
        if (ok) {
          await _reloadAfterSuccess();
          if (!mounted) return;
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
          await _reloadAfterSuccess();
          if (!mounted) return;
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
          await _reloadAfterSuccess();
          if (!mounted) return;
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
          await _reloadAfterSuccess();
          if (!mounted) return;
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
          await _reloadAfterSuccess();
          if (!mounted) return;
          KatianToast.success(
            context,
            'Litige enregistré — colis déclaré perdu',
          );
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
          await _reloadAfterSuccess();
          if (!mounted) return;
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
