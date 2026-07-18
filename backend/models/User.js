const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'الاسم مطلوب'],
    trim: true,
    minlength: [3, 'الاسم يجب أن يكون 3 أحرف على الأقل'],
  },
  email: {
    type: String,
    required: [true, 'البريد الإلكتروني مطلوب'],
    unique: true,
    lowercase: true,
    trim: true,
  },
  phone: {
    type: String,
    // مطلوب بس لو الحساب مش جاي من جوجل/فيسبوك (تسجيل بالـ SMS التقليدي)
    required: [
      function () {
        return !this.googleId && !this.facebookId;
      },
      'رقم الهاتف مطلوب',
    ],
    unique: true,
    sparse: true, // يسمح بوجود أكتر من مستخدم من غير phone (حسابات السوشيال)
    trim: true,
  },
  password: {
    type: String,
    // مطلوب بس لو الحساب مش جاي من جوجل/فيسبوك
    required: [
      function () {
        return !this.googleId && !this.facebookId;
      },
      'كلمة المرور مطلوبة',
    ],
    minlength: [6, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'],
    select: false, // لا تُرجع كلمة المرور افتراضياً
  },
  // معرّف حساب جوجل (لو الحساب اتسجل أو اترتبط بجوجل)
  googleId: {
    type: String,
    unique: true,
    sparse: true,
  },
  // معرّف حساب فيسبوك (لو الحساب اتسجل أو اترتبط بفيسبوك)
  facebookId: {
    type: String,
    unique: true,
    sparse: true,
  },
  // صورة البروفايل (بتيجي من جوجل/فيسبوك غالبًا)
  avatar: {
    type: String,
  },
  role: {
    type: String,
    enum: ['admin', 'customer'],
    default: 'customer',
  },
  // هل الحساب نشط (غير محظور) - الأدمن يقدر يحظر/ي_cancel
  isActive: {
    type: Boolean,
    default: true,
  },
}, {
  timestamps: true,
});

// تشفير كلمة المرور قبل الحفظ
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// مقارنة كلمة المرور
userSchema.methods.comparePassword = async function(candidatePassword) {
  // حسابات السوشيال ممكن ماعندهاش password خالص
  if (!this.password) return false;
  return await bcrypt.compare(candidatePassword, this.password);
};

// إرجاع بيانات المستخدم بدون كلمة المرور
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  return obj;
};

module.exports = mongoose.model('User', userSchema);