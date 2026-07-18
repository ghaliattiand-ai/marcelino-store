const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// ─────────────────────────────────────────────────────────────
// كود التحقق المؤقت (OTP)
//
// اعتبارات أمنية:
//  - لا نخزّن الكود كنص صريح؛ نُشفّره بـ bcrypt.
//  - لكل رقم: كود واحد صالح فقط في كل لحظة (نحذف القديم قبل إصدار الجديد).
//  - صلاحية محدودة + حد أقصى لمحاولات الإدخال الخاطئة.
//  - TTL index يمسح المستندات القديمة تلقائياً بعد انتهاء صلاحيتها
//    لمنع تراكمها في قاعدة البيانات.
// ─────────────────────────────────────────────────────────────

const otpSchema = new mongoose.Schema(
  {
    // رقم الهاتف بصيغة دولية (مطابق لما يُرسل للتطبيق)
    phone: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    // الكود مُشفّر (bcrypt) — لا يُرجع في أي استجابة API
    codeHash: {
      type: String,
      required: true,
    },
    // عدد محاولات الإدخال الخاطئة
    attempts: {
      type: Number,
      default: 0,
    },
    // هل اتم استخدامه (verified) — عشان نمنع إعادة الاستخدام
    used: {
      type: Boolean,
      default: false,
    },
    // تاريخ انتهاء الصلاحية (UTC)
    expiresAt: {
      type: Date,
      required: true,
    },
    // وقت الإنشاء — يستخدمه TTL index لمسح المستندات القديمة
    createdAt: {
      type: Date,
      default: Date.now,
      expires: 60 * 60, // يُمسح تلقائياً بعد ساعة من الإنشاء (حتى لو فات وقت الصلاحية)
    },
  },
  { timestamps: { createdAt: true, updatedAt: true } }
);

// ── إنشاء كود عشوائي 6 أرقام + تخزين نسخته المشفّرة ──
otpSchema.statics.issueFor = async function (phone, expiryMinutes = 2) {
  // حذف أي أكواد سابقة لنفس الرقم (كود واحد صالح في كل مرة)
  await this.deleteMany({ phone });

  // توليد كود 6 أرقام (000000 - 999999) عبر crypto لضمان العشوائية
  const crypto = require('crypto');
  const n = crypto.randomInt(0, 1000000);
  const code = String(n).padStart(6, '0');

  const salt = await bcrypt.genSalt(10);
  const codeHash = await bcrypt.hash(code, salt);

  const expiresAt = new Date(Date.now() + expiryMinutes * 60 * 1000);

  await this.create({ phone, codeHash, expiresAt });
  return code; // الكود الصريح يُرجع للمتصل (اللي هيرسله عبر SMS)
};

// ── التحقق من كود أدخله المستخدم ──
// يرجع: 'valid' | 'expired' | 'max_attempts' | 'invalid' | 'not_found'
otpSchema.statics.verify = async function (phone, candidateCode, maxAttempts = 5) {
  const rec = await this.findOne({ phone }).sort({ createdAt: -1 });

  if (!rec) {
    return { status: 'not_found' };
  }

  // لو اتم استخدامه قبل كده (لا يُعاد الاستخدام)
  if (rec.used) {
    return { status: 'invalid' };
  }

  // لو انتهت صلاحيته
  if (rec.expiresAt.getTime() < Date.now()) {
    return { status: 'expired' };
  }

  // لو عدّى الحد الأقصى للمحاولات الخاطئة
  if (rec.attempts >= maxAttempts) {
    return { status: 'max_attempts' };
  }

  const isMatch = await bcrypt.compare(String(candidateCode), rec.codeHash);

  if (!isMatch) {
    rec.attempts += 1;
    // لو وصلنا للحد بعد هذه المحاولة، نُعلم الكود كمستهلك (مبطل)
    if (rec.attempts >= maxAttempts) {
      rec.used = true;
    }
    await rec.save();
    return { status: 'invalid' };
  }

  // تطابق ✓ — نُعلّمه كمُستخدم ولا يُعاد
  rec.used = true;
  await rec.save();
  return { status: 'valid' };
};

module.exports = mongoose.model('OtpCode', otpSchema);
