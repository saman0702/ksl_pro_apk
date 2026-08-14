import '../models/models.dart';

enum ParcelMenuKind {
  tracking,
  viewDetails,
  changeStatus,
  assignRelay,
  markDelivered,
  manageReturn,
  manageDispute,
  printLabel,
  generateInvoice,
  reprintReceipt,
  editAmount,
}

class ParcelMenuItem {
  const ParcelMenuItem({
    required this.kind,
    required this.label,
    this.color,
    this.destructive = false,
  });

  final ParcelMenuKind kind;
  final String label;
  final MenuItemColor? color;
  final bool destructive;
}

enum MenuItemColor { green, orange, red, blue, amber }

/// Menu « ⋮ » — aligné RelayPackages.js ActionDropdown (6464-6583).
List<ParcelMenuItem> parcelMenuItemsFor({
  required KatianExpedition parcel,
  required ExpeditionTab tab,
  bool canAssignRelay = false,
}) {
  final terminal = _isTerminalStatus(parcel);
  final isRedevance = (parcel.raw['type_facture'] ?? '')
      .toString()
      .toLowerCase()
      .trim() ==
      'redevance';

  return [
    const ParcelMenuItem(kind: ParcelMenuKind.tracking, label: 'Suivi'),
    const ParcelMenuItem(kind: ParcelMenuKind.viewDetails, label: 'Voir détails'),
    const ParcelMenuItem(
      kind: ParcelMenuKind.changeStatus,
      label: 'Modifier le statut',
    ),
    if (canAssignRelay)
      const ParcelMenuItem(
        kind: ParcelMenuKind.assignRelay,
        label: 'Assigner à un point relais',
      ),
    if (!terminal)
      const ParcelMenuItem(
        kind: ParcelMenuKind.markDelivered,
        label: 'Marquer comme livré',
        color: MenuItemColor.green,
      ),
    if (!terminal)
      const ParcelMenuItem(
        kind: ParcelMenuKind.manageReturn,
        label: 'Gérer le retour',
        color: MenuItemColor.orange,
      ),
    const ParcelMenuItem(
      kind: ParcelMenuKind.manageDispute,
      label: 'Gérer le litige',
      color: MenuItemColor.red,
      destructive: true,
    ),
    if (tab != ExpeditionTab.reception)
      const ParcelMenuItem(
        kind: ParcelMenuKind.printLabel,
        label: 'Imprimer étiquette',
        color: MenuItemColor.blue,
      ),
    const ParcelMenuItem(
      kind: ParcelMenuKind.generateInvoice,
      label: 'Générer facture',
      color: MenuItemColor.green,
    ),
    if (isRedevance)
      const ParcelMenuItem(
        kind: ParcelMenuKind.editAmount,
        label: 'Modifier le montant',
        color: MenuItemColor.amber,
      ),
    if (tab != ExpeditionTab.reception)
      const ParcelMenuItem(
        kind: ParcelMenuKind.reprintReceipt,
        label: 'Réimprimer le reçu',
        color: MenuItemColor.blue,
      ),
  ];
}

bool _isTerminalStatus(KatianExpedition parcel) {
  final s = (parcel.currentStatus ?? '')
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .trim();
  // Équivalent web parcel.status delivered / returned / lost
  return s == 'retire' ||
      s == 'livre' ||
      s == 'retourne' ||
      s == 'perdue';
}

class StatusChangeOption {
  const StatusChangeOption({required this.uiKey, required this.label});

  final String uiKey;
  final String label;
}

/// Options modal « Modifier le statut » — non-admin (RelayPackages 11432-11464).
List<StatusChangeOption> statusChangeOptionsFor(ExpeditionTab tab) {
  switch (tab) {
    case ExpeditionTab.reception:
      return const [
        StatusChangeOption(uiKey: 'in_transit', label: 'En transit'),
        StatusChangeOption(uiKey: 'received', label: 'Réceptionné'),
        StatusChangeOption(uiKey: 'returned', label: 'Retourné'),
        StatusChangeOption(uiKey: 'cancelled', label: 'Annulé'),
        StatusChangeOption(uiKey: 'lost', label: 'Perdu'),
      ];
    case ExpeditionTab.expedition:
    case ExpeditionTab.stock:
      return const [
        StatusChangeOption(uiKey: 'in_transit', label: 'En transit'),
        StatusChangeOption(uiKey: 'returned', label: 'Retourné'),
        StatusChangeOption(uiKey: 'cancelled', label: 'Annulé'),
        StatusChangeOption(uiKey: 'lost', label: 'Perdu'),
      ];
  }
}

const returnReasonOptions = [
  ('adresse_incorrecte', 'Adresse incorrecte'),
  ('destinataire_absent', 'Destinataire absent'),
  ('refus_destinataire', 'Refus du destinataire'),
  ('colis_endommage', 'Colis endommagé'),
  ('contenu_non_conforme', 'Contenu non conforme'),
  ('delai_depasse', 'Délai de récupération dépassé'),
  ('probleme_paiement', 'Problème de paiement PAL'),
  ('autre', 'Autre raison'),
];
