import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/features/auth/presentation/pages/login_page.dart';
import 'favorites_page.dart';
import 'addresses_page.dart';
import 'notifications_page.dart';
import 'coupons_page.dart';
import 'settings_page.dart';
import '../../../../core/widgets/page_transitions.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _navy,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_navy, Color(0xFF152040)],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          child: Icon(
                            auth.isLoggedIn ? Icons.person : Icons.person_outline,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          auth.isLoggedIn ? (auth.name ?? 'مستخدم') : 'زائر',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          auth.isLoggedIn
                              ? (auth.phone ?? '')
                              : 'سجّل الدخول للاستفادة من جميع الميزات',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (!auth.isLoggedIn)
                      _LoginBanner(
                        onLogin: () => _openLogin(context),
                      ),
                    if (!auth.isLoggedIn) const SizedBox(height: 12),
                    _MenuCard(
                      items: [
                        _MenuItem(
                          icon: Icons.receipt_long_outlined,
                          label: 'طلباتي',
                          onTap: () => context.read<NavigationProvider>().goToTab(4),
                        ),
                        _MenuItem(
                          icon: Icons.favorite_border,
                          label: 'المفضلة',
                          onTap: () {
                            Navigator.push(
                              context,
                              AppTransitions.slideUp(const FavoritesPage()),
                            );
                          },
                        ),
                        _MenuItem(
                          icon: Icons.location_on_outlined,
                          label: 'عناويني',
                          onTap: () => _navigateTo(context, const AddressesPage()),
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'الإشعارات',
                          onTap: () => _navigateTo(context, const NotificationsPage()),
                        ),
                        _MenuItem(
                          icon: Icons.local_offer_outlined,
                          label: 'كوبونات الخصم',
                          onTap: () => _navigateTo(context, const CouponsPage()),
                        ),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'الإعدادات',
                          onTap: () => _navigateTo(context, const SettingsPage()),
                        ),
                      ],
                    ),
                    if (auth.isLoggedIn) ...[
                      const SizedBox(height: 12),
                      _MenuCard(
                        items: [
                          _MenuItem(
                            icon: Icons.logout,
                            label: 'تسجيل الخروج',
                            color: Colors.red,
                            onTap: () => _logout(context, auth),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogin(BuildContext context) async {
    await Navigator.push(
      context,
      AppTransitions.slideUp(const LoginPage()),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, AppTransitions.slideUp(page));
  }

  void _logout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _LoginBanner extends StatelessWidget {
  final VoidCallback onLogin;
  const _LoginBanner({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.login, color: _orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'سجّل الدخول لتتبع طلباتك وحفظ المفضلة',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onLogin,
            child: const Text('دخول', style: TextStyle(color: _orange)),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: item.color ?? _navy),
                title: Text(item.label),
                trailing: Icon(Icons.arrow_back_ios, size: 14, color: Colors.grey[400]),
                onTap: item.onTap,
              ),
              if (!isLast) Divider(height: 1, indent: 56, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}
