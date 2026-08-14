class BordereauColisLine {
  BordereauColisLine({
    required this.id,
    required this.expeditionId,
    this.expeditionNumber,
    this.orderNumber,
    this.recipientName,
    this.destination,
    this.currentStatus,
    this.returnStatus,
    this.isReturn = false,
    this.canReceive = false,
  });

  final int id;
  final int expeditionId;
  final String? expeditionNumber;
  final String? orderNumber;
  final String? recipientName;
  final String? destination;
  final String? currentStatus;
  final String? returnStatus;
  final bool isReturn;
  final bool canReceive;

  factory BordereauColisLine.fromJson(Map<String, dynamic> json) {
    return BordereauColisLine(
      id: json['id'] as int? ?? 0,
      expeditionId: json['expedition_id'] as int? ?? 0,
      expeditionNumber: json['expedition_number'] as String?,
      orderNumber: json['order_number'] as String?,
      recipientName: json['recipient_name'] as String?,
      destination: json['destination'] as String?,
      currentStatus: json['current_status'] as String?,
      returnStatus: json['return_status'] as String?,
      isReturn: json['is_return'] == true,
      canReceive: json['can_receive'] == true,
    );
  }
}

class BordereauExpedition {
  BordereauExpedition({
    required this.id,
    required this.number,
    this.departureDate,
    this.departureTime,
    this.carNumber,
    this.driverName,
    this.driverPhone,
    this.comment,
    this.status,
    this.parcelCount = 0,
    this.eligibleCount,
    this.departureRelayName,
    this.createdAt,
    this.colis = const [],
  });

  final int id;
  final String number;
  final String? departureDate;
  final String? departureTime;
  final String? carNumber;
  final String? driverName;
  final String? driverPhone;
  final String? comment;
  final String? status;
  final int parcelCount;
  final int? eligibleCount;
  final String? departureRelayName;
  final String? createdAt;
  final List<BordereauColisLine> colis;

  String get departureLabel {
    final d = departureDate;
    final t = departureTime;
    if (d == null) return '—';
    if (t != null && t.isNotEmpty) return '$d $t';
    return d;
  }

  factory BordereauExpedition.fromJson(Map<String, dynamic> json) {
    final colisRaw = json['colis'];
    return BordereauExpedition(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String? ?? '',
      departureDate: json['departure_date'] as String?,
      departureTime: json['departure_time'] as String?,
      carNumber: json['car_number'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      comment: json['comment'] as String?,
      status: json['status'] as String?,
      parcelCount: json['parcel_count'] as int? ?? 0,
      eligibleCount: json['eligible_count'] as int?,
      departureRelayName: json['departure_relay_name'] as String?,
      createdAt: json['created_at'] as String?,
      colis: colisRaw is List
          ? colisRaw
              .map((e) => BordereauColisLine.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }
}

class BordereauReceiveResult {
  BordereauReceiveResult({
    required this.bordereauId,
    required this.bordereauNumber,
    required this.receivedCount,
    required this.errorCount,
    this.received = const [],
  });

  final int bordereauId;
  final String bordereauNumber;
  final int receivedCount;
  final int errorCount;
  final List<Map<String, dynamic>> received;

  factory BordereauReceiveResult.fromJson(Map<String, dynamic> json) {
    final recv = json['received'];
    return BordereauReceiveResult(
      bordereauId: json['bordereau_id'] as int? ?? 0,
      bordereauNumber: json['bordereau_number'] as String? ?? '',
      receivedCount: json['received_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      received: recv is List
          ? recv.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : const [],
    );
  }
}
