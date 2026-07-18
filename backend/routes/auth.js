const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Product = require('../models/Product');
const Order = require('../models/Order');
const OtpCode = require('../models/OtpCode');
const { isSmsConfigured, sendSms } = require('../services/smsService');
const { protect, admin } = require('../middleware/auth');

const router = express.Router();

const rateLimit = require('express-rate-limit');

// تقييد محاولات تسجيل الدخول لمنع brute-force و credential stuffing
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 دقيقة
  max: 20, // 20 محاولة لكل IP في النافذة
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'كترت محاولات الدخول، حاول بعد ربع ساعة' },
});

// تقييد إنشاء الحسابات لمنع التسجيل الجماعي/السبام
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // ساعة
  max: 10, // 10 حساب لكل IP في الساعة
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'كترت إنشاء الحسابات، حاول بعد ساعة' },
});

// تقييد إرسال أكواد التحقق لمنع الإغراق والتكلفة (SMS مدفوعة)
// 5 طلبات/ساعة لكل IP، ومثلاً 3 لكل رقم (في enforce إضافي بالرقم)
const otpSendLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // ساعة
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'كترت طلب أكواد التحقق، حاول بعد ساعة' },
});

// تقييد التحقق من الأكواد لمنع تخمينها (brute-force)
const otpVerifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 دقيقة
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'كترت محاولات التحقق، حاول بعد ربع ساعة' },
});

// توحيد رقم الهاتف قبل تخزينه/مطابقته (نستعمل صيغة E164 المصرية +201XXXXXXXXX)
function normalizePhoneForDb(raw) {
  if (!raw) return '';
  let s = String(raw).replace(/[^\d]/g, '');
  if (s.startsWith('00')) s = s.slice(2);
  if (s.startsWith('20')) return '+' + s;
  if (s.startsWith('0')) return '+2' + s;
  return '+20' + s;
}

// توليد توكن JWT
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// ─────────────────────────────────────────────────────────────
// OTP عبر SMS Misr — التحقق من رقم الهاتف عند إنشاء الحساب
// ─────────────────────────────────────────────────────────────

// @route   POST /api/auth/send-otp
// @desc    إرسال كود تحقق (6 أرقام) إلى رقم الهاتف للتسجيل
// @access  Public
router.post('/send-otp', otpSendLimiter, async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone || String(phone).trim().length < 10) {
      return res.status(400).json({ message: 'رقم هاتف غير صالح' });
    }

    const normalized = normalizePhoneForDb(phone);

    // منع إرسال OTP لرقم مسجل أصلاً (ده مسار التسجيل)
    const existing = await User.findOne({ phone: normalized });
    if (existing) {
      return res.status(400).json({ message: 'رقم الهاتف مسجل بالفعل — سجّل الدخول بدلاً من ذلك' });
    }

    // التأكد من تهيئة خدمة SMS
    if (!isSmsConfigured()) {
      return res.status(500).json({ message: 'خدمة الإرسال غير مُهيّأة — راجع SMSMISR_TOKEN و SMSMISR_SENDER' });
    }

    // توليد الكود وتخزين نسخته المشفّرة
    const expiryMin = parseInt(process.env.OTP_EXPIRY_MINUTES || '2', 10);
    const code = await OtpCode.issueFor(normalized, expiryMin);

    // إرسال SMS
    const smsText = `كود التحقق لحسابك في مارسيلينو: ${code}`;
    const result = await sendSms(normalized, smsText);

    // 🔍 تشخيص مؤقت: اطبع الرد الخام من SMS Misr في الـ logs (نجاح أو فشل)
    console.log('SMS Misr raw response:', JSON.stringify(result.raw), '| code:', result.code, '| ok:', result.ok);

    if (!result.ok) {
      // لو فشل الإرسال، نحذف الكود المخزّن عشان ما يبقاش صالح بدون استلام
      await OtpCode.deleteMany({ phone: normalized });
      return res.status(502).json({ message: `تعذّر إرسال الكود: ${result.message}` });
    }

    res.json({
      message: 'تم إرسال كود التحقق إلى رقمك',
      expiresInSeconds: expiryMin * 60,
    });
  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({ message: 'خطأ في إرسال كود التحقق' });
  }
});

// @route   POST /api/auth/verify-otp
// @desc    التحقق من كود OTP — لو صحيح يُرجع verifyToken مؤقت (10 دقائق)
//          يستخدم في خطوة إنشاء الحساب لإثبات ملكية الرقم
// @access  Public
router.post('/verify-otp', otpVerifyLimiter, async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) {
      return res.status(400).json({ message: 'رقم الهاتف والكود مطلوبان' });
    }
    const normalized = normalizePhoneForDb(phone);
    const maxAttempts = parseInt(process.env.OTP_MAX_ATTEMPTS || '5', 10);

    const result = await OtpCode.verify(normalized, code, maxAttempts);

    if (result.status !== 'valid') {
      const msg = {
        expired: 'انتهت صلاحية الكود، اطلب كود جديد',
        max_attempts: 'كترت المحاولات الخاطئة، اطلب كود جديد',
        invalid: 'الكود غير صحيح',
        not_found: 'لم يُطلب كود لهذا الرقم',
      }[result.status] || 'الكود غير صحيح';
      return res.status(400).json({ message: msg });
    }

    // إصدار verifyToken موقع (لا يمكن تزويره) يحمل الرقم المتحقَّق منه
    const verifyToken = jwt.sign(
      { phone: normalized, otpVerified: true },
      process.env.JWT_SECRET,
      { expiresIn: '10m' }
    );

    res.json({ message: 'تم التحقق من الرقم', verifyToken, verifiedPhone: normalized });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ message: 'خطأ في التحقق من الكود' });
  }
});

// @route   POST /api/auth/register
// @access  Public
router.post('/register', registerLimiter, async (req, res) => {
  try {
    const { name, email, phone, password, verifyToken } = req.body;

    // التحقق من البيانات
    if (!name || !email || !phone || !password || !verifyToken) {
      return res.status(400).json({ message: 'جميع الحقول مطلوبة بما فيها كود التحقق' });
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

    // التحقق من verifyToken (يثبت أن الرقم تم تأكيده عبر OTP)
    let decodedPhone = null;
    try {
      const decoded = jwt.verify(verifyToken, process.env.JWT_SECRET);
      if (!decoded.otpVerified) {
        return res.status(400).json({ message: 'تحقق غير صالح — أكّد الرقم أولاً' });
      }
      decodedPhone = decoded.phone;
    } catch (e) {
      return res.status(400).json({ message: 'انتهت صلاحية التحقق — أعد طلب الكود' });
    }

    // توحيد الرقم والتأكد من تطابقه مع الـ verifyToken
    const normalizedPhone = normalizePhoneForDb(phone);
    if (decodedPhone !== normalizedPhone) {
      return res.status(400).json({ message: 'رقم الهاتف لا يطابق الرقم المتحقَّق منه' });
    }

    // التحقق من عدم وجود المستخدم
    const existingEmail = await User.findOne({ email: email.toLowerCase() });
    if (existingEmail) {
      return res.status(400).json({ message: 'البريد الإلكتروني مستخدم بالفعل' });
    }
    const existingPhone = await User.findOne({ phone: normalizedPhone });
    if (existingPhone) {
      return res.status(400).json({ message: 'رقم الهاتف مستخدم بالفعل' });
    }

    // إنشاء المستخدم (نخزّن الرقم بالصيغة الموحّدة)
    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      phone: normalizedPhone,
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
router.post('/login', loginLimiter, async (req, res) => {
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