const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  nameAr: {
    type: String,
    required: [true, 'اسم القسم (عربي) مطلوب'],
    trim: true,
  },
  nameEn: {
  type: String,
  default: '',
  trim: true,
},
  icon: {
    type: String, // اسم الأيقونة (مثل: water_drop) — اختياري لو فيه imageUrl
    default: 'category',
  },
  color: {
    type: String, // لون hex (مثل: #1565C0)
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  imageUrl: {
    type: String, // صورة أيقونة مرفوعة من جهاز الأدمن (تظهر بدل/مع الأيقونة)
    default: null,
  },
  order: {
    type: Number,
    default: 0, // ترتيب العرض
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Category', categorySchema);
