// lib/features/auth/presentation/pages/login_page.dart
// ضيف الأجزاء دي على صفحة الـ login الحالية

import 'package:flutter/material.dart';
import '../../../../core/widgets/marcelino_mascot.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ─── Controllers ──────────────────────────────────────────────────────────
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  MascotState _mascotState = MascotState.idle;
  bool _isLoading = false;
  String? _errorMsg;

  // ─── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // لما المستخدم يبدأ يكتب الإيميل → الماسكوت يتابع
    _emailFocus.addListener(() {
      if (!mounted) return;
      setState(() {
        _mascotState =
            _emailFocus.hasFocus ? MascotState.watching : MascotState.idle;
      });
    });

    // لما يبدأ يكتب الباسورد → الماسكوت يغمي عينيه
    _passwordFocus.addListener(() {
      if (!mounted) return;
      setState(() {
        _mascotState =
            _passwordFocus.hasFocus ? MascotState.shy : MascotState.idle;
      });
    });
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ─── Login logic ──────────────────────────────────────────────────────────
  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _mascotState = MascotState.thinking;
      _isLoading   = true;
      _errorMsg    = null;
    });

    try {
      // ← هنا ضع call الـ BLoC أو Cubit بتاعك
      // مثال: await context.read<AuthCubit>().login(email, password);
      await Future.delayed(const Duration(seconds: 2)); // simulate

      // ✅ نجح الـ login
      if (!mounted) return;
      setState(() => _mascotState = MascotState.happy);
      await Future.delayed(const Duration(milliseconds: 1300));

      // ← Navigate to home
      // Navigator.of(context).pushReplacementNamed('/home');

    } catch (e) {
      // ❌ فشل الـ login
      if (!mounted) return;
      setState(() {
        _mascotState = MascotState.angry;
        _errorMsg    = 'البريد الإلكتروني أو كلمة المرور غلط';
        _isLoading   = false;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      setState(() => _mascotState = MascotState.idle);
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            children: [

              // ── الماسكوت ─────────────────────────────────────────────────
              // AnimatedSwitcher علشان الانتقال بين الحالات يبقى ناعم
              SizedBox(
                height: 210,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  child: MarcelinoMascot(
                    key: ValueKey(_mascotState),
                    state: _mascotState,
                    size: 190,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'مرحباً بك في مارسيلينو',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 32),

              // ── Email field ──────────────────────────────────────────────
              TextField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              // ── Password field ───────────────────────────────────────────
              TextField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              // ── Error message ────────────────────────────────────────────
              if (_errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textDirection: TextDirection.rtl,
                ),
              ],

              const SizedBox(height: 28),

              // ── Login button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── نفس الطريقة للـ RegisterPage ─────────────────────────────────────────────
// في register_page.dart:
//
//   _emailFocus   → watching
//   _passwordFocus → shy
//   _confirmFocus  → shy
//   submit loading → thinking
//   success        → happy
//   error          → angry
//
// نفس الكود بالظبط، بس ضيف FocusNode للـ confirm password field.