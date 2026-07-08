const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ===== Cloudinary (اختياري) =====
// لو متوفر، نرفع الصور على Cloudinary بدل القرص المحلي — مناسب بيئات النشر
// (لأن قرص Render/Railway غير دائم). لو مش متوفر، بنا fallback على القرص المحلي.
let cloudinary = null;
let cloudinaryStorage = null;
try {
  if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
    cloudinary = require('cloudinary').v2;
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
      secure: true,
    });
    const { CloudinaryStorage } = require('multer-storage-cloudinary');
    cloudinaryStorage = CloudinaryStorage;
  }
} catch (_) {
  // الحزم مش متثبتة — نشتغل بالقرص المحلي
}

// التأكد من وجود المجلد (للـ fallback على القرص)
const ensureDir = (dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
};

// المجلدات المسموح بها فقط (منع path traversal عبر req.body.folder)
const ALLOWED_FOLDERS = ['products', 'banners'];
const UPLOADS_ROOT = path.resolve(__dirname, '..', 'uploads');

// فلتر الصور — نتحقق من MIME type الحقيقي لا اسم الملف فقط
const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('صيغة الصورة غير مدعومة. استخدم JPG أو PNG أو WEBP'), false);
  }
};

let storage;
if (cloudinary && cloudinaryStorage) {
  // ===== وضع Cloudinary =====
  // نستعمل مجلد (folder) حسب req.body.folder لأنواع الصور، ونولّد public_id فريد
  storage = new cloudinaryStorage({
    cloudinary,
    params: async (req) => {
      const requested = (req.body && req.body.folder) || 'products';
      const folder = ALLOWED_FOLDERS.includes(requested) ? requested : 'products';
      const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
      return {
        folder: `marcelino/${folder}`,
        public_id: unique,
        // ن forces صيغة موحدة ونحول PNG/WEBP jpg للتوافق مع الـ URLs المستخدمة في المنتجات
        format: 'jpg',
        transformation: [{ quality: 'auto:good' }],
      };
    },
  });
} else {
  // ===== Fallback — قرص محلي (dev/lعب) =====
  storage = multer.diskStorage({
    destination: (req, file, cb) => {
      const requested = (req.body && req.body.folder) || 'products';
      const folder = ALLOWED_FOLDERS.includes(requested) ? requested : 'products';
      const dir = path.join(UPLOADS_ROOT, folder);
      const resolved = path.resolve(dir);
      if (!resolved.startsWith(UPLOADS_ROOT + path.sep) && resolved !== UPLOADS_ROOT) {
        return cb(new Error('مجلد رفع غير صالح'), false);
      }
      ensureDir(resolved);
      cb(null, resolved);
    },
    filename: (req, file, cb) => {
      const ext = '.jpg';
      const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
      cb(null, unique);
    },
  });
}

// رفع حتى 5 صور
const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB للصورة
});

// helper: يرجّع URL المناسب من ملف مرفوع (req.file / f في req.files)
// - Cloudinary: f.path هو URL مطلق
// - قرص محلي: f.filename نركّب معه المسار النسبي بنفس الشكل القديم
// نمرر folderIs  لتوليد المسار النسبي الصحيح في حال القرص المحلي
function filePublicUrl(file, folder = 'products') {
  if (file.path && /^https?:\/\//.test(file.path)) {
    // Cloudinary مجموع (URL مطلق ومؤمن)
    return file.path;
  }
  // قرص محلي — نرجّع المسار النسبي زي ما كان
  return `/uploads/${folder}/${file.filename}`;
}

module.exports = upload;
module.exports.filePublicUrl = filePublicUrl;
module.exports.isCloudinaryEnabled = !!(cloudinary && cloudinaryStorage);
