import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';
import 'package:plumbing_store_app/core/theme/app_theme.dart';
import 'package:plumbing_store_app/core/providers/cart_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/providers/orders_provider.dart';
import 'package:plumbing_store_app/core/providers/favorites_provider.dart';
import 'package:plumbing_store_app/core/providers/settings_provider.dart';
import 'package:plumbing_store_app/core/providers/addresses_provider.dart';
import 'package:plumbing_store_app/core/providers/public_settings_provider.dart';
import 'package:plumbing_store_app/core/network/api_service.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/data/tracking_service.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // 1) نحمّل عنوان الـ API المحفوظ من الإعدادات (إن وُجد) قبل إنشاء Dio
  await AppConstants.loadBaseUrl();

  // 2) تهيئة الـ API service + جلب المنتجات/الأقسام
  // ملاحظة: التطبيق مصمم ليعمل بالـ mock fallback لو فشل الاتصال — لا يُحجَم على الإطلاق
  await ApiService().init();
  await StoreApiService().init();

  // 3) تتبع فتح التطبيق (fire-and-forget) — بدون أي خدمات طرف ثالث
  TrackingService().trackAppOpen();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => CartProvider()..load()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()..loadOrders()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AddressesProvider()..load(),
        ),
        ChangeNotifierProvider(create: (_) => PublicSettingsProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            // التطبيق نهاري دايماً (تم إلغاء الوضع الليلي)
            theme: AppTheme.lightTheme(),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
