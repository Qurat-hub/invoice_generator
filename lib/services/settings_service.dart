import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Persists [AppSettings] to device storage via SharedPreferences.
class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  static const _key = 'app_settings';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  /// Increments and returns the next invoice number, persisting the
  /// updated counter so numbers stay unique across app sessions.
  Future<String> generateNextInvoiceNumber(AppSettings settings) async {
    final next = settings.lastInvoiceNumber + 1;
    final updated = settings.copyWith(lastInvoiceNumber: next);
    await saveSettings(updated);
    return '${settings.invoicePrefix}${next.toString().padLeft(3, '0')}';
  }
}
