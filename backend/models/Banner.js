const mongoose = require('mongoose');

const bannerSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'عنوان الإعلان مطلوب'],
    trim: true,
  },
  // مسار الصورة (مثل: /uploads/banners/xxx.png) أو رابط خارجي
  image: {
    type: String,
    required: [true, 'صورة الإعلان مطلوبة'],
  },
  // ربط الإعلان بمنتج معين (الضغط على الإعلان يفتح المنتج)
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    default: null,
  },
  // نص اختياري يظهر فوق الإعلان
  subtitle: {
    type: String,
    default: '',
  },
  // ترتيب العرض (الأصغر يظهر أولاً)
  order: {
    type: Number,
    default: 0,
  },
  // مفعّل أو متعطل
  isActive: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Banner', bannerSchema);
