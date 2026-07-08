import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

/// مساعد موحّد لانتقالات الصفحات — كل التطبيقات تستخدم هذا بدل MaterialPageRoute
class AppTransitions {
  AppTransitions._();

  /// انتقال رئيسي من الأسفل للأعلى (لتفاصيل المنتج، السلة، إلخ)
  static PageTransition slideUp(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.bottomToTop,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      reverseDuration: const Duration(milliseconds: 280),
    );
  }

  /// انتقال انزلاق يمين/يسار (للصفحات الفرعية)
  static PageTransition slideLeft(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.leftToRightJoined,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      reverseDuration: const Duration(milliseconds: 250),
    );
  }

  /// انتقال بتكبير (scale + fade) — مناسب للبحث
  static PageTransition scale(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      alignment: Alignment.center,
      reverseDuration: const Duration(milliseconds: 250),
    );
  }

  /// انتقال بتأثير fade — خفيف وسلس
  static PageTransition fade(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.fade,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      reverseDuration: const Duration(milliseconds: 200),
    );
  }

  /// انتقال مخصص للتفاصيل مع Hero
  static PageTransition details(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.rightToLeftJoined,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      reverseDuration: const Duration(milliseconds: 280),
    );
  }
}
