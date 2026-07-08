import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ثيم التطبيق الموحد (MARCELINO).
///
/// نستخدم نظام الألوان هذا في كل مكان بدل كتابة `Color(0xFF0D1B3E)` يدوياً
/// في كل ملف. كل الألوان المخصصة في الصفحات يجب أن تأتي من هنا عبر
/// `AppTheme.of(context)` أو من `Theme.of(context)` عندما يكون متاحاً.
class AppTheme {
  AppTheme._();

  // ===== الألوان الثابتة =====
  /// الأساسي — كحلي داكن
  static const Color navy = Color(0xFF0D1B3E);
  static const Color navyLight = Color(0xFF1B2A4A);
  static const Color navySoft = Color(0xFF2A3C66);

  /// المميز — برتقالي حيوي
  static const Color orange = Color(0xFFFF6B00);
  static const Color orangeLight = Color(0xFFFF8C42);

  /// ألوان الحالة
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF57F17);
  static const Color info = Color(0xFF1565C0);

  /// تدرجات رمادية/خلفيات
  static const Color bgLight = Color(0xFFF2F3F7);
  static const Color bgDark = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color cardDarkElevated = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF3A3A3A);
  static const Color textLightPrimary = Color(0xFF1A1A2E);
  static const Color textLightMuted = Color(0xFF757575);
  static const Color textDarkPrimary = Color(0xFFEDEDED);
  static const Color textDarkMuted = Color(0xFFAAAAAA);

  /// تدرّج شريط التطبيق (AppBar) — مرن للوضعين
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyLight, navySoft],
  );

  /// أخضر النجاح للتأكيد
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// برتقالي للإبراز/الزر الرئيسي
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orange, orangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== أنماط النص المخصصة =====
  // خط Cairo العربي يتم تحميله عبر google_fonts لضمان توافره على كل المنصات
  static TextStyle _cairo({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) {
    return GoogleFonts.cairo(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle headline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _cairo(size: 22, weight: FontWeight.w800, color: isDark ? textDarkPrimary : textLightPrimary);
  }

  static TextStyle title(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _cairo(size: 18, weight: FontWeight.w700, color: isDark ? textDarkPrimary : textLightPrimary);
  }

  static TextStyle body(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _cairo(size: 14, weight: FontWeight.w400, color: isDark ? textDarkPrimary : textLightPrimary);
  }

  static TextStyle caption(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _cairo(size: 12, weight: FontWeight.w400, color: isDark ? textDarkMuted : textLightMuted);
  }

  /// اختصار يحل القيم المخصصة حسب سطوع الثيم الحالي
  static AppThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _darkInstance : _lightInstance;
  }

  static final AppThemeColors _lightInstance = AppThemeColors(
    isDark: false,
    background: bgLight,
    card: cardLight,
    border: borderLight,
    textPrimary: textLightPrimary,
    textMuted: textLightMuted,
    fieldFill: const Color(0xFFF7F8FA),
    shadow: const Color(0x14000000),
  );

  static final AppThemeColors _darkInstance = AppThemeColors(
    isDark: true,
    background: bgDark,
    card: cardDark,
    border: borderDark,
    textPrimary: textDarkPrimary,
    textMuted: textDarkMuted,
    fieldFill: cardDarkElevated,
    shadow: const Color(0x33000000),
  );

  // ===== بناء الثيمات =====
  static ThemeData lightTheme() => _build(Brightness.light);
  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      useMaterial3: false,
      primaryColor: navy,
      scaffoldBackgroundColor: isDark ? bgDark : bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: orange,
        brightness: brightness,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? cardDark : cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      iconTheme: IconThemeData(
        color: isDark ? textDarkPrimary : textLightPrimary,
      ),
      dividerColor: isDark ? borderDark : borderLight,
      hintColor: isDark ? textDarkMuted : textLightMuted,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cardDarkElevated : const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? borderDark : borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        labelStyle: GoogleFonts.cairo(
          color: isDark ? textDarkMuted : textLightMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orange,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: GoogleFonts.cairoTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      fontFamily: 'Cairo',
    );
  }
}

/// مجموعة عينة الثيم المختصرة لاستخدامها داخل الصفحات بسهولة
class AppThemeColors {
  final bool isDark;
  final Color background;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color fieldFill;
  final Color shadow;

  const AppThemeColors({
    required this.isDark,
    required this.background,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.fieldFill,
    required this.shadow,
  });
}
