import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app language and locale settings
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'skaletek_kyc_language';

  Locale _currentLocale = const Locale('en');

  /// Available languages in the app
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('fr'), // French
    Locale('es'), // Spanish
  ];

  /// Mapping of locale codes to display names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
  };

  Locale get currentLocale => _currentLocale;

  /// Initialize language service with device locale or saved preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      // Use saved language preference
      _currentLocale = Locale(savedLanguage);
    } else {
      // Auto-detect device locale, default to English if not supported
      final deviceLocale = PlatformDispatcher.instance.locale;
      final deviceLanguageCode = deviceLocale.languageCode;

      if (supportedLocales.any(
        (locale) => locale.languageCode == deviceLanguageCode,
      )) {
        _currentLocale = Locale(deviceLanguageCode);
      } else {
        _currentLocale = const Locale('en'); // Default to English
      }

      // Save the detected/default language
      await _saveLanguagePreference(_currentLocale.languageCode);
    }

    notifyListeners();
  }

  /// Change the app language
  Future<void> changeLanguage(String languageCode) async {
    if (supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      _currentLocale = Locale(languageCode);
      await _saveLanguagePreference(languageCode);
      notifyListeners();
    }
  }

  /// Save language preference to local storage
  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  /// Get display name for a language code
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  /// Check if a locale is supported
  bool isLocaleSupported(Locale locale) {
    return supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }
}
