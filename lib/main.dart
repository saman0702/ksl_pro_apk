import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/firebase_init.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'providers/app_provider.dart';
import 'widgets/bootstrap_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseEarly();
  if (kDebugMode) {
    debugPrint('[Katian Pro] API base: ${AppConfig.baseUrl}');
  }
  await initializeDateFormatting('fr_FR');

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const KatianProApp(),
    ),
  );
}

class KatianProApp extends StatelessWidget {
  const KatianProApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp(
      title: 'Katian Expédition Transporteur',
      debugShowCheckedModeBanner: false,
      theme: KatianTheme.light,
      darkTheme: KatianTheme.dark,
      themeMode: themeMode,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const BootstrapGate(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          isDark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                ),
        );
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
