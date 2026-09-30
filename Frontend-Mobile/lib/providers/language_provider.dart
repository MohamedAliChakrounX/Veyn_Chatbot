import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'veyn_language';

  static const List<Locale> supportedLocales = [
    Locale('fr'),
    Locale('ar'),
    Locale('en'),
  ];

  Locale _locale = const Locale('fr');

  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';
  String get languageCode => _locale.languageCode;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey);
      if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    if (!supportedLocales.any((l) => l.languageCode == newLocale.languageCode)) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
}
