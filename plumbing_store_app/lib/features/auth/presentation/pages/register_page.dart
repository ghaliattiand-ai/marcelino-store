import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';

const _navy = Color(0xFF0D1B3E);
const _navyL = Color(0xFF152040);
const _orange = Color(0xFFFF6B00);
const _bg = Color(0xFFF2F3F7);

/// صفحة إنشاء حساب - 3 خطوات:
/// 1) رقم التليفون ← إرسال OTP
/// 2) كود OTP ← تأكيد
/// 3) الاسم + الإيميل + كلمة السر + تأكيدها ← إنشاء الحساب
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ── المتحكمات ──
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  String? _error;

  /// 0 = رقم، 1 = OTP، 2 = بيانات الحساب
  int _step = 0;
  String _verifiedPhone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _formatE164(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.startsWith('20')) return '+$clean';
    if (clean.startsWith('0')) return '+2$clean';
    return '+20$clean';
  }

  // ── خطوة 1: إرسال OTP ──
  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim();
    if (raw.length < 10) {
      setState(() => _error = 'اكتب رقم تليفون صحيح (11 رقم)');
      return;
    }
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final e164 = _formatE164(raw);
    await auth.sendOtp(e164);

    if (!mounted) return;
    if (auth.errorMessage != null) {
      setState(() => _error = auth.errorMessage);
    } else if (auth.codeSent) {
      setState(() => _step = 1);
    }
  }

  // ── خطوة 2: التحقق من OTP ──
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'الكود لازم يكون 6 أرقام');
      return;
    }
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtpForRegister(code);

    if (!mounted) return;
    if (ok) {
      setState(() {
        _verifiedPhone = auth.verifiedPhoneForRegister ?? _formatE164(_phoneController.text.trim());
        _step = 2;
      });
    } else {
      setState(() => _error = auth.errorMessage ?? 'الكود غلط أو انتهت صلاحيته');
    }
  }

  // ── خطوة 3: إنشاء الحساب ──
  Future<void> _finishRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.length < 3) {
      setState(() => _error = 'اكتب اسمك بالكامل');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'بريد إلكتروني غير صالح');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'كلمة المرور لازم 6 أحرف على الأقل');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    if (!_acceptTerms) {
      setState(() => _error = 'لازم توافق على الشروط والأحكام');
      return;
    }

    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      name: name,
      phone: _verifiedPhone.isEmpty ? _formatE164(_phoneController.text.trim()) : _verifiedPhone,
      email: email,
      password: pass,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح 🎉')),
      );
    } else {
      setState(() => _error = auth.errorMessage ?? 'حصل خطأ، حاول تاني');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // ===== الترويسة + مؤشر الخطوات =====
              _buildHeader(),

              // ===== المحتوى =====
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _buildStep(auth),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== الترويسة مع مؤشر الخطوات =====
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navy, _navyL],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_step > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () {
                    final auth = context.read<AuthProvider>();
                    if (_step == 2) {
                      setState(() => _step = 1);
                    } else if (_step == 1) {
                      auth.cancelRegistration();
                      _otpController.clear();
                      setState(() {
                        _step = 0;
                        _error = null;
                      });
                    }
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 4),
              const Text(
                'إنشاء حساب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // مؤشر الخطوات (3 دوائر)
          Row(
            children: List.generate(3, (i) {
              final active = i <= _step;
              final done = i < _step;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: done
                            ? _orange
                            : (active ? Colors.white : Colors.white.withValues(alpha: 0.2)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? _orange : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${i + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: active ? _navy : Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                            ),
                    ),
                    if (i < 2)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < _step
                              ? _orange
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _step == 0
                ? 'هنبعتلك كود تحقق على رقمك'
                : _step == 1
                    ? 'اكتب الكود اللي وصلك'
                    : 'آخر خطوة — كمّل بياناتك',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ===== اختيار الخطوة =====
  Widget _buildStep(AuthProvider auth) {
    switch (_step) {
      case 0:
        return _PhoneStep(
          key: const ValueKey(0),
          controller: _phoneController,
          error: _error,
          isLoading: auth.isLoading,
          onSend: _sendOtp,
        );
      case 1:
        return _OtpStep(
          key: const ValueKey(1),
          phoneController: _phoneController,
          otpController: _otpController,
          error: _error,
          isLoading: auth.isLoading,
          onVerify: _verifyOtp,
          onResend: _sendOtp,
        );
      default:
        return _DetailsStep(
          key: const ValueKey(2),
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmController: _confirmController,
          obscurePass: _obscurePass,
          obscureConfirm: _obscureConfirm,
          acceptTerms: _acceptTerms,
          verifiedPhone: _verifiedPhone.isEmpty
              ? _formatE164(_phoneController.text.trim())
              : _verifiedPhone,
          error: _error,
          isLoading: auth.isLoading,
          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
          onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
          onToggleTerms: () => setState(() => _acceptTerms = !_acceptTerms),
          onSubmit: _finishRegister,
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// خطوة 1: رقم التليفون
// ════════════════════════════════════════════════════════════════════
class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.controller,
    required this.error,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final String? error;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // أيقونة + شرح
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android, color: _navy, size: 38),
              ),
              const SizedBox(height: 12),
              const Text(
                'رقم التليفون',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 4),
              Text(
                'هنستخدمه للتأكد من حسابك عبر كود SMS',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // الحقل
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 11,
          decoration: InputDecoration(
            counterText: '',
            labelText: 'رقم الهاتف',
            hintText: '01XXXXXXXXX',
            prefixIcon: const Icon(Icons.phone_outlined, color: _navy),
            prefixText: '+20  ',
            prefixStyle: const TextStyle(color: _navy, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _orange, width: 2),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onSend,
            icon: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.send_rounded),
            label: const Text('إرسال الكود', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// خطوة 2: كود OTP
// ════════════════════════════════════════════════════════════════════
class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.phoneController,
    required this.otpController,
    required this.error,
    required this.isLoading,
    required this.onVerify,
    required this.onResend,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final String? error;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_outlined, color: _orange, size: 38),
              ),
              const SizedBox(height: 12),
              const Text('كود التحقق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 4),
              Text(
                'بعتنا كود على +20${phoneController.text}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 14, color: _navy),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: TextStyle(fontSize: 22, letterSpacing: 10, color: Colors.grey.shade300),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _orange, width: 2),
            ),
          ),
          onChanged: (val) {
            if (val.length == 6) {
              FocusScope.of(context).unfocus();
              onVerify();
            }
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('تأكيد الكود', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton.icon(
            onPressed: isLoading ? null : onResend,
            icon: const Icon(Icons.refresh_rounded, color: _navy, size: 18),
            label: const Text('إعادة إرسال الكود', style: TextStyle(color: _navy, fontSize: 14)),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// خطوة 3: بيانات الحساب
// ════════════════════════════════════════════════════════════════════
class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.acceptTerms,
    required this.verifiedPhone,
    required this.error,
    required this.isLoading,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onToggleTerms,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePass;
  final bool obscureConfirm;
  final bool acceptTerms;
  final String verifiedPhone;
  final String? error;
  final bool isLoading;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final VoidCallback onToggleTerms;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1, color: _navy, size: 38),
              ),
              const SizedBox(height: 12),
              const Text('بيانات الحساب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 4),
              // عرض الرقم المتحقَّق منه كبادج
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 6),
                    Text(verifiedPhone,
                        style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // الاسم
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('الاسم الكامل', Icons.person_outline),
        ),
        const SizedBox(height: 14),
        // الإيميل
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('البريد الإلكتروني', Icons.email_outlined),
        ),
        const SizedBox(height: 14),
        // كلمة المرور
        TextField(
          controller: passwordController,
          obscureText: obscurePass,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration('كلمة المرور', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: _navy),
              onPressed: onTogglePass,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // تأكيد كلمة المرور
        TextField(
          controller: confirmController,
          obscureText: obscureConfirm,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration('تأكيد كلمة المرور', Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _navy),
              onPressed: onToggleConfirm,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // الموافقة على الشروط
        InkWell(
          onTap: onToggleTerms,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: acceptTerms,
                    onChanged: (_) => onToggleTerms(),
                    activeColor: _orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أوافق على الشروط والأحكام وسياسة الخصوصية',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('إنشاء الحساب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _navy),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _orange, width: 2),
      ),
    );
  }
}
