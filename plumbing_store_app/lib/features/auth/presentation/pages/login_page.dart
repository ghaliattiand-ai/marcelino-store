import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/widgets/marcelino_mascot.dart';
import 'register_page.dart';

const _navy   = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus         = FocusNode();
  final _passwordFocus      = FocusNode();

  bool _obscure = true;
  String? _error;
  MascotState _mascotState = MascotState.idle;

  /// الماسكوت مشغول (API call أو animation delay) ← الزرار يتعطّل
  bool get _isBusy =>
      _mascotState == MascotState.thinking ||
      _mascotState == MascotState.happy    ||
      _mascotState == MascotState.angry;

  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_isBusy) return; // لا تقاطع الأنيميشن
    if (_passwordFocus.hasFocus) {
      setState(() => _mascotState = MascotState.shy);
    } else if (_phoneFocus.hasFocus) {
      setState(() => _mascotState = MascotState.watching);
    } else {
      setState(() => _mascotState = MascotState.idle);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final pass  = _passwordController.text;

    // validation بدون call للـ API
    if (phone.isEmpty || pass.isEmpty) {
      setState(() {
        _error        = 'اكتب رقم الهاتف وكلمة المرور';
        _mascotState  = MascotState.angry;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _mascotState = MascotState.idle);
      return;
    }

    setState(() {
      _error       = null;
      _mascotState = MascotState.thinking;
    });

    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(phone, pass);
    if (!mounted) return;

    if (ok) {
      // ✅ نجاح — الماسكوت يفرح ثم ننتقل
      setState(() => _mascotState = MascotState.happy);
      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      // ❌ خطأ — الماسكوت يزعل ثم يرجع idle
      setState(() {
        _mascotState = MascotState.angry;
        _error       = auth.errorMessage ?? 'رقم الهاتف أو كلمة المرور غير صحيحة';
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _mascotState = MascotState.idle);
    }
  }

  // ─────────────────────────────────────────────
  // تسجيل الدخول بجوجل — نفس أسلوب _login بس بيستدعي loginWithGoogle
  // ─────────────────────────────────────────────
  Future<void> _loginWithGoogle() async {
    setState(() {
      _error       = null;
      _mascotState = MascotState.thinking;
    });

    final auth = context.read<AuthProvider>();
    final ok   = await auth.loginWithGoogle();
    if (!mounted) return;

    if (ok) {
      setState(() => _mascotState = MascotState.happy);
      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else if (auth.errorMessage != null) {
      // فيه خطأ فعلي (مش مجرد إلغاء المستخدم للعملية)
      setState(() {
        _mascotState = MascotState.angry;
        _error       = auth.errorMessage;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _mascotState = MascotState.idle);
    } else {
      // المستخدم لغى تسجيل الدخول من نافذة جوجل — من غير رسالة خطأ
      setState(() => _mascotState = MascotState.idle);
    }
  }

  // ─────────────────────────────────────────────
  // تسجيل الدخول بفيسبوك — نفس أسلوب _login بس بيستدعي loginWithFacebook
  // ─────────────────────────────────────────────
  Future<void> _loginWithFacebook() async {
    setState(() {
      _error       = null;
      _mascotState = MascotState.thinking;
    });

    final auth = context.read<AuthProvider>();
    final ok   = await auth.loginWithFacebook();
    if (!mounted) return;

    if (ok) {
      setState(() => _mascotState = MascotState.happy);
      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.pop(context, true);
    } else if (auth.errorMessage != null) {
      setState(() {
        _mascotState = MascotState.angry;
        _error       = auth.errorMessage;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _mascotState = MascotState.idle);
    } else {
      setState(() => _mascotState = MascotState.idle);
    }
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          title: const Text('تسجيل الدخول'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // ── Header card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // ── الماسكوت (بدل الأيقونة الثابتة) ──
                    MarcelinoMascot(
                      state: _mascotState,
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مارسيلينو',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'مرحباً بعودتك!',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── حقل الهاتف ───────────────────────────────
              TextField(
                controller: _phoneController,
                focusNode:  _phoneFocus,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText:  'رقم الهاتف',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled:     true,
                  fillColor:  Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── حقل كلمة المرور ──────────────────────────
              TextField(
                controller: _passwordController,
                focusNode:  _passwordFocus,
                obscureText: _obscure,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText:  'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled:    true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // ── رسالة الخطأ ──────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ),

              const SizedBox(height: 8),

              // ── زرار دخول ────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  // معطّل أثناء API call أو أنيميشن الماسكوت
                  onPressed: (auth.isLoading || _isBusy) ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  // سبينر فقط أثناء الـ API call الفعلي
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'دخول',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),

              // ── فاصل "أو" ────────────────────────────────
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو سجل دخول بـ',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),

              const SizedBox(height: 16),

              // ── أزرار جوجل وفيسبوك ────────────────────────
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed:
                            (auth.isLoading || _isBusy) ? null : _loginWithGoogle,
                        icon: const _GoogleGIcon(),
                        label: const Text('جوجل'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: (auth.isLoading || _isBusy)
                            ? null
                            : _loginWithFacebook,
                        icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                        label: const Text('فيسبوك'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── زرار إنشاء حساب ──────────────────────────
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:  const BorderSide(color: _navy, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                      color:      _navy,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// أيقونة "G" بسيطة لزرار جوجل (Material Icons مفيهاش شعار جوجل الرسمي)
class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}