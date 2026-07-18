const express = require('express');
const Order = require('../models/Order');
const Product = require('../models/Product');
const Setting = require('../models/Setting');
const Coupon = require('../models/Coupon');
const { protect, admin } = require('../middleware/auth');

const router = express.Router();

// ضغط صورة الإثبات (Base64 data URI) كـ JPEG صغير لتوفير مساحة قاعدة البيانات
async function compressProofImage(dataUri) {
  if (!dataUri || typeof dataUri !== 'string') return '';
  const match = dataUri.match(/^data:(image\/[a-zA-Z+]+);base64,(.+)$/);
  if (!match) return '';
  try {
    const sharp = require('sharp');
    const buffer = Buffer.from(match[2], 'base64');
    const compressed = await sharp(buffer)
      .resize({ width: 1024, withoutEnlargement: true })
      .jpeg({ quality: 70 })
      .toBuffer();
    return 'data:image/jpeg;base64,' + compressed.toString('base64');
  } catch (e) {
    return dataUri.length < 600000 ? dataUri : '';
  }
}

// @route   POST /api/orders
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const {
      items, address, customerPhone, paymentMethod, couponCode,
      proofFromNumber, proofFromName, proofImage, proofDate,
    } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'السلة فارغة' });
    }

    // 1) خصم المخزون ذرياً + حساب المجموع من السيرفر
    // نستعمل findOneAndUpdate بشرط stock >= quantity لمنع overselling عند الطلبات المتزامنة.
    // لو أي منتج غير متوفر، نرجع (rollback) كل ما اتخصم قبل كده.
    let subtotal = 0;
    const serverItems = [];
    const decremented = []; // { productId, quantity } للتتبع في حال الـ rollback

    for (const item of items) {
      if (!item.productId || !item.quantity) continue;

      const product = await Product.findOneAndUpdate(
        { _id: item.productId, stock: { $gte: item.quantity } },
        { $inc: { stock: -item.quantity } },
        { new: true }
      );

      if (!product) {
        // المنتج غير موجود أو مخزونه غير كافٍ — نرجع ما اتخصم قبل كده
        for (const d of decremented) {
          await Product.updateOne({ _id: d.productId }, { $inc: { stock: d.quantity } });
        }
        const missing = await Product.findById(item.productId).select('nameAr stock');
        return res.status(400).json({
          message: 'الكمية المطلوبة غير متوفرة في المخزون',
          outOfStock: [{
            name: missing ? missing.nameAr : item.productId,
            available: missing ? missing.stock : 0,
            requested: item.quantity,
          }],
        });
      }

      decremented.push({ productId: item.productId, quantity: item.quantity });

      const unitPrice = product.discountPrice != null ? product.discountPrice : product.price;
      const lineTotal = unitPrice * item.quantity;
      subtotal += lineTotal;

      serverItems.push({
        productId: product._id,
        name: product.nameAr,
        price: unitPrice,
        quantity: item.quantity,
        imageUrl: product.images[0] || null,
      });
    }

    if (serverItems.length === 0) {
      return res.status(400).json({ message: 'لا توجد منتجات صالحة في الطلب' });
    }

    // 3) الشحن من الإعدادات بدل الأرقام الثابتة
    const storeSettings = await Setting.getSettings();
    const shippingFee = storeSettings.shippingFee != null ? storeSettings.shippingFee : 30;
    const freeThreshold = storeSettings.freeShippingThreshold != null ? storeSettings.freeShippingThreshold : 500;
    // الشحن من السيرفر فقط — العميل لا يتحكم في قيمته (منع تلاعب بالأسعار)
    let shippingCost = subtotal >= freeThreshold ? 0 : shippingFee;

    // 4) تطبيق الكوبون (إن وجد)
    let discount = 0;
    let appliedCouponCode = null;
    let freeShipping = false;
    if (couponCode) {
      const coupon = await Coupon.findOne({ code: String(couponCode).toUpperCase() });
      if (!coupon || !coupon.isActive || coupon.expiresAt <= new Date()) {
        return res.status(400).json({ message: 'كوبون غير صالح أو منتهي' });
      }
      if (subtotal < (coupon.minOrder || 0)) {
        return res.status(400).json({
          message: `الحد الأدنى للطلب لهذا الكوبون هو ${coupon.minOrder}ج`,
        });
      }
      if (coupon.type === 'percent') {
        discount = (subtotal * coupon.discount) / 100;
      } else if (coupon.type === 'fixed') {
        discount = Math.min(coupon.discount, subtotal);
      } else if (coupon.type === 'shipping') {
        freeShipping = true;
        shippingCost = 0;
      }
      appliedCouponCode = coupon.code;
    }

    const total = Math.max(0, subtotal - discount) + (freeShipping ? 0 : shippingCost);

    // التحقق من طريقة الدفع
    const validMethods = ['cod', 'etisalat_cash', 'instapay', 'bank_transfer'];
    const method = validMethods.includes(paymentMethod) ? paymentMethod : 'cod';

    // 5) إثبات الدفع للمسارات غير COD — نضغط الصورة ونحفظها
    let proofImageCompressed = '';
    if (method !== 'cod' && proofImage) {
      proofImageCompressed = await compressProofImage(proofImage);
    }

    const order = await Order.create({
      userId: req.user._id,
      items: serverItems,
      subtotal,
      shipping: shippingCost,
      discount,
      couponCode: appliedCouponCode,
      total,
      status: 'pending',
      customerName: req.user.name,
      customerPhone: customerPhone || req.user.phone,
      address: address || 'القاهرة، مصر',
      paymentMethod: method,
      // إثبات الدفع (للمسارات غير COD)
      proofFromNumber: method !== 'cod' ? String(proofFromNumber || '').trim().slice(0, 30) : '',
      proofFromName: method !== 'cod' ? String(proofFromName || '').trim().slice(0, 80) : '',
      proofImage: proofImageCompressed,
      proofDate: method !== 'cod' ? String(proofDate || '').trim().slice(0, 30) : '',
    });

    res.status(201).json({
      order,
      message: 'تم إنشاء الطلب بنجاح',
    });
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({ message: 'خطأ في إنشاء الطلب' });
  }
});

// @route   GET /api/orders
// @access  Private (طلبات المستخدم الحالي)
router.get('/', protect, async (req, res) => {
  try {
    const { status } = req.query;
    const query = { userId: req.user._id };
    if (status) query.status = status;

    const orders = await Order.find(query).sort({ createdAt: -1 });
    res.json({ orders });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب الطلبات' });
  }
});

// @route   GET /api/orders/:id
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'الطلب غير موجود' });
    }
    // التأكد إن الطلب للمستخدم الحالي (أو أدمن)
    if (order.userId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'غير مصرح' });
    }
    res.json({ order });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب الطلب' });
  }
});

module.exports = router;
