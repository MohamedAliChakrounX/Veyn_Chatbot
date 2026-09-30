import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/history_provider.dart';
import 'providers/language_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/chat_screen.dart';
import 'theme/colors.dart';
import 'theme/text_styles.dart';

import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();

  // Auto-détection de l'URL backend au démarrage (sans bloquer l'UI)
  final api = ApiService();
  api.autoDetectWorkingUrl().then((url) {
    if (url != null) {
      debugPrint('[Main] Backend actif détecté: $url');
    } else {
      debugPrint('[Main] ⚠️ Aucun backend accessible. URLs testées: ${ApiService.candidateUrls}');
    }
  });

  // Style de la barre de statut système
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: VeynColors.surfaceSunken,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const VeynApp());
}

class VeynApp extends StatelessWidget {
  const VeynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Veyn Transport',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            supportedLocales: LanguageProvider.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: VeynTheme.getTheme(isArabic: languageProvider.isRtl),
            home: const ChatScreen(),
          );
        },
      ),
    );
  }
}

