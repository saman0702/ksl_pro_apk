/// Formats de colis — aligné RelayCompagnieDeposits.js packageFormats.
class PackageFormat {
  const PackageFormat({
    required this.id,
    required this.name,
    required this.category,
    this.isCustom = false,
    this.weightMin = 0,
    this.weightMax = 0,
    this.weightFixed = 0,
    this.volumeFixed = 0,
    this.dimensions = const PackageDimensions(),
    this.examples = '',
    this.description = '',
  });

  final String id;
  final String name;
  final String category;
  final bool isCustom;
  final double weightMin;
  final double weightMax;
  final double weightFixed;
  final double volumeFixed;
  final PackageDimensions dimensions;
  final String examples;
  final String description;
}

class PackageDimensions {
  const PackageDimensions({
    this.length = 0,
    this.width = 0,
    this.height = 0,
  });

  final double length;
  final double width;
  final double height;
}

class PackageFormats {
  PackageFormats._();

  static const carTab = 'car';
  static const camionTab = 'camion';

  static const List<PackageFormat> all = [
    PackageFormat(
      id: 'xs',
      name: '🏍️ XS (Moto)',
      category: 'moto',
      weightMax: 2,
      weightFixed: 1,
      volumeFixed: 5000,
      dimensions: PackageDimensions(length: 20, width: 20, height: 25),
      examples: 'Documents, accessoires, petits appareils',
      description: 'Volume: ≤10 000 cm³ - Poids: 0-2 kg',
    ),
    PackageFormat(
      id: 's',
      name: '🏍️ S (Moto)',
      category: 'moto',
      weightMin: 2,
      weightMax: 5,
      weightFixed: 3.5,
      volumeFixed: 10000,
      dimensions: PackageDimensions(length: 40, width: 25, height: 20),
      examples: 'Vêtements, petite électronique',
      description: 'Volume: ≤20 000 cm³ - Poids: 2-5 kg',
    ),
    PackageFormat(
      id: 'sm',
      name: '🏍️ SM (Moto)',
      category: 'moto',
      weightMin: 5,
      weightMax: 10,
      weightFixed: 7.5,
      volumeFixed: 13500,
      dimensions: PackageDimensions(length: 30, width: 30, height: 30),
      examples: 'Livres, chaussures, articles de sport',
      description: 'Volume: ≤27 000 cm³ - Poids: 5-10 kg',
    ),
    PackageFormat(
      id: 'm',
      name: '🏍️ M (Moto)',
      category: 'moto',
      weightMin: 10,
      weightMax: 30,
      weightFixed: 20,
      volumeFixed: 40000,
      dimensions: PackageDimensions(length: 40, width: 40, height: 50),
      examples: 'Électroménager, équipements',
      description: 'Volume: ≤80 000 cm³ - Poids: 10-30 kg',
    ),
    PackageFormat(
      id: 'moto_hors_gabarit',
      name: '🏍️ Taille hors Gabarit (Moto)',
      category: 'moto',
      isCustom: true,
      examples: 'Dimensions personnalisées',
      description: 'Saisie manuelle requise',
    ),
    PackageFormat(
      id: 'l',
      name: '🚐 L (Petit fourgon ou Voiture)',
      category: 'fourgon',
      weightMin: 30,
      weightMax: 100,
      weightFixed: 65,
      volumeFixed: 150000,
      dimensions: PackageDimensions(length: 60, width: 50, height: 100),
      examples: 'Meubles plats, équipements moyens',
      description: 'Volume: ≤300 000 cm³ - Poids: 30-100 kg',
    ),
    PackageFormat(
      id: 'xl',
      name: '🚐 XL (Petit Fourgon)',
      category: 'fourgon',
      weightMin: 100,
      weightMax: 300,
      weightFixed: 200,
      volumeFixed: 400000,
      dimensions: PackageDimensions(length: 100, width: 80, height: 100),
      examples: 'Meubles, électroménager, équipements',
      description: 'Volume: ≤800 000 cm³ - Poids: 100-300 kg',
    ),
    PackageFormat(
      id: '2xl',
      name: '🚐 2XL (Petit Fourgon)',
      category: 'fourgon',
      weightMin: 300,
      weightMax: 500,
      weightFixed: 400,
      volumeFixed: 480000,
      dimensions: PackageDimensions(length: 120, width: 80, height: 100),
      examples: 'Meubles volumineux, équipements lourds',
      description: 'Volume: ≤960 000 cm³ - Poids: 300-500 kg',
    ),
    PackageFormat(
      id: '3xl',
      name: '🚐 3XL (Moyen Fourgon)',
      category: 'fourgon',
      weightMin: 500,
      weightMax: 1000,
      weightFixed: 750,
      volumeFixed: 960000,
      dimensions: PackageDimensions(length: 120, width: 80, height: 200),
      examples: 'Gros meubles, équipements industriels',
      description: 'Volume: ≤1 920 000 cm³ - Poids: 500-1000 kg',
    ),
    PackageFormat(
      id: 'grand_fourgon',
      name: '🚐 Grand fourgon',
      category: 'fourgon',
      weightMin: 1000,
      weightMax: 1500,
      weightFixed: 1250,
      volumeFixed: 1440000,
      dimensions: PackageDimensions(length: 240, width: 120, height: 100),
      examples: 'Très gros meubles, équipements volumineux',
      description: 'Volume: ≤2 880 000 cm³ - Poids: 1000-1500 kg',
    ),
    PackageFormat(
      id: 'fourgon_hors_gabarit',
      name: '🚐 Taille hors Gabarit (Fourgon)',
      category: 'fourgon',
      isCustom: true,
      examples: 'Dimensions personnalisées',
      description: 'Saisie manuelle requise',
    ),
    PackageFormat(
      id: 'petit_camion',
      name: '🚛 Petit Camion',
      category: 'camion',
      weightMin: 1500,
      weightMax: 3000,
      weightFixed: 2250,
      volumeFixed: 2400000,
      dimensions: PackageDimensions(length: 300, width: 160, height: 100),
      examples: 'Équipements industriels, marchandises lourdes',
      description: 'Volume: ≤4 800 000 cm³ - Poids: 1500-3000 kg',
    ),
    PackageFormat(
      id: 'camion_leger',
      name: '🚛 Camion léger',
      category: 'camion',
      weightMin: 3000,
      weightMax: 5000,
      weightFixed: 4000,
      volumeFixed: 4800000,
      dimensions: PackageDimensions(length: 300, width: 200, height: 160),
      examples: 'Machines, équipements lourds',
      description: 'Volume: ≤9 600 000 cm³ - Poids: 3000-5000 kg',
    ),
    PackageFormat(
      id: 'camion_moyen',
      name: '🚛 Camion moyen',
      category: 'camion',
      weightMin: 5000,
      weightMax: 10000,
      weightFixed: 7500,
      volumeFixed: 15000000,
      dimensions: PackageDimensions(length: 600, width: 250, height: 200),
      examples: 'Machines industrielles, équipements très lourds',
      description: 'Volume: ≤30 000 000 cm³ - Poids: 5000-10000 kg',
    ),
    PackageFormat(
      id: 'camion_grand',
      name: '🚛 Camion grand',
      category: 'camion',
      weightMin: 10000,
      weightMax: 20000,
      weightFixed: 15000,
      volumeFixed: 30000000,
      dimensions: PackageDimensions(length: 1200, width: 250, height: 200),
      examples: 'Machines très lourdes, équipements industriels',
      description: 'Volume: ≤60 000 000 cm³ - Poids: 10000-20000 kg',
    ),
    PackageFormat(
      id: 'camion_remorque',
      name: '🚛 Camion REMORQUE',
      category: 'camion',
      weightMin: 20000,
      weightMax: 40000,
      weightFixed: 30000,
      volumeFixed: 45000000,
      dimensions: PackageDimensions(length: 1360, width: 250, height: 260),
      examples: 'Machines très lourdes, équipements industriels',
      description: 'Volume: ≤90 000 000 cm³ - Poids: 20000-40000 kg',
    ),
    PackageFormat(
      id: 'camion_hors_gabarit',
      name: '🚛 Taille hors Gabarit (Camion)',
      category: 'camion',
      isCustom: true,
      examples: 'Dimensions personnalisées',
      description: 'Saisie manuelle requise',
    ),
  ];

  static PackageFormat? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }

  static String getSimplifiedFormatName(PackageFormat? format, String selectedCategory) {
    if (format == null) return '';
    if (selectedCategory == carTab) {
      final match = RegExp(
        r'(XS|SM|S|M|L|XL|2XL|3XL|Grand fourgon|Taille hors Gabarit)',
      ).firstMatch(format.name);
      if (match != null) {
        final size = match.group(1)!;
        if (size == 'Taille hors Gabarit') return '📦 Colis hors Gabarit';
        return '📦 Colis $size';
      }
    }
    return format.name;
  }

  static List<PackageFormat> formatsForTab(String selectedCategory) {
    if (selectedCategory == carTab) {
      final motoFourgon = all
          .where((f) => f.category == 'moto' || f.category == 'fourgon')
          .toList();
      final seenHorsGabarit = <String>{};
      final filtered = <PackageFormat>[];
      for (final f in motoFourgon) {
        if (f.name.contains('Taille hors Gabarit')) {
          if (seenHorsGabarit.contains('hors_gabarit')) continue;
          seenHorsGabarit.add('hors_gabarit');
        }
        filtered.add(f);
      }
      filtered.sort((a, b) {
        if (a.name.contains('Taille hors Gabarit')) return 1;
        if (b.name.contains('Taille hors Gabarit')) return -1;
        return 0;
      });
      return filtered;
    }
    return all.where((f) => f.category == selectedCategory).toList();
  }

  static String effectiveCategory(PackageFormat format, String selectedCategory) {
    if (selectedCategory == carTab) return carTab;
    return format.category;
  }

  static double vehicleWeightLimit(String selectedCategory) {
    if (selectedCategory == carTab) {
      final motoMax = all
          .where((f) => f.category == 'moto')
          .map((f) => f.weightMax)
          .fold(0.0, (a, b) => a > b ? a : b);
      final fourgonMax = all
          .where((f) => f.category == 'fourgon')
          .map((f) => f.weightMax)
          .fold(0.0, (a, b) => a > b ? a : b);
      return motoMax > fourgonMax ? motoMax : fourgonMax;
    }
    return all
        .where((f) => f.category == selectedCategory)
        .map((f) => f.weightMax)
        .fold(0.0, (a, b) => a > b ? a : b);
  }
}

/// Catégories article — aligné RelayCompagnieDeposits.js.
class ItemCategories {
  ItemCategories._();

  static const defaultCategory = 'Autres / Divers';

  static const List<String> all = [
    'Documents / Imprimés / Enveloppe',
    'Textile & Accessoires',
    'Électronique & Objets connectés',
    'Produits alimentaires',
    'Produits de beauté & Hygiène',
    'Articles pour bébé & Enfants',
    'Pièces détachées & Outils',
    'Maison, Déco & Électroménagers',
    'Santé & Produits médicaux',
    'Fournitures & Accessoires de bureau',
    'Autres / Divers',
  ];

  static String iconFor(String category) {
    switch (category) {
      case 'Documents / Imprimés / Enveloppe':
        return '📄';
      case 'Textile & Accessoires':
        return '👕';
      case 'Électronique & Objets connectés':
        return '💻';
      case 'Produits alimentaires':
        return '🍎';
      case 'Produits de beauté & Hygiène':
        return '💄';
      case 'Articles pour bébé & Enfants':
        return '👶';
      case 'Pièces détachées & Outils':
        return '🔧';
      case 'Maison, Déco & Électroménagers':
        return '🏠';
      case 'Santé & Produits médicaux':
        return '💊';
      case 'Fournitures & Accessoires de bureau':
        return '📎';
      default:
        return '📦';
    }
  }
}

/// Descriptions conditionnement colis (interurbaine / sous-régionale).
class ColisDescriptions {
  ColisDescriptions._();

  static const autres = 'Autres';
  static const predefined = [
    'Carton',
    'Bidon',
    'Sac',
    'Sachet',
    'Enveloppe',
    'Bôrô',
    'Valise',
    'Barrique',
    'Balle',
    autres,
  ];

  static bool isPredefined(String value) =>
      predefined.contains(value) && value != autres;
}
