import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

final languageProvider = StateProvider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode == 'hi' ? 'hi' : 'en';
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('hi', 'IN')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final box = await Hive.openBox('settings');
      final lang = box.get('language', defaultValue: 'hi') as String;
      state = Locale(lang, 'IN');
    } catch (e) {
      debugPrint('Error loading locale from Hive: $e');
    }
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode, 'IN');
    try {
      final box = await Hive.openBox('settings');
      await box.put('language', languageCode);
    } catch (e) {
      debugPrint('Error saving locale to Hive: $e');
    }
  }

  void toggle() {
    if (state.languageCode == 'hi') {
      setLocale('en');
    } else {
      setLocale('hi');
    }
  }
}
