const mongoose = require('mongoose');

// أحد استخدام التطبيق — تتبع داخلي خفيف بدون أي خدمات طرف ثالث
// نستخدمه في إحصائيات الأدمن: عدد دخول التطبيق + أكثر المنتجات مشاهدة
const appEventSchema = new mongoose.Schema({
  // نوع الحدث: app_open (فتح التطبيق) أو product_view (مشاهدة منتج)
  type: {
    type: String,
    enum: ['app_open', 'product_view'],
    required: true,
    index: true,
  },
  // المستخدم لو مسجل دخول (null للزوار)
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
    index: true,
  },
  // معرف جلسة العميل (نولّده في التطبيق ونخزنه في SharedPreferences)
  sessionId: {
    type: String,
    required: true,
    index: true,
  },
  // المنتج (في حالة product_view بس)
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    default: null,
    index: true,
  },
  // عنوان IP (للأمان وتحليل بسيط)
  ip: {
    type: String,
    default: '',
  },
  // User Agent (متسفح/جهاز)
  userAgent: {
    type: String,
    default: '',
  },
}, {
  timestamps: true,
});

// index مركّب لتجميع الأحداث حسب اليوم + النوع بسرعة
appEventSchema.index({ type: 1, createdAt: -1 });
appEventSchema.index({ productId: 1, createdAt: -1 });

module.exports = mongoose.model('AppEvent', appEventSchema);
