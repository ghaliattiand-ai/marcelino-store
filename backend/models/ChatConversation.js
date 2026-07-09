const mongoose = require('mongoose');

// محادثة المساعد الذكي — نحفظها في الـ DB عشان العميل يقدر يرجعلها من أي جهاز
// والأدمن يقدر يشوفها من لوحة التحكم
const chatConversationSchema = new mongoose.Schema({
  // المستخدم صاحب المحادثة (null للزوار)
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
    index: true,
  },
  // معرف جلسة العميل (نولّده في التطبيق ونخزنه في SharedPreferences)
  // نستخدمه لمطابقة محادثة الزائر وربطها بحساب لما يسجل دخوله
  sessionId: {
    type: String,
    required: true,
    index: true,
  },
  // عنوان المحادثة (أول رسالة من العميل) — عشان نظهرها في قائمة المحادثات
  title: {
    type: String,
    default: 'محادثة جديدة',
  },
  // عدد الرسائل (مش حساب في كل مرة نسأل DB)
  messageCount: {
    type: Number,
    default: 0,
  },
  // المحادثة نفسها
  messages: [
    {
      role: {
        type: String,
        enum: ['user', 'assistant'],
        required: true,
      },
      text: {
        type: String,
        required: true,
      },
      // المنتجات المقترحة في رسالة المساعد
      products: [
        {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Product',
        },
      ],
      createdAt: {
        type: Date,
        default: Date.now,
      },
    },
  ],
}, {
  timestamps: true,
});

// index عشان نرتب المحادثات بآخر تحديث
chatConversationSchema.index({ updatedAt: -1 });

module.exports = mongoose.model('ChatConversation', chatConversationSchema);
