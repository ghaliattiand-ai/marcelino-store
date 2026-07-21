import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:plumbing_store_app/core/network/api_service.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyName    = 'auth_name';
  static const _keyPhone   = 'auth_phone';
  static const _keyEmail   = 'auth_email';

  String? _name;
  String? _phone;
  String? _email;
  bool    _isLoggedIn    = false;
  bool    _isLoading     = false;
  String? _errorMessage;

  // ── OTP (SMS Misr) ──
  bool    _codeSent   = false;      // true بعد نجاح /send-otp
  String? _verifyToken;             // التوكن المؤقت بعد /verify-otp (يثبت ملكية الرقم)
  String? _verifiedPhoneForRegister; // الرقم المتحقَّق منه في session التسجيل

  // ── تسجيل الدخول بجوجل ──
  // لازم تحط هنا الـ Web Client ID من Google Cloud Console (نفس القيمة اللي في
  // GOOGLE_CLIENT_ID في الباك اند) عشان الباك اند يقدر يتحقق من idToken
  final GoogleSignIn _googleSignIn = GoogleSignIn(
serverClientId: '840074700643-ial7qptr4ir8qa7uvic45p877i7n0c3k.apps.googleusercontent.com',    scopes: ['email'],
  );

  // Getters
  String? get name         => _name;
  String? get phone        => _phone;
  String? get email        => _email;
  bool    get isLoggedIn   => _isLoggedIn;
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;
  bool    get codeSent     => _codeSent;
  String? get verifiedPhoneForRegister => _verifiedPhoneForRegister;

  // ─────────────────────────────────────────
  // تحميل الجلسة من التخزين المحلي
  // ─────────────────────────────────────────
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _name  = prefs.getString(_keyName);
    _phone = prefs.getString(_keyPhone);
    _email = prefs.getString(_keyEmail);

    final hasToken = prefs.getString(AppConstants.tokenKey) != null;
    if (_isLoggedIn && hasToken) {
      try {
        await ApiService().init();
        final res  = await ApiService().get('/auth/me');
        final user = res.data['user'];
        _name  = user['name'];
        _phone = user['phone'];
        _email = user['email'];
        await _persist();
      } catch (e) {
        await _clearSession();
      }
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // OTP ─ خطوة 1: إرسال كود التحقق إلى رقم الهاتف
  // phoneNumber مثال: '+201234567890'
  // ─────────────────────────────────────────
  Future<void> sendOtp(String phoneNumber) async {
    _isLoading    = true;
    _errorMessage = null;
    _codeSent     = false;
    notifyListeners();

    try {
      await ApiService().init();
      await ApiService().post('/auth/send-otp', data: {'phone': phoneNumber});
      _codeSent = true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'فشل الاتصال بالخادم. تأكد إن السيرفر شغال.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // OTP ─ خطوة 2: التحقق من كود SMS لإنشاء حساب (بدون تسجيل دخول)
  // لو صح، يخزّن verifyToken + الرقم المتحقَّق منه في session التسجيل
  // ─────────────────────────────────────────
  Future<bool> verifyOtpForRegister(String smsCode) async {
    if (!(_phoneForOtp ?? '').isNotEmpty) {
      _errorMessage = 'لازم تبعت الكود الأول';
      notifyListeners();
      return false;
    }

    _isLoading    = true;
    _errorMessage  = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res = await ApiService().post('/auth/verify-otp', data: {
        'phone': _phoneForOtp,
        'code':  smsCode,
      });
      _verifyToken = res.data['verifyToken'] as String?;
      _verifiedPhoneForRegister = res.data['verifiedPhone'] as String?;
      _codeSent = false;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'فشل الاتصال بالخادم';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// الرقم اللي بنعمل له OTP دلوقتي (يُضبط قبل sendOtp)
  String? _phoneForOtp;
  set phoneForOtp(String? v) => _phoneForOtp = v;

  /// إلغاء session التسجيل (لو العميل رجع أو قفل الصفحة)
  void cancelRegistration() {
    _verifiedPhoneForRegister = null;
    _verifyToken              = null;
    _codeSent                  = false;
    _errorMessage              = null;
    _phoneForOtp               = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // تسجيل الدخول (برقم/إيميل + كلمة مرور)
  // ─────────────────────────────────────────
  Future<bool> login(String phoneOrEmail, String password) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res   = await ApiService().post('/auth/login', data: {
        'email':    phoneOrEmail.trim(),
        'password': password,
      });
      final user  = res.data['user']  as Map<String, dynamic>;
      final token = res.data['token'] as String;

      await ApiService().setToken(token);

      _name       = user['name']  as String?;
      _phone      = user['phone'] as String?;
      _email      = user['email'] as String?;
      _isLoggedIn = true;
      await _persist();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading    = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل الاتصال بالخادم. تأكد إن السيرفر شغال.';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────
  // تسجيل الدخول بجوجل
  // بيرجع false من غير errorMessage لو المستخدم لغى العملية بنفسه
  // ─────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // المستخدم لغى تسجيل الدخول من نافذة جوجل
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('لم يتم الحصول على idToken من جوجل');
      }

      await ApiService().init();
      final res   = await ApiService().post('/auth/google', data: {'idToken': idToken});
      final user  = res.data['user']  as Map<String, dynamic>;
      final token = res.data['token'] as String;

      await ApiService().setToken(token);

      _name       = user['name']  as String?;
      _phone      = user['phone'] as String?;
      _email      = user['email'] as String?;
      _isLoggedIn = true;
      await _persist();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading    = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل تسجيل الدخول بجوجل';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────
  // تسجيل الدخول بفيسبوك
  // بيرجع false من غير errorMessage لو المستخدم لغى العملية بنفسه
  // ─────────────────────────────────────────
  Future<bool> loginWithFacebook() async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'فشل تسجيل الدخول بفيسبوك');
      }

      final accessToken = result.accessToken!.tokenString;

      await ApiService().init();
      final res   = await ApiService().post('/auth/facebook', data: {'accessToken': accessToken});
      final user  = res.data['user']  as Map<String, dynamic>;
      final token = res.data['token'] as String;

      await ApiService().setToken(token);

      _name       = user['name']  as String?;
      _phone      = user['phone'] as String?;
      _email      = user['email'] as String?;
      _isLoggedIn = true;
      await _persist();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading    = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل تسجيل الدخول بفيسبوك';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────
  // إنشاء حساب — يتطلب verifyToken (من خطوة OTP)
  // ─────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (_verifyToken == null) {
      _errorMessage = 'لازم تتأكد من رقمك عبر كود التحقق الأول';
      notifyListeners();
      return false;
    }

    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res   = await ApiService().post('/auth/register', data: {
        'name':         name.trim(),
        'email':        email.trim().toLowerCase(),
        'phone':        phone.trim(),
        'password':     password,
        'verifyToken':  _verifyToken,
      });
      final user  = res.data['user']  as Map<String, dynamic>;
      final token = res.data['token'] as String;

      await ApiService().setToken(token);

      _name       = user['name']  as String?;
      _phone      = user['phone'] as String?;
      _email      = user['email'] as String?;
      _isLoggedIn = true;

      // مسح بيانات OTP بعد نجاح التسجيل
      _verifyToken = null;
      _verifiedPhoneForRegister = null;
      _codeSent = false;
      _phoneForOtp = null;

      await _persist();

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading    = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل الاتصال بالخادم. تأكد إن السيرفر شغال.';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService().init();
      await ApiService().post('/auth/logout');
    } catch (_) {}
    // تسجيل الخروج من جوجل/فيسبوك كمان لو المستخدم داخل بيهم
    try { await _googleSignIn.signOut(); } catch (_) {}
    try { await FacebookAuth.instance.logOut(); } catch (_) {}
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
    await prefs.setString(_keyName,  _name  ?? '');
    await prefs.setString(_keyPhone, _phone ?? '');
    await prefs.setString(_keyEmail, _email ?? '');
  }

  Future<void> _clearSession() async {
    _isLoggedIn = false;
    _name = null; _phone = null; _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyEmail);
  }
}