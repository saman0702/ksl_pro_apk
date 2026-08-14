import 'package:flutter/material.dart';

import '../models/expedition.dart';
import '../utils/parcel_status_colors.dart';

/// Badge ou texte coloré selon le statut colis.
class ParcelStatusBadge extends StatelessWidget {
  const ParcelStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.badge = true,
  });

  factory ParcelStatusBadge.fromParcel(
    KatianExpedition parcel, {
    bool compact = false,
    bool badge = true,
  }) {
    final color = parcelStatusColor(parcel);
    return ParcelStatusBadge(
      label: parcel.statusLabel,
      color: color,
      compact: compact,
      badge: badge,
    );
  }

  factory ParcelStatusBadge.fromLabel(
    String label, {
    bool compact = false,
    bool badge = true,
  }) {
    final color = parcelStatusColorFromLabel(label);
    return ParcelStatusBadge(
      label: label,
      color: color,
      compact: compact,
      badge: badge,
    );
  }

  final String label;
  final Color color;
  final bool compact;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 11 : 12,
    );

    if (!badge) {
      return Text(label, style: style);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: parcelStatusBackgroundColor(color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: style),
    );
  }
}
