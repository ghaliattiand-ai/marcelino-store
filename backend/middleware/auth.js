const jwt = require('jsonwebtoken');
const User = require('../models/User');

// حماية المسارات - التحقق من التوكن
const protect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ message: 'غير مصرح، برجاء تسجيل الدخول' });
    }

    // التأكد من وجود سر التوقيع
    if (!process.env.JWT_SECRET) {
      console.error('JWT_SECRET غير معرّف في متغيرات البيئة');
      return res.status(500).json({ message: 'خطأ في إعدادات الخادم' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // نجلب المستخدم مع كلمة المرور not selected
    req.user = await User.findById(decoded.id).select('-password');

    if (!req.user) {
      return res.status(401).json({ message: 'المستخدم غير موجود' });
    }

    // منع المستخدمين المحظورين من استخدام توكن قديم ساري
    if (req.user.isActive === false) {
      return res.status(403).json({ message: 'تم حظر هذا الحساب. تواصل مع الإدارة' });
    }

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ message: 'توكن غير صالح' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'انتهت صلاحية التوكن، برجاء تسجيل الدخول مرة أخرى' });
    }
    return res.status(500).json({ message: 'خطأ في المصادقة' });
  }
};

// التحقق من صلاحيات الأدمن
const admin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    return res.status(403).json({ message: 'محظور الوصول - صلاحيات أدمن مطلوبة' });
  }
};

module.exports = { protect, admin };
