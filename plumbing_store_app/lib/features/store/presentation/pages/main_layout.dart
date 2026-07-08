import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/cart_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/core/theme/app_theme.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'assistant_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  static const _screenLabels = [
    'الرئيسية',
    'الأقسام',
    'المساعد',
    'السلة',
    'طلباتي',
    'الملف الشخصي',
  ];

  static const _screens = <Widget>[
    HomePage(),
    CategoriesPage(),
    AssistantPage(),
    CartPage(),
    OrdersPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final currentIndex = nav.currentIndex;
    final t = AppTheme.of(context);

    // نلفّ كل tab بـ TickerMode معطّل ما لم يكن هو الظاهر — هذا يوقف
    // كل الأنميشنز والـ animation controllers في الـ tabs غير الظاهرة
    // (مثل typing dots في tab المساعد) ويوفّر البطارية والـ CPU.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: [
            for (var i = 0; i < _screens.length; i++)
              TickerMode(
                enabled: i == currentIndex,
                child: _screens[i],
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: t.card,
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_screenLabels.length, (index) {
                  final selected = currentIndex == index;
                  final isCart = index == 3;
                  final cartCount =
                      isCart ? context.watch<CartProvider>().totalItems : 0;

                  return Expanded(
                    child: InkWell(
                      onTap: () =>
                          context.read<NavigationProvider>().goToTab(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(
                                    begin: 0,
                                    end: selected ? 1 : 0,
                                  ),
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  builder: (_, v, child) => Transform.scale(
                                    scale: 1 + 0.15 * v,
                                    child: child,
                                  ),
                                  child: Icon(
                                    _iconFor(index, selected),
                                    color: selected
                                        ? AppTheme.orange
                                        : t.textMuted,
                                    size: 24,
                                  ),
                                ),
                                if (isCart && cartCount > 0)
                                  Positioned(
                                    top: -6,
                                    left: -8,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                                      child: Container(
                                        key: ValueKey(cartCount),
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '$cartCount',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected ? AppTheme.orange : t.textMuted,
                              ),
                              child: Text(_screenLabels[index]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(int index, bool selected) {
    switch (index) {
      case 0:
        return selected ? Icons.home : Icons.home_outlined;
      case 1:
        return selected ? Icons.grid_view_rounded : Icons.grid_view;
      case 2:
        return selected ? Icons.smart_toy : Icons.smart_toy_outlined;
      case 3:
        return selected ? Icons.shopping_cart : Icons.shopping_cart_outlined;
      case 4:
        return selected ? Icons.receipt_long : Icons.receipt_long_outlined;
      default:
        return selected ? Icons.person : Icons.person_outline;
    }
  }
}
