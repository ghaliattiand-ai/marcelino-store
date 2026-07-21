import 'package:flutter/material.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);
const _faceColor = Color(0xFFFFB74D);
const _inkColor = Color(0xFF1A1A2E);

/// أنميشن نجاح تسجيل الدخول — وجه لطيف بيغمض عينيه (غمضتين) مع ابتسامة ونص ترحيب.
/// يُعرض كـ dialog شفاف full-screen، وبعد انتهاء الأنميشن يستدعي [onCompleted].
class LoginSuccessAnimation extends StatefulWidget {
  const LoginSuccessAnimation({
    super.key,
    required this.onCompleted,
    this.userName,
  });

  final VoidCallback onCompleted;
  final String? userName;

  @override
  State<LoginSuccessAnimation> createState() => _LoginSuccessAnimationState();
}

class _LoginSuccessAnimationState extends State<LoginSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ظهور الوجه (scale + fade)
  late final Animation<double> _faceScale;
  late final Animation<double> _faceFade;

  // غمضة العين: 0 = مفتوحة، 1 = مغمضة (غمضتين متتاليتين)
  late final Animation<double> _blink;

  // ظهور الابتسامة + النص
  late final Animation<double> _contentFade;

  // اختفاء الكل في الآخر
  late final Animation<double> _outro;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // ظهور الوجه في أول ~20%
    _faceFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
    );
    _faceScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutBack),
      ),
    );

    // غمضتان: أولى أوضح، تانية أسرع، ثم تبقى العيون مفتوحة لظهور النص
    _blink = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 18), // مفتوحة (ظهور)
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10), // تغمض 1
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 4), // مغمضة
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 8), // تفتح 1
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10), // مفتوحة
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 7), // تغمض 2
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3), // مغمضة
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 7), // تفتح 2
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 33), // مفتوحة (النص)
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // ابتسامة + نص يظهران بعد أول غمضة
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.58, curve: Curves.easeIn),
    );

    // اختفاء كله في آخر ~18%
    _outro = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _navy.withValues(alpha: 0.94),
              _navy.withValues(alpha: 0.97),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final outroOpacity = 1.0 - _outro.value;
              return Opacity(
                opacity: outroOpacity.clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── الوجه ──
                    Transform.scale(
                      scale: _faceScale.value,
                      child: Opacity(
                        opacity: _faceFade.value,
                        child: _buildFace(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // ── نص الترحيب ──
                    Opacity(
                      opacity: (_contentFade.value * outroOpacity).clamp(0.0, 1.0),
                      child: _buildText(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── الوجه: دائرة + عينان بجفون متحركة + ابتسامة ──
  Widget _buildFace() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: _faceColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 48, left: 42, child: _buildEye()),
          Positioned(top: 48, right: 42, child: _buildEye()),
          // الابتسامة تظهر بعد أول غمضة
          Positioned(
            bottom: 34,
            child: Opacity(
              opacity: _contentFade.value,
              child: const _Smile(),
            ),
          ),
        ],
      ),
    );
  }

  // ── عين: بؤبؤ أسود + جفن ينزل من فوق حسب قيمة الـ blink ──
  Widget _buildEye() {
    const eyeSize = 16.0;
    final lidHeight = eyeSize * _blink.value; // 0 = مفتوحة، eyeSize = مغمضة
    return SizedBox(
      width: eyeSize,
      height: eyeSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // بؤبؤ العين
          Container(
            width: eyeSize,
            height: eyeSize,
            decoration: const BoxDecoration(
              color: _inkColor,
              shape: BoxShape.circle,
            ),
          ),
          // الجفن (نفس لون الوجه) ينزل ليغطي العين
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: lidHeight,
              decoration: const BoxDecoration(
                color: _faceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText() {
    final name = (widget.userName ?? '').trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name.isEmpty ? 'أهلاً بعودتك! 👋' : 'أهلاً $name! 👋',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'تم تسجيل الدخول بنجاح',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// ابتسامة مرسومة كقوس سفلي (نص دائرة) عبر CustomPaint.
class _Smile extends StatelessWidget {
  const _Smile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 30,
      child: CustomPaint(painter: _SmilePainter()),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // مركز الدائرة أعلى الحاوية ونصف القطر = ارتفاع الحاوية → قوس سفلي = ابتسامة
    final rect = Rect.fromLTWH(0, -size.height, size.width, size.height * 2);
    // من 0 (يمين) إلى pi (يسار) عكس عقارب الساعة = النص السفلي
    canvas.drawArc(rect, 0, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
