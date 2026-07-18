const express = require('express');
const Product = require('../models/Product');
const Category = require('../models/Category');
const { protect, admin } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { filePublicUrl } = require('../middleware/upload');

const router = express.Router();

// هرب الأحرف الخاصة في regex لمنع ReDoS وتجاوز الفلاتر
function escapeRegex(str) {
  return String(str).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// @route   GET /api/products
// @access  Public
router.get('/', async (req, res) => {
  try {
    const { category_id, search, featured, page, limit } = req.query;
    const query = {};

    // فلتر بالقسم
    if (category_id) {
      query.categoryId = category_id;
    }

    // فلتر المنتجات المميزة
    if (featured === 'true') {
      query.isFeatured = true;
    }

    // البحث — نهرب النص قبل إدخاله في regex
    if (search && search.trim()) {
      const s = escapeRegex(search.trim());
      query.$or = [
        { nameAr: { $regex: s, $options: 'i' } },
        { nameEn: { $regex: s, $options: 'i' } },
        { description: { $regex: s, $options: 'i' } },
      ];
    }

    // Pagination
    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 50;
    const skip = (pageNum - 1) * limitNum;

    const products = await Product.find(query)
      .populate('categoryId', 'nameAr nameEn icon color')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    const total = await Product.countDocuments(query);

    res.json({
      products,
      total,
      page: pageNum,
      pages: Math.ceil(total / limitNum),
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ message: 'خطأ في جلب المنتجات' });
  }
});

// @route   GET /api/products/:id
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).populate('categoryId');
    if (!product) {
      return res.status(404).json({ message: 'المنتج غير موجود' });
    }
    res.json({ product });
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(404).json({ message: 'المنتج غير موجود' });
    }
    res.status(500).json({ message: 'خطأ في جلب المنتج' });
  }
});

// @route   POST /api/products
// @access  Admin
router.post('/', protect, admin, upload.array('images', 5), async (req, res) => {
  try {
    const {
      categoryId, nameAr, nameEn, description, price,
      discountPrice, stock, unit, isFeatured, rating,
      color, icon,
    } = req.body;

    // التحقق من البيانات
    if (!categoryId || !nameAr || !price || !stock) {
  return res.status(400).json({
    message: 'الحقول الأساسية مطلوبة: categoryId, nameAr, price, stock',
  });
}

    // المواصفات (JSON string)
    let specifications = {};
    if (req.body.specifications) {
      try {
        specifications = typeof req.body.specifications === 'string'
          ? JSON.parse(req.body.specifications)
          : req.body.specifications;
      } catch (_) {
        specifications = {};
      }
    }

    // الصور: URLs Cloudinary المطلقة (لو متفعّل) أو المسار النسبي للقرص المحلي
    const images = req.files
      ? req.files.map((f) => filePublicUrl(f, 'products'))
      : [];

    const product = await Product.create({
      categoryId,
      nameAr: nameAr.trim(),
nameEn: nameEn ? nameEn.trim() : '',
      description: description || '',
      price: parseFloat(price),
      discountPrice: discountPrice ? parseFloat(discountPrice) : null,
      stock: parseInt(stock),
      unit: unit || 'piece',
      isFeatured: isFeatured === 'true' || isFeatured === true,
      rating: rating ? parseFloat(rating) : 0,
      images,
      specifications,
      color: color || '#1565C0',
      icon: icon || 'inventory_2',
    });

    res.status(201).json({ product, message: 'تم إضافة المنتج بنجاح' });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ message: 'خطأ في إضافة المنتج' });
  }
});

// @route   PUT /api/products/:id
// @access  Admin
router.put('/:id', protect, admin, upload.array('images', 5), async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ message: 'المنتج غير موجود' });
    }

    const updates = { ...req.body };

    // معالجة الحقول الرقمية — نتحقق من وجود المفتاح لا صحته (لتطبيق 0)
    if (updates.price !== undefined) updates.price = parseFloat(updates.price);
    if (updates.discountPrice !== undefined && updates.discountPrice !== '') {
      updates.discountPrice = parseFloat(updates.discountPrice);
    } else if (updates.discountPrice === '') {
      updates.discountPrice = null;
    }
    if (updates.stock !== undefined) updates.stock = parseInt(updates.stock, 10);
    if (updates.rating !== undefined) updates.rating = parseFloat(updates.rating);
    if (updates.isFeatured !== undefined) {
      updates.isFeatured = updates.isFeatured === 'true' || updates.isFeatured === true;
    }

    // التحقق من وجود categoryId لو تم إرساله
    if (updates.categoryId && updates.categoryId !== product.categoryId?.toString()) {
      const Category = require('../models/Category');
      const cat = await Category.findById(updates.categoryId);
      if (!cat) {
        return res.status(400).json({ message: 'القسم غير موجود' });
      }
    }

    // المواصفات
    if (updates.specifications) {
      try {
        updates.specifications = typeof updates.specifications === 'string'
          ? JSON.parse(updates.specifications)
          : updates.specifications;
      } catch (_) {}
    }

    // الصور الجديدة - تضاف للقائمة
    if (req.files && req.files.length > 0) {
      const newImages = req.files.map((f) => filePublicUrl(f, 'products'));
      // لو حدد تحديد الصور القديمة في body.keepImages
      if (updates.keepImages) {
        try {
          const keep = JSON.parse(updates.keepImages);
          product.images = keep;
        } catch (_) {}
      }
      product.images = [...(product.images || []), ...newImages];
      delete updates.keepImages;
      delete updates.images;
    }

    // تطبيق التحديثات (نتجاهل الحقول المحمية)
    const PROTECTED = ['_id', 'createdAt', 'updatedAt', '__v'];
    Object.keys(updates).forEach((key) => {
      if (PROTECTED.includes(key)) return;
      product[key] = updates[key];
    });

    await product.save();

    res.json({ product, message: 'تم تحديث المنتج بنجاح' });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({ message: 'خطأ في تحديث المنتج' });
  }
});

// @route   DELETE /api/products/:id
// @access  Admin
router.delete('/:id', protect, admin, async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) {
      return res.status(404).json({ message: 'المنتج غير موجود' });
    }
    res.json({ message: 'تم حذف المنتج بنجاح' });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في حذف المنتج' });
  }
});

module.exports = router;
