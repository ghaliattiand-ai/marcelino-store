const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: [true, 'القسم مطلوب'],
  },
  nameAr: {
    type: String,
    required: [true, 'اسم المنتج (عربي) مطلوب'],
    trim: true,
  },
  nameEn: {
    type: String,
    required: [true, 'اسم المنتج (إنجليزي) مطلوب'],
    trim: true,
  },
  description: {
    type: String,
    default: '',
  },
  price: {
    type: Number,
    required: [true, 'السعر مطلوب'],
    min: [0, 'السعر يجب أن يكون موجباً'],
  },
  discountPrice: {
    type: Number,
    min: [0, 'سعر الخصم يجب أن يكون موجباً'],
    default: null,
  },
  stock: {
    type: Number,
    required: [true, 'الكمية مطلوبة'],
    min: [0, 'الكمية لا يمكن أن تكون سالبة'],
    default: 0,
  },
  unit: {
    type: String,
    enum: ['piece', 'meter', 'kg', 'liter', 'gallon', 'box', 'pack', 'set'],
    default: 'piece',
  },
  isFeatured: {
    type: Boolean,
    default: false,
  },
  images: {
    type: [String],
    default: [],
  },
  rating: {
    type: Number,
    min: 0,
    max: 5,
    default: 0,
  },
  specifications: {
    type: Map,
    of: String,
    default: {},
  },
  color: {
    type: String, // لون hex للعرض في التطبيق
    default: '#1565C0',
  },
  icon: {
    type: String, // اسم الأيقونة
    default: 'inventory_2',
  },
}, {
  timestamps: true,
});

// Index للبحث
productSchema.index({ nameAr: 'text', nameEn: 'text', description: 'text' });

// computed: السعر الفعلي
productSchema.virtual('effectivePrice').get(function() {
  return this.discountPrice != null ? this.discountPrice : this.price;
});

productSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Product', productSchema);
