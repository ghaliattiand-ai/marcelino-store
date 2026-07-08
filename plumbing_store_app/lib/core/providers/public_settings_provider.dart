import 'package:flutter/material.dart';
import '../models/public_settings.dart';
import '../network/api_service.dart';

/// يدير إعدادات المتجر العامة (المتاحة للعامة) — نجلبها مرة واحدة عند
/// الحاجة (مثلاً صفحة الـ checkout) ونعيد استخدامها. لو فشل الاتصال نرجّع
/// قيمًا افتراضية من [PublicSettings.fallback].
class PublicSettingsProvider extends ChangeNotifier {
  PublicSettings _settings = PublicSettings.fallback;
  bool _loaded = false;
  bool _loading = false;
  String? _error;

  PublicSettings get settings => _settings;
  bool get loaded => _loaded;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService().init();
      final res = await ApiService().get('/settings/public');
      _settings = PublicSettings.fromJson(res.data as Map<String, dynamic>);
      _loaded = true;
    } catch (e) {
      _error = e.toString();
      // نبقى على القيم الافتراضية
      _settings = PublicSettings.fallback;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
