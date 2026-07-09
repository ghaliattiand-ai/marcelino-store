const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const { protect, admin } = require('../middleware/auth');
const firebaseAdmin = require('../config/firebase'); // ✅ Firebase Admin

const router = express.Router();

// توليد توكن JWT
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// @route   POST /api/auth/register
// @access  Public
router.post('/register', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;

    // التحقق من البيانات
    if (!name || !email || !phone || !password) {
      return res.status(400).json({ message: 'جميع الحقول مطلوبة' });
    }
    if (name.trim().length < 3) {
      return res.status(400).json({ message: 'الاسم يجب أن يكون 3 أحرف على الأقل' });
    }
    if (phone.trim().length < 10) {
      return res.status(400).json({ message: 'رقم الهاتف قصير جداً' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' });
    }

    // التحقق من عدم وجود المستخدم
    const existingEmail = await User.findOne({ email: email.toLowerCase() });
    if (existingEmail) {
      return res.status(400).json({ message: 'البريد الإلكتروني مستخدم بالفعل' });
    }
    const existingPhone = await User.findOne({ phone: phone.trim() });
    if (existingPhone) {
      return res.status(400).json({ message: 'رقم الهاتف مستخدم بالفعل' });
    }

    // إنشاء المستخدم
    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      phone: phone.trim(),
      password,
    });

    const token = generateToken(user._id);

    res.status(201).json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        created_at: user.createdAt,
      },
      token,
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'خطأ في إنشاء الحساب' });
  }
});

// @route   POST /api/auth/login
// @access  Public
router.post('/login', async (req, res) => {
  try {
    const { email, phone, password } = req.body;

    // التطبيق يرسل email لكننا نقبل phone أو email
    const identifier = (email || phone || '').trim();

    if (!identifier || !password) {
      return res.status(400).json({ message: 'البريد/الهاتف وكلمة المرور مطلوبة' });
    }

    // البحث بالميل أو الهاتف
    let user = await User.findOne({ email: identifier.toLowerCase() }).select('+password');
    if (!user) {
      user = await User.findOne({ phone: identifier }).select('+password');
    }

    if (!user) {
      return res.status(401).json({ message: 'بيانات الدخول غير صحيحة' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'بيانات الدخول غير صحيحة' });
    }

    const token = generateToken(user._id);

    res.json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        created_at: user.createdAt,
      },
      token,
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'خطأ في تسجيل الدخول' });
  }
});

// @route   POST /api/auth/firebase-phone-login
// @desc    تسجيل دخول أو تسجيل جديد عبر Firebase Phone Auth
// @access  Public
router.post('/firebase-phone-login', async (req, res) => {
  try {
    const { firebase_token } = req.body;

    if (!firebase_token) {
      return res.status(400).json({ message: 'firebase_token مطلوب' });
    }

    // ── 1) التحقق من التوكن عبر Firebase Admin ──────────────────────────
    let decodedToken;
    try {
      decodedToken = await firebaseAdmin.auth().verifyIdToken(firebase_token);
    } catch (firebaseError) {
      console.error('Firebase token error:', firebaseError.message);
      return res.status(401).json({ message: 'توكن Firebase غير صالح أو منتهي الصلاحية' });
    }

    const { phone_number, uid } = decodedToken;

    // Firebase Phone Auth دايمًا بيبعت phone_number — لو مفيش يبقى في مشكلة
    if (!phone_number) {
      return res.status(400).json({ message: 'التوكن لا يحتوي على رقم هاتف' });
    }

    // ── 2) البحث عن المستخدم ─────────────────────────────────────────────
    let user = await User.findOne({ phone: phone_number });
    let isNewUser = false;

    if (!user) {
      // ── 3) مستخدم جديد — ننشئه ─────────────────────────────────────────
      isNewUser = true;

      // الـ email مطلوب في السكيما وفريد — نستخدم uid الفريد من Firebase
      const placeholderEmail = `${uid}@firebase.marcelino`;

      // باسورد عشوائي قوي (المستخدم مش هيستخدمه، دخوله عبر Firebase فقط)
      const randomPassword =
        Math.random().toString(36).slice(-6) +
        Math.random().toString(36).toUpperCase().slice(-4) +
        '!9';

      // الاسم المؤقت — أطول من 3 أحرف كما يشترط السكيما
      const tempName = `مستخدم ${phone_number.slice(-4)}`;

      user = await User.create({
        name: tempName,
        email: placeholderEmail,
        phone: phone_number,
        password: randomPassword,
        role: 'customer',
      });
    }

    // ── 4) التحقق من أن الحساب غير محظور ────────────────────────────────
    if (!user.isActive) {
      return res.status(403).json({ message: 'الحساب محظور، تواصل مع الدعم' });
    }

    // ── 5) توليد JWT وإرجاع الرد ─────────────────────────────────────────
    const token = generateToken(user._id);

    res.status(isNewUser ? 201 : 200).json({
      user: {
        id:         user._id,
        name:       user.name,
        email:      user.email,
        phone:      user.phone,
        role:       user.role,
        created_at: user.createdAt,
        isNewUser,            // Flutter تستخدمه لتوجيه المستخدم لإكمال بياناته
      },
      token,
    });

  } catch (error) {
    console.error('Firebase phone login error:', error);
    res.status(500).json({ message: 'خطأ في تسجيل الدخول بالهاتف' });
  }
});

// @route   POST /api/auth/logout
// @access  Private
router.post('/logout', protect, (req, res) => {
  // JWT stateless - العميل يمسح التوكن
  res.json({ message: 'تم تسجيل الخروج بنجاح' });
});

// @route   GET /api/auth/me
// @access  Private
router.get('/me', protect, (req, res) => {
  res.json({
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      phone: req.user.phone,
      role: req.user.role,
      created_at: req.user.createdAt,
    },
  });
});

// @route   PUT /api/auth/me
// @access  Private - المستخدم يعدّل بياناته (اسم، تليفون)
router.put('/me', protect, async (req, res) => {
  try {
    const { name, phone } = req.body;
    const user = req.user;

    if (name !== undefined) {
      if (name.trim().length < 3) {
        return res.status(400).json({ message: 'الاسم يجب أن يكون 3 أحرف على الأقل' });
      }
      user.name = name.trim();
    }
    if (phone !== undefined) {
      if (phone.trim().length < 10) {
        return res.status(400).json({ message: 'رقم الهاتف قصير جداً' });
      }
      // نتأكد إن التليفون مش مستخدم بواسطة حد تاني
      const existing = await User.findOne({ phone: phone.trim(), _id: { $ne: user._id } });
      if (existing) {
        return res.status(400).json({ message: 'رقم الهاتف مستخدم بالفعل' });
      }
      user.phone = phone.trim();
    }

    await user.save();
    res.json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        created_at: user.createdAt,
      },
      message: 'تم تحديث البيانات بنجاح',
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ message: 'خطأ في تحديث البيانات' });
  }
});

// @route   PUT /api/auth/change-password
// @access  Private - أي مستخدم يغيّر كلمة مروره (يحتاج القديمة + الجديدة)
router.put('/change-password', protect, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'كلمة المرور الحالية والجديدة مطلوبة' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل' });
    }

    // نجيب المستخدم بكلمة المرور
    const user = await User.findById(req.user._id).select('+password');
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'كلمة المرور الحالية غير صحيحة' });
    }

    user.password = newPassword;
    await user.save();
    res.json({ message: 'تم تغيير كلمة المرور بنجاح' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ message: 'خطأ في تغيير كلمة المرور' });
  }
});

// @route   PUT /api/auth/admin/change-password
// @access  Admin - الأدمن يغيّر كلمة مروره (نفس الـ change-password بس للأدمن)
router.put('/admin/change-password', protect, admin, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'كلمة المرور الحالية والجديدة مطلوبة' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل' });
    }
    const user = await User.findById(req.user._id).select('+password');
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'كلمة المرور الحالية غير صحيحة' });
    }
    user.password = newPassword;
    await user.save();
    res.json({ message: 'تم تغيير كلمة المرور بنجاح' });
  } catch (error) {
    console.error('Admin change password error:', error);
    res.status(500).json({ message: 'خطأ في تغيير كلمة المرور' });
  }
});

module.exports = router;