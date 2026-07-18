const axios = require('axios');

// ─────────────────────────────────────────────────────────────
// خدمة إرسال SMS عبر SMS Misr (SMS API - form-urlencoded)
// توثيق رسمي: قسم Developers في https://smsmisr.com/
//
// الطلب الحقيقي المتوقع من الـ API (form-urlencoded مش JSON):
//   POST https://smsmisr.com/api/SMS/
//   {
//     environment: "1",   // 1 = تشغيل فعلي (بعد اعتماد الـ Sender ID)، 2 = تجريبي
//     username:    "<SMSMISR_USERNAME>",  // من صفحة Developer API بلوحة SMS Misr
//     password:    "<SMSMISR_PASSWORD>",  // من نفس الصفحة
//     sender:      "<SMSMISR_TOKEN>",     // ⚠️ ده الـ Sender Token نفسه، مش اسم المرسل النصي
//     mobile:      "2XXXXXXXXXX",         // دولي بدون + أو 00، مثال: 201152447119
//     language:    "1",                   // جرّب 1 أو 2 وشوف أنهي واحدة بتظهر عربي صح عندك
//     message:     "نص الرسالة",
//   }
//
// الاستجابة أكواد شائعة (راجعها مقابل أول رد فعلي تستلمه — بعض المصادر
// بتختلف في تحديد كود النجاح بالظبط، فاطبع raw أول مرة وتأكد):
//   1900 = نجاح (في أغلب التوثيقات المتاحة)
//   1902 = رصيد غير كافٍ   |  1903 = نص فارغ   |  1904 = رقم غير صالح
//   1905 = Sender Token غير معتمد   |  1908 = قيمة environment غلط
//   9993 = IP السيرفر مش مضاف في لوحة SMS Misr (Whitelist)
// ─────────────────────────────────────────────────────────────

const SMS_API_URL = 'https://smsmisr.com/api/SMS/';

function getConfig() {
  return {
    username: process.env.SMSMISR_USERNAME || '',
    password: process.env.SMSMISR_PASSWORD || '',
    senderToken: process.env.SMSMISR_TOKEN || '',
    environment: process.env.SMSMISR_ENVIRONMENT || '2',
    language: process.env.SMSMISR_LANGUAGE || '1',
  };
}

/// هل خدمة الإرسال مُهيّأة (username + password + sender token)؟
function isSmsConfigured() {
  const { username, password, senderToken } = getConfig();
  return Boolean(username && password && senderToken);
}

/// يحوّل رقم الهاتف لصيغة SMS Misr المتوقعة (دولي بدون + أو صفر بادئ).
/// مثال: "+201152447119" أو "01152447119" → "201152447119"
function normalizeMobile(raw) {
  if (!raw) return '';
  let s = String(raw).replace(/[^\d]/g, '');
  if (s.startsWith('00')) s = s.slice(2);
  if (s.startsWith('20')) return s; // صيغة دولية خلاص
  if (s.startsWith('0')) return '20' + s.slice(1); // محلي مصري: شيل الصفر وضيف كود الدولة كامل
  return '20' + s;
}

const CODE_MESSAGES = {
  '1900': 'تم الإرسال بنجاح',
  '1901': 'كود يحتاج تأكيد (يُفسَّر كـ"مصدر غير مصرّح" في توثيقات، وكنجاح في توثيقات تانية) — راجع الحقل raw وتأكد هل وصلت الرسالة فعليًا',
  '1902': 'رصيد غير كافٍ لإرسال الرسالة',
  '1903': 'نص الرسالة فارغ',
  '1904': 'رقم الموبايل غير صالح',
  '1905': 'الـ Sender Token غير معتمد',
  '1907': 'وقت التأخير غير صالح',
  '1908': 'قيمة البيئة (environment) غير صحيحة',
  '9999': 'خطأ غير معروف من المزود',
  '9993': 'IP غير مصرّح به — أضف IP السيرفر في لوحة SMS Misr',
};

/// يُرسل رسالة SMS نصية واحدة. يرجع { ok, code, message, mobile, raw }
async function sendSms(mobile, message) {
  const { username, password, senderToken, environment, language } = getConfig();

  if (!username || !password) {
    return {
      ok: false,
      code: 'NO_CREDENTIALS',
      message: 'SMSMISR_USERNAME أو SMSMISR_PASSWORD غير موجودين في .env — جيبهم من صفحة Developer API بلوحة SMS Misr',
    };
  }
  if (!senderToken) {
    return { ok: false, code: 'NO_SENDER_TOKEN', message: 'SMSMISR_TOKEN غير موجود في .env' };
  }

  const to = normalizeMobile(mobile);
  if (to.length < 11) {
    return { ok: false, code: 'BAD_MOBILE', message: 'رقم الموبايل غير صالح' };
  }

  const params = new URLSearchParams({
    environment: String(environment),
    username,
    password,
    sender: senderToken,
    mobile: to,
    language: String(language),
    message: String(message),
  });

  try {
    const res = await axios.post(SMS_API_URL, params, { timeout: 15000 });

    let code;
    if (typeof res.data === 'string') {
      code = res.data.trim();
    } else if (res.data && typeof res.data === 'object') {
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
      raw: res.data, // اطبعها (console.log) أول تجربة عشان تتأكد من شكل الرد الحقيقي
    };
  } catch (err) {
    const status = err.response?.status;
    return {
      ok: false,
      code: 'REQUEST_ERROR',
      message: `فشل الاتصال بـ SMS Misr${status ? ` (HTTP ${status})` : ''}`,
      raw: err.response?.data,
    };
  }
}

module.exports = {
  isSmsConfigured,
  normalizeMobile,
  sendSms,
  getConfig,
};