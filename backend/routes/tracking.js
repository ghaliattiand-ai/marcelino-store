const express = require('express');
const AppEvent = require('../models/AppEvent');

const router = express.Router();

// Rate limiting بسيط لكل IP لمنع الإغراق في إرسال الأحداث
const TRACK_WINDOW_MS = 60_000; // دقيقة
const TRACK_MAX_PER_IP = 60; // 60 حدث/دقيقة لكل IP بقيمة كافية
const trackRateMap = new Map();
function trackRateLimit(ip) {
  const now = Date.now();
  const arr = (trackRateMap.get(ip) || []).filter((t) => now - t < TRACK_WINDOW_MS);
  arr.push(now);
  trackRateMap.set(ip, arr);
  return arr.length <= TRACK_MAX_PER_IP;
}
// تنظيف دوري
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of trackRateMap.entries()) {
    const filtered = v.filter((t) => now - t < TRACK_WINDOW_MS);
    if (filtered.length === 0) trackRateMap.delete(k);
    else trackRateMap.set(k, filtered);
  }
}, TRACK_WINDOW_MS).unref?.();

// middleware اختياري لاستخراج userId من JWT لو فيه توكن (مش إجباري)
async function optionalAuth(req, _res, next) {
  try {
    const bearer = req.headers.authorization;
    if (bearer && bearer.startsWith('Bearer ')) {
      const jwt = require('jsonwebtoken');
      const User = require('../models/User');
      const decoded = jwt.verify(bearer.split(' ')[1], process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select('-password');
      if (user && user.isActive !== false) {
        req.user = user;
      }
    }
  } catch (_) {
    // أي خطأ في الـ token متتجاهل — المسار صالح للزوار
  }
  next();
}

// @route   POST /api/tracking/event
// @access  Public (يرد الموبايل أحداث استخدام — app_open / product_view)
router.post('/event', optionalAuth, async (req, res) => {
  try {
    // نستعمل req.ip (Express بتحلّه صح مع trust proxy) بدل قراءة X-Forwarded-For يدوياً
    const ip = req.ip || req.socket?.remoteAddress || 'unknown';
    if (!trackRateLimit(ip)) {
      return res.status(429).json({ message: 'كترت إرسال أحداث' });
    }

    const { type, sessionId, productId } = req.body;

    // تحقق من نوع الحدث
    if (!['app_open', 'product_view'].includes(type)) {
      return res.status(400).json({ message: 'نوع حدث غير صالح' });
    }
    if (!sessionId || typeof sessionId !== 'string' || sessionId.trim().length < 4) {
      return res.status(400).json({ message: 'sessionId مطلوب' });
    }
    // product_view لازم يبعت productId
    if (type === 'product_view' && !productId) {
      return res.status(400).json({ message: 'productId مطلوب لحدث product_view' });
    }

    await AppEvent.create({
      type,
      userId: req.user ? req.user._id : null,
      sessionId: sessionId.trim(),
      productId: type === 'product_view' ? productId : null,
      ip,
      userAgent: (req.headers['user-agent'] || '').slice(0, 250),
    });

    res.status(201).json({ ok: true });
  } catch (error) {
    // لو فيه أي خطأ، نتجاهله علشان ما نوقفش التطبيق — التتبع مش ضروري
    console.error('Tracking event error:', error.message);
    res.status(500).json({ message: 'خطأ في تسجيل الحدث' });
  }
});

module.exports = router;
