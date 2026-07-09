import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';

/// خدمة تتبع استخدام التطبيق — ترسل أحداثاً بسيطة للـ backend (بدون أي خدمات طرف ثالث).
/// كل الأحداث fire-and-forget: أي خطأ ما يوقفش التطبيق.
class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  static const _sessionIdKey = 'app_session_id';

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  String? _cachedSessionId;
  bool _sessionInitialized = false;

  /// معرف جلسة فريد ثابت لكل عملية تشغيل (نخزنه في SharedPreferences).
  /// لو اتسِتعاد التطبيق، الجلسة تبقى نفسها (لحد ما المستخدم يمسح بيانات التطبيق).
  Future<String> get sessionId async {
    if (_sessionInitialized && _cachedSessionId != null) {
      return _cachedSessionId!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      var sid = prefs.getString(_sessionIdKey);
      if (sid == null || sid.length < 8) {
        sid = 'sess_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}_${Platform.isAndroid ? 'andr' : 'other'}';
        await prefs.setString(_sessionIdKey, sid);
      }
      _cachedSessionId = sid;
      _sessionInitialized = true;
      return sid;
    } catch (_) {
      // fallback لأي خطأ في القراءة/الكتابة
      final sid = 'sess_${DateTime.now().millisecondsSinceEpoch}_fallback';
      _cachedSessionId = sid;
      _sessionInitialized = true;
      return sid;
    }
  }

  /// تحديث عنوان الـ baseUrl لو اتغير من الإعدادات
  Future<void> reconfigure() async {
    _dio.options.baseUrl = AppConstants.baseUrl;
  }

  /// نقرأ الـ auth token (لو موجود) عشان نربط الحدث بالمستخدم
  Future<String?> _readToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    } catch (_) {
      return null;
    }
  }

  /// يرسل حدث تتبع — fire-and-forget, ما يرمي أي استثناء للمستدعي
  Future<void> _sendEvent({required String type, String? productId}) async {
    try {
      final sid = await sessionId;
      final token = await _readToken();
      final headers = <String, dynamic>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      await _dio.post(
        '/tracking/event',
        data: jsonEncode({
          'type': type,
          'sessionId': sid,
          if (productId != null) 'productId': productId,
        }),
        options: Options(headers: headers),
      );
    } catch (_) {
      // ما نعملش أي حاجة — التتبع مفيش ضرورة
    }
  }

  /// تتبع فتح التطبيق — يستدعى مرة عند الإقلاع + عند كل hot restart
  Future<void> trackAppOpen() => _sendEvent(type: 'app_open');

  /// تتبع مشاهدة منتج — يستدعى من ProductDetailsPage.initState
  Future<void> trackProductView(String productId) =>
      _sendEvent(type: 'product_view', productId: productId);
}
