import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/katian_theme_extension.dart';
import '../core/theme.dart';
import '../navigation/post_auth_navigation.dart';
import '../providers/app_provider.dart';

/// Affiche l'app Flutter immédiatement (fond gris, sans logo),
/// puis redirige après bootstrap session.
class BootstrapGate extends StatefulWidget {
  const BootstrapGate({super.key});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final app = context.read<AppProvider>();
    await app.bootstrap();
    if (!mounted) return;
    setState(() {
      _destination = destinationAfterBootstrap(app.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;
    if (destination != null) return destination;

    final ext = Theme.of(context).extension<KatianThemeExtension>() ??
        KatianThemeExtension.light;
    return Scaffold(
      backgroundColor: ext.background,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: KatianColors.red,
          ),
        ),
      ),
    );
  }
}
