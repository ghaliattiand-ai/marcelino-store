const express = require('express');
const Coupon = require('../models/Coupon');
const { protect, admin } = require('../middleware/auth');

const router = express.Router();

// middleware يتحقق من وجود توكن أدمن صالح — يستخدم لفتح ?all=true
const adminOnlyIfRequested = async (req, res, next) => {
  if (req.query.all === 'true' || req.query.all === '1') {
    // نتحقق من التوكن يدوياً
    const bearer = req.headers.authorization;
    if (!bearer || !bearer.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'غير مصرح لعرض كل الكوبونات' });
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

// @route   GET /api/coupons
// @access  Public (العميل يشوف الصالح بس) — ?all=true يتطلب أدمن
router.get('/', adminOnlyIfRequested, async (req, res) => {
  try {
    const { all } = req.query;
    let query = { isActive: true, expiresAt: { $gt: new Date() } };
    // الأدمن فقط يقدر يشوف الكل
    if (all === 'true' || all === '1') {
      if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({ message: 'محظور' });
      }
      query = {};
    }
    const coupons = await Coupon.find(query).sort({ createdAt: -1 });
    res.json({ coupons });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب الكوبونات' });
  }
});

// @route   GET /api/coupons/:id  (للأدمن — تعديل بسيط)
// @access  Admin
router.get('/:id', protect, admin, async (req, res) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) {
      return res.status(404).json({ message: 'الكوبون غير موجود' });
    }
    res.json({ coupon });
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(404).json({ message: 'الكوبون غير موجود' });
    }
    res.status(500).json({ message: 'خطأ في جلب الكوبون' });
  }
});

// @route   POST /api/coupons/validate  (للعميل — التحقق من صلاحية كوبون قبل الطلب)
// @access  Private (أي مستخدم مسجل)
router.post('/validate', protect, async (req, res) => {
  try {
    const { code, subtotal } = req.body;
    if (!code) {
      return res.status(400).json({ message: 'أدخل كود الكوبون' });
    }
    const coupon = await Coupon.findOne({ code: code.toUpperCase() });
    if (!coupon || !coupon.isActive || coupon.expiresAt <= new Date()) {
      return res.status(400).json({ message: 'كوبون غير صالح أو منتهي' });
    }
    const orderTotal = parseFloat(subtotal) || 0;
    if (orderTotal < (coupon.minOrder || 0)) {
      return res.status(400).json({
        message: `الحد الأدنى للطلب لهذا الكوبون هو ${coupon.minOrder}ج. مطالبتك ${orderTotal}ج`,
      });
    }
    // نحسب قيمة الخصم
    let discount = 0;
    let freeShipping = false;
    if (coupon.type === 'percent') {
      discount = (orderTotal * coupon.discount) / 100;
    } else if (coupon.type === 'fixed') {
      discount = Math.min(coupon.discount, orderTotal);
    } else if (coupon.type === 'shipping') {
      freeShipping = true;
    }
    res.json({
      coupon: { _id: coupon._id, code: coupon.code, type: coupon.type, discount: coupon.discount, minOrder: coupon.minOrder },
      discount,
      freeShipping,
      message: 'تم تفعيل الكوبون',
    });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في التحقق من الكوبون' });
  }
});

// @route   POST /api/coupons
// @access  Admin
router.post('/', protect, admin, async (req, res) => {
  try {
    const { code, description, discount, type, minOrder, expiresAt } = req.body;

    if (!code || !description || !discount || !type || !expiresAt) {
      return res.status(400).json({ message: 'الحقول الأساسية مطلوبة' });
    }

    // التحقق من عدم تكرار الكود
    const existing = await Coupon.findOne({ code: code.toUpperCase() });
    if (existing) {
      return res.status(400).json({ message: 'كود الكوبون موجود بالفعل' });
    }

    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      description,
      discount: parseFloat(discount),
      type,
      minOrder: parseFloat(minOrder) || 0,
      expiresAt: new Date(expiresAt),
    });

    res.status(201).json({ coupon, message: 'تم إضافة الكوبون بنجاح' });
  } catch (error) {
    console.error('Create coupon error:', error);
    res.status(500).json({ message: 'خطأ في إضافة الكوبون' });
  }
});

// @route   PUT /api/coupons/:id
// @access  Admin
router.put('/:id', protect, admin, async (req, res) => {
  try {
    const updates = { ...req.body };
    if (updates.discount) updates.discount = parseFloat(updates.discount);
    if (updates.minOrder) updates.minOrder = parseFloat(updates.minOrder);
    if (updates.expiresAt) updates.expiresAt = new Date(updates.expiresAt);
    if (updates.code) updates.code = updates.code.toUpperCase();

    const coupon = await Coupon.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    );
    if (!coupon) {
      return res.status(404).json({ message: 'الكوبون غير موجود' });
    }
    res.json({ coupon, message: 'تم تحديث الكوبون بنجاح' });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في تحديث الكوبون' });
  }
});

// @route   DELETE /api/coupons/:id
// @access  Admin
router.delete('/:id', protect, admin, async (req, res) => {
  try {
    const coupon = await Coupon.findByIdAndDelete(req.params.id);
    if (!coupon) {
      return res.status(404).json({ message: 'الكوبون غير موجود' });
    }
    res.json({ message: 'تم حذف الكوبون بنجاح' });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في حذف الكوبون' });
  }
});

module.exports = router;
