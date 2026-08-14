import 'package:flutter/material.dart';

import '../core/theme.dart';

class KatianLogo extends StatelessWidget {
  const KatianLogo({
    super.key,
    this.height = 48,
    this.showTagline = false,
    this.transparent = true,
  });

  static const _logoTransparent = 'assets/images/katian-logo-transparent.png';
  static const _logoSolid = 'assets/images/katian-logo.png';

  final double height;
  final bool showTagline;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          transparent ? _logoTransparent : _logoSolid,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        if (showTagline) ...[
          SizedBox(height: height * 0.1),
          Text(
            'Expédition Transporteur',
            style: TextStyle(
              fontSize: height * 0.14,
              color: KatianColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
