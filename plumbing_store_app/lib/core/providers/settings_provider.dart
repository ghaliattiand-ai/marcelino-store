import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../network/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _language = 'ar';
  String _apiBaseUrl = AppConstants.defaultBaseUrl;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;
  bool get isArabic => _language == 'ar';
  String get apiBaseUrl => _apiBaseUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _language = prefs.getString('language') ?? 'ar';
    // نجلب العنوان من ثابت AppConstants الذي تم تحميله في main()
    _apiBaseUrl = AppConstants.baseUrl;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  /// يحدّث عنوان الـ API، يحفظه، ويعيد تهيئة Dio فوراً. يُرجِع true عند النجاح.
  Future<bool> setApiBaseUrl(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return false;

    try {
      await AppConstants.setBaseUrl(clean);
      _apiBaseUrl = clean;
      // إعادة بناء Dio بالعنوان الجديد
      await ApiService().reconfigure();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// يعيد عنوان الـ API للافتراضي
  Future<void> resetApiBaseUrl() async {
    await AppConstants.resetBaseUrl();
    await ApiService().reconfigure();
    _apiBaseUrl = AppConstants.defaultBaseUrl;
    notifyListeners();
  }
}
