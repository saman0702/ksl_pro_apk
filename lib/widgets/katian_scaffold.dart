import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';
import 'katian_avatar.dart';
import 'notifications_bottom_sheet.dart';

class KatianScaffold extends StatelessWidget {
  const KatianScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showHeader = true,
    this.floatingActionButton,
  });

  /// Coins supérieurs du panneau blanc (comme la maquette).
  static const bodyTopRadius = 28.0;
  static const bodyTopOverlap = 22.0;

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showHeader;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().user;
    final ext = context.katian;

    return Scaffold(
      backgroundColor: ext.surface,
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Container(
              color: KatianColors.red,
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 12,
                8,
                28,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KatianAvatar(
                    size: 40,
                    imageUrl: user?.displayLogo,
                    initial: user?.avatarInitial ?? 'K',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GreetingLine(
                          firstName: user?.firstName ?? user?.fullName ?? '',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayRelayName ?? title,
                          style: TextStyle(
                            color: KatianColors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        onPressed: () => showNotificationsBottomSheet(context),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: KatianColors.white,
                        ),
                      ),
                      if (context.watch<AppProvider>().unreadNotificationCount > 0)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: KatianColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: KatianColors.red, width: 1.5),
                            ),
                            child: Text(
                              context.watch<AppProvider>().unreadNotificationCount > 99
                                  ? '99+'
                                  : '${context.watch<AppProvider>().unreadNotificationCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: KatianColors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: showHeader ? -bodyTopOverlap : 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ext.surface,
                      borderRadius: showHeader
                          ? const BorderRadius.vertical(
                              top: Radius.circular(bodyTopRadius),
                            )
                          : BorderRadius.zero,
                    ),
                    child: ClipRRect(
                      borderRadius: showHeader
                          ? const BorderRadius.vertical(
                              top: Radius.circular(bodyTopRadius),
                            )
                          : BorderRadius.zero,
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingLine extends StatelessWidget {
  const _GreetingLine({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final name = firstName.trim();
    if (name.isEmpty) {
      return const Text(
        'Bonjour',
        style: TextStyle(
          color: KatianColors.white,
          fontWeight: FontWeight.w500,
          fontSize: 17,
        ),
      );
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: KatianColors.white,
          fontSize: 17,
          height: 1.25,
        ),
        children: [
          const TextSpan(
            text: 'Bonjour ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class KatianLogoMark extends StatelessWidget {
  const KatianLogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/katian-logo-transparent.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
