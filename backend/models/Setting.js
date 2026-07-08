const mongoose = require('mongoose');

const settingSchema = new mongoose.Schema({
  storeName: {
    type: String,
    default: 'MARCELINO',
    trim: true,
  },
  // رمز العملة (ج.م، ر.س، د.إ...)
  currency: {
    type: String,
    default: 'ج.م',
    trim: true,
  },
  // رسوم الشحن الافتراضية
  shippingFee: {
    type: Number,
    default: 30,
    min: 0,
  },
  // الحد اللي فوقه الشحن يبقى مجاني
  freeShippingThreshold: {
    type: Number,
    default: 500,
    min: 0,
  },
  // ملاحظة تظهر مع الشحن (مثلاً: الشحن خلال 2-4 أيام)
  shippingNote: {
    type: String,
    default: 'الشحن خلال 2-4 أيام عمل',
    trim: true,
  },
  // بيانات التواصل
  contactPhone: {
    type: String,
    default: '',
    trim: true,
  },
  contactEmail: {
    type: String,
    default: '',
    trim: true,
  },
  // حد تنبيه نفاذ المخزون (لو stock <= الحد، ننبّه الأدمن)
  lowStockThreshold: {
    type: Number,
    default: 5,
    min: 0,
  },
  // رسالة ترحيب تظهر في التطبيق/اللوحة
  welcomeMessage: {
    type: String,
    default: 'كل ما تحتاجه في مكان واحد',
    trim: true,
  },
  // ===== طرق الدفع =====
  // رقم واتساب المتجر (اللي العملاء يتبعتوا عليه تفاصيل الطلب)
  whatsappNumber: {
    type: String,
    default: '',
    trim: true,
  },
  // اتصالات كاش
  etisalatCashNumber: {
    type: String,
    default: '',
    trim: true,
  },
  etisalatCashName: {
    type: String,
    default: '',
    trim: true,
  },
  // انستا باي
  instapayHandle: {
    type: String,
    default: '',
    trim: true,
  },
  // حساب بنكي
  bankName: {
    type: String,
    default: '',
    trim: true,
  },
  bankAccountName: {
    type: String,
    default: '',
    trim: true,
  },
  bankAccountNumber: {
    type: String,
    default: '',
    trim: true,
  },
}, {
  timestamps: true,
});

// الإعدادات عبارة عن صف واحد بس (singleton). نجيبه أو نعمله لو مش موجود
settingSchema.statics.getSettings = async function () {
  let settings = await this.findOne();
  if (!settings) {
    settings = await this.create({});
  }
  return settings;
};

// تحديث الإعدادات
settingSchema.statics.updateSettings = async function (updates) {
  const settings = await this.getSettings();
  Object.assign(settings, updates);
  return settings.save();
};

module.exports = mongoose.model('Setting', settingSchema);
