import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ جديد
import 'package:plumbing_store_app/core/network/api_service.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyName    = 'auth_name';
  static const _keyPhone   = 'auth_phone';
  static const _keyEmail   = 'auth_email';

  // ✅ جديد ─ Firebase OTP
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? _verificationId;
  int?    _resendToken;
  bool    _codeSent = false;

  String? _name;
  String? _phone;
  String? _email;
  bool    _isLoggedIn    = false;
  bool    _isLoading     = false;
  String? _errorMessage;

  // Getters
  String? get name         => _name;
  String? get phone        => _phone;
  String? get email        => _email;
  bool    get isLoggedIn   => _isLoggedIn;
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;
  bool    get codeSent     => _codeSent; // ✅ جديد ─ الـ UI يعرض شاشة OTP لما يبقى true

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
  // ✅ جديد ─ خطوة 1: إرسال OTP
  // phoneNumber مثال: '+201234567890'
  // ─────────────────────────────────────────
  Future<void> sendOtp(String phoneNumber) async {
    _isLoading    = true;
    _errorMessage = null;
    _codeSent     = false;
    notifyListeners();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber:         phoneNumber,
      forceResendingToken: _resendToken,

      // Android فقط ─ التحقق التلقائي
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential);
      },

      // فشل الإرسال
      verificationFailed: (FirebaseAuthException e) {
        _errorMessage = e.message ?? 'فشل إرسال الكود';
        _isLoading    = false;
        notifyListeners();
      },

      // تم إرسال الكود بنجاح
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken    = resendToken;
        _codeSent       = true;
        _isLoading      = false;
        notifyListeners(); // ← الـ UI هيفتح شاشة OTP هنا
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ─────────────────────────────────────────
  // ✅ جديد ─ خطوة 2: التحقق من كود SMS
  // ─────────────────────────────────────────
  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = 'لازم تبعت الكود الأول';
      notifyListeners();
      return false;
    }

    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode:        smsCode,
      );
      return await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'الكود غلط أو انتهت صلاحيته';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ جديد ─ إعادة إرسال
  Future<void> resendOtp(String phoneNumber) async {
    await sendOtp(phoneNumber); // _resendToken محفوظ تلقائياً
  }

  // ─────────────────────────────────────────
  // ✅ جديد ─ التحقق من كود SMS لإنشاء حساب (بدون signIn للـ backend)
  // نتحقق بس إن الكود صحيح ونعمل signIn Firebase مؤقتاً عشان نأكد إن الرقم متحرّك
  // لكن ما نبعتش للـ backend دلّيني. بعدها العميل يكمّل بياناته ونعمل register.
  // ─────────────────────────────────────────
  String? _verifiedPhoneForRegister; // الرقم المتحقَّق منه في session التسجيل

  /// التحقق من كود SMS لإنشاء حساب جديد (بدون تسجيل دخول للـ backend)
  Future<bool> verifyOtpForRegister(String smsCode) async {
    if (_verificationId == null) {
      _errorMessage = 'لازم تبعت الكود الأول';
      notifyListeners();
      return false;
    }

    _isLoading    = true;
    _errorMessage  = null;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode:        smsCode,
      );
      // نعمل signIn مؤقت Firebase عشان نتأكد إن الكود صحيح (وavailibleالرقم verified)
      // بعدها هنعمل signOut Firebase مباشرة عشان ما يفضلش logged-in على Firebase بدون حساب backend
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      // الرقم اللي تم تحقّقه من Firebase
      _verifiedPhoneForRegister = userCred.user?.phoneNumber;
      // نعمل signOut Firebase مؤقت (الحساب على backend لسه ما اتعملش)
      await _firebaseAuth.signOut();

      _isLoading    = false;
      _codeSent     = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'الكود غلط أو انتهت صلاحيته';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  /// الرقم المتحقَّق منه في session التسجيل (null لو لسه ما تحقّقش)
  String? get verifiedPhoneForRegister => _verifiedPhoneForRegister;

  /// إلغاء session التسجيل (لو العميل رجع أو قفل الصفحة)
  void cancelRegistration() {
    _verifiedPhoneForRegister = null;
    _verificationId           = null;
    _resendToken               = null;
    _codeSent                  = false;
    _errorMessage              = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // ✅ جديد ─ Helper: Firebase Sign-in → Backend Token
  // ─────────────────────────────────────────
  Future<bool> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCred = await _firebaseAuth.signInWithCredential(credential);
      final idToken  = await userCred.user!.getIdToken();

      // بعت Firebase Token للـ backend عشان يرجعلنا app token
      await ApiService().init();
      final res   = await ApiService().post('/auth/firebase-login', data: {
        'firebase_token': idToken,
      });

      final user  = res.data['user'] as Map<String, dynamic>;
      final token = res.data['token'] as String;

      await ApiService().setToken(token);

      _name       = user['name']  as String?;
      _phone      = user['phone'] as String?;
      _email      = user['email'] as String?;
      _isLoggedIn = true;
      _codeSent   = false;
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
      _errorMessage = 'فشل الاتصال بالخادم';
      _isLoading    = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────
  // الدوال الموجودة ─ مش اتغيرت
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

  Future<bool> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res   = await ApiService().post('/auth/register', data: {
        'name':     name.trim(),
        'email':    email.trim().toLowerCase(),
        'phone':    phone.trim(),
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

  Future<void> logout() async {
    try {
      await ApiService().init();
      await ApiService().post('/auth/logout');
    } catch (_) {}
    await _firebaseAuth.signOut(); // ✅ جديد ─ نسجل خروج من Firebase كمان
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