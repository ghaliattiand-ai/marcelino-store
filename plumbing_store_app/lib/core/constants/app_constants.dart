import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ثابتات التطبيق.
///
/// عنوان الـ API قابل للتعديل من شاشة الإعدادات — نحفظه في SharedPreferences
/// ونعيد تهيئة Dio عند تغييره. يدعم `http` و `https` و IPs المحلية للتجربة
/// على جهاز حقيقي بدونإعادة بناء التطبيق.
class AppConstants {
  AppConstants._();

  static const String appName = 'MARCELINO';

  /// عنوان الـ API للإنتاج — يُحقن عبر `--dart-define=API_BASE_URL=...`
  /// عند بناء الـ release. لو اتحدد، يفضل على كل المنصات (ويب/موبايل/ديسكتوب).
  /// لو فاضي (dev)، نرجّع للقيمة الافتراضية المناسبة للمنصة.
  static const String _prodBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // قيمة افتراضية مخصصة للمحاكي الرسمي (Android Emulator → localhost	host)
 static const String _defaultBaseUrl = 'https://marcelino-api.onrender.com/api';

  // مفاتيح SharedPreferences
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String baseUrlKey = 'api_base_url';

  /// قيمة مؤقتة للعنوان الحالي — تتحدث عبر [setBaseUrl]
  static String _baseUrl = _defaultBaseUrl;
  static bool _loaded = false;

  /// يجلب العنوان الحالي للـ API (يتحمّل أول مرة من SharedPreferences)
  static String get baseUrl {
    return _baseUrl;
  }

  /// يحمل العنوان المحفوظ من SharedPreferences — يستدعى مرة واحدة عند إقلاع التطبيق
  static Future<void> loadBaseUrl() async {
    if (_loaded) return;
    // الأولوية: (1) عنوان الإنتاج المحقون عبر --dart-define، (2) قيمة محفوظة من الإعدادات،
    // (3) القيمة الافتراضية المناسبة للمنصة الحالية
    _baseUrl = _prodBaseUrl.isNotEmpty ? _prodBaseUrl : detectBestBaseUrl();
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(baseUrlKey);
      if (stored != null && stored.trim().isNotEmpty) {
        _baseUrl = stored.trim();
      }
    } catch (_) {}
    _loaded = true;
  }

  /// يحدّث العنوان ويحفظه في SharedPreferences — يعيد التطبيق لاستخدامه بعد إعادة التهيئة
  static Future<void> setBaseUrl(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return;
    _baseUrl = clean;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(baseUrlKey, clean);
    } catch (_) {}
  }

  /// يعيد العنوان للافتراضي
  static Future<void> resetBaseUrl() async {
    _baseUrl = _defaultBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(baseUrlKey);
    } catch (_) {}
  }

  /// العناوين المقترحة في شاشة الإعدادات
  static const String defaultBaseUrl = _defaultBaseUrl;
  static List<String> get suggestedBaseUrls => [
    // عنوان الإنتاج أولًا لو حقنّاه عبر --dart-define
    if (_prodBaseUrl.isNotEmpty) _prodBaseUrl,
    'http://10.0.2.2:5000/api',        // Android Emulator
    'http://localhost:5000/api',        // Web / Desktop
    'http://127.0.0.1:5000/api',        // localhost بديل
  ];

  /// كشف المنصة لاختيار العنوان الأنسب تلقائياً
  static String detectBestBaseUrl() {
    // الأولوية القصوى: عنوان الإنتاج المحقون عبر --dart-define
    if (_prodBaseUrl.isNotEmpty) return _prodBaseUrl;
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  /// يرجّع أصل الـ API (origin) بدون `/api` — لاستخدامه في إكمال روابط الصور النسبية
  /// مثل `/uploads/products/x.jpg` → `<origin>/uploads/products/x.jpg`.
  /// مثلاً لو baseUrl = `https://api.example.com/api` يرجع `https://api.example.com`.
  static String get apiOrigin {
    final b = baseUrl;
    // ننزع trailing slashes
    String s = b.replaceAll(RegExp(r'/+$'), '');
    // لو ينتهي بـ /api ننزعها
    if (s.endsWith('/api')) {
      s = s.substring(0, s.length - 4);
    }
    return s;
  }
}
