class DashboardStats {
  const DashboardStats({
    this.packagesInStock = 0,
    this.toShip = 0,
    this.toReceive = 0,
    this.inTransit = 0,
  });

  final int packagesInStock;
  final int toShip;
  final int toReceive;
  final int inTransit;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      packagesInStock: _int(json['en_stock']),
      toShip: _int(json['a_expedier']),
      toReceive: _int(json['a_receptionner']),
      inTransit: _int(json['en_transit']),
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse('$v') ?? 0;
  }
}
