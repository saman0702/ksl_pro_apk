import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/parcel_status_colors.dart';
import 'parcel_shipping_photo.dart';

/// Vignette colis : photo si disponible, sinon icône par défaut.
class ParcelThumbnail extends StatelessWidget {
  const ParcelThumbnail({
    super.key,
    required this.parcel,
    this.width = 62,
    this.height = 72,
    this.borderRadius = 10,
  });

  final KatianExpedition parcel;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final statusColor = parcelStatusColor(parcel);
    final bgColor = parcelStatusBackgroundColor(statusColor);
    final fallback = Icon(
      Icons.inventory_2_outlined,
      color: statusColor,
      size: height * 0.42,
    );

    if (!parcel.hasShippingPhoto) {
      return _iconBox(bgColor, fallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: ParcelPhotoImage(
          photoRef: parcel.shippingPhotoUrl,
          fit: BoxFit.cover,
          width: width,
          height: height,
          loadingSize: height * 0.35,
          fallback: _iconBox(bgColor, fallback),
        ),
      ),
    );
  }

  Widget _iconBox(Color bgColor, Widget child) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
