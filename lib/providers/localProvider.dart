import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _secureStorage = FlutterSecureStorage();
const _localeStorageKey = 'lang_code';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _initLocale();
  }

  Future<void> _initLocale() async {
    final savedLangCode = await _secureStorage.read(key: _localeStorageKey);

    if (savedLangCode == null) {
      // First run: store and use default locale 'en'
      await _secureStorage.write(key: _localeStorageKey, value: 'en');
      state = const Locale('en');
    } else {
      // Load saved locale
      state = Locale(savedLangCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _secureStorage.write(key: _localeStorageKey, value: locale.languageCode);
  }

  Future<void> clearLocale() async {
    state = const Locale('en');
    await _secureStorage.delete(key: _localeStorageKey);
  }
}

final localeNotifierProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
