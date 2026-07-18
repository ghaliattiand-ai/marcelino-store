const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const connectDB = require('./config/db');

// الاتصال بقاعدة البيانات
connectDB();

const app = express();

// الثقة بالـ proxy العكسي (Render/Nginx) — علشان req.protocol / req.secure و IP يشتغلوا صح
app.set('trust proxy', 1);

// ===== الأصول المسموح بها لـ CORS =====
// تطبيقات الموبايل بلا Origin تُسمح تلقائياً؛ لواحات الويب نحدد قائمة صريحة.
const corsOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

// Middleware
// CORS: نسمح بتطبيق الموبايل (بلا Origin) + لوحات الويب من الأصول المصرّح بها فقط
app.use(cors({
  origin: (origin, callback) => {
    // لا Origin = طلب موبايل/curl — نسمحه
    if (!origin) return callback(null, true);
    // لو القائمة فاضية (مش مكوّنة) نسمح بنفس الـ Origin كحل وسط آمن
    if (corsOrigins.length === 0) return callback(null, true);
    if (corsOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('غير مسموح بهذا المصدر بواسطة CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
}));

// ===== Security Headers عبر helmet =====
// نرخّص بعض الهيدرز علشان لوحة التحكم (صور/سكربتات من نفس الأصل + Cloudinary + Google Fonts)
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }, // السماح بتحميل صور المنتجات من /uploads عبر الأصل
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      // لوحة التحكم vanilla JS — نسمح بالـ inline scripts/styles الموجودة في index.html
      scriptSrc: ["'self'", "'unsafe-inline'", 'https://apis.google.com'],
      styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
      fontSrc: ["'self'", 'https://fonts.gstatic.com', 'data:'],
      imgSrc: ["'self'", 'data:', 'https:'], // صور Cloudinary + data URIs + أي https
      connectSrc: ["'self'", 'https://api.openai.com', 'https://generativelanguage.googleapis.com'],
    },
  },
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// أمان: إخفاء معلومات الخادم
app.disable('x-powered-by');

// تقديم الملفات الثابتة (صور المنتجات) — للتوافق مع الـ URLs النسبية القديمة
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// تقديم لوحة التحكم — ندعم مسارين:
//  1) admin-panel كمجلد شقيق للـ backend (dev/local)
//  2) backend/public/admin لو تم نسخها داخل مجلد الـ backend (إنتاج Render)
const adminPanelCandidates = [
  path.join(__dirname, '..', 'admin-panel'),
  path.join(__dirname, 'public', 'admin'),
];
const adminPanelDir = adminPanelCandidates.find((p) => fs.existsSync(p));
if (adminPanelDir) {
  app.use('/admin', express.static(adminPanelDir));
}

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/categories', require('./routes/categories'));
app.use('/api/products', require('./routes/products'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/coupons', require('./routes/coupons'));
app.use('/api/banners', require('./routes/banners'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/settings', require('./routes/settings'));
app.use('/api/assistant', require('./routes/assistant'));
app.use('/api/tracking', require('./routes/tracking'));

// Route رئيسي للتأكد إن السيرفر شغال (health check فقط — بلا كشف هيكل الـ API)
app.get('/', (req, res) => {
  res.json({ status: 'ok', name: 'MARCELINO API' });
});

// معالج الأخطاء
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  // أخطاء رفع الصور (multer): نوع غير مدعوم أو حجم أكبر من المسموح
  if (err.message && err.message.includes('صيغة الصورة')) {
    return res.status(400).json({ message: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ message: 'حجم الصورة كبير جداً (الحد الأقصى 5 ميجابايت)' });
  }
  res.status(500).json({ message: 'خطأ داخلي في الخادم' });
});

// 404
app.use((req, res) => {
  res.status(404).json({ message: 'المسار غير موجود' });
});

const PORT = process.env.PORT || 5000;

const upload = require('./middleware/upload');

app.listen(PORT, () => {
  console.log(`\n🚀 MARCELINO API يعمل على المنفذ ${PORT}`);
  console.log(`📌 API: http://localhost:${PORT}/api`);
  console.log(`📌 Admin: ${adminPanelDir ? `http://localhost:${PORT}/admin` : '(admin panel غير موجود — تأكد من نسخ مجلد admin-panel)'}`);
  console.log(`🖼️  Cloudinary: ${upload.isCloudinaryEnabled ? 'مفعّل (الصور تُرفع على Cloudinary)' : 'غير مفعّل — الصور تُحفظ على القرص المحلي'}\n`);
});
