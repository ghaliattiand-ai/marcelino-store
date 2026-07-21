// lib/core/widgets/marcelino_mascot.dart
// ماسكوت مارسيلينو السباك - Animated plumber mascot for login screen
// نسخة احترافية: تدرجات لونية، ظلال طبقية، وتفاصيل هوية بصرية بريميوم

import 'dart:math';
import 'package:flutter/material.dart';

/// حالات الماسكوت الـ 6
enum MascotState {
  idle,      // رايق - Normal
  watching,  // متابع - Tracks email/username typing
  shy,       // خجول - Hands cover eyes while typing password
  thinking,  // بيفكر - Loading / logging in
  happy,     // مبسوط ⭐ - Login success
  angry,     // زعلان 😤 - Login failed
}

class MarcelinoMascot extends StatefulWidget {
  final MascotState state;
  final double size;

  const MarcelinoMascot({
    super.key,
    required this.state,
    this.size = 200,
  });

  @override
  State<MarcelinoMascot> createState() => _MarcelinoMascotState();
}

class _MarcelinoMascotState extends State<MarcelinoMascot>
    with TickerProviderStateMixin {

  late final AnimationController _floatCtrl;   // طفوة ناعمة فوق وتحت
  late final AnimationController _blinkCtrl;   // رمشة
  late final AnimationController _transCtrl;   // انتقال بين الحالات
  late final AnimationController _loopCtrl;    // حركة متكررة (نجوم، نقاط تفكير)
  late final AnimationController _peekCtrl;    // فتح عين واحدة بنظرة خبيثة وهو مستحي

  late final Animation<double> _floatAnim;
  late final Animation<double> _blinkAnim;
  late final Animation<double> _transAnim;
  late final Animation<double> _loopAnim;
  late final Animation<double> _peekAnim;

  int _winkSide = 0; // -1 = عين شمال بتغمز، 1 = عين يمين، 0 = رمشة عادية بالعينين
  final int _peekSide = 0; // العين اللي بتلمح بخبث وهو مستحي

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );

    _transCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _blinkAnim = CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeIn);
    _transAnim = CurvedAnimation(parent: _transCtrl, curve: Curves.elasticOut);
    _loopAnim  = CurvedAnimation(parent: _loopCtrl,  curve: Curves.easeInOut);

    _scheduleBlink();
  }

  void _scheduleBlink() {
    final delay = 2000 + Random().nextInt(3000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      if (widget.state == MascotState.shy) { _scheduleBlink(); return; }

      // من وقت للتاني، بدل الرمشة العادية، يغمز بعين واحدة كلمحة شخصية مرحة
      final canWink = widget.state == MascotState.idle || widget.state == MascotState.watching;
      _winkSide = (canWink && Random().nextDouble() < 0.3)
          ? (Random().nextBool() ? -1 : 1)
          : 0;

      _blinkCtrl.forward().then((_) {
        _blinkCtrl.reverse().then((_) { if (mounted) _scheduleBlink(); });
      });
    });
  }

  @override
  void didUpdateWidget(MarcelinoMascot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _transCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _blinkCtrl.dispose();
    _transCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _blinkAnim, _transAnim, _loopAnim]),
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MascotPainter(
            state: widget.state,
            blink: _blinkAnim.value,
            trans: _transAnim.value,
            loop: _loopAnim.value,
            winkSide: _winkSide,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// لوحة الألوان الاحترافية (هوية بصرية موحّدة)
// ─────────────────────────────────────────────────────────────────────────────

class _Palette {
  // بشرة: تدرج دافئ بإضاءة علوية يسارية
  static const skinHi   = Color(0xFFFFE1B8);
  static const skinMid  = Color(0xFFF5B77E);
  static const skinLo   = Color(0xFFDD9257);
  static const skinLine = Color(0xFFC97A3F);

  // الطربوش: كحلي عميق بتدرج ولمعة معدنية
  static const capHi    = Color(0xFF2F6FCE);
  static const capMid   = Color(0xFF14468F);
  static const capLo    = Color(0xFF0A2C61);
  static const gold     = Color(0xFFE8B84B);
  static const goldDeep = Color(0xFFB9862A);

  // تفاصيل
  static const brow     = Color(0xFF2A1A14);
  static const mustHi   = Color(0xFF6D4534);
  static const mustLo   = Color(0xFF3E2417);
  static const lip      = Color(0xFF8A4A3D);
  static const iris     = Color(0xFF3B2A20);
  static const blush    = Color(0xFFF48A7B);
}

class _MascotPainter extends CustomPainter {
  final MascotState state;
  final double blink; // 0→1 (1 = مغمض)
  final double trans; // 0→1 transition
  final double loop;  // 0→1→0 continuous
  final int winkSide; // -1 شمال / 1 يمين / 0 من غير غمزة

  const _MascotPainter({
    required this.state,
    required this.blink,
    required this.trans,
    required this.loop,
    this.winkSide = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.37;

    _shadow(canvas, size, r);
    _neck(canvas, cx, cy, r);
    _head(canvas, cx, cy, r);
    _ears(canvas, cx, cy, r);
    _hat(canvas, cx, cy, r);
    _face(canvas, cx, cy, r);

    if (state == MascotState.happy) _stars(canvas, cx, cy, r);
    if (state == MascotState.angry) {
      _angryFx(canvas, cx, cy, r);
      _earSteam(canvas, cx, cy, r);
    }
  }

  // ── ظل أرضي طبقي ─────────────────────────────────────────────────────────
  void _shadow(Canvas canvas, Size size, double r) {
    final cx = size.width / 2;
    final baseY = size.height * 0.94;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY), width: r * 1.55, height: r * 0.22),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY), width: r * 1.05, height: r * 0.12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  // ── رقبة بسيطة لربط الرأس بالظل ────────────────────────────────────────
  void _neck(Canvas canvas, double cx, double cy, double r) {
    final rect = Rect.fromCenter(center: Offset(cx, cy + r * 0.86), width: r * 0.55, height: r * 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r * 0.12)),
      Paint()..color = _Palette.skinLo,
    );
  }

  // ── رأس مع تدرج ثلاثي الأبعاد ────────────────────────────────────────────
  void _head(Canvas canvas, double cx, double cy, double r) {
    double dx = 0;
    if (state == MascotState.angry && trans < 0.65) {
      dx = sin(trans * 5 * pi) * 5 * (0.65 - trans);
    }

    final c = Offset(cx + dx, cy);
    final rect = Rect.fromCircle(center: c, radius: r);

    // تدرج إضاءة من أعلى اليسار لإحساس كروي
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.45, -0.55),
          radius: 1.15,
          colors: [_Palette.skinHi, _Palette.skinMid, _Palette.skinLo],
          stops: [0.0, 0.62, 1.0],
        ).createShader(rect),
    );

    // خط تحديد ناعم
    canvas.drawCircle(c, r, Paint()
      ..color = _Palette.skinLine.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);

    // ظل تلامسي أسفل يمين الوجه لعمق إضافي
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawCircle(
      Offset(c.dx + r * 0.35, c.dy + r * 0.45),
      r * 0.85,
      Paint()
        ..color = _Palette.skinLo.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.restore();

    // لمعة علوية خفيفة (glossy highlight)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx - r * 0.42, c.dy - r * 0.55), width: r * 0.5, height: r * 0.28),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    if (state == MascotState.happy || state == MascotState.shy) {
      final a = state == MascotState.happy ? 0.55 : 0.35;
      for (final s in [-1, 1]) {
        canvas.drawCircle(
          Offset(cx + s * r * 0.47, cy + r * 0.1),
          r * 0.17,
          Paint()
            ..shader = RadialGradient(
              colors: [_Palette.blush.withValues(alpha: a), _Palette.blush.withValues(alpha: 0)],
            ).createShader(Rect.fromCircle(center: Offset(cx + s * r * 0.47, cy + r * 0.1), radius: r * 0.17)),
        );
      }
    }
  }

  // ── أذنين خفيفتين لواقعية أكتر ────────────────────────────────────────────
  void _ears(Canvas canvas, double cx, double cy, double r) {
    for (final s in [-1, 1]) {
      final ec = Offset(cx + s * r * 0.97, cy + r * 0.06);
      canvas.drawOval(
        Rect.fromCenter(center: ec, width: r * 0.22, height: r * 0.30),
        Paint()..color = _Palette.skinMid,
      );
      canvas.drawOval(
        Rect.fromCenter(center: ec, width: r * 0.11, height: r * 0.17),
        Paint()..color = _Palette.skinLo.withValues(alpha: 0.6),
      );
    }
  }

  // ── طربوش السباك الاحترافي (كاب بشعار) ────────────────────────────────────
  void _hat(Canvas canvas, double cx, double cy, double r) {
    final visorRect = Rect.fromCenter(
      center: Offset(cx, cy - r * 0.73), width: r * 1.72, height: r * 0.22,
    );
    // حافة الكاب بتدرج معدني
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_Palette.capMid, _Palette.capLo],
        ).createShader(visorRect),
    );
    canvas.drawLine(
      Offset(visorRect.left + 4, visorRect.top + 2),
      Offset(visorRect.right - 4, visorRect.top + 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.2,
    );

    // جسم الكاب
    final domePath = Path()
      ..moveTo(cx - r * 0.62, cy - r * 0.73)
      ..lineTo(cx - r * 0.46, cy - r * 1.12)
      ..quadraticBezierTo(cx, cy - r * 1.22, cx + r * 0.46, cy - r * 1.12)
      ..lineTo(cx + r * 0.62, cy - r * 0.73)
      ..close();
    canvas.drawPath(
      domePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_Palette.capHi, _Palette.capMid, _Palette.capLo],
          stops: [0.0, 0.55, 1.0],
        ).createShader(domePath.getBounds()),
    );

    // خط تماس علوي أنيق
    canvas.drawPath(
      domePath,
      Paint()
        ..color = _Palette.capLo.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // لمعة قماشية علوية
    canvas.drawLine(
      Offset(cx - r * 0.26, cy - r * 0.84),
      Offset(cx + r * 0.30, cy - r * 0.87),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = r * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // شارة ذهبية بشكل مفتاح إنجليزي مبسّط (هوية سباك محترف)
    final badgeC = Offset(cx, cy - r * 0.885);
    canvas.drawCircle(
      badgeC, r * 0.145,
      Paint()
        ..shader = const RadialGradient(
          colors: [_Palette.gold, _Palette.goldDeep],
        ).createShader(Rect.fromCircle(center: badgeC, radius: r * 0.145)),
    );
    canvas.drawCircle(
      badgeC, r * 0.145,
      Paint()
        ..color = _Palette.goldDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final wrenchPaint = Paint()
      ..color = const Color(0xFFFFF6E0)
      ..strokeWidth = r * 0.032
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(badgeC.dx - r * 0.06, badgeC.dy + r * 0.06),
      Offset(badgeC.dx + r * 0.06, badgeC.dy - r * 0.06),
      wrenchPaint,
    );
    canvas.drawCircle(Offset(badgeC.dx - r * 0.065, badgeC.dy + r * 0.065), r * 0.028, wrenchPaint..style = PaintingStyle.stroke);
  }

  // ── وجه (dispatcher) ──────────────────────────────────────────────────────
  void _face(Canvas canvas, double cx, double cy, double r) {
    switch (state) {
      case MascotState.idle:
        _brows(canvas, cx, cy, r, relaxed: true);
        _eyePair(canvas, cx, cy, r, Offset.zero, winkSide: winkSide);
        _mouth(canvas, cx, cy, r, _MouthType.smile);
        break;
      case MascotState.watching:
        _brows(canvas, cx, cy, r, relaxed: true);
        // بيبص تحت باستمرار على مكان الكتابة
        _eyePair(canvas, cx, cy, r, const Offset(0, 0.5), winkSide: winkSide);
        _mouth(canvas, cx, cy, r, _MouthType.smile);
        break;
      case MascotState.shy:
        _funnyShyFace(canvas, cx, cy, r);
        _mouth(canvas, cx, cy, r, _MouthType.nervous);
        break;
      case MascotState.thinking:
        _brows(canvas, cx, cy, r, relaxed: false);
        _eyePair(canvas, cx, cy, r, const Offset(-0.28, -0.22));
        _mouth(canvas, cx, cy, r, _MouthType.flat);
        _thinkDots(canvas, cx, cy, r);
        break;
      case MascotState.happy:
        _brows(canvas, cx, cy, r, relaxed: true, raised: true);
        _happyEyes(canvas, cx, cy, r);
        _mouth(canvas, cx, cy, r, _MouthType.bigSmile);
        break;
      case MascotState.angry:
        _angryBrows(canvas, cx, cy, r);
        _eyePair(canvas, cx, cy, r, Offset.zero);
        _mouth(canvas, cx, cy, r, _MouthType.frown);
        break;
    }
    _mustache(canvas, cx, cy, r);
  }

  // ── حواجب مصفّفة ─────────────────────────────────────────────────────────
  void _brows(Canvas canvas, double cx, double cy, double r, {required bool relaxed, bool raised = false}) {
    final p = Paint()
      ..color = _Palette.brow
      ..strokeWidth = r * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lift = raised ? r * 0.06 : 0.0;
    for (final s in [-1, 1]) {
      final path = Path()
        ..moveTo(cx + s * r * 0.44, cy - r * 0.30 - lift)
        ..quadraticBezierTo(
          cx + s * r * 0.30, cy - r * 0.38 - lift,
          cx + s * r * 0.16, cy - r * 0.31 - lift,
        );
      canvas.drawPath(path, p);
    }
  }

  // ── عين بتفاصيل بريميوم ──────────────────────────────────────────────────
  void _eye(Canvas canvas, double ex, double ey, double r, Offset pupilDir, {bool forceOpen = false}) {
    final effectiveBlink = forceOpen ? 0.0 : blink; // لو غمزة، العين دي تفضل مفتوحة مهما كانت قيمة الرمشة
    final ew = r * 0.30;
    final eh = r * 0.26 * (1 - effectiveBlink);
    final eyeRect = Rect.fromCenter(center: Offset(ex, ey), width: ew, height: max(0.5, eh));

    canvas.drawOval(
      eyeRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF2F2F2)],
        ).createShader(eyeRect),
    );
    canvas.drawOval(
      eyeRect,
      Paint()
        ..color = const Color(0xFF2A2A2A).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    if (effectiveBlink < 0.55) {
      final px = ex + pupilDir.dx * r * 0.06;
      final py = ey + pupilDir.dy * r * 0.07;
      final irisC = Offset(px, py);
      canvas.drawCircle(
        irisC, r * 0.105,
        Paint()
          ..shader = const RadialGradient(
            colors: [_Palette.mustHi, _Palette.iris],
          ).createShader(Rect.fromCircle(center: irisC, radius: r * 0.105)),
      );
      canvas.drawCircle(irisC, r * 0.045, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(px - r * 0.045, py - r * 0.045),
        r * 0.038,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        Offset(px + r * 0.03, py + r * 0.02),
        r * 0.016,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
    }
  }

  void _eyePair(Canvas canvas, double cx, double cy, double r, Offset pd, {int winkSide = 0}) {
    final leftForceOpen  = winkSide == 1;  // الغمزة يمين → الشمال يفضل مفتوح
    final rightForceOpen = winkSide == -1; // الغمزة شمال → اليمين يفضل مفتوح
    _eye(canvas, cx - r * 0.30, cy - r * 0.12, r, pd, forceOpen: leftForceOpen);
    _eye(canvas, cx + r * 0.30, cy - r * 0.12, r, pd, forceOpen: rightForceOpen);
  }

  void _happyEyes(Canvas canvas, double cx, double cy, double r) {
    final p = Paint()
      ..color = _Palette.brow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (int s in [-1, 1]) {
      final ex = cx + s * r * 0.30;
      final ey = cy - r * 0.12;
      final path = Path()
        ..moveTo(ex - r * 0.16, ey)
        ..quadraticBezierTo(ex, ey - r * 0.19, ex + r * 0.16, ey);
      canvas.drawPath(path, p);
      // رمش صغير علوي
      canvas.drawLine(
        Offset(ex + r * 0.14, ey - r * 0.14),
        Offset(ex + r * 0.20, ey - r * 0.22),
        Paint()..color = _Palette.brow..strokeWidth = 1.4..strokeCap = StrokeCap.round,
      );
    }
  }

  void _funnyShyFace(Canvas canvas, double cx, double cy, double r) {
    // نبضة دخول مرتدة (العين بتتقفل بسرعة وترتد شوية) + اهتزاز خفيف مستمر لإحساس التوتر الكوميدي
    final squeeze = trans.clamp(0.0, 1.0);
    final jitter  = sin(loop * pi * 5) * r * 0.012 * squeeze;

    // خدود محمرة من الخجل
    for (final s in [-1, 1]) {
      final bc = Offset(cx + s * r * 0.47 + jitter, cy + r * 0.12);
      canvas.drawCircle(
        bc, r * (0.12 + squeeze * 0.03),
        Paint()
          ..shader = RadialGradient(
            colors: [_Palette.blush.withValues(alpha: 0.55), _Palette.blush.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: bc, radius: r * 0.15)),
      );
    }

    // حواجب متقطبة (furrowed) قريبة من العين - إحساس "مقفل بقوة"
    final browPaint = Paint()
      ..color = _Palette.brow
      ..strokeWidth = r * 0.06
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in [-1, 1]) {
      final bx = cx + s * r * 0.30 + jitter;
      final by = cy - r * 0.30 - squeeze * r * 0.04;
      canvas.drawLine(
        Offset(bx - s * r * 0.15, by + r * 0.06),
        Offset(bx + s * r * 0.05, by - r * 0.03),
        browPaint,
      );
    }

    // عيون مقفولة بقوة - قوس كوميدي سميك (^) بدل الخط العادي
    final eyePaint = Paint()
      ..color = _Palette.brow
      ..strokeWidth = r * (0.05 + squeeze * 0.015)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in [-1, 1]) {
      final ex = cx + s * r * 0.30 + jitter;
      final ey = cy - r * 0.09;
      final path = Path()
        ..moveTo(ex - r * 0.17, ey + r * 0.02)
        ..quadraticBezierTo(ex, ey - r * 0.17 * squeeze, ex + r * 0.17, ey + r * 0.02);
      canvas.drawPath(path, eyePaint);

      // خطوط توتر صغيرة كوميدية فوق كل عين (زي "><" مبالغ فيها)
      final tensionPaint = Paint()
        ..color = _Palette.brow.withValues(alpha: 0.55 * squeeze)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round;
      for (final k in [-1, 1]) {
        canvas.drawLine(
          Offset(ex + k * r * 0.13, ey - r * 0.19),
          Offset(ex + k * r * 0.19, ey - r * 0.27),
          tensionPaint,
        );
      }
    }

    // قطرة عرق كوميدية صغيرة على الجنب
    if (squeeze > 0.25) {
      final op = ((squeeze - 0.25) * 1.6).clamp(0.0, 1.0);
      final sx = cx + r * 0.78;
      final sy = cy - r * 0.42;
      final dropPath = Path()
        ..moveTo(sx, sy - r * 0.10)
        ..quadraticBezierTo(sx + r * 0.08, sy, sx, sy + r * 0.10)
        ..quadraticBezierTo(sx - r * 0.08, sy, sx, sy - r * 0.10);
      canvas.drawPath(
        dropPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFFCBE6FF).withValues(alpha: op), const Color(0xFF8FC4EE).withValues(alpha: op)],
          ).createShader(dropPath.getBounds()),
      );
    }
  }

  void _angryBrows(Canvas canvas, double cx, double cy, double r) {
    final p = Paint()
      ..color = _Palette.brow
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - r * 0.48, cy - r * 0.40), Offset(cx - r * 0.13, cy - r * 0.27), p);
    canvas.drawLine(Offset(cx + r * 0.13, cy - r * 0.27), Offset(cx + r * 0.48, cy - r * 0.40), p);
  }

  void _thinkDots(Canvas canvas, double cx, double cy, double r) {
    for (int i = 0; i < 3; i++) {
      final t    = (loop + i / 3.0) % 1.0;
      final yOff = -sin(t * pi) * r * 0.20;
      final dc = Offset(cx + (i - 1) * r * 0.22, cy - r * 1.30 + yOff);
      canvas.drawCircle(
        dc, r * 0.065,
        Paint()
          ..shader = RadialGradient(
            colors: [_Palette.capHi.withValues(alpha: 0.85), _Palette.capMid.withValues(alpha: 0.7)],
          ).createShader(Rect.fromCircle(center: dc, radius: r * 0.065)),
      );
    }
  }

  // ── شنب بتدرج وعمق ───────────────────────────────────────────────────────
  void _mustache(Canvas canvas, double cx, double cy, double r) {
    for (int s in [-1, 1]) {
      final path = Path()
        ..moveTo(cx + s * r * 0.04, cy + r * 0.20)
        ..quadraticBezierTo(
            cx + s * r * 0.33, cy + r * 0.15,
            cx + s * r * 0.45, cy + r * 0.27)
        ..quadraticBezierTo(
            cx + s * r * 0.29, cy + r * 0.30,
            cx + s * r * 0.04, cy + r * 0.24)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_Palette.mustHi, _Palette.mustLo],
          ).createShader(path.getBounds()),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = _Palette.mustLo.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  // ── بق بتفاصيل شفايف ──────────────────────────────────────────────────────
  void _mouth(Canvas canvas, double cx, double cy, double r, _MouthType type) {
    final p = Paint()
      ..color = _Palette.lip
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (type) {
      case _MouthType.smile:
        path
          ..moveTo(cx - r * 0.17, cy + r * 0.38)
          ..quadraticBezierTo(cx, cy + r * 0.47, cx + r * 0.17, cy + r * 0.38);
        break;
      case _MouthType.nervous:
        path
          ..moveTo(cx - r * 0.14, cy + r * 0.38)
          ..lineTo(cx - r * 0.04, cy + r * 0.41)
          ..lineTo(cx + r * 0.04, cy + r * 0.36)
          ..lineTo(cx + r * 0.14, cy + r * 0.38);
        break;
      case _MouthType.flat:
        path
          ..moveTo(cx - r * 0.14, cy + r * 0.38)
          ..lineTo(cx + r * 0.14, cy + r * 0.38);
        break;
      case _MouthType.bigSmile:
        final smileRect = Rect.fromCenter(center: Offset(cx, cy + r * 0.39), width: r * 0.58, height: r * 0.16);
        canvas.drawOval(
          smileRect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFBE4D8)],
            ).createShader(smileRect),
        );
        path
          ..moveTo(cx - r * 0.38, cy + r * 0.27)
          ..quadraticBezierTo(cx, cy + r * 0.54, cx + r * 0.38, cy + r * 0.27);
        break;
      case _MouthType.frown:
        path
          ..moveTo(cx - r * 0.26, cy + r * 0.44)
          ..quadraticBezierTo(cx, cy + r * 0.32, cx + r * 0.26, cy + r * 0.44);
        break;
    }

    canvas.drawPath(path, p);
  }

  // ── نجوم بريق النجاح (happy) ─────────────────────────────────────────────
  void _stars(Canvas canvas, double cx, double cy, double r) {
    final locs = [
      Offset(cx - r * 0.90, cy - r * 0.40),
      Offset(cx + r * 0.90, cy - r * 0.40),
      Offset(cx - r * 0.64, cy - r * 0.80),
      Offset(cx + r * 0.64, cy - r * 0.80),
    ];
    for (int i = 0; i < locs.length; i++) {
      final pulse = (sin(loop * pi * 2 + i * pi / 2) + 1) / 2;
      final sz = r * (0.09 + pulse * 0.05);
      // توهج خلفي
      canvas.drawCircle(
        locs[i], sz * 1.8,
        Paint()
          ..color = _Palette.gold.withValues(alpha: 0.18 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      _drawStar(
        canvas, locs[i], sz,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFF3CE), _Palette.gold],
          ).createShader(Rect.fromCircle(center: locs[i], radius: sz))
          ..color = _Palette.gold.withValues(alpha: 0.65 + pulse * 0.35),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset c, double sz, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a1 = -pi / 2 + 2 * pi * i / 5;
      final a2 = a1 + pi / 5;
      final o = Offset(c.dx + sz * cos(a1), c.dy + sz * sin(a1));
      final inn = Offset(c.dx + sz * 0.42 * cos(a2), c.dy + sz * 0.42 * sin(a2));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      path.lineTo(inn.dx, inn.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  // ── تأثيرات الزعل ─────────────────────────────────────────────────────────
  void _angryFx(Canvas canvas, double cx, double cy, double r) {
    // خط غضب متعرج
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.74, cy - r * 0.54)
        ..relativeLineTo( r * 0.12, -r * 0.09)
        ..relativeLineTo( r * 0.09,  r * 0.13)
        ..relativeLineTo( r * 0.10, -r * 0.07),
      Paint()
        ..color = Colors.red.shade400.withValues(alpha: 0.7)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // قطرة عرق بتدرج
    final sx = cx + r * 0.79;
    final sy = cy - r * 0.10;
    final dropPath = Path()
      ..moveTo(sx, sy - r * 0.13)
      ..quadraticBezierTo(sx + r * 0.10, sy, sx, sy + r * 0.12)
      ..quadraticBezierTo(sx - r * 0.10, sy, sx, sy - r * 0.13);
    canvas.drawPath(
      dropPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFCBE6FF), Color(0xFF8FC4EE)],
        ).createShader(dropPath.getBounds()),
    );
    canvas.drawCircle(
      Offset(sx - r * 0.025, sy - r * 0.04), r * 0.018,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  // ── بخار من الودان (لمسة كوميدية زعل) ────────────────────────────────────
  void _earSteam(Canvas canvas, double cx, double cy, double r) {
    for (final s in [-1, 1]) {
      final baseX = cx + s * r * 0.97;
      final baseY = cy - r * 0.05;
      for (int i = 0; i < 2; i++) {
        final t     = (loop + i * 0.5) % 1.0;
        final rise  = t * r * 0.55;
        final wiggle = sin(t * pi * 3) * r * 0.07;
        final op    = (1 - t) * 0.55;
        canvas.drawCircle(
          Offset(baseX + wiggle, baseY - rise),
          r * (0.045 + t * 0.035),
          Paint()..color = Colors.white.withValues(alpha: op),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.state != state ||
      old.blink != blink ||
      old.trans  != trans  ||
      old.loop   != loop   ||
      old.winkSide != winkSide;
}

enum _MouthType { smile, nervous, flat, bigSmile, frown }