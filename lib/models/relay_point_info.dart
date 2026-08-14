class RelayPointInfo {
  const RelayPointInfo({
    required this.id,
    this.name,
    this.city,
    this.village,
    this.country,
    this.address,
    this.businessNumber,
    this.available,
    this.commissionRateRecep,
    this.commissionRateExp,
    this.commissionRatePal,
    this.commission,
  });

  final int id;
  final String? name;
  final String? city;
  final String? village;
  final String? country;
  final String? address;
  final String? businessNumber;
  final bool? available;
  final double? commissionRateRecep;
  final double? commissionRateExp;
  final double? commissionRatePal;
  final double? commission;

  String get locationLine {
    final parts = <String>[
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (village != null && village!.trim().isNotEmpty) village!.trim(),
      if (country != null && country!.trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(' · ');
  }

  factory RelayPointInfo.fromJson(Map<String, dynamic> json) {
    double? rate(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    return RelayPointInfo(
      id: json['id'] as int? ?? 0,
      name: json['nom'] as String? ?? json['name'] as String?,
      city: json['ville'] as String? ?? json['city'] as String?,
      village: json['vilage'] as String? ?? json['village'] as String?,
      country: json['pays'] as String? ?? json['country'] as String?,
      address: json['adresse'] as String? ?? json['address'] as String?,
      businessNumber: json['numero_entreprise'] as String?,
      available: json['disponible'] as bool?,
      commissionRateRecep: rate(json['tauxcommission_recep'] ?? json['tauxcommissionRecep']),
      commissionRateExp: rate(json['tauxcommission_exp'] ?? json['tauxcommissionExp']),
      commissionRatePal: rate(json['tauxcommission_pal'] ?? json['tauxcommissionPal']),
      commission: rate(json['commission']),
    );
  }
}
