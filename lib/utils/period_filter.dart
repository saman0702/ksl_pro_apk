/// Filtres de période — alignés RelayPackages.js / expedition_filters.py
class PeriodFilterOption {
  const PeriodFilterOption({required this.id, required this.label});

  /// `''` = toutes les périodes
  final String id;
  final String label;
}

const kPeriodFilters = [
  PeriodFilterOption(id: '', label: 'Toutes'),
  PeriodFilterOption(id: 'today', label: "Aujourd'hui"),
  PeriodFilterOption(id: 'week', label: 'Cette semaine'),
  PeriodFilterOption(id: 'month', label: 'Ce mois'),
  PeriodFilterOption(id: 'quarter', label: 'Ce trimestre'),
  PeriodFilterOption(id: 'year', label: 'Cette année'),
];

String periodFilterLabel(String id) {
  for (final o in kPeriodFilters) {
    if (o.id == id) return o.label;
  }
  return 'Toutes';
}

Map<String, dynamic> periodQueryParams(String period) {
  if (period.isEmpty) return const {};
  return {'period': period};
}
