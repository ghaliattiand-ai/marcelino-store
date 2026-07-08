# MARCELINO - متجر السباكة والحدايد والبويات 🏪

نظام متكامل لمتجر مستلزمات السباكة والحدايد والبويات، متكون من **3 مشاريع**:

| المشروع | التقنية | المنفذ |
|---------|---------|--------|
| 📱 **plumbing_store_app** | Flutter (تطبيق موبايل) | - |
| ⚙️ **backend** | Node.js + Express + MongoDB | 5000 |
| 🖥️ **admin-panel** | HTML + CSS + JavaScript | 5000/admin |

---

## 📁 هيكل المشروع

```
sameh/
├── plumbing_store_app/     # تطبيق Flutter للموبايل
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/app_constants.dart
│   │   │   ├── data/store_products.dart          # بيانات محلية (fallback)
│   │   │   ├── data/store_api_service.dart       # خدمة API
│   │   │   ├── network/api_client.dart           # عميل Dio القديم
│   │   │   ├── network/api_service.dart          # خدمة API الجديدة
│   │   │   ├── models/                           # النماذج
│   │   │   └── providers/                        # إدارة الحالة
│   │   └── features/
│   │       ├── auth/                             # تسجيل الدخول/إنشاء حساب
│   │       ├── splash/                           # شاشة الافتتاحية
│   │       └── store/                            # صفحات المتجر
│   └── android/app/src/main/AndroidManifest.xml  # صلاحيات الإنترنت
│
├── backend/                 # خادم API
│   ├── server.js            # نقطة الدخول
│   ├── config/db.js
│   ├── models/              # 5 نماذج MongoDB
│   ├── routes/              # 6 ملفات Routes
│   ├── middleware/          # Auth + Upload
│   ├── seed/seed.js         # بيانات تجريبية
│   ├── uploads/products/    # صور المنتجات
│   └── package.json
│
└── admin-panel/            # لوحة تحكم الويب
    ├── index.html
    ├── styles.css
    └── app.js
```

---

## 🚀 خطوات التشغيل الكاملة

### المتطلبات المسبقة

```bash
- تثبيت Node.js  (https://nodejs.org/)
- تثبيت MongoDB  (https://www.mongodb.com/try/download/community)
- تثبيت Flutter  (https://docs.flutter.dev/get-started/install)
- تشغيل MongoDB على المنفذ الافتراضي (27017)
```

### 1) تشغيل الـ Backend API

```bash
# ادخل مجلد الـ backend
cd backend

# تثبيت الحزم
npm install

# ملء قاعدة البيانات ببيانات تجريبية
npm run seed

# تشغيل السيرفر
npm start
```

السيرفر هيشتغل على `http://localhost:5000`

### 2) فتح لوحة التحكم

بعد تشغيل Backend، افتح المتصفح على:

```
http://localhost:5000/admin
```

### 3) تشغيل تطبيق Flutter

```bash
# ادخل مجلد التطبيق
cd plumbing_store_app

# تثبيت التبعيات
flutter pub get

# شغل جهاز Android Emulator من Android Studio

# تشغيل التطبيق
flutter run
```

---

## 🔐 بيانات الدخول التجريبية

### لوحة تحكم الأدمن
| الحقل | القيمة |
|------|--------|
| الهاتف | `01000000000` |
| كلمة المرور | `admin123` |

### العملاء (للتطبيق)
| الاسم | الهاتف | كلمة المرور |
|-------|--------|--------------|
| أحمد محمد | `01012345678` | `123456` |
| سارة علي | `01123456789` | `123456` |

---

## 📡 واجهات API المتاحة

| Method | Endpoint | الوصف | Auth |
|--------|----------|-------|------|
| POST | `/api/auth/register` | إنشاء حساب جديد | ❌ |
| POST | `/api/auth/login` | تسجيل الدخول (يدعم email أو phone) | ❌ |
| POST | `/api/auth/logout` | تسجيل الخروج | ✅ |
| GET | `/api/auth/me` | بيانات المستخدم الحالي | ✅ |
| GET | `/api/categories` | جلب كل الأقسام | ❌ |
| POST | `/api/categories` | إضافة قسم | Admin |
| PUT | `/api/categories/:id` | تعديل قسم | Admin |
| DELETE | `/api/categories/:id` | حذف قسم | Admin |
| GET | `/api/products` | جلب المنتجات (مع فلاتر) | ❌ |
| GET | `/api/products/:id` | منتج واحد | ❌ |
| POST | `/api/products` | إضافة منتج + صور | Admin |
| PUT | `/api/products/:id` | تعديل منتج | Admin |
| DELETE | `/api/products/:id` | حذف منتج | Admin |
| GET | `/api/orders` | طلبات المستخدم | ✅ |
| POST | `/api/orders` | إنشاء طلب جديد | ✅ |
| GET | `/api/orders/:id` | تفاصيل طلب | ✅ |
| GET | `/api/coupons` | الكوبونات | ❌ |
| POST | `/api/coupons` | إضافة كوبون | Admin |
| PUT | `/api/coupons/:id` | تعديل كوبون | Admin |
| DELETE | `/api/coupons/:id` | حذف كوبون | Admin |
| GET | `/api/admin/stats` | إحصائيات | Admin |
| GET | `/api/admin/orders` | كل الطلبات | Admin |
| PUT | `/api/admin/orders/:id/status` | تحديث حالة طلب | Admin |
| GET | `/api/admin/users` | جميع المستخدمين | Admin |

---

## 📊 ميزات لوحة التحكم

- **الرئيسية**: إحصائيات (منتجات، طلبات، إيرادات، مستخدمين) + أحدث الطلبات + الأكثر مبيعاً
- **المنتجات**: إضافة/تعديل/حذف + رفع صور متعددة + بحث
- **الأقسام**: إدارة كاملة بالألوان والأيقونات
- **الطلبات**: عرض كل الطلبات + تغيير الحالة
- **الكوبونات**: إدارة الكوبونات (نسبة، مبلغ، شحن مجاني)
- **المستخدمين**: عرض العملاء المسجلين

---

## 📱 ميزات تطبيق الموبايل

### المتجر
- صفحة رئيسية مع بانر، أقسام، منتجات مميزة، شبكة منتجات مع pagination
- تفاصيل المنتج مع معرض صور، مواصفات، تقييمات
- بحث فوري في المنتجات
- تصفح حسب الأقسام

### الطلبات
- سلة كاملة مع تحكم في الكميات
- إتمام الطلب عبر الـ API
- تتبع الطلبات (قيد المراجعة، جاري التجهيز، تم التوصيل)
- تفاصيل كل طلب

### الحساب
- تسجيل دخول/إنشاء حساب (مرتبط بالـ API)
- إدارة العناوين
- الإشعارات
- كوبونات الخصم (من الـ API)
- إعدادات (وضع ليلي، لغة، إشعارات)

---

## ⚠️ ملاحظات هامة

### عنوان الـ API (قابل للتعديل من داخل التطبيق)
عنوان الـ API أصبح **قابلاً للتعديل مباشرةً من شاشة الإعدادات** (⚙️ → الاتصال بالخادم → عنوان الـ API)، يُحفظ في SharedPreferences ويعيد تهيئة Dio فوراً — لا حاجة لإعادة بناء التطبيق عند تغييره.

- **التجربة على جهاز حقيقي**: افتح الإعدادات داخل التطبيق وحدّث العنوان لـ `http://IP-OF-YOUR-PC:5000/api`.
- **Android Emulator**: `http://10.0.2.2:5000/api` (الافتراضي).
- **ويب/سطح المكتب**: `http://localhost:5000/api`.

القيمة الافتراضية في `plumbing_store_app/lib/core/constants/app_constants.dart`.

### الـ Fallback
التطبيق مصمم ليعمل **حتى لو السيرفر مش شغال** — لو فشل الاتصال، يستخدم البيانات المحلية (mock data) تلقائياً، وممكن تجرب كل صفحاته بدون باك إند.

### قاعدة البيانات
المشروع بيستخدم MongoDB محلي (localhost:27017). لو حابب تستخدم MongoDB Atlas (سحابي)، عدّل `MONGODB_URI` في ملف `.env`.

### الصور
الصور بتتحفظ محلياً في `backend/uploads/products/`. لو حابب ترفع صور من خلال لوحة التحكم، اختر الصور من جهازك وقت إضافة/تعديل منتج.

### الكوبونات
تُطبَّق فعلياً عند إنشاء الطلب — أرسل `couponCode` في POST `/api/orders`، ويقوم الـ backend بالتحقق من الصلاحية وتطبيق الخصم (نسبة/مبلغ/شحن مجاني) وإعادته في الـ order المنشأ.

### طرق الدفع وإثبات التحويل
- **الدفع عند الاستلام (COD)**: بعد إنشاء الطلب، يُحوَّل العميل تلقائياً لواتساب المتجر لإكمال التأكيد — كما هو.
- **المسارات غير COD** (اتصالات كاش / إنستا باي / تحويل بنكي):
  1. تظهر للعميل بيانات الحساب/المحفظة المناسبة (تُجلب من `GET /api/settings/public`) مع زر نسخ الرقم.
  2. يملأ العميل "رقم اللي حوّلت منه" + الاسم (اختياري) + التاريخ + يرفع سكرين شوت إثبات التحويل.
  3. تُضغط الصورة (sharp) وتُرسل كـ Base64 مع الطلب لتُخزَّن في `order.proofImage`.
  4. يرى الأدمن في تفاصيل الطلب: رقم اللي حوّل منه + الاسم + التاريخ + صورة الإيصال (مع زر تنزيل).
  5. يبقى الطلب "قيد المراجعة" حتى يؤكده الأدمن بعد التحقق من وصول التحويل.
- لإعداد بيانات الحسابات يكفي أن يملأها الأدمن من **الإعدادات → طرق الدفع** (ستظهر تلقائياً في تطبيق العميل).
- `POST /api/orders` يقبل الآن: `proofFromNumber`, `proofFromName`, `proofImage` (Base64 dataURI), `proofDate`.

---

## 🛠️ التقنيات المستخدمة

### Backend
- **Express.js** - إطار الويب
- **MongoDB + Mongoose** - قاعدة البيانات
- **JWT** - المصادقة (json web tokens)
- **bcrypt** - تشفير الباسوردات
- **Multer** - رفع الصور (مع منع path traversal)
- **CORS** - السماح بالطلبات من مصادر مختلفة

### Mobile App
- **Flutter** - إطار العمل
- **Dart** - اللغة
- **Provider** - إدارة الحالة
- **Dio** - عميل HTTP
- **SharedPreferences** - التخزين المحلي (السلة محفوظة الآن)
- **CachedNetworkImage** - عرض الصور
- **page_transition + Hero** - انتقالات صفحات سلسة
- **google_fonts (Cairo)** - خط موحّد
- **RTL** - واجهة عربية من اليمين لليسار
- **Dark mode** فعّال عبر `app_theme.dart` الموحّد

### Admin Panel
- **HTML5 + CSS3 + Vanilla JavaScript**
- **Fetch API** للاتصال بالـ backend
- **CSS Grid + Flexbox** للتخطيط
- خط **Cairo** من Google Fonts
- **Animations**: modal fade+scale، section fade-in، count-up stats، hover-lift، skeleton loaders
- **Accessibility**: Esc-to-close, ARIA dialogs, focus restoration

---

## ₩ الأمان

### تم تطبيق
- **upload.js**: منع path traversal — مجلدات مسموحة فقط (`products`, `banners`) + التحقق من MIME type الفعلي.
- **auth middleware**: التحقق من `isActive` — مستخدم محظور لا يمكنه استخدام توكن قديم.
- **CORS تضييق**: methods + headers صريحة + `credentials` + `maxAge`.
- **Gate `?all=true`**: coupons & banners لا تكشف غير النشط إلا للأدمن فقط.
- **منع ترقية الأدوار**: الأدمن لا يمكنه تغيير دور حسابه (ضد self-lockout).
- **رفض الطلب عند نفاد المخزون** + حفظ صحيح لـ `stock=0`.
- **assistant**: تنظيف رسالة العميل من prompt injection + rate limit لكل IP + استخدام roles صحيحة في Gemini.
- **escapeHtml** في لوحة التحكم سليم ضد XSS.

### ينصح به في الإنتاج
- استبدال `JWT_SECRET` بمفتاح قوي عشوائي ومتغيّر عبر `.env` (لا تُcommitه للمستودع).
- إضافة rate-limiting حقيقي على `/api/auth/login`, `/api/register`.
- تفعيل `MONGODB_URI` لـ Atlas بدل localhost للنشر.
- إضافة `helmet` و`express-rate-limit` للنشر العام.

---

## 📄 الرخصة

هذا المشروع خاص بـ **MARCELINO** - جميع الحقوق محفوظة © 2024
