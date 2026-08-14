class RelayPointOption {
  const RelayPointOption({
    required this.id,
    required this.name,
    this.address,
    this.city,
  });

  final int id;
  final String name;
  final String? address;
  final String? city;

  factory RelayPointOption.fromJson(Map<String, dynamic> json) {
    return RelayPointOption(
      id: json['id'] as int? ?? 0,
      name: (json['nom'] as String? ?? json['name'] as String? ?? 'Point relais')
          .trim(),
      address: json['adresse'] as String? ?? json['address'] as String?,
      city: json['ville'] as String? ?? json['city'] as String?,
    );
  }
}

class TraceabilityEvent {
  const TraceabilityEvent({
    this.id,
    this.eventType,
    this.eventTypeDisplay,
    this.description,
    this.createdAt,
    this.relayName,
    this.fromRelayName,
    this.toRelayName,
    this.bordereauNumber,
    this.driverName,
    this.recipientName,
    this.actorType,
  });

  final int? id;
  final String? eventType;
  final String? eventTypeDisplay;
  final String? description;
  final String? createdAt;
  final String? relayName;
  final String? fromRelayName;
  final String? toRelayName;
  final String? bordereauNumber;
  final String? driverName;
  final String? recipientName;
  final String? actorType;

  factory TraceabilityEvent.fromJson(Map<String, dynamic> json) {
    String? relayName(dynamic relay) {
      if (relay is Map) {
        final name = relay['nom'] as String? ?? relay['name'] as String?;
        final city = relay['ville'] as String? ?? relay['city'] as String?;
        if (name == null) return null;
        if (city != null && city.isNotEmpty) return '$name, $city';
        return name;
      }
      return null;
    }

    return TraceabilityEvent(
      id: json['id'] as int?,
      eventType: json['event_type'] as String? ?? json['type'] as String?,
      eventTypeDisplay: json['event_type_display'] as String?,
      description: json['description'] as String? ?? json['objet'] as String?,
      createdAt: json['created_at'] as String?,
      relayName: relayName(json['relay'] ?? json['relay_id']),
      fromRelayName: relayName(json['from_relay'] ?? json['from_relay_id']),
      toRelayName: relayName(json['to_relay'] ?? json['to_relay_id']),
      bordereauNumber: json['bordereau_number'] as String?,
      driverName: json['driver_name'] as String?,
      recipientName: json['recipient_name'] as String?,
      actorType: json['actor_type'] as String?,
    );
  }
}

class TraceabilityData {
  const TraceabilityData({
    this.expeditionNumber,
    this.currentStatus,
    this.createdByRelayName,
    this.currentRelayName,
    this.destinationRelayName,
    this.events = const [],
  });

  final String? expeditionNumber;
  final String? currentStatus;
  final String? createdByRelayName;
  final String? currentRelayName;
  final String? destinationRelayName;
  final List<TraceabilityEvent> events;

  static String? _relayName(dynamic v) {
    if (v is Map) {
      final name = v['nom'] as String? ?? v['name'] as String?;
      final city = v['ville'] as String? ?? v['city'] as String?;
      if (name == null) return null;
      if (city != null && city.isNotEmpty) return '$name, $city';
      return name;
    }
    return null;
  }

  factory TraceabilityData.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'];
    return TraceabilityData(
      expeditionNumber: json['expedition_number'] as String?,
      currentStatus: json['current_status'] as String?,
      createdByRelayName: _relayName(json['created_by_relay']),
      currentRelayName: _relayName(json['current_relay']),
      destinationRelayName: _relayName(json['destination_relay']),
      events: eventsRaw is List
          ? eventsRaw
              .whereType<Map>()
              .map((e) => TraceabilityEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
