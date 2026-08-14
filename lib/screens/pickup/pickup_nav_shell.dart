import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../navigation/flow_navigation.dart';
import '../../providers/app_provider.dart';
import 'pickup_hub_screen.dart';
import 'pickup_search_screen.dart';
import 'pickup_wizard_screen.dart';

/// Routes retrait — navigateur imbriqué pour garder la barre du [MainShell].
class PickupRoutes {
  static const hub = '/';
  static const search = '/search';
  static const wizard = '/wizard';
}

class PickupNavShell extends StatefulWidget {
  const PickupNavShell({super.key});

  @override
  State<PickupNavShell> createState() => _PickupNavShellState();
}

class _PickupNavShellState extends State<PickupNavShell> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  PickupFlowRequest? _handledRequest;

  void _consumePickupFlow(AppProvider app) {
    final request = app.pickupFlowRequest;
    if (request == null || identical(request, _handledRequest)) return;

    _handledRequest = request;
    app.clearPickupFlowRequest();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      if (request.openDetail && request.parcel != null) {
        nav.pushNamed(
          PickupRoutes.wizard,
          arguments: {
            'step': PickupWizardStep.detail,
            'parcel': request.parcel,
          },
        );
        return;
      }

      nav.pushNamed(
        PickupRoutes.wizard,
        arguments: request.parcel == null
            ? PickupWizardStep.list
            : {
                'step': PickupWizardStep.detail,
                'parcel': request.parcel,
              },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    _consumePickupFlow(app);

    return Navigator(
      key: _navigatorKey,
      initialRoute: PickupRoutes.hub,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case PickupRoutes.search:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const PickupSearchScreen(embedded: true),
            );
          case PickupRoutes.wizard:
            final args = settings.arguments;
            PickupWizardStep step = PickupWizardStep.list;
            KatianExpedition? parcel;
            if (args is PickupWizardStep) {
              step = args;
            } else if (args is Map) {
              step = args['step'] as PickupWizardStep? ?? step;
              parcel = args['parcel'] as KatianExpedition?;
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => PickupWizardScreen(
                embedded: true,
                initialStep: step,
                initialParcel: parcel,
              ),
            );
          case PickupRoutes.hub:
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const PickupHubBody(),
            );
        }
      },
    );
  }
}
