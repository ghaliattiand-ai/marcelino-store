import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  // عدد الـ tabs في main_layout (الرئيسية، الأقسام، المساعد، السلة، طلباتي، الملف الشخصي)
  static const int maxTabs = 6;

  int get currentIndex => _currentIndex;

  void goToTab(int index) {
    if (index < 0 || index >= maxTabs) return;
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
