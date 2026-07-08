const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const connectDB = require('./config/db');

// الاتصال بقاعدة البيانات
connectDB();

const app = express();

// الثقة بالـ proxy العكسي (Render/Nginx) — علشان req.protocol / req.secure و IP يشتغلوا صح
app.set('trust proxy', 1);

// Middleware
// CORS: نسمح بكل المصادر (تطبيق موبايل + لوحة ويب محلية)، لكن مع إعدادات صريحة
app.use(cors({
  origin: true, // يرد على نفس Origin الطلب
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
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

// Route رئيسي للتأكد إن السيرفر شغال
app.get('/', (req, res) => {
  res.json({
    name: 'MARCELINO API',
    version: '1.0.0',
    description: 'متجر السباكة والحدايد والبويات',
    endpoints: {
      auth: '/api/auth',
      products: '/api/products',
      categories: '/api/categories',
      orders: '/api/orders',
      coupons: '/api/coupons',
      banners: '/api/banners',
      admin: '/api/admin',
    },
    adminPanel: '/admin',
  });
});

// معالج الأخطاء
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  if (err.message && err.message.includes('صيغة الصورة')) {
    return res.status(400).json({ message: err.message });
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
