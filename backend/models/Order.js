const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  productId: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  imageUrl: {
    type: String,
    default: null,
  },
}, { _id: false });

const orderSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  items: [orderItemSchema],
  subtotal: {
    type: Number,
    required: true,
  },
  shipping: {
    type: Number,
    required: true,
    default: 0,
  },
  total: {
    type: Number,
    required: true,
  },
  // خصم الكوبون (إن وجد)
  discount: {
    type: Number,
    default: 0,
  },
  couponCode: {
    type: String,
    default: null,
  },
  // ===== إثبات الدفع (للمسارات غير COD) =====
  // رقم المحفظة/الحساب اللي حوّل منه العميل (مثلاً رقم فودافون كاش لي حوّل بيه)
  proofFromNumber: {
    type: String,
    default: '',
    trim: true,
  },
  // اسم صاحب اللي حوّل (اختياري)
  proofFromName: {
    type: String,
    default: '',
    trim: true,
  },
  // سكرين شوت الإثبات كـ Base64 dataURI (نخزّنه نسخة مصغّرة لتوفير مساحة)
  proofImage: {
    type: String,
    default: '',
  },
  // تاريخ التحويل (لو العميل حدّده)
  proofDate: {
    type: String,
    default: '',
    trim: true,
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'delivered', 'cancelled'],
    default: 'pending',
  },
  customerName: {
    type: String,
    default: '',
  },
  customerPhone: {
    type: String,
    default: '',
  },
  address: {
    type: String,
    default: 'القاهرة، مصر',
  },
  paymentMethod: {
    type: String,
    enum: ['cod', 'etisalat_cash', 'instapay', 'bank_transfer'],
    default: 'cod',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Order', orderSchema);
