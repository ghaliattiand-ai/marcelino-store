import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';

const _navy   = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _phoneController = TextEditingController();
  final _otpController   = TextEditingController();
  String? _error;
  bool    _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── خطوة 1: إرسال OTP ──────────────────────────────────────
  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'ادخل رقم التليفون');
      return;
    }

    // تحويل الرقم لصيغة دولية مصرية  01xxxxxxx → +201xxxxxxx
    final formatted = raw.startsWith('0') ? '+2$raw' : '+20$raw';

    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    await auth.sendOtp(formatted);

    if (!mounted) return;
    if (auth.errorMessage != null) {
      setState(() => _error = auth.errorMessage);
    } else if (auth.codeSent) {
      setState(() => _codeSent = true);
    }
  }

  // ── خطوة 2: التحقق من الكود ────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'الكود لازم يكون 6 أرقام');
      return;
    }
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final ok   = await auth.verifyOtp(code);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = auth.errorMessage ?? 'الكود غلط أو انتهت صلاحيته');
    }
  }

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
          title: const Text('دخول برمز SMS'),
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
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _codeSent ? Icons.mark_email_read_outlined : Icons.phone_android,
                        color: _orange,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _codeSent ? 'أدخل الكود' : 'التحقق برمز SMS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _codeSent
                          ? 'تم إرسال كود على +20${_phoneController.text}'
                          : 'هنبعتلك كود تحقق على رقمك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── المحتوى: مرحلة 1 أو 2 ───────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _codeSent
                    ? _OtpStep(
                        key: const ValueKey('otp'),
                        phoneController: _phoneController,
                        otpController: _otpController,
                        error: _error,
                        isLoading: auth.isLoading,
                        onVerify: _verifyOtp,
                        onResend: _sendOtp,
                        onEditPhone: () => setState(() {
                          _codeSent = false;
                          _otpController.clear();
                          _error = null;
                        }),
                      )
                    : _PhoneStep(
                        key: const ValueKey('phone'),
                        phoneController: _phoneController,
                        error: _error,
                        isLoading: auth.isLoading,
                        onSend: _sendOtp,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// مرحلة 1: إدخال رقم التليفون
// ────────────────────────────────────────────────────────────────────────────
class _PhoneStep extends StatelessWidget {
  const _PhoneStep({
    super.key,
    required this.phoneController,
    required this.error,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController phoneController;
  final String?               error;
  final bool                  isLoading;
  final VoidCallback          onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // حقل الرقم
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'رقم الهاتف',
            hintText: '01XXXXXXXXX',
            prefixIcon: const Icon(Icons.phone_outlined),
            prefixText: '+20  ',
            prefixStyle: const TextStyle(
                color: _navy, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 2),
            ),
          ),
        ),

        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center),
        ],

        const SizedBox(height: 20),

        // زرار إرسال
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onSend,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: const Text(
              'إرسال الكود',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ملاحظة
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'هيوصلك رسالة SMS على رقمك خلال ثوانٍ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// مرحلة 2: إدخال كود OTP
// ────────────────────────────────────────────────────────────────────────────
class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.phoneController,
    required this.otpController,
    required this.error,
    required this.isLoading,
    required this.onVerify,
    required this.onResend,
    required this.onEditPhone,
  });

  final TextEditingController phoneController;
  final TextEditingController otpController;
  final String?               error;
  final bool                  isLoading;
  final VoidCallback          onVerify;
  final VoidCallback          onResend;
  final VoidCallback          onEditPhone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الرقم مع زرار تعديل
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined, color: _navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '+20${phoneController.text}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _navy),
                ),
              ),
              GestureDetector(
                onTap: onEditPhone,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'تعديل',
                    style: TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // حقل الكود (6 أرقام)
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 14,
            color: _navy,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              fontSize: 22,
              letterSpacing: 10,
              color: Colors.grey.shade300,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange, width: 2),
            ),
          ),
          onChanged: (val) {
            // تحقق تلقائي لما يكمل 6 أرقام
            if (val.length == 6) {
              FocusScope.of(context).unfocus();
              onVerify();
            }
          },
        ),

        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center),
        ],

        const SizedBox(height: 20),

        // زرار تحقق
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text(
                    'تأكيد الكود',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // إعادة إرسال
        Center(
          child: TextButton.icon(
            onPressed: isLoading ? null : onResend,
            icon: const Icon(Icons.refresh_rounded, color: _navy, size: 18),
            label: const Text(
              'إعادة إرسال الكود',
              style: TextStyle(color: _navy, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}