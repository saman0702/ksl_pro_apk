import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../models/models.dart';
import '../navigation/flow_navigation.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/bordereau_service.dart';
import '../services/deposit_service.dart';
import '../services/document_service.dart';
import '../services/expedition_service.dart';
import '../services/fleet_service.dart';
import '../services/notification_service.dart';
import '../services/parcel_status_service.dart';
import '../services/push_notification_service.dart';
import '../utils/parcel_actions.dart';
import '../utils/parcel_status.dart';
import '../utils/period_filter.dart';
import '../utils/status_update_mapper.dart';

class AppProvider extends ChangeNotifier {
  AppProvider() {
    _api = ApiClient();
    auth = AuthService(_api);
    dashboard = DashboardService(_api);
    finances = FinanceService(_api);
    expeditions = ExpeditionService(_api);
    parcelStatus = ParcelStatusService(expeditions);
    bordereaux = BordereauService(_api);
    deposits = DepositService(_api);
    fleet = FleetService(_api);
    notifications = NotificationService(_api);
  }

  late final ApiClient _api;
  late final AuthService auth;
  late final DashboardService dashboard;
  late final FinanceService finances;
  late final ExpeditionService expeditions;
  late final ParcelStatusService parcelStatus;
  late final BordereauService bordereaux;
  late final DepositService deposits;
  late final FleetService fleet;
  late final NotificationService notifications;
  final DocumentService documents = DocumentService();

  Timer? _notificationPollTimer;
  List<AppNotification> notificationItems = [];
  int unreadNotificationCount = 0;
  bool loadingNotifications = false;

  KatianUser? user;
  /// Mot de passe saisi à la dernière connexion (mémoire uniquement, pour préremplir le changement MDP).
  String? sessionPassword;
  DashboardStats stats = const DashboardStats();
  RelayFinanceSummary? financeSummary;
  bool financeLoading = false;
  bool loading = false;
  String? error;
  int navIndex = 0;
  /// 0=Réception, 1=Expédition, 2=Stock, 3=Retrait (onglet Colis).
  int colisTabIndex = 0;
  ExpeditionTab expeditionTab = ExpeditionTab.reception;
  PickupFlowRequest? pickupFlowRequest;
  DepartureFlowRequest? departureFlowRequest;
  String receptionStatusFilter = 'all';
  String expeditionStatusFilter = 'all';
  String stockStatusFilter = 'all';
  /// Filtre période global (dashboard + Colis) — `''` = toutes.
  String periodFilter = '';

  /// Gares gérées — renseigné pour role=relay_point ou agent_admin avec plusieurs gares.
  List<RelayPointOption> managedRelays = [];
  /// Gare sélectionnée pour les filtres — null = toutes les gares.
  int? selectedRelayId;

  List<KatianExpedition> receptionParcels = [];
  List<KatianExpedition> expeditionParcels = [];
  List<KatianExpedition> stockParcels = [];
  bool parcelsLoading = false;

  Future<void> bootstrap() async {
    try {
      await PushNotificationService.instance.initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Katian Pro] Push init ignorée: $e');
      }
    }
    if (!await auth.isLoggedIn()) return;
    try {
      user = await auth.profile();
      sessionPassword = await auth.readSessionPassword();
      if (user?.isConvoyeur != true) {
        await loadDashboardStats();
        await loadManagedRelays();
      }
      await _startNotificationServices();
    } catch (_) {
      await auth.logout();
      user = null;
      sessionPassword = null;
    }
    notifyListeners();
  }

  /// Charge les gares gérées si l'utilisateur est gérant (relay_point / agent_admin) avec plusieurs gares.
  Future<void> loadManagedRelays() async {
    final u = user;
    if (u == null) return;
    final isGerant = u.isGerantLike;
    if (!isGerant) {
      managedRelays = [];
      return;
    }
    try {
      final all = await expeditions.relayPoints();
      managedRelays = all;
    } catch (_) {
      managedRelays = [];
    }
  }

  /// Change la gare sélectionnée et recharge le dashboard + toutes les listes de colis.
  Future<void> setSelectedRelay(int? relayId) async {
    if (selectedRelayId == relayId) return;
    selectedRelayId = relayId;
    notifyListeners();
    await Future.wait([
      loadDashboardStats(),
      loadAllParcelLists(),
    ]);
  }

  Future<void> _rememberSessionPassword(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return;
    sessionPassword = trimmed;
    await auth.saveSessionPassword(trimmed);
  }

  /// Mot de passe actuel utilisé automatiquement pour le changement MDP.
  Future<String?> resolveOldPasswordPrefill({
    String? explicit,
    bool useDefaultHint = false,
  }) async {
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    if (sessionPassword != null && sessionPassword!.trim().isNotEmpty) {
      return sessionPassword!.trim();
    }
    final stored = await auth.readSessionPassword();
    if (stored != null && stored.trim().isNotEmpty) {
      sessionPassword = stored.trim();
      return stored.trim();
    }
    if (useDefaultHint || user?.mustChangePassword == true) {
      return AppConfig.defaultConvoyeurPassword;
    }
    return null;
  }

  Future<void> loadDashboardStats() async {
    try {
      final params = <String, dynamic>{...periodQueryParams(periodFilter)};
      if (selectedRelayId != null) {
        params['id_pointrelais'] = selectedRelayId;
      }
      stats = await dashboard.fetchStats(queryParams: params);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Katian Pro] dashboard stats error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadFinanceSummary() async {
    financeLoading = true;
    notifyListeners();
    try {
      financeSummary = await finances.fetchTpSummary();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Katian Pro] finance summary error: $e');
      }
    } finally {
      financeLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriodFilter(String period) async {
    if (periodFilter == period) return;
    periodFilter = period;
    notifyListeners();
    await loadDashboardStats();
    if (navIndex == 1) {
      await loadAllParcelLists();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      user = await auth.login(email, password);
      await _rememberSessionPassword(password);
      if (user?.isConvoyeur != true) {
        await loadDashboardStats();
        await loadManagedRelays();
      }
      await _startNotificationServices();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithOtp({
    required String identifier,
    required String code,
  }) async {
    _setLoading(true);
    try {
      user = await auth.loginWithOtp(identifier: identifier, code: code);
      if (user?.isConvoyeur != true) {
        await loadDashboardStats();
        await loadManagedRelays();
      }
      await _startNotificationServices();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await auth.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      user = await auth.profile();
      await _rememberSessionPassword(newPassword);
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<OtpVerifyResult?> sendOtp(String identifier) async {
    _setLoading(true);
    try {
      final result = await auth.verifyIdentifier(identifier);
      error = null;
      notifyListeners();
      return result;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<ForgotPasswordResult?> requestPasswordReset(String identifier) async {
    _setLoading(true);
    try {
      final result = await auth.requestPasswordReset(identifier);
      error = null;
      notifyListeners();
      return result;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String identifier,
    required String code,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await auth.resetPassword(
        identifier: identifier,
        code: code,
        password: password,
      );
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _unregisterPushToken();
    _stopNotificationServices();
    await auth.logout();
    user = null;
    sessionPassword = null;
    stats = const DashboardStats();
    notificationItems = [];
    unreadNotificationCount = 0;
    navIndex = 0;
    colisTabIndex = 0;
    expeditionTab = ExpeditionTab.reception;
    receptionStatusFilter = 'all';
    expeditionStatusFilter = 'all';
    stockStatusFilter = 'all';
    periodFilter = '';
    receptionParcels = [];
    expeditionParcels = [];
    stockParcels = [];
    notifyListeners();
  }

  void setNavIndex(
    int index, {
    ExpeditionTab? openExpeditionTab,
    int? openColisTabIndex,
  }) {
    navIndex = index.clamp(0, 4);
    if (openColisTabIndex != null) {
      setColisTabIndex(openColisTabIndex);
    } else if (openExpeditionTab != null) {
      setExpeditionTab(openExpeditionTab);
    }
    notifyListeners();
  }

  void setColisTabIndex(int index) {
    colisTabIndex = index.clamp(0, 3);
    if (colisTabIndex < 3) {
      expeditionTab = ExpeditionTab.values[colisTabIndex];
    }
    notifyListeners();
  }

  void openPickupTab() {
    navIndex = 1;
    colisTabIndex = 3;
    notifyListeners();
  }

  /// Ouvre l'onglet Retrait puis le wizard (retrait / livraison).
  void requestPickupFlow({KatianExpedition? parcel, bool openDetail = true}) {
    pickupFlowRequest = PickupFlowRequest(
      parcel: parcel,
      openDetail: openDetail,
    );
    openPickupTab();
  }

  void clearPickupFlowRequest() {
    pickupFlowRequest = null;
    notifyListeners();
  }

  /// Ouvre l'écran Départs puis le wizard de départ.
  void requestDepartureFlow({Set<int> parcelIds = const {}}) {
    departureFlowRequest = DepartureFlowRequest(parcelIds: parcelIds);
    navIndex = 3;
    notifyListeners();
  }

  void clearDepartureFlowRequest() {
    departureFlowRequest = null;
    notifyListeners();
  }

  /// Scanner — réception colis.
  void openReceptionScanner() {
    navIndex = 2;
    notifyListeners();
  }

  /// Stock — colis EN_TRANSIT chez le point relais (`current_relay_id`).
  Future<void> openInTransitStock() async {
    stockStatusFilter = 'EN_TRANSIT';
    navIndex = 1;
    colisTabIndex = ExpeditionTab.stock.index;
    expeditionTab = ExpeditionTab.stock;
    notifyListeners();
    await loadStockParcels();
  }

  /// Stock complet (tous statuts en stock).
  Future<void> openStock({String statusFilter = 'all'}) async {
    stockStatusFilter = statusFilter;
    navIndex = 1;
    colisTabIndex = ExpeditionTab.stock.index;
    expeditionTab = ExpeditionTab.stock;
    notifyListeners();
    await loadStockParcels();
  }

  void setExpeditionTab(ExpeditionTab tab) {
    expeditionTab = tab;
    colisTabIndex = tab.index;
    notifyListeners();
  }

  void setStatusFilter(ExpeditionTab tab, String value) {
    switch (tab) {
      case ExpeditionTab.reception:
        receptionStatusFilter = value;
      case ExpeditionTab.expedition:
        expeditionStatusFilter = value;
      case ExpeditionTab.stock:
        stockStatusFilter = value;
    }
    notifyListeners();
  }

  String statusFilterFor(ExpeditionTab tab) {
    switch (tab) {
      case ExpeditionTab.reception:
        return receptionStatusFilter;
      case ExpeditionTab.expedition:
        return expeditionStatusFilter;
      case ExpeditionTab.stock:
        return stockStatusFilter;
    }
  }

  Future<void> loadReceptionParcels({String? search}) async {
    parcelsLoading = true;
    notifyListeners();
    try {
      receptionParcels = await queryReceptionParcels(
        statusFilter: receptionStatusFilter,
        search: search,
      );
      error = null;
    } catch (e) {
      error = _messageFromError(e);
    } finally {
      parcelsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpeditionParcels({String? search}) async {
    parcelsLoading = true;
    notifyListeners();
    try {
      expeditionParcels = await queryExpeditionParcels(
        statusFilter: expeditionStatusFilter,
        search: search,
      );
      error = null;
    } catch (e) {
      error = _messageFromError(e);
    } finally {
      parcelsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStockParcels() async {
    parcelsLoading = true;
    notifyListeners();
    try {
      stockParcels = await queryStockParcels(
        statusFilter: stockStatusFilter,
      );
      error = null;
    } catch (e) {
      error = _messageFromError(e);
    } finally {
      parcelsLoading = false;
      notifyListeners();
    }
  }

  /// Liste « À réceptionner » — destination = gare connectée, A_EXPEDIER + EXPEDIE.
  /// Réception physique (scan) : EXPEDIE uniquement via scope=receivable.
  Future<List<KatianExpedition>> queryReceptionableParcels({String? search}) async {
    final relayId = user?.relayPoint?.id;
    return expeditions.receptionables(
      search: search,
      relayId: relayId != null && relayId > 0 ? relayId : null,
      scope: 'pending',
      period: periodFilter.isEmpty ? null : periodFilter,
    );
  }

  Future<List<KatianExpedition>> queryReceptionParcels({
    String statusFilter = 'all',
    String? search,
  }) async {
    final q = search?.trim();
    final status = statusFilter == 'all' ? null : statusFilter;
    return expeditions.list(
      mode: 'reception',
      currentStatus: status,
      search: q != null && q.isNotEmpty ? q : null,
      period: periodFilter.isEmpty ? null : periodFilter,
      relayId: selectedRelayId,
    );
  }

  Future<List<KatianExpedition>> queryExpeditionParcels({
    String statusFilter = 'all',
    String? search,
  }) async {
    final q = search?.trim();
    final status = statusFilter == 'all' ? null : statusFilter;
    return expeditions.list(
      mode: 'expedition',
      currentStatus: status,
      search: q != null && q.isNotEmpty ? q : null,
      period: periodFilter.isEmpty ? null : periodFilter,
      relayId: selectedRelayId,
    );
  }

  /// Colis pour le wizard Départ — A_EXPEDIER (expédition/stock) + EN_TRANSIT intermédiaire (stock).
  Future<List<KatianExpedition>> queryDepartableParcels() async {
    final results = await Future.wait([
      queryExpeditionParcels(),
      queryStockParcels(),
    ]);
    final byId = <int, KatianExpedition>{};
    for (final list in results) {
      for (final p in list) {
        byId[p.id] = p;
      }
    }
    return byId.values.where((p) => isDepartableParcel(p, user)).toList();
  }

  /// Colis à expédier (A_EXPEDIER) — tableau de bord.
  Future<List<KatianExpedition>> queryToShipParcels() async {
    final all = await queryDepartableParcels();
    return all
        .where((p) => normalizeParcelStatus(p.currentStatus) == 'a_expedier')
        .toList();
  }

  /// Colis en transit intermédiaire à réexpédier — tableau de bord.
  Future<List<KatianExpedition>> queryToReshipParcels() async {
    final all = await queryDepartableParcels();
    return all
        .where((p) => normalizeParcelStatus(p.currentStatus) == 'en_transit')
        .toList();
  }

  /// Stock API — A_EXPEDIER, EN_TRANSIT (current_relay_id), EN_ATTENTE_RETRAIT, etc.
  Future<List<KatianExpedition>> queryStockParcels({
    String statusFilter = 'all',
  }) async {
    var list = await expeditions.stock(
      period: periodFilter.isEmpty ? null : periodFilter,
      relayId: selectedRelayId,
    );
    if (statusFilter != 'all') {
      final want = normalizeParcelStatus(statusFilter);
      list = list
          .where((p) => normalizeParcelStatus(p.currentStatus) == want)
          .toList();
    }
    return list;
  }

  Future<void> loadAllParcelLists() async {
    await Future.wait([
      loadReceptionParcels(),
      loadExpeditionParcels(),
      loadStockParcels(),
    ]);
  }

  Future<bool> applyParcelAction(
    KatianExpedition parcel,
    ParcelActionKind action, {
    String? driverName,
    String? driverPhoneOrId,
  }) async {
    _setLoading(true);
    try {
      await parcelStatus.applyAction(
        parcel,
        action,
        driverName: driverName,
        driverPhoneOrId: driverPhoneOrId,
      );
      await loadAllParcelLists();
      await loadDashboardStats();
      error = null;
      notifyListeners();
      return true;
    } on ParcelStatusException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> applyUiStatus(
    KatianExpedition parcel,
    String uiStatus,
    ExpeditionTab tab,
  ) async {
    _setLoading(true);
    try {
      await parcelStatus.applyUiStatus(parcel, uiStatus, tab);
      await loadAllParcelLists();
      await loadDashboardStats();
      error = null;
      notifyListeners();
      return true;
    } on StatusUpdateException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } on ParcelStatusException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markParcelDelivered(KatianExpedition parcel) async {
    _setLoading(true);
    try {
      await parcelStatus.markDelivered(parcel);
      await loadAllParcelLists();
      await loadDashboardStats();
      error = null;
      notifyListeners();
      return true;
    } on StatusUpdateException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markParcelReturned(KatianExpedition parcel) async {
    _setLoading(true);
    try {
      await parcelStatus.markReturned(parcel);
      await loadAllParcelLists();
      await loadDashboardStats();
      error = null;
      notifyListeners();
      return true;
    } on StatusUpdateException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markParcelLost(KatianExpedition parcel) async {
    _setLoading(true);
    try {
      await parcelStatus.markLost(parcel);
      await loadAllParcelLists();
      await loadDashboardStats();
      error = null;
      notifyListeners();
      return true;
    } on StatusUpdateException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignParcelRelay(KatianExpedition parcel, int relayId) async {
    _setLoading(true);
    try {
      await parcelStatus.assignRelay(parcel, relayId);
      await loadAllParcelLists();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateParcelAmount(
    KatianExpedition parcel,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    try {
      await expeditions.update(parcel.id, data);
      await loadAllParcelLists();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<TraceabilityData?> fetchTraceability(int id) async {
    try {
      return await expeditions.traceability(id);
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return null;
    }
  }

  Future<List<RelayPointOption>> fetchRelayPoints() async {
    try {
      return await expeditions.relayPoints();
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return [];
    }
  }

  Future<void> generateParcelInvoice(KatianExpedition parcel) async {
    try {
      await documents.generateInvoice(parcel, user);
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> generateParcelReceipt(KatianExpedition parcel) async {
    try {
      await documents.generateCashReceipt(parcel, user);
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<bool> receiveParcel(KatianExpedition parcel) =>
      applyParcelAction(parcel, ParcelActionKind.receive);

  Future<bool> expedierParcel(
    int id, {
    required String driverName,
    required String driverPhoneOrId,
  }) async {
    _setLoading(true);
    try {
      final parcel = KatianExpedition(id: id, raw: const {});
      await parcelStatus.applyAction(
        parcel,
        ParcelActionKind.expedier,
        driverName: driverName,
        driverPhoneOrId: driverPhoneOrId,
      );
      await loadAllParcelLists();
      await loadDashboardStats();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNotifications() async {
    if (!await auth.isLoggedIn()) return;
    loadingNotifications = true;
    notifyListeners();
    try {
      final result = await notifications.fetchNotifications();
      notificationItems = result.notifications;
      unreadNotificationCount = result.unreadCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Katian Pro] loadNotifications: $e');
      }
    } finally {
      loadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadNotificationCount() async {
    if (!await auth.isLoggedIn()) return;
    try {
      unreadNotificationCount = await notifications.fetchUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationRead(int notificationId) async {
    try {
      unreadNotificationCount = await notifications.markRead(notificationId);
      notificationItems = notificationItems
          .map(
            (n) => n.id == notificationId ? n.copyWith(isRead: true) : n,
          )
          .toList();
      notifyListeners();
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      unreadNotificationCount = await notifications.markAllRead();
      notificationItems = notificationItems
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      error = _messageFromError(e);
      notifyListeners();
    }
  }

  Future<void> _startNotificationServices() async {
    PushNotificationService.instance.onRefreshNotifications = loadNotifications;
    PushNotificationService.instance.onPushDataReceived = (_) {};
    PushNotificationService.instance.onNotificationOpened = (_) {
      refreshUnreadNotificationCount();
      loadNotifications();
    };
    PushNotificationService.instance.onTokenRefreshed = (token) async {
      try {
        await notifications.registerDevice(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
          deviceName: Platform.operatingSystem,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Katian Pro Push] registerDevice refresh: $e');
        }
      }
    };

    await loadNotifications();
    await _registerPushTokenIfAvailable();
    _startNotificationPolling();
  }

  Future<void> _registerPushTokenIfAvailable() async {
    final push = PushNotificationService.instance;
    if (!push.isReady) return;

    final token = await push.refreshToken();
    if (token == null || token.isEmpty) return;

    try {
      await notifications.registerDevice(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
        deviceName: Platform.operatingSystem,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Katian Pro Push] registerDevice: $e');
      }
    }
  }

  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => refreshUnreadNotificationCount(),
    );
  }

  void _stopNotificationServices() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
  }

  Future<void> _unregisterPushToken() async {
    final token = PushNotificationService.instance.currentToken;
    if (token == null || token.isEmpty) return;
    try {
      await notifications.unregisterDevice(token);
    } catch (_) {}
  }

  void _setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  String formatError(Object e) => _messageFromError(e);

  String _messageFromError(Object e) {
    if (e is DioException) {
      return _api.extractError(e);
    }
    return e.toString();
  }
}
