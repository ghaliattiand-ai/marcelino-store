import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plumbing_store_app/core/network/api_service.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyName = 'auth_name';
  static const _keyPhone = 'auth_phone';
  static const _keyEmail = 'auth_email';

  String? _name;
  String? _phone;
  String? _email;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? get name => _name;
  String? get phone => _phone;
  String? get email => _email;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // تحميل الجلسة من التخزين المحلي
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _name = prefs.getString(_keyName);
    _phone = prefs.getString(_keyPhone);
    _email = prefs.getString(_keyEmail);

    // لو في توكن، نتأكد إنه لسه صالح بطلب /auth/me
    final hasToken = prefs.getString(AppConstants.tokenKey) != null;
    if (_isLoggedIn && hasToken) {
      try {
        await ApiService().init();
        final res = await ApiService().get('/auth/me');
        final user = res.data['user'];
        _name = user['name'];
        _phone = user['phone'];
        _email = user['email'];
        await _persist();
      } catch (e) {
        // التوكن انتهى - نسجل خروج
        await _clearSession();
      }
    }
    notifyListeners();
  }

  // تسجيل الدخول عن طريق الـ API
  Future<bool> login(String phoneOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res = await ApiService().post('/auth/login', data: {
        'email': phoneOrEmail.trim(),
        'password': password,
      });

      final user = res.data['user'] as Map<String, dynamic>;
      final token = res.data['token'] as String;

      // حفظ التوكن
      await ApiService().setToken(token);

      _name = user['name'] as String?;
      _phone = user['phone'] as String?;
      _email = user['email'] as String?;
      _isLoggedIn = true;
      await _persist();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل الاتصال بالخادم. تأكد إن السيرفر شغال.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // إنشاء حساب جديد عن طريق الـ API
  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res = await ApiService().post('/auth/register', data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
      });

      final user = res.data['user'] as Map<String, dynamic>;
      final token = res.data['token'] as String;

      await ApiService().setToken(token);

      _name = user['name'] as String?;
      _phone = user['phone'] as String?;
      _email = user['email'] as String?;
      _isLoggedIn = true;
      await _persist();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل الاتصال بالخادم. تأكد إن السيرفر شغال.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    try {
      await ApiService().init();
      await ApiService().post('/auth/logout');
    } catch (_) {
      // حتى لو فشل الطلب، نسجل خروج محلياً
    }
    await ApiService().clearToken();
    await _clearSession();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyName, _name ?? '');
    await prefs.setString(_keyPhone, _phone ?? '');
    await prefs.setString(_keyEmail, _email ?? '');
  }

  Future<void> _clearSession() async {
    _isLoggedIn = false;
    _name = null;
    _phone = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyEmail);
  }
}
