const express = require('express');
const Banner = require('../models/Banner');
const Product = require('../models/Product');
const { protect, admin } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { filePublicUrl } = require('../middleware/upload');

const router = express.Router();

// middleware يفتح ?all=1 للأدمن فقط
const adminOnlyIfAll = async (req, res, next) => {
  if (req.query.all === '1' || req.query.all === 'true') {
    const bearer = req.headers.authorization;
    if (!bearer || !bearer.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'غير مصرح لعرض كل الإعلانات' });
    }
    try {
      const jwt = require('jsonwebtoken');
      const User = require('../models/User');
      const decoded = jwt.verify(bearer.split(' ')[1], process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('-password');
      if (!user || user.role !== 'admin' || user.isActive === false) {
        return res.status(403).json({ message: 'محظور - صلاحيات أدمن مطلوبة' });
      }
      req.user = user;
    } catch (e) {
      return res.status(401).json({ message: 'توكن غير صالح' });
    }
  }
  next();
};

// @route   GET /api/banners
// @access  Public (?all=1 يتطلب أدمن)
router.get('/', adminOnlyIfAll, async (req, res) => {
  try {
    // نرجّع الإعلانات النشطة فقط مرتبة بـ order، ما لم الأدمن طلب الكل
    const onlyActive = req.query.all !== '1' && req.query.all !== 'true';
    const filter = onlyActive ? { isActive: true } : {};
    const banners = await Banner.find(filter)
      .sort({ order: 1, createdAt: 1 })
      .populate('productId', 'nameAr nameEn price images');
    res.json({ banners });
  } catch (error) {
    console.error('Get banners error:', error);
    res.status(500).json({ message: 'خطأ في جلب الإعلانات' });
  }
});

// @route   GET /api/banners/:id
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const banner = await Banner.findById(req.params.id).populate('productId');
    if (!banner) {
      return res.status(404).json({ message: 'الإعلان غير موجود' });
    }
    res.json({ banner });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب الإعلان' });
  }
});

// @route   POST /api/banners
// @access  Admin
router.post('/', protect, admin, upload.single('image'), async (req, res) => {
  try {
    const { title, subtitle, productId, order, isActive } = req.body;

    if (!title) {
      return res.status(400).json({ message: 'عنوان الإعلان مطلوب' });
    }

    // الصورة: لو مرفوعة، نستخرج URL المناسب (Cloudinary أو قرص محلي)، وإلا نستخدم رابط من body
    let imagePath = req.body.image || '';
    if (req.file) {
      imagePath = filePublicUrl(req.file, 'banners');
    }

    if (!imagePath) {
      return res.status(400).json({ message: 'صورة الإعلان مطلوبة' });
    }

    const banner = await Banner.create({
      title,
      subtitle: subtitle || '',
      image: imagePath,
      productId: productId && productId !== '' ? productId : null,
      order: order ? Number(order) : 0,
      isActive: isActive === undefined ? true : isActive === 'true' || isActive === true,
    });

    res.status(201).json({ banner, message: 'تم إضافة الإعلان بنجاح' });
  } catch (error) {
    console.error('Create banner error:', error);
    res.status(500).json({ message: 'خطأ في إضافة الإعلان' });
  }
});

// @route   PUT /api/banners/:id
// @access  Admin
router.put('/:id', protect, admin, upload.single('image'), async (req, res) => {
  try {
    const { title, subtitle, productId, order, isActive } = req.body;

    const banner = await Banner.findById(req.params.id);
    if (!banner) {
      return res.status(404).json({ message: 'الإعلان غير موجود' });
    }

    // تحديث الحقول لو موجودة في الطلب
    if (title !== undefined) banner.title = title;
    if (subtitle !== undefined) banner.subtitle = subtitle;
    if (productId !== undefined) {
      banner.productId = productId && productId !== '' ? productId : null;
    }
    if (order !== undefined) banner.order = Number(order);
    if (isActive !== undefined) {
      banner.isActive = isActive === 'true' || isActive === true;
    }
    // لو فيه صورة جديدة مرفوعة
    if (req.file) {
      banner.image = filePublicUrl(req.file, 'banners');
    } else if (req.body.image) {
      banner.image = req.body.image;
    }

    await banner.save();
    res.json({ banner, message: 'تم تحديث الإعلان بنجاح' });
  } catch (error) {
    console.error('Update banner error:', error);
    res.status(500).json({ message: 'خطأ في تحديث الإعلان' });
  }
});

// @route   DELETE /api/banners/:id
// @access  Admin
router.delete('/:id', protect, admin, async (req, res) => {
  try {
    const banner = await Banner.findByIdAndDelete(req.params.id);
    if (!banner) {
      return res.status(404).json({ message: 'الإعلان غير موجود' });
    }
    res.json({ message: 'تم حذف الإعلان بنجاح' });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في حذف الإعلان' });
  }
});

module.exports = router;
