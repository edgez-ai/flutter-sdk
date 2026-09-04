import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages currently shipped with the example application.
enum AppLanguage {
  english('en', 'English'),
  chinese('zh', '中文'),
  french('fr', 'Français'),
  spanish('es', 'Español'),
  german('de', 'Deutsch'),
  japanese('ja', '日本語');

  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
        (language) => language.code == code,
        orElse: () => AppLanguage.english,
      );
}

class AppLocaleStore {
  static const _localeKey = 'edgez_app_locale';

  Future<AppLanguage> load({Locale? deviceLocale}) async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_localeKey);
    if (savedCode != null) return AppLanguage.fromCode(savedCode);
    return AppLanguage.fromCode(
      deviceLocale?.languageCode ??
          PlatformDispatcher.instance.locale.languageCode,
    );
  }

  Future<void> save(AppLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, language.code);
  }
}
