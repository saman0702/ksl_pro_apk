import 'package:flutter/material.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'parcel_status_badge.dart';
import 'parcel_thumbnail.dart';

class ParcelCard extends StatelessWidget {
  const ParcelCard({
    super.key,
    required this.parcel,
    required this.onTap,
    this.onMenuTap,
    this.trailing,
    this.showShipToYou = false,
  });

  final KatianExpedition parcel;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;
  final Widget? trailing;
  final bool showShipToYou;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ParcelThumbnail(parcel: parcel, width: 62, height: 72, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.displayNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ext.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (showShipToYou)
                      const Row(
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: KatianColors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'À expédier vers vous',
                            style: TextStyle(
                              color: KatianColors.orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      ParcelStatusBadge.fromParcel(parcel, badge: false),
                    if (parcel.recipientName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dest. ${parcel.recipientName}',
                        style: TextStyle(color: ext.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (parcel.destinationRelayName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        parcel.destinationRelayName!,
                        style: TextStyle(color: ext.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onMenuTap != null)
                IconButton(
                  icon: Icon(Icons.more_horiz, color: ext.textSecondary),
                  onPressed: onMenuTap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                )
              else if (trailing != null)
                trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
