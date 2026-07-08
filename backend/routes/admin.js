const express = require('express');
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Category = require('../models/Category');
const Coupon = require('../models/Coupon');
const Setting = require('../models/Setting');
const { protect, admin } = require('../middleware/auth');

const router = express.Router();

// كل المسارات هنا محمية بـ admin
router.use(protect, admin);

// @route   GET /api/admin/stats
router.get('/stats', async (req, res) => {
  try {
    const productsCount = await Product.countDocuments();
    const categoriesCount = await Category.countDocuments();
    const usersCount = await User.countDocuments({ role: 'customer' });
    const ordersCount = await Order.countDocuments();

    // إحصائيات الطلبات حسب الحالة
    const ordersByStatus = await Order.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);

    // إجمالي الإيرادات (من الطلبات المسلمة فقط)
    const revenue = await Order.aggregate([
      { $match: { status: { $in: ['delivered', 'processing'] } } },
      { $group: { _id: null, total: { $sum: '$total' } } },
    ]);

    // أحدث 5 طلبات
    const recentOrders = await Order.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .populate('userId', 'name phone');

    // أكثر المنتجات مبيعاً
    const topProducts = await Order.aggregate([
      { $unwind: '$items' },
      { $group: {
        _id: '$items.productId',
        name: { $first: '$items.name' },
        totalSold: { $sum: '$items.quantity' },
        revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
      }},
      { $sort: { totalSold: -1 } },
      { $limit: 5 },
    ]);

    res.json({
      productsCount,
      categoriesCount,
      usersCount,
      ordersCount,
      totalRevenue: revenue[0]?.total || 0,
      ordersByStatus: ordersByStatus.reduce((acc, item) => {
        acc[item._id] = item.count;
        return acc;
      }, {}),
      recentOrders,
      topProducts,
    });
  } catch (error) {
    console.error('Stats error:', error);
    res.status(500).json({ message: 'خطأ في جلب الإحصائيات' });
  }
});

// @route   GET /api/admin/orders
router.get('/orders', async (req, res) => {
  try {
    const { status } = req.query;
    const query = {};
    if (status) query.status = status;

    const orders = await Order.find(query)
      .sort({ createdAt: -1 })
      .populate('userId', 'name phone email');
    res.json({ orders });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب الطلبات' });
  }
});

// @route   PUT /api/admin/orders/:id/status
router.put('/orders/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    if (!['pending', 'processing', 'delivered', 'cancelled'].includes(status)) {
      return res.status(400).json({ message: 'حالة غير صحيحة' });
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );
    if (!order) {
      return res.status(404).json({ message: 'الطلب غير موجود' });
    }
    res.json({ order, message: 'تم تحديث حالة الطلب بنجاح' });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في تحديث الطلب' });
  }
});

// @route   GET /api/admin/users
router.get('/users', async (req, res) => {
  try {
    const users = await User.find({ role: 'customer' }).sort({ createdAt: -1 });
    res.json({ users });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب المستخدمين' });
  }
});

// @route   GET /api/admin/users/:id
router.get('/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'المستخدم غير موجود' });
    }
    // نجيب طلبات المستخدم
    const orders = await Order.find({ userId: user._id }).sort({ createdAt: -1 });
    res.json({ user, orders });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب بيانات المستخدم' });
  }
});

// @route   PUT /api/admin/users/:id
router.put('/users/:id', async (req, res) => {
  try {
    const { name, phone, email, role } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'المستخدم غير موجود' });
    }
    if (name !== undefined) user.name = name.trim();
    if (phone !== undefined) {
      const existing = await User.findOne({ phone: phone.trim(), _id: { $ne: user._id } });
      if (existing) {
        return res.status(400).json({ message: 'رقم الهاتف مستخدم بالفعل' });
      }
      user.phone = phone.trim();
    }
    if (email !== undefined) {
      const existing = await User.findOne({ email: email.toLowerCase().trim(), _id: { $ne: user._id } });
      if (existing) {
        return res.status(400).json({ message: 'البريد الإلكتروني مستخدم بالفعل' });
      }
      user.email = email.toLowerCase().trim();
    }
    if (role !== undefined && ['admin', 'customer'].includes(role)) {
      // منع الأدمن من ترقية نفسه/تخفيلها (ضد self-lockout)
      if (user._id.toString() === req.user._id.toString() && role !== user.role) {
        return res.status(400).json({ message: 'لا يمكنك تغيير دور حسابك' });
      }
      user.role = role;
    }
    await user.save();
    res.json({ user, message: 'تم تحديث المستخدم بنجاح' });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'خطأ في تحديث المستخدم' });
  }
});

// @route   PUT /api/admin/users/:id/block
router.put('/users/:id/block', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'المستخدم غير موجود' });
    }
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ message: 'لا يمكنك حظر حسابك' });
    }
    user.isActive = !user.isActive;
    await user.save();
    res.json({ user, message: user.isActive ? 'تم إلغاء حظر المستخدم' : 'تم حظر المستخدم' });
  } catch (error) {
    console.error('Block user error:', error);
    res.status(500).json({ message: 'خطأ في حظر المستخدم' });
  }
});

// @route   DELETE /api/admin/users/:id
router.delete('/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'المستخدم غير موجود' });
    }
    if (user._id.toString() === req.user._id.toString()) {
      return res.status(400).json({ message: 'لا يمكنك حذف حسابك' });
    }
    await user.deleteOne();
    res.json({ message: 'تم حذف المستخدم بنجاح' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'خطأ في حذف المستخدم' });
  }
});

// @route   GET /api/admin/orders/:id
router.get('/orders/:id', async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).populate('userId', 'name phone email');
    if (!order) {
      return res.status(404).json({ message: 'الطلب غير موجود' });
    }
    res.json({ order });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب الطلب' });
  }
});

// @route   GET /api/admin/analytics/sales
// تجميع المبيعات حسب اليوم/الشهر (للـ chart)
router.get('/analytics/sales', async (req, res) => {
  try {
    const { period } = req.query; // 'daily' أو 'monthly'
    const isDaily = period !== 'monthly';
    const dateFormat = isDaily ? '%Y-%m-%d' : '%Y-%m';
    const limit = isDaily ? 7 : 12;

    const startDate = new Date();
    if (isDaily) {
      startDate.setDate(startDate.getDate() - limit);
    } else {
      startDate.setMonth(startDate.getMonth() - limit);
    }

    const sales = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate }, status: { $in: ['delivered', 'processing'] } } },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$createdAt' } },
          revenue: { $sum: '$total' },
          ordersCount: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
      { $limit: limit },
    ]);

    res.json({ sales, period: isDaily ? 'daily' : 'monthly' });
  } catch (error) {
    console.error('Analytics sales error:', error);
    res.status(500).json({ message: 'خطأ في جلب تحليلات المبيعات' });
  }
});

// @route   GET /api/admin/analytics/categories
// أكثر الأقسام مبيعاً (للـ chart)
router.get('/analytics/categories', async (req, res) => {
  try {
    const top = await Order.aggregate([
      { $match: { status: { $in: ['delivered', 'processing'] } } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.productId',
          totalSold: { $sum: '$items.quantity' },
          revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
        },
      },
      { $sort: { totalSold: -1 } },
      { $limit: 100 },
    ]);

    const productIds = top.map((t) => t._id).filter(Boolean);
    const products = await Product.find({ _id: { $in: productIds } }).populate('categoryId');
    const productMap = new Map(products.map((p) => [p._id.toString(), p]));

    // تجميع حسب القسم
    const catMap = new Map();
    top.forEach((t) => {
      const p = productMap.get(t._id?.toString());
      if (!p || !p.categoryId) return;
      const catId = p.categoryId._id.toString();
      const catName = p.categoryId.nameAr;
      if (!catMap.has(catId)) {
        catMap.set(catId, { _id: catId, name: catName, totalSold: 0, revenue: 0 });
      }
      const cat = catMap.get(catId);
      cat.totalSold += t.totalSold;
      cat.revenue += t.revenue;
    });

    const categories = Array.from(catMap.values())
      .sort((a, b) => b.totalSold - a.totalSold)
      .slice(0, 6);
    res.json({ categories });
  } catch (error) {
    console.error('Analytics categories error:', error);
    res.status(500).json({ message: 'خطأ في جلب تحليلات الأقسام' });
  }
});

// @route   GET /api/admin/low-stock
// منتجات قاربت على النفاد (للتنبيهات)
router.get('/low-stock', async (req, res) => {
  try {
    const settings = await Setting.getSettings();
    const threshold = settings.lowStockThreshold || 5;
    const products = await Product.find({ stock: { $lte: threshold } })
      .sort({ stock: 1 })
      .select('nameAr nameEn stock price');
    res.json({ products, threshold });
  } catch (error) {
    console.error('Low stock error:', error);
    res.status(500).json({ message: 'خطأ في جلب المنتجات منخفضة المخزون' });
  }
});

module.exports = router;
