import '../data/package_formats.dart';
import '../models/expedition_draft.dart';

class DepositItemLogic {
  /// Retourne un message d'erreur ou null si OK — aligné addItem() web.
  static String? validateAddItem({
    required CurrentDraftItem current,
    required List<DraftPickupItem> existingItems,
  }) {
    if (current.name.trim().isEmpty || current.packageFormat.isEmpty) {
      return 'Veuillez remplir au minimum le nom et le format de colis de l\'article';
    }

    final selectedFormat = PackageFormats.byId(current.packageFormat);
    if (selectedFormat == null) {
      return 'Format de colis invalide';
    }

    if (selectedFormat.isCustom) {
      if (current.weight <= 0 ||
          current.length <= 0 ||
          current.width <= 0 ||
          current.height <= 0) {
        return 'Pour les formats hors gabarit, veuillez saisir le poids et toutes les dimensions de l\'article';
      }
    }

    if (existingItems.isNotEmpty) {
      final existingFormat = PackageFormats.byId(existingItems.first.packageFormat);
      if (existingFormat != null) {
        final existingCat =
            PackageFormats.effectiveCategory(existingFormat, current.selectedCategory);
        final newCat =
            PackageFormats.effectiveCategory(selectedFormat, current.selectedCategory);
        if (existingCat != newCat) {
          final names = {
            'moto': 'Moto',
            'fourgon': 'Fourgon',
            'camion': 'Camion',
            PackageFormats.carTab: 'Car',
          };
          return 'Formats de véhicules incompatibles ! L\'article existant utilise un format ${names[existingCat]} et vous essayez d\'ajouter un format ${names[newCat]}.';
        }
      }
    }

    final vehicleLimit = PackageFormats.vehicleWeightLimit(current.selectedCategory);
    final currentTotal = existingItems.fold<double>(0, (sum, item) {
      final fmt = PackageFormats.byId(item.packageFormat);
      if (fmt == null) return sum;
      final itemCat = PackageFormats.effectiveCategory(fmt, current.selectedCategory);
      final curCat = PackageFormats.effectiveCategory(selectedFormat, current.selectedCategory);
      if (itemCat != curCat) return sum;
      return sum + item.weight * item.quantity;
    });

    final newWeight = current.weight * current.quantity;
    if (currentTotal + newWeight > vehicleLimit) {
      return 'Le poids total (${(currentTotal + newWeight).toStringAsFixed(1)} kg) dépasse la limite autorisée pour ${_vehicleLabel(current.selectedCategory)} ($vehicleLimit kg).';
    }

    final globalTotal = existingItems.fold<double>(
          0,
          (sum, item) => sum + item.weight * item.quantity,
        ) +
        newWeight;
    if (globalTotal > 40000) {
      return 'Le poids total ne peut pas dépasser 40000 kg.';
    }

    return null;
  }

  static String _vehicleLabel(String cat) {
    switch (cat) {
      case 'moto':
        return 'Moto';
      case 'fourgon':
        return 'Fourgon';
      case PackageFormats.camionTab:
        return 'Camion';
      case PackageFormats.carTab:
        return 'Car';
      default:
        return cat;
    }
  }

  static DraftPickupItem buildPickupItem(CurrentDraftItem current) {
    final format = PackageFormats.byId(current.packageFormat)!;
    final weightForCalculation =
        format.isCustom ? current.weight : format.weightFixed;
    final volumeForCalculation = format.isCustom
        ? current.length * current.width * current.height
        : format.volumeFixed;

    return DraftPickupItem(
      name: current.name.trim(),
      category: current.category,
      packageFormat: current.packageFormat,
      selectedCategory: current.selectedCategory,
      weight: current.weight,
      length: current.length,
      width: current.width,
      height: current.height,
      quantity: current.quantity,
      weightForCalculation: weightForCalculation,
      volumeForCalculation: volumeForCalculation,
    );
  }

  static void applyPackageFormat(CurrentDraftItem current, String formatId) {
    final format = PackageFormats.byId(formatId);
    if (format == null) return;
    current.packageFormat = formatId;
    if (!format.isCustom) {
      current.weight = format.weightFixed;
      current.length = format.dimensions.length;
      current.width = format.dimensions.width;
      current.height = format.dimensions.height;
    } else {
      current.weight = 0;
      current.length = 0;
      current.width = 0;
      current.height = 0;
    }
  }
}

/// Formulaire article en cours de saisie — aligné currentItem web.
class CurrentDraftItem {
  CurrentDraftItem({
    this.name = '',
    this.category = ItemCategories.defaultCategory,
    this.packageFormat = '',
    this.selectedCategory = PackageFormats.carTab,
    this.showFormats = false,
    this.weight = 0,
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.quantity = 1,
  });

  String name;
  String category;
  String packageFormat;
  String selectedCategory;
  bool showFormats;
  double weight;
  double length;
  double width;
  double height;
  int quantity;

  CurrentDraftItem copy() => CurrentDraftItem(
        name: name,
        category: category,
        packageFormat: packageFormat,
        selectedCategory: selectedCategory,
        showFormats: showFormats,
        weight: weight,
        length: length,
        width: width,
        height: height,
        quantity: quantity,
      );

  void resetKeepCategory() {
    name = '';
    category = ItemCategories.defaultCategory;
    packageFormat = '';
    showFormats = false;
    weight = 0;
    length = 0;
    width = 0;
    height = 0;
    quantity = 1;
  }
}
