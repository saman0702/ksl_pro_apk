class TpCarOption {
  TpCarOption({
    required this.id,
    required this.internalNumber,
    required this.registration,
    this.brand,
    this.model,
    this.serviceType,
    this.displayLabel,
    this.departureRelayName,
  });

  final int id;
  final String internalNumber;
  final String registration;
  final String? brand;
  final String? model;
  final String? serviceType;
  final String? displayLabel;
  final String? departureRelayName;

  factory TpCarOption.fromJson(Map<String, dynamic> json) {
    return TpCarOption(
      id: json['id'] as int,
      internalNumber: (json['internal_number'] ?? '').toString(),
      registration: (json['registration'] ?? '').toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      serviceType: json['service_type']?.toString(),
      displayLabel: json['display_label']?.toString(),
      departureRelayName: json['departure_relay_name']?.toString(),
    );
  }

  String get pickerLabel {
    if (displayLabel != null && displayLabel!.isNotEmpty) return displayLabel!;
    return '$internalNumber — $registration';
  }
}

class TpConvoyeurOption {
  TpConvoyeurOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.fullName,
    this.assignedCarId,
    this.assignedCarNumber,
    this.assignedCarRegistration,
    this.assignedCarLabel,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? fullName;
  final int? assignedCarId;
  final String? assignedCarNumber;
  final String? assignedCarRegistration;
  final String? assignedCarLabel;

  factory TpConvoyeurOption.fromJson(Map<String, dynamic> json) {
    return TpConvoyeurOption(
      id: json['id'] as int,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      fullName: json['full_name']?.toString(),
      assignedCarId: json['assigned_car_id'] as int?,
      assignedCarNumber: json['assigned_car_number']?.toString(),
      assignedCarRegistration: json['assigned_car_registration']?.toString(),
      assignedCarLabel: json['assigned_car_label']?.toString(),
    );
  }

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return '$firstName $lastName'.trim();
  }
}
