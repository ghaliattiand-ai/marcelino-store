import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  bool _isInitialized = false;

  Dio get dio {
    if (!_isInitialized) {
      throw StateError('ApiService not initialized. Call init() first.');
    }
    return _dio;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    // لو Dio اتعمل قبل كده، نحدّث التوكن بس (منغير ما نعمل Dio جديد)
    if (_isInitialized) {
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      } else {
        _dio.options.headers.remove('Authorization');
      }
      return;
    }

    await _createDio();
    _isInitialized = true;
  }

  /// يعيد بناء Dio بالعنوان الحالي — يستخدم بعد تغيير الـ API URL من الإعدادات
  Future<void> reconfigure() async {
    await _createDio();
    _isInitialized = true;
  }

  Future<void> _createDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));

    // Interceptor لتحديث التوكن أو تسجيل الخروج
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // إضافة التوكن لو موجود
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // مسح التوكن عند انتهاء الصلاحية
          prefs.remove(AppConstants.tokenKey);
        }
        handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    _dio.options.headers.remove('Authorization');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // ===== Generic HTTP Methods =====
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // تحليل رسالة الخطأ من السيرفر
  ApiException _handleError(DioException e) {
    String message = 'حدث خطأ غير متوقع';

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'انتهى وقت الاتصال بالخادم';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'لا يوجد اتصال بالإنترنت أو السيرفر غير متاح';
    } else if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is String) {
        try {
          final json = jsonDecode(data);
          message = json['message'] ?? message;
        } catch (_) {
          message = data;
        }
      } else if (data is Map) {
        message = data['message'] ?? message;
      }
    } else if (e.response?.statusCode != null) {
      switch (e.response!.statusCode) {
        case 400:
          message = 'طلب غير صالح';
          break;
        case 401:
          message = 'غير مصرح، برجاء تسجيل الدخول';
          break;
        case 403:
          message = 'محظور الوصول';
          break;
        case 404:
          message = 'غير موجود';
          break;
        case 500:
          message = 'خطأ داخلي في الخادم';
          break;
      }
    }

    return ApiException(message: message, statusCode: e.response?.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
