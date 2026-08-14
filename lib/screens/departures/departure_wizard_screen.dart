import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/parcel_status.dart';
import '../../widgets/parcel_status_badge.dart';

enum _ParcelFilter { all, ready, pending }

class DepartureWizardScreen extends StatefulWidget {
  const DepartureWizardScreen({
    super.key,
    this.initialSelectedIds = const {},
  });

  final Set<int> initialSelectedIds;

  @override
  State<DepartureWizardScreen> createState() => _DepartureWizardScreenState();
}

class _DepartureWizardScreenState extends State<DepartureWizardScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late TabController _filterTabs;
  final _selectedIds = <int>{};
  List<KatianExpedition> _parcels = [];
  bool _loadingParcels = false;

  DateTime _departureDate = DateTime.now();
  TimeOfDay _departureTime = TimeOfDay.now();
  final _commentCtrl = TextEditingController();

  final _carCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  List<TpCarOption> _cars = [];
  List<TpConvoyeurOption> _drivers = [];
  int? _selectedCarId;
  int? _selectedDriverId;
  bool _loadingFleet = false;
  bool _useManualEntry = false;

  BordereauExpedition? _bordereau;
  bool _submitting = false;
  bool _printing = false;
  String? _error;
  final _confirmFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _filterTabs = TabController(length: 3, vsync: this);
    _loadParcels();
    _loadFleet();
  }

  Future<void> _loadFleet() async {
    setState(() => _loadingFleet = true);
    try {
      final app = context.read<AppProvider>();
      final results = await Future.wait([
        app.fleet.listActiveCars(),
        app.fleet.listActiveDrivers(),
      ]);
      if (!mounted) return;
      setState(() {
        _cars = results[0] as List<TpCarOption>;
        _drivers = results[1] as List<TpConvoyeurOption>;
        _useManualEntry = _cars.isEmpty && _drivers.isEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _useManualEntry = true);
    } finally {
      if (mounted) setState(() => _loadingFleet = false);
    }
  }

  void _onDriverSelected(int? driverId) {
    setState(() {
      _selectedDriverId = driverId;
      if (driverId == null) {
        _driverCtrl.clear();
        _phoneCtrl.clear();
        return;
      }
      final driver = _drivers.firstWhere((d) => d.id == driverId);
      _driverCtrl.text = driver.displayName;
      _phoneCtrl.text = driver.phone;
      if (driver.assignedCarId != null) {
        _selectedCarId = driver.assignedCarId;
        final car = _cars.cast<TpCarOption?>().firstWhere(
              (c) => c?.id == driver.assignedCarId,
              orElse: () => null,
            );
        if (car != null) {
          _carCtrl.text = car.internalNumber.isNotEmpty
              ? car.internalNumber
              : car.registration;
        }
      }
    });
  }

  void _onCarSelected(int? carId) {
    setState(() {
      _selectedCarId = carId;
      if (carId == null) {
        _carCtrl.clear();
        return;
      }
      final car = _cars.firstWhere((c) => c.id == carId);
      _carCtrl.text =
          car.internalNumber.isNotEmpty ? car.internalNumber : car.registration;
    });
  }

  @override
  void dispose() {
    _filterTabs.dispose();
    _commentCtrl.dispose();
    _carCtrl.dispose();
    _driverCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadParcels() async {
    setState(() {
      _loadingParcels = true;
      _error = null;
    });
    try {
      final app = context.read<AppProvider>();
      _parcels = await app.queryDepartableParcels();
      if (widget.initialSelectedIds.isNotEmpty) {
        final validIds = widget.initialSelectedIds
            .where((id) => _parcels.any((p) => p.id == id))
            .toSet();
        _selectedIds
          ..clear()
          ..addAll(validIds);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingParcels = false);
      }
    }
  }

  List<KatianExpedition> _filteredParcels(_ParcelFilter filter) {
    switch (filter) {
      case _ParcelFilter.all:
        return _parcels;
      case _ParcelFilter.ready:
        return _parcels
            .where((p) => normalizeParcelStatus(p.currentStatus) == 'a_expedier')
            .toList();
      case _ParcelFilter.pending:
        return _parcels
            .where((p) => normalizeParcelStatus(p.currentStatus) == 'en_transit')
            .toList();
    }
  }

  int get _readyCount =>
      _parcels.where((p) => normalizeParcelStatus(p.currentStatus) == 'a_expedier').length;

  int get _pendingCount =>
      _parcels.where((p) => normalizeParcelStatus(p.currentStatus) == 'en_transit').length;

  bool _canSelect(KatianExpedition p) {
    final app = context.read<AppProvider>();
    return isDepartableParcel(p, app.user);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _departureDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (picked != null) setState(() => _departureTime = picked);
  }

  String get _timeLabel {
    final h = _departureTime.hour.toString().padLeft(2, '0');
    final m = _departureTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submitPlanification() async {
    if (_selectedIds.isEmpty) {
      _showSnack('Sélectionnez au moins un colis.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final app = context.read<AppProvider>();
      _bordereau = await app.bordereaux.planDeparture(
        parcelIds: _selectedIds.toList(),
        departureDate: _departureDate,
        departureTime: _timeLabel,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      setState(() => _step = 2);
    } catch (e) {
      _error = context.read<AppProvider>().formatError(e);
      _showSnack(_error!);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitConfirmation() async {
    if (!(_confirmFormKey.currentState?.validate() ?? false)) return;
    if (_bordereau == null) return;

    final car = _carCtrl.text.trim();
    final driver = _driverCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final app = context.read<AppProvider>();
      _bordereau = await app.bordereaux.confirm(
        bordereauId: _bordereau!.id,
        carNumber: car,
        driverName: driver,
        driverPhone: phone,
        carId: _selectedCarId,
        convoyeurId: _selectedDriverId,
        departureTime: _timeLabel,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );
      await app.loadDashboardStats();
      await app.loadExpeditionParcels();
      setState(() => _step = 3);
    } catch (e) {
      _error = context.read<AppProvider>().formatError(e);
      _showSnack(_error!);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _printBordereau() async {
    final b = _bordereau;
    if (b == null || _printing) return;
    setState(() => _printing = true);
    try {
      final app = context.read<AppProvider>();
      final full = await app.bordereaux.detail(b.id);
      await app.documents.generateBordereau(full);
    } catch (e) {
      _showSnack('Impossible de générer le PDF : $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  List<KatianExpedition> get _selectedParcels =>
      _parcels.where((p) => _selectedIds.contains(p.id)).toList();

  String get _departureDateLabel =>
      DateFormat('dd/MM/yyyy', 'fr_FR').format(_departureDate);

  String? get _relayName {
    final fromBordereau = _bordereau?.departureRelayName;
    if (fromBordereau != null && fromBordereau.isNotEmpty) return fromBordereau;
    return context.read<AppProvider>().user?.relayPoint?.name;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Scaffold(
      backgroundColor: ext.background,
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0 && _step < 3) {
              setState(() => _step -= 1);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(current: _step, ext: ext),
          Expanded(child: _buildStep(ext)),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'Colis à expédier';
      case 1:
        return 'Préparation du départ';
      case 2:
        return 'Confirmation du départ';
      case 3:
        return 'Départ confirmé';
      default:
        return 'Départs';
    }
  }

  Widget _buildStep(KatianThemeExtension ext) {
    switch (_step) {
      case 0:
        return _buildSelectionStep(ext);
      case 1:
        return _buildPlanStep(ext);
      case 2:
        return _buildCarStep(ext);
      case 3:
        return _buildSuccessStep(ext);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionStep(KatianThemeExtension ext) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Material(
            color: ext.surface,
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: TabBar(
              controller: _filterTabs,
              indicatorColor: KatianColors.red,
              indicatorWeight: 3,
              labelColor: KatianColors.red,
              unselectedLabelColor: ext.textSecondary,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: 'Tous ($_totalCount)'),
                Tab(text: 'Prêts ($_readyCount)'),
                Tab(text: 'En attente ($_pendingCount)'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _filterTabs,
            children: [
              _buildParcelList(ext, _ParcelFilter.all),
              _buildParcelList(ext, _ParcelFilter.ready),
              _buildParcelList(ext, _ParcelFilter.pending),
            ],
          ),
        ),
        _BottomAction(
          label: 'Préparer départ (${_selectedIds.length})',
          icon: Icons.playlist_add_check,
          loading: false,
          onPressed: _selectedIds.isEmpty ? null : () => setState(() => _step = 1),
        ),
      ],
    );
  }

  int get _totalCount => _parcels.length;

  Widget _buildParcelList(KatianThemeExtension ext, _ParcelFilter filter) {
    final list = _filteredParcels(filter);
    return _loadingParcels
        ? const Center(child: CircularProgressIndicator(color: KatianColors.red))
        : list.isEmpty
            ? Center(
                child: Text(
                  'Aucun colis pour ce filtre',
                  style: TextStyle(color: ext.textSecondary),
                ),
              )
            : RefreshIndicator(
                color: KatianColors.red,
                onRefresh: _loadParcels,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final p = list[index];
                    final selectable = _canSelect(p);
                    final checked = _selectedIds.contains(p.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: checked,
                        onChanged: selectable
                            ? (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.add(p.id);
                                  } else {
                                    _selectedIds.remove(p.id);
                                  }
                                });
                              }
                            : null,
                        title: Text(
                          p.displayNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ext.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${p.originRelayName ?? '—'} → ${p.destinationRelayName ?? '—'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: ext.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ParcelStatusBadge.fromParcel(p, compact: true),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              );
  }

  Widget _buildPlanStep(KatianThemeExtension ext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Vous avez sélectionné ${_selectedIds.length} colis',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ext.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text('Date de départ', style: TextStyle(color: ext.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              _FieldTap(
                value: DateFormat('dd/MM/yyyy', 'fr_FR').format(_departureDate),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              Text('Heure de départ', style: TextStyle(color: ext.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              _FieldTap(
                value: _timeLabel,
                icon: Icons.access_time,
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              Text('Commentaires (optionnel)', style: TextStyle(color: ext.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ajouter un commentaire…',
                ),
              ),
            ],
          ),
        ),
        _BottomAction(
          label: 'Confirmer la préparation',
          icon: Icons.fact_check_outlined,
          loading: _submitting,
          onPressed: _submitting ? null : _submitPlanification,
        ),
      ],
    );
  }

  Widget _buildCarStep(KatianThemeExtension ext) {
    final selected = _selectedParcels;
    final comment = _commentCtrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _WizardInfoBanner(
                icon: Icons.directions_bus_rounded,
                title: 'Confirmation du départ',
                subtitle:
                    'Vérifiez le récapitulatif puis renseignez les informations du car.',
              ),
              const SizedBox(height: 16),
              _RecapCard(
                ext: ext,
                title: 'Récapitulatif du départ',
                rows: [
                  _RecapItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Colis sélectionnés',
                    value: '${selected.length}',
                  ),
                  _RecapItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _departureDateLabel,
                  ),
                  _RecapItem(
                    icon: Icons.access_time,
                    label: 'Heure prévue',
                    value: _timeLabel,
                  ),
                  if (_relayName != null)
                    _RecapItem(
                      icon: Icons.location_on_outlined,
                      label: 'Gare de départ',
                      value: _relayName!,
                    ),
                  if (comment.isNotEmpty)
                    _RecapItem(
                      icon: Icons.notes_outlined,
                      label: 'Commentaire',
                      value: comment,
                    ),
                ],
              ),
              if (selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ParcelPreviewCard(parcels: selected, ext: ext),
              ],
              const SizedBox(height: 16),
              Text(
                'Informations du car',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: ext.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (_loadingFleet)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (!_useManualEntry)
                Form(
                  key: _confirmFormKey,
                  child: _FormCard(
                    ext: ext,
                    children: [
                      _FleetDropdownField<int>(
                        label: 'Conducteur',
                        required: true,
                        value: _selectedDriverId,
                        hint: 'Choisir un chauffeur',
                        prefixIcon: Icons.person_outline,
                        items: _drivers
                            .map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(
                                  '${d.displayName} — ${d.phone}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        selectedItemBuilder: (context) => _drivers
                            .map(
                              (d) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  d.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _onDriverSelected,
                        validator: (v) =>
                            v == null ? 'Sélectionnez un conducteur' : null,
                      ),
                      const SizedBox(height: 14),
                      _FleetDropdownField<int>(
                        label: 'Car',
                        required: true,
                        value: _selectedCarId,
                        hint: 'Choisir un car',
                        prefixIcon: Icons.directions_bus_outlined,
                        items: _cars
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.pickerLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        selectedItemBuilder: (context) => _cars
                            .map(
                              (c) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  c.pickerLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _onCarSelected,
                        validator: (v) => v == null ? 'Sélectionnez un car' : null,
                      ),
                      if (_selectedDriverId != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Téléphone : ${_phoneCtrl.text}',
                          style: TextStyle(color: ext.textSecondary, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() => _useManualEntry = true),
                          child: const Text('Saisie manuelle'),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Heure de départ effective',
                        style: TextStyle(color: ext.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      _FieldTap(
                        value: _timeLabel,
                        icon: Icons.schedule,
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                )
              else
                Form(
                  key: _confirmFormKey,
                  child: _FormCard(
                    ext: ext,
                    children: [
                      if (_drivers.isNotEmpty || _cars.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _useManualEntry = false),
                            child: const Text('Choisir dans la flotte'),
                          ),
                        ),
                      _RequiredField(
                        label: 'Numéro du car',
                        controller: _carCtrl,
                        icon: Icons.directions_bus_outlined,
                        hint: 'Ex. CAR-001',
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 14),
                      _RequiredField(
                        label: 'Nom du conducteur',
                        controller: _driverCtrl,
                        icon: Icons.person_outline,
                        hint: 'Ex. Yao Patrice',
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 14),
                      _RequiredField(
                        label: 'Téléphone du conducteur',
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        hint: '07 01 02 03 04',
                        keyboard: TextInputType.phone,
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 8) {
                            return 'Numéro invalide (8 chiffres min.)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Heure de départ effective',
                        style: TextStyle(color: ext.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      _FieldTap(
                        value: _timeLabel,
                        icon: Icons.schedule,
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KatianColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: KatianColors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: KatianColors.redDark,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _BottomAction(
          label: 'Confirmer le départ',
          icon: Icons.departure_board_outlined,
          loading: _submitting,
          onPressed: _submitting ? null : _submitConfirmation,
        ),
      ],
    );
  }

  Widget _buildSuccessStep(KatianThemeExtension ext) {
    final b = _bordereau;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KatianColors.green.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: KatianColors.green,
                    size: 52,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Départ confirmé avec succès !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KatianColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les colis sont maintenant expédiés (EXPEDIE).',
                textAlign: TextAlign.center,
                style: TextStyle(color: ext.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (b != null) ...[
                _RecapCard(
                  ext: ext,
                  title: 'Résumé du bordereau',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KatianColors.redLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b.number,
                      style: const TextStyle(
                        color: KatianColors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  rows: [
                    _RecapItem(
                      icon: Icons.directions_bus_outlined,
                      label: 'Car',
                      value: b.carNumber ?? '—',
                    ),
                    _RecapItem(
                      icon: Icons.person_outline,
                      label: 'Conducteur',
                      value: b.driverName ?? '—',
                    ),
                    _RecapItem(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: b.driverPhone ?? '—',
                    ),
                    _RecapItem(
                      icon: Icons.event_outlined,
                      label: 'Date & heure',
                      value: b.departureLabel,
                    ),
                    _RecapItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Nombre de colis',
                      value: '${b.parcelCount}',
                    ),
                    if (b.departureRelayName != null)
                      _RecapItem(
                        icon: Icons.location_on_outlined,
                        label: 'Gare de départ',
                        value: b.departureRelayName!,
                      ),
                  ],
                ),
                if (b.colis.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FormCard(
                    ext: ext,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.list_alt, size: 18, color: ext.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Colis expédiés',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ext.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...b.colis.take(5).map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: KatianColors.redLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: KatianColors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.expeditionNumber ?? '—',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: ext.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${c.recipientName ?? '—'} · ${c.destination ?? '—'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ext.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (b.colis.length > 5)
                        Text(
                          '+ ${b.colis.length - 5} autre(s) colis',
                          style: TextStyle(
                            fontSize: 12,
                            color: ext.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: FilledButton.icon(
            onPressed: _printing ? null : _printBordereau,
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.print_outlined),
            label: Text(_printing ? 'Génération…' : 'Imprimer bordereau d\'expédition'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: KatianTheme.buttonShape,
            ),
          ),
        ),
        _BottomAction(
          label: 'Retour à la liste',
          icon: Icons.list_alt_outlined,
          loading: false,
          filled: false,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.ext});

  final int current;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: List.generate(4, (i) {
          final active = i <= current;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              decoration: BoxDecoration(
                color: active ? KatianColors.red : ext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FieldTap extends StatelessWidget {
  const _FieldTap({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: Icon(icon, color: KatianColors.red),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _FleetDropdownField<T> extends StatelessWidget {
  const _FleetDropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.selectedItemBuilder,
    this.validator,
    this.required = false,
  });

  final String label;
  final T? value;
  final String hint;
  final IconData prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final String? Function(T?)? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: ext.textSecondary, fontSize: 13),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: KatianColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          isExpanded: true,
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, maxWidth: 44, minHeight: 44),
          ),
          hint: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          items: items,
          selectedItemBuilder: selectedItemBuilder,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.label,
    required this.controller,
    this.keyboard,
    this.icon,
    this.hint,
    this.textCapitalization,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final IconData? icon;
  final String? hint;
  final TextCapitalization? textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: context.katian.textSecondary, fontSize: 13),
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: KatianColors.red)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: KatianColors.red, size: 20) : null,
          ),
        ),
      ],
    );
  }
}

class _WizardInfoBanner extends StatelessWidget {
  const _WizardInfoBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KatianColors.redLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KatianColors.red.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: KatianColors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: KatianColors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: KatianColors.redDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.katian.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapItem {
  const _RecapItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({
    required this.ext,
    required this.title,
    required this.rows,
    this.trailing,
  });

  final KatianThemeExtension ext;
  final String title;
  final List<_RecapItem> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      ext: ext,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ext.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(row.icon, size: 18, color: ext.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(fontSize: 12, color: ext.textSecondary),
                      ),
                      Text(
                        row.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ext.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.ext, required this.children});

  final KatianThemeExtension ext;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ParcelPreviewCard extends StatelessWidget {
  const _ParcelPreviewCard({required this.parcels, required this.ext});

  final List<KatianExpedition> parcels;
  final KatianThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    final preview = parcels.take(3).toList();
    return _FormCard(
      ext: ext,
      children: [
        Text(
          'Aperçu des colis',
          style: TextStyle(fontWeight: FontWeight.w700, color: ext.textPrimary),
        ),
        const SizedBox(height: 8),
        ...preview.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: context.katian.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${p.displayNumber} → ${p.destinationRelayName ?? '—'}',
                    style: TextStyle(fontSize: 12, color: ext.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (parcels.length > 3)
          Text(
            '+ ${parcels.length - 3} autre(s)',
            style: TextStyle(fontSize: 12, color: ext.textSecondary),
          ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.filled = true,
    this.icon,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: filled
            ? FilledButton.icon(
                onPressed: loading ? null : onPressed,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(icon ?? Icons.check, size: 18),
                label: Text(label),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: KatianTheme.buttonShape,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon ?? Icons.arrow_back, size: 18),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: KatianTheme.buttonShape,
                ),
              ),
      ),
    );
  }
}
