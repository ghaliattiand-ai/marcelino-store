# MARCELINO - متجر السباكة والحدايد والبويات 🏪

تطبيق متجر احترافي لمستلزمات السباكة، الحدايد، البويات، والأدوات مبني بـ **Flutter**.

![Flutter](https://img.shields.io/badge/Flutter-3.12+-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)

---

## ✨ المميزات

### 🛍️ المتجر
- صفحة رئيسية غنية ببانر إعلاني وأقسام المنتجات والمنتجات المميزة
- شبكة منتجات مع تحميل تدريجي (Pagination)
- تفاصيل المنتج مع معرض صور ومواصفات وتقييمات
- بحث فوري في المنتجات مع نتائج مباشرة
- تصفح الأقسام ومنتجاتها

### 🛒 سلة المشتريات والطلبات
- إضافة وحذف وتعديل كميات المنتجات
- حساب المجموع مع الشحن (شحن مجاني فوق 500 جنيه)
- إتمام الطلب مع تأكيد وعرض رقم الطلب
- تتبع حالة الطلبات (قيد التنفيذ، تم التوصيل، قيد الانتظار)
- تفاصيل كل طلب كاملة

### 👤 الملف الشخصي
- تسجيل دخول وإنشاء حساب
- إدارة العناوين (إضافة، حذف، تعيين افتراضي)
- الإشعارات (طلبات، عروض، تحديثات)
- كوبونات خصم مع نسخ الكود
- إعدادات التطبيق (وضع ليلي، لغة، إشعارات)
- من نحن، تواصل معنا، سياسة الخصوصية

### 🎨 التصميم
- واجهة عربية RTL بالكامل
- ستايل احترافي (Navy + Orange)
- أنيميشن وتأثيرات بصرية
- وضع ليلي (Dark Mode)
- شريط تنقل سفلي بـ 5 تبويبات

---

## 🏗️ هيكل المشروع

```
plumbing_store_app/
├── lib/
│   ├── main.dart                          # نقطة الدخول
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart         # ثوابت التطبيق
│   │   ├── data/
│   │   │   └── store_products.dart        # بيانات المنتجات التجريبية
│   │   ├── errors/
│   │   │   ├── exceptions.dart            # الاستثناءات
│   │   │   └── failures.dart              # حالات الفشل
│   │   ├── mock/
│   │   │   └── mock_data.dart             # بيانات وهمية
│   │   ├── models/                        # النماذج (Product, Order, User, Category)
│   │   ├── network/
│   │   │   └── api_client.dart           # عميل API (Dio)
│   │   ├── providers/                     # State Management (ChangeNotifier)
│   │   │   ├── auth_provider.dart
│   │   │   ├── cart_provider.dart
│   │   │   ├── favorites_provider.dart
│   │   │   ├── navigation_provider.dart
│   │   │   ├── orders_provider.dart
│   │   │   ├── settings_provider.dart
│   │   │   └── addresses_provider.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart             # ألوان وثيم التطبيق
│   │   ├── utils/
│   │   │   └── validators.dart
│   │   └── widgets/                       # ويدجتات عامة
│   └── features/
│       ├── auth/                          # ميزة المصادقة
│       │   ├── data/
│       │   │   ├── datasources/           # (local + remote)
│       │   │   ├── models/
│       │   │   └── repositories/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   └── usecases/
│       │   └── presentation/
│       │       └── pages/                 # تسجيل الدخول وإنشاء الحساب
│       ├── splash/                        # شاشة الافتتاحية
│       │   └── presentation/pages/
│       └── store/                         # ميزة المتجر (الصفحات الرئيسية)
│           ├── data/
│           │   ├── datasources/
│           │   └── repositories/
│           ├── domain/
│           │   ├── entities/
│           │   ├── repositories/
│           │   └── usecases/
│           └── presentation/
│               ├── blocs/                 # BLoC للمنتجات
│               └── pages/                 # كل صفحات المتجر
├── assets/
│   ├── images/
│   └── icons/
├── pubspec.yaml
└── README.md
```

---

## 🛠️ التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|-----------|
| **Flutter** | إطار العمل الأساسي |
| **Dart** | لغة البرمجة |
| **Provider** | إدارة الحالة (State Management) |
| **Dio** | طلبات HTTP |
| **Shared Preferences** | التخزين المحلي |
| **Cached Network Image** | تحميل وعرض الصور |
| **Shimmer** | تأثير التحميل |
| **Flutter Rating Bar** | عرض التقييمات |
| **Intl** | التنسيق الدولي |
| **Equatable** | مقارنة الكائنات |
| **Dartz** | البرمجة الوظيفية (Either) |

---

## 🚀 كيفية التشغيل

### المتطلبات
- Flutter SDK 3.12 أو أحدث
- Android Studio / VS Code
- جهاز Android/iOS أو محاكي

### خطوات التشغيل

```bash
# 1. استنساخ المشروع
cd plumbing_store_app

# 2. تثبيت التبعيات
flutter pub get

# 3. تشغيل التطبيق
flutter run
```

---

## 📱 بيانات الدخول التجريبية

| الهاتف | كلمة المرور | الملاحظة |
|--------|------------|---------|
| 01012345678 | 123456 | مستخدم: أحمد |
| 01123456789 | 123456 | مستخدم: سارة |

---

## 📌 ملاحظات

- التطبيق يعمل حالياً ببيانات تجريبية (Mock Data)
- جاهز للربط بـ API خلفي عند توفره
- `baseUrl` موجود في `lib/core/constants/app_constants.dart`
- البنية تدعم Clean Architecture مع BLoC

---

## 📄 الرخصة

هذا المشروع خاص بـ **MARCELINO** - جميع الحقوق محفوظة.
