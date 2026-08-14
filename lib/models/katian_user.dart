import 'relay_point_info.dart';

/// Normalise les rôles portail (admin_agent ≡ agent_admin).
String normalizeUserRole(String? role) {
  final r = (role ?? '').toLowerCase().trim();
  if (r == 'admin_agent') return 'agent_admin';
  return r;
}

class KatianUser {
  KatianUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.role,
    this.businessType,
    this.address,
    this.profilePicture,
    this.logo,
    this.companyName,
    this.relayPoint,
    this.relayIds,
    this.gerant,
    this.permissions = const [],
    this.isCredit = false,
    this.convoyeurId,
    this.convoyeurStatus,
    this.licenseNumber,
    this.licenseCategories = const [],
    this.licenseExpiry,
    this.assignedCar,
    this.mustChangePassword = false,
  });

  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? role;
  final String? businessType;
  final String? address;
  final String? profilePicture;
  final String? logo;
  final String? companyName;
  final RelayPointInfo? relayPoint;
  final dynamic relayIds;
  final Map<String, dynamic>? gerant;
  final List<String> permissions;
  final bool isCredit;
  final int? convoyeurId;
  final String? convoyeurStatus;
  final String? licenseNumber;
  final List<String> licenseCategories;
  final String? licenseExpiry;
  final Map<String, dynamic>? assignedCar;
  final bool mustChangePassword;

  String get fullName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? email : name;
  }

  String get avatarInitial {
    if (firstName != null && firstName!.trim().isNotEmpty) {
      return firstName!.trim()[0].toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'K';
  }

  /// Nom affiché dans le header — aligné Layout.js web.
  String get displayRelayName {
    final roleLower = normalizeUserRole(role);
    if (roleLower == 'convoyeur') {
      final company = companyName?.trim();
      if (company != null && company.isNotEmpty) return company;
      return 'Convoyeur';
    }
    if (roleLower == 'relay_point' || roleLower == 'agent_admin') {
      final company = companyName?.trim();
      if (company != null && company.isNotEmpty) return company;
    }
    final rpName = relayPoint?.name?.trim();
    if (rpName != null && rpName.isNotEmpty) return rpName;
    final company = companyName?.trim();
    if (company != null && company.isNotEmpty) return company;
    return 'Agence';
  }

  @Deprecated('Use displayRelayName')
  String get displayAgency => displayRelayName;

  /// Logo gérant / point relais (comme dynamicLogo côté web).
  String? get displayLogo {
    if (logo != null && logo!.trim().isNotEmpty) return logo;
    if (profilePicture != null && profilePicture!.trim().isNotEmpty) {
      return profilePicture;
    }
    final gerantLogo = gerant?['profile_picture'] ?? gerant?['logo'];
    if (gerantLogo is String && gerantLogo.trim().isNotEmpty) {
      return gerantLogo;
    }
    return null;
  }

  /// Photo de profil affichée (convoyeur = photo chauffeur, staff = logo agence).
  String? get displayAvatar {
    if (isConvoyeur) {
      if (profilePicture != null && profilePicture!.trim().isNotEmpty) {
        return profilePicture;
      }
      return null;
    }
    return displayLogo;
  }

  bool get isGerantLike {
    final r = normalizeUserRole(role);
    return r == 'relay_point' || r == 'agent_admin';
  }

  bool get isAgent {
    return normalizeUserRole(role) == 'agent';
  }

  bool get isConvoyeur {
    return normalizeUserRole(role) == 'convoyeur';
  }

  String? get assignedCarLabel {
    final car = assignedCar;
    if (car == null) return null;
    return (car['label'] ?? car['internal_number'] ?? car['registration'])?.toString();
  }

  String get licenseCategoriesLabel {
    if (licenseCategories.isEmpty) return '—';
    return licenseCategories.join(', ');
  }

  String? get gerantName {
    final g = gerant;
    if (g == null) return null;
    final name = '${g['first_name'] ?? ''} ${g['last_name'] ?? ''}'.trim();
    return name.isEmpty ? null : name;
  }

  String? get gerantPhone => gerant?['phone']?.toString();

  String? get gerantEmail => gerant?['email']?.toString();

  /// Assignation relais — admin plateforme, gérant relais ou chef d'agence.
  bool get canAssignRelay {
    final r = normalizeUserRole(role);
    return r == 'admin' || r == 'relay_point' || r == 'agent_admin';
  }

  String get roleLabel {
    switch (normalizeUserRole(role)) {
      case 'relay_point':
      case 'agent_admin':
        return 'Chef d\'agence';
      case 'agent':
        return 'Agent d\'expédition';
      case 'convoyeur':
        return 'Convoyeur';
      default:
        return role ?? 'Utilisateur';
    }
  }

  factory KatianUser.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    final relayRaw = json['relay_point'];
    RelayPointInfo? relayPoint;
    if (relayRaw is Map<String, dynamic>) {
      relayPoint = RelayPointInfo.fromJson(relayRaw);
    }

    Map<String, dynamic>? gerant;
    final gerantRaw = json['gerant'];
    if (gerantRaw is Map<String, dynamic>) {
      gerant = Map<String, dynamic>.from(gerantRaw);
    }

    Map<String, dynamic>? assignedCar;
    final carRaw = json['assigned_car'];
    if (carRaw is Map<String, dynamic>) {
      assignedCar = Map<String, dynamic>.from(carRaw);
    }

    final licenseRaw = json['license_category'];
    final licenseCategories = licenseRaw is List
        ? licenseRaw.map((e) => e.toString()).toList()
        : licenseRaw is String && licenseRaw.trim().isNotEmpty
            ? [licenseRaw]
            : const <String>[];

    final rawRole = json['role'] as String?;
    return KatianUser(
      id: json['user_id'] as int? ?? json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      role: rawRole == null ? null : normalizeUserRole(rawRole),
      businessType: json['business_type'] as String?,
      address: json['address'] as String?,
      profilePicture: json['profile_picture'] as String?,
      logo: json['logo'] as String?,
      companyName: json['nom_compagnie_ou_entreprise'] as String?,
      relayPoint: relayPoint,
      relayIds: json['relais'] ?? json['pointrelais'],
      gerant: gerant,
      permissions: perms is List
          ? perms.map((e) => e.toString()).toList()
          : const [],
      isCredit: json['is_credit'] == true,
      convoyeurId: json['convoyeur_id'] as int?,
      convoyeurStatus: json['convoyeur_status'] as String?,
      licenseNumber: json['license_number'] as String?,
      licenseCategories: licenseCategories,
      licenseExpiry: json['license_expiry'] as String?,
      assignedCar: assignedCar,
      mustChangePassword: json['must_change_password'] == true,
    );
  }
}
