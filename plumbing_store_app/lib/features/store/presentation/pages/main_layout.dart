import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/providers/cart_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/core/theme/app_theme.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'assistant_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

const _navyD = Color(0xFF0D1B3E);
const _navyL = Color(0xFF152040);

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _screenLabels = [
    'الرئيسية',
    'الأقسام',
    'المساعد',
    'السلة',
    'طلباتي',
    'الملف الشخصي',
  ];

  /// يفتح الـ Drawer الجانبي (يُستدعى من HomePage)
  void openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      HomePage(onOpenDrawer: openDrawer),
      const CategoriesPage(),
      const AssistantPage(),
      const CartPage(),
      const OrdersPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final currentIndex = nav.currentIndex;
    final t = AppTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: _buildAppDrawer(context, nav),
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

  // ===== Drawer (القائمة الجانبية) =====
  Widget _buildAppDrawer(BuildContext context, NavigationProvider nav) {
    final auth = context.watch<AuthProvider>();
    final t = AppTheme.of(context);
    final isLoggedIn = auth.isLoggedIn;
    final userName = auth.name ?? 'زائر';
    final userPhone = auth.phone ?? 'تسجيل الدخول';

    void closeDrawer() {
      Navigator.of(context).maybePop();
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: Container(
          color: t.background,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // رأس القائمة
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_navyD, _navyL],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: Icon(
                        isLoggedIn ? Icons.person : Icons.person_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userPhone,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // روابط التنقل
              _drawerItem(context, icon: Icons.home_outlined, label: 'الرئيسية', onTap: () { nav.goToTab(0); closeDrawer(); }),
              _drawerItem(context, icon: Icons.grid_view_outlined, label: 'الأقسام', onTap: () { nav.goToTab(1); closeDrawer(); }),
              _drawerItem(context, icon: Icons.smart_toy_outlined, label: 'المساعد الذكي', onTap: () { nav.goToTab(2); closeDrawer(); }),
              _drawerItem(context, icon: Icons.shopping_cart_outlined, label: 'سلة التسوق', onTap: () { nav.goToTab(3); closeDrawer(); }),
              _drawerItem(context, icon: Icons.receipt_long_outlined, label: 'طلباتي', onTap: () { nav.goToTab(4); closeDrawer(); }),
              _drawerItem(context, icon: Icons.person_outline, label: 'الملف الشخصي', onTap: () { nav.goToTab(5); closeDrawer(); }),

              const Divider(height: 32),

              // خروج / تسجيل دخول
              _drawerItem(
                context,
                icon: isLoggedIn ? Icons.logout_outlined : Icons.login_outlined,
                label: isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
                color: isLoggedIn ? AppTheme.error : AppTheme.navy,
                onTap: () {
                  closeDrawer();
                  if (isLoggedIn) {
                    auth.logout();
                  } else {
                    nav.goToTab(5);
                  }
                },
              ),

              const SizedBox(height: 20),

              // معلومات التطبيق
              Center(
                child: Column(
                  children: [
                    Text('MARCELINO', style: TextStyle(color: t.textMuted, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('الإصدار 1.0.0', style: TextStyle(color: t.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final t = AppTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.navy),
      title: Text(
        label,
        style: TextStyle(color: color ?? t.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
