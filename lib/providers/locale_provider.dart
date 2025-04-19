// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English

  Locale get locale => _locale;

  // Key for saving preference
  static const String _localePrefKey = 'language_code';

  LocaleProvider() {
    _loadLocale(); // Load preference when provider is created
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_localePrefKey);

    if (languageCode != null && ['en', 'am'].contains(languageCode)) {
      _locale = Locale(languageCode);
    } else {
      _locale = const Locale('en'); // Default if nothing saved or invalid
    }
    notifyListeners(); // Notify widgets after loading
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!['en', 'am'].contains(newLocale.languageCode))
      return; // Only allow supported locales

    if (_locale != newLocale) {
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localePrefKey, newLocale.languageCode);
      notifyListeners(); // Notify all listening widgets to rebuild
      debugPrint("Locale changed to: ${newLocale.languageCode} and saved.");
    }
  }

  void toggleLocale() {
    final newLocale =
        (_locale.languageCode == 'en')
            ? const Locale('am')
            : const Locale('en');
    setLocale(newLocale);
  }
}
