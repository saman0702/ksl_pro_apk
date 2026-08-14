import '../../models/models.dart';
import '../../utils/parcel_status.dart';

/// Écrans dédiés depuis le tableau de bord — un bouton = un écran.
enum ParcelHubKind {
  toReceive,
  toShip,
  toReship,
  reception,
  expedition,
  inTransit,
  stock,
  history,
}

class ParcelHubConfig {
  const ParcelHubConfig({
    required this.title,
    required this.tab,
    required this.initialStatusFilter,
    this.subtitle,
    this.lockStatusFilter = false,
    this.statusFilters,
    this.emptyMessage = 'Aucun colis',
  });

  final String title;
  final String? subtitle;
  final ExpeditionTab tab;
  final String initialStatusFilter;
  final bool lockStatusFilter;
  final List<StatusFilterOption>? statusFilters;
  final String emptyMessage;

  static ParcelHubConfig forKind(ParcelHubKind kind) {
    switch (kind) {
      case ParcelHubKind.toReceive:
        return const ParcelHubConfig(
          title: 'Colis à réceptionner',
          subtitle:
              'Destinés à votre gare — réception possible uniquement si statut Expédié',
          tab: ExpeditionTab.reception,
          initialStatusFilter: 'all',
          lockStatusFilter: true,
          emptyMessage: 'Aucun colis à réceptionner pour le moment',
        );
      case ParcelHubKind.toShip:
        return const ParcelHubConfig(
          title: 'Colis à expédier',
          subtitle: 'Colis prêts au départ depuis votre gare',
          tab: ExpeditionTab.expedition,
          initialStatusFilter: 'A_EXPEDIER',
          lockStatusFilter: true,
          emptyMessage: 'Aucun colis à expédier pour le moment',
        );
      case ParcelHubKind.toReship:
      case ParcelHubKind.inTransit:
        return const ParcelHubConfig(
          title: 'En transit à réexpédier',
          subtitle:
              'Colis en transit chez vous — gare intermédiaire, à réexpédier',
          tab: ExpeditionTab.stock,
          initialStatusFilter: 'EN_TRANSIT',
          lockStatusFilter: true,
          emptyMessage: 'Aucun colis en transit à réexpédier',
        );
      case ParcelHubKind.reception:
        return const ParcelHubConfig(
          title: 'Réception',
          subtitle: 'Colis en route vers votre agence ou à réceptionner',
          tab: ExpeditionTab.reception,
          initialStatusFilter: 'all',
        );
      case ParcelHubKind.expedition:
        return const ParcelHubConfig(
          title: 'Expédition',
          subtitle: 'Colis à expédier depuis votre point relais',
          tab: ExpeditionTab.expedition,
          initialStatusFilter: 'A_EXPEDIER',
        );
      case ParcelHubKind.stock:
        return const ParcelHubConfig(
          title: 'Colis en stock',
          subtitle:
              'Inventaire complet : à expédier, en transit, en attente de retrait, retrouvés…',
          tab: ExpeditionTab.stock,
          initialStatusFilter: 'all',
        );
      case ParcelHubKind.history:
        return const ParcelHubConfig(
          title: 'Historique des expéditions',
          subtitle: 'Toutes vos expéditions',
          tab: ExpeditionTab.expedition,
          initialStatusFilter: 'all',
        );
    }
  }

  List<StatusFilterOption> filters() =>
      statusFilters ?? statusFiltersForTab(tab);
}
