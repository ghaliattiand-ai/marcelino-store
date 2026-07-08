const express = require('express');
const Category = require('../models/Category');
const Product = require('../models/Product');
const { protect, admin } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/categories
// @access  Public
router.get('/', async (req, res) => {
  try {
    const categories = await Category.find().sort({ order: 1, createdAt: 1 });
    res.json({ categories });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ message: 'خطأ في جلب الأقسام' });
  }
});

// @route   GET /api/categories/:id
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const category = await Category.findById(req.params.id);
    if (!category) {
      return res.status(404).json({ message: 'القسم غير موجود' });
    }
    res.json({ category });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في جلب القسم' });
  }
});

// @route   POST /api/categories
// @access  Admin
router.post('/', protect, admin, async (req, res) => {
  try {
    const { nameAr, nameEn, icon, color, description, imageUrl, order } = req.body;

    if (!nameAr || !nameEn || !icon || !color) {
      return res.status(400).json({ message: 'الحقول الأساسية مطلوبة (nameAr, nameEn, icon, color)' });
    }

    const category = await Category.create({
      nameAr, nameEn, icon, color,
      description: description || '',
      imageUrl: imageUrl || null,
      order: order || 0,
    });

    res.status(201).json({ category, message: 'تم إضافة القسم بنجاح' });
  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({ message: 'خطأ في إضافة القسم' });
  }
});

// @route   PUT /api/categories/:id
// @access  Admin
router.put('/:id', protect, admin, async (req, res) => {
  try {
    const updates = req.body;
    const category = await Category.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    );
    if (!category) {
      return res.status(404).json({ message: 'القسم غير موجود' });
    }
    res.json({ category, message: 'تم تحديث القسم بنجاح' });
  } catch (error) {
    res.status(500).json({ message: 'خطأ في تحديث القسم' });
  }
});

// @route   DELETE /api/categories/:id
// @access  Admin — نقل المنتجات لقسم افتراضي أو رفض الحذف لو فيه منتجات
router.delete('/:id', protect, admin, async (req, res) => {
  try {
    const { force } = req.query; // ?force=true للحذف مع نقل المنتجات لقسم افتراضي

    // تأكد إن القسم موجود
    const category = await Category.findById(req.params.id);
    if (!category) {
      return res.status(404).json({ message: 'القسم غير موجود' });
    }

    // احسب عدد المنتجات المرتبطة
    const productsCount = await Product.countDocuments({ categoryId: req.params.id });

    if (productsCount > 0) {
      if (force !== 'true') {
        return res.status(400).json({
          message: `لا يمكن حذف القسم لأنه يحتوي على ${productsCount} منتج. احذف المنتجات أولاً أو أضف ?force=true لنقلها لقسم "أخرى".`,
          productsCount,
        });
      }
      // ابحث عن/أنشئ قسم افتراضي "أخرى" وانقل المنتجات إليه
      let defaultCat = await Category.findOne({ nameEn: 'other' });
      if (!defaultCat || defaultCat._id.toString() === req.params.id) {
        defaultCat = await Category.create({
          nameAr: 'أخرى', nameEn: 'other', icon: 'category', color: '#607D8B',
          description: 'منتجات متنوعة', order: 999,
        });
      }
      await Product.updateMany(
        { categoryId: req.params.id },
        { $set: { categoryId: defaultCat._id } }
      );
    }

    await Category.findByIdAndDelete(req.params.id);
    res.json({
      message:
        productsCount > 0
          ? `تم حذف القسم ونقل ${productsCount} منتج لقسم "أخرى"`
          : 'تم حذف القسم بنجاح',
    });
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({ message: 'خطأ في حذف القسم' });
  }
});

module.exports = router;
