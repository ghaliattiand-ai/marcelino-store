const axios = require('axios');

// ─────────────────────────────────────────────────────────────
// خدمة إرسال SMS عبر SMS Misr (token-based API)
// توثيق: https://smsmisr.com/api/SMS
//
// الطلب: POST https://smsmisr.com/api/SMS  (JSON)
//   {
//     "environment": "1",          // 1 = إنتاج، 2 = تجريبي
//     "token":    "<SMSMISR_TOKEN>",
//     "sender":   "<SMSMISR_SENDER>",
//     "mobile":   "2<رقم بدون + أو صفر>",   // مثال: 201012345678
//     "message":  "نص الرسالة",
//     "delay":    "YYYY-MM-DD-HH-MM-SS"  // اختياري
//   }
//
// الاستجابة: نص أو JSON بأكواد مثل:
//   1900 = نجاح
//   1901 = مصدر غير مصرّح
//   1902 = رصيد غير كافٍ
//   1903 = نص فارغ
//   1904 = رقم موبايل غير صالح
//   1905 = اسم مُرسِل غير معتمد
//   1907 = تأخير زمني غير صالح
//   1908 = قيمة environment غير صحيحة
//   9999 = خطأ غير معروف
//   9993 = لا يوجد IP مصرّح به (whitelist)
// ─────────────────────────────────────────────────────────────

const SMS_API_URL = 'https://smsmisr.com/api/SMS';

function getConfig() {
  return {
    token: process.env.SMSMISR_TOKEN || '',
    sender: process.env.SMSMISR_SENDER || '',
    environment: process.env.SMSMISR_ENVIRONMENT || '1',
  };
}

/// هل خدمة الإرسال مُهيّأة (فيها token + sender)؟
function isSmsConfigured() {
  const { token, sender } = getConfig();
  return Boolean(token && sender);
}

/// يحوّل رقم الهاتف لصيغة SMS Misr المتوقعة (دولي بدون + أو صفر بادئ).
/// مثال: "+201012345678" أو "01012345678" → "201012345678"
function normalizeMobile(raw) {
  if (!raw) return '';
  let s = String(raw).replace(/[^\d]/g, '');
  if (s.startsWith('00')) s = s.slice(2);
  if (s.startsWith('+')) s = s.slice(1);
  // لو بدأ بـ 20 خلاص (مثال دولي)
  if (s.startsWith('20')) return s;
  // لو بدأ بـ 0 (محلي مصري) → نشيل الصفر ونضيف 20
  if (s.startsWith('0')) return '2' + s.slice(1);
  // غير ذلك نفتكره مصري ونضيف 20
  return '20' + s;
}

/// خرائط أكواد الاستجابة لرسائل عربية مفهومة
const CODE_MESSAGES = {
  '1900': 'تم الإرسال بنجاح',
  '1901': 'مصدر غير مصرّح به',
  '1902': 'رصيد غير كافٍ لإرسال الرسالة',
  '1903': 'نص الرسالة فارغ',
  '1904': 'رقم الموبايل غير صالح',
  '1905': 'اسم المُرسِل غير معتمد',
  '1907': 'وقت التأخير غير صالح',
  '1908': 'قيمة البيئة (environment) غير صحيحة',
  '9999': 'خطأ غير معروف من المزود',
  '9993': 'IP غير مصرّح به — أضف IP السيرفر في لوحة SMS Misr',
};

/// يُرسل رسالة SMS نصية واحدة. يرجع { ok, code, message }
async function sendSms(mobile, message) {
  const { token, sender, environment } = getConfig();

  if (!token) {
    return { ok: false, code: 'NO_TOKEN', message: 'SMSMISR_TOKEN غير مُهيّأ في .env' };
  }
  if (!sender) {
    return { ok: false, code: 'NO_SENDER', message: 'SMSMISR_SENDER غير مُهيّأ في .env' };
  }

  const to = normalizeMobile(mobile);
  if (to.length < 10) {
    return { ok: false, code: 'BAD_MOBILE', message: 'رقم الموبايل غير صالح' };
  }

  try {
    const res = await axios.post(
      SMS_API_URL,
      {
        environment: String(environment),
        token,
        sender,
        mobile: to,
        message: String(message),
      },
      { timeout: 15000, headers: { 'Content-Type': 'application/json' } }
    );

    // الاستجابة ممكن تكون JSON أو نص بكود واحد. نتعامل مع الحالتين.
    let code;
    if (typeof res.data === 'string') {
      code = res.data.trim();
    } else if (res.data && typeof res.data === 'object') {
      // بعض الردود ترجع { "code": "1900" } أو مصفوفة
      if (Array.isArray(res.data) && res.data.length > 0) {
        code = String(res.data[0]?.code ?? res.data[0] ?? '');
      } else {
        code = String(res.data.code ?? '');
      }
    }

    const ok = code === '1900';
    return {
      ok,
      code,
      message: ok ? CODE_MESSAGES['1900'] : (CODE_MESSAGES[code] || `كود الاستجابة: ${code}`),
      mobile: to,
    };
  } catch (err) {
    const status = err.response?.status;
    return {
      ok: false,
      code: 'REQUEST_ERROR',
      message: `فشل الاتصال بـ SMS Misr${status ? ` (HTTP ${status})` : ''}`,
    };
  }
}

module.exports = {
  isSmsConfigured,
  normalizeMobile,
  sendSms,
  getConfig,
};
