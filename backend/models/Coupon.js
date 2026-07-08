const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code: {
    type: String,
    required: [true, 'كود الكوبون مطلوب'],
    unique: true,
    uppercase: true,
    trim: true,
  },
  description: {
    type: String,
    required: [true, 'وصف الكوبون مطلوب'],
  },
  discount: {
    type: Number,
    required: [true, 'قيمة الخصم مطلوبة'],
    min: [0, 'الخصم لا يمكن أن يكون سالباً'],
  },
  type: {
    type: String,
    enum: ['percent', 'fixed', 'shipping'],
    required: true,
  },
  minOrder: {
    type: Number,
    default: 0,
  },
  expiresAt: {
    type: Date,
    required: [true, 'تاريخ الانتهاء مطلوب'],
  },
  isActive: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Coupon', couponSchema);
