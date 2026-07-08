const express = require('express');
const axios = require('axios');
const Product = require('../models/Product');
const Category = require('../models/Category');

const router = express.Router();

// اقرأ المفتاح من .env (لو موجود) - يدعم OpenAI و Gemini و DeepSeek
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY || '';

// Rate limiting بسيط في الذاكرة لمنع الإفراط في استدعاء LLM المدفوع
const RATE_WINDOW_MS = 60_000; // دقيقة
const RATE_MAX_PER_IP = 12;
const rateMap = new Map();
function rateLimit(ip) {
  const now = Date.now();
  const arr = (rateMap.get(ip) || []).filter((t) => now - t < RATE_WINDOW_MS);
  arr.push(now);
  rateMap.set(ip, arr);
  return arr.length <= RATE_MAX_PER_IP;
}
// تنظيف دوري لتفريغ الذاكرة
setInterval(() => {
  const now = Date.now();
  for (const [k, v] of rateMap.entries()) {
    const filtered = v.filter((t) => now - t < RATE_WINDOW_MS);
    if (filtered.length === 0) rateMap.delete(k);
    else rateMap.set(k, filtered);
  }
}, RATE_WINDOW_MS).unref?.();

// تنظيف رسالة العميل من محاولات prompt injection (تجريد الأوامر/الحدود)
function sanitizeUserMessage(msg) {
  if (!msg) return '';
  let cleaned = String(msg)
    // نحذف أي محاولات لتعريف دور جديد للمساعد
    .replace(/\b(ignore|disregard|forget|تجاهل|انسى|تجاهل)(\s+(all|previous|السابق|above|instructions?))?.*$/gi, ' ')
    // نحذف علامات تعليم الـ system/common في النص
    .replace(/<<<[\s\S]*?>>>/g, ' ')
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/\bsystem\b|\bassistant\b|\bdeveloper\b/gi, ' ')
    // نحد الطول لمنع إغراق النموذج
    .slice(0, 500);
  return cleaned.trim();
}

// بناء سياق المنتجات للمساعد (نقتصر على أهم 20 منتج عشان ما نboveflowش الـ tokens)
async function buildStoreContext() {
  try {
    const products = await Product.find().sort({ isFeatured: -1, rating: -1 }).limit(20).populate('categoryId');
    const categories = await Category.find().sort({ order: 1 }).limit(8);

    const ctx = {
      storeName: 'MARCELINO',
      storeDescription: 'متجر مستلزمات السباكة والحدايد والبويات',
      categories: categories.map(c => c.nameAr),
      products: products.map(p => ({
        id: p._id,
        name: p.nameAr,
        price: p.price,
        category: p.categoryId && typeof p.categoryId === 'object' ? p.categoryId.nameAr : '',
        description: (p.description || '').slice(0, 150),
      })),
    };
    return ctx;
  } catch (err) {
    console.error('buildStoreContext error:', err.message);
    return null;
  }
}

// قاعدة معرفة keywords ذكية للـ fallback (عربي)
const KNOWLEDGE_BASE = [
  { keywords: ['تقطير', 'بقطّر', 'تقطر', 'بتقطر', 'نقطة', 'ماء بتقطّر', 'ماء بتقطر', 'تقطير مية'], suggest: ['خلاط', 'صنبور', 'مضخة'], message: 'لو الحنفية بتقطّر، المشكلة غالباً في الخلاط أو الصنبور. دي المنتجات اللي ممكن تساعدك:' },
  { keywords: ['صرف', 'انسداد', 'ممسود', 'تصريف', 'بالوعة'], suggest: ['ماسورة', 'pvc', 'مضخة'], message: 'انسداد الصرف بيحتاج ماسورة PVC أو مضخة تسليك. دي الخيارات:' },
  { keywords: ['عمر', 'لمبة', 'نيون', 'انارة', 'إنارة', 'مضيئة'], suggest: ['لمبة', 'led', 'نيون'], message: 'للإضاءة، عندنا لمبات LED موفرة للكهرباء. دي الاختيارات:' },
  { keywords: ['بويا', 'دهان', 'صبغ', 'صباغ', 'طلاء', 'حايط'], suggest: ['بويا', 'فرشة', 'طلاء'], message: 'للدهانات، عندنا بويات مختلفة وفرشاتي عالية الجودة. شوف دي:' },
  { keywords: ['دريل', 'ثقب', 'حفر', 'مسمار', 'برغي'], suggest: ['دريل', 'مفك', 'مثقاب'], message: 'للحفر والتثبيت، دريل شحن أو مفك كهربائي هو الحل. شوف المنتجات:' },
  { keywords: ['صدأ', 'شريط', 'عازل', 'تسرب', 'تسريب', 'فرار'], suggest: ['شريط', 'عازل', 'ماسورة'], message: 'للتسريب والصدأ، شريط عازل كهربائي أو ماسورة جديدة ممكن تحل المشكلة. شوف:' },
  { keywords: ['سخان', 'ماء سخن', 'تسخين', 'ميه سخنة'], suggest: ['سخان', 'مضخة', 'خلاط'], message: 'مشاكل السخان غالباً تحتاج سخان جديد أو خلاط مياه. شوف:' },
  { keywords: ['حديد', 'ماسورة حديد', 'كسر', 'شق'], suggest: ['ماسورة', 'حديد'], message: 'لو ال MASORA مكسورة، محتاجة ماسورة حديد جديدة. شوف الخيارات:' },
];

function fallbackResponse(userMessage, products) {
  const msg = (userMessage || '').toLowerCase();
  let matched = null;
  for (const item of KNOWLEDGE_BASE) {
    if (item.keywords.some(k => msg.includes(k))) {
      matched = item;
      break;
    }
  }
  if (!matched) {
    return {
      message: 'أهلاً! أنا مساعد متجر MARCELINO. أحتاج أعرف مشكلتك بالتفصيل. مثلاً: "الحنفية بتقطّر" أو "محتاج بويا للحيط" أو "الصرف ممسود".',
      products: [],
    };
  }
  // نفلتر المنتجات ب keywords matching
  const matchedProducts = (products || []).filter(p =>
    matched.suggest.some(s => (p.name || '').toLowerCase().includes(s) || (p.description || '').toLowerCase().includes(s))
  ).slice(0, 4);
  return {
    message: matched.message,
    products: matchedProducts,
  };
}

// استدعاء OpenAI
async function callOpenAI(userMessage, storeContext) {
  const systemPrompt = `أنت مساعد ذكي لمتجر اسمه "${storeContext.storeName}" (${storeContext.storeDescription}).
ضعف: تفهم مشكلة العميل بالعربي المصري/الفصحى، وتقترح المنتجات المناسبة من المتجر.
أدوارك:
1. احيّ العميل باختصار ولباقة.
2. اسأله عن تفاصيل المشكلة لو سهلة.
3. ردّ بطريقة نظيفة بسيطة بدون إطالة (3-4 جمل).
4. لو فيه منتجات تناسب المشكلة: رد في JSON بالشكل ده بالظبط:
{"message": "نص الرد للعميل بالعربي", "productIds": ["id1","id2",...]}
5. لو مفيش منتجات مناسبة، رد في JSON بالشكل ده:
{"message": "نص الرد", "productIds": []}

سيرفع لك بيانات المنتجات المتاحة في المتجر (id, name, price, category, description). اختار بس المنتجات اللي فعلاً تساعد في حل المشكلة. maximum 4 منتجات.

السياق: المنتجات المتاحة: ${JSON.stringify(storeContext.products)}
الأقسام: ${storeContext.categories.join(', ')}`;

  const res = await axios.post(
    'https://api.openai.com/v1/chat/completions',
    {
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
      temperature: 0.5,
      max_tokens: 400,
    },
    {
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
    }
  );
  const content = res.data?.choices?.[0]?.message?.content?.trim() || '';
  try {
    // نحاول parse JSON
    const parsed = JSON.parse(content);
    return parsed;
  } catch (_) {
    // لو الـ model رد نص مش JSON، نرجعه زي ما هو
    return { message: content, productIds: [] };
  }
}

// استدعاء Gemini — نستخدم roles الصحيحة (system:user:instruction) بدل دمج رسالة العميل في النص
async function callGemini(userMessage, storeContext) {
  const systemInstruction = `أنت مساعد ذكي لمتجر اسمه "${storeContext.storeName}" (${storeContext.storeDescription}).
ردّ بالعربي المصري/الفصحى بسيطة (3-4 جمل).
مهم: لازم تردّ دايماً بصيغة JSON صحيحة فقط بدون أي نص إضافي قبلها أو بعدها.
الصيغة المطلوبة بالظبط:
{"message": "نص الرد للعميل بالعربي", "productIds": ["id1", "id2"]}

لو مفيش منتجات مناسبة، رد:
{"message": "نص الرد", "productIds": []}

اليك قائمة المنتجات المتاحة في المتجر (استعمل الـ id فقط في productIds):
${JSON.stringify(storeContext.products.map(p=>({id:p.id,name:p.name,price:p.price,category:p.category})))}

اختار بس المنتجات اللي فعلاً تساعد في حل المشكلة، حد أقصى ٤ منتجات. لو مفيش، رجّع productIds فاضي.`;

  const res = await axios.post(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
    {
      system_instruction: { parts: [{ text: systemInstruction }] },
      contents: [{ role: 'user', parts: [{ text: userMessage }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 1024, responseMimeType: 'application/json' },
    },
    { timeout: 20000 }
  );
  const content = res.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';
  // الموديلات بترجع JSON أحياناً متغطاة بـ ```json ... ``` أو فيها علامات شرط زايدة.
  // نطهّر الرد ونحاول نلقط الجزء اللي بين أول { وآخر }
  function safeParse(text) {
    let t = String(text).trim();
    // نشيل أكواد markdown لو موجودة
    t = t.replace(/```json/gi, '').replace(/```/g, '').trim();
    // نلقط أول { لآخر }
    const first = t.indexOf('{');
    const last = t.lastIndexOf('}');
    if (first !== -1 && last !== -1 && last > first) {
      t = t.slice(first, last + 1);
    }
    try {
      return JSON.parse(t);
    } catch (_) {
      // لو فيه علامات تنصيص زايدة (escaped)، نشيلها ونجرب تاني
      try {
        const cleaned = t.replace(/\\"/g, '"').replace(/\\n/g, ' ');
        return JSON.parse(cleaned);
      } catch (_) {
        return null;
      }
    }
  }
  const parsed = safeParse(content);
  if (parsed && (parsed.message || parsed.productIds)) {
    return parsed;
  }
  // لو مفيش JSON مفهوم، نرجّع النص كرسالة عادية
  return { message: content.replace(/[{}[\]"]/g, '').trim() || 'أهلاً بك', productIds: [] };
}

// استدعاء DeepSeek
async function callDeepSeek(userMessage, storeContext) {
  const systemPrompt = `أنت مساعد ذكي لمتجر "${storeContext.storeName}" - ${storeContext.storeDescription}. ردّ بالعربي بسيط (3-4 جمل). لو فيه منتجات مناسبة، رد JSON بالشكل: {"message":"...","productIds":["id1"...]}. المنتجات المتاحة: ${JSON.stringify(storeContext.products.map(p=>({id:p.id,name:p.name,price:p.price})))}`;
  const res = await axios.post(
    'https://api.deepseek.com/v1/chat/completions',
    {
      model: 'deepseek-chat',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
      temperature: 0.5,
      max_tokens: 400,
    },
    {
      headers: { 'Authorization': `Bearer ${DEEPSEEK_API_KEY}`, 'Content-Type': 'application/json' },
      timeout: 15000,
    }
  );
  const content = res.data?.choices?.[0]?.message?.content?.trim() || '';
  try {
    return JSON.parse(content);
  } catch (_) {
    return { message: content, productIds: [] };
  }
}

// @route   POST /api/assistant/message
// @access  Public (العميل بيدخل مشكلته)
router.post('/message', async (req, res) => {
  try {
    // rate limit بسيط لكل IP
    const ip = (req.headers['x-forwarded-for'] || req.socket?.remoteAddress || 'unknown').toString().split(',')[0].trim();
    if (!rateLimit(ip)) {
      return res.status(429).json({ message: 'كترت رسايل، حاول بعد دقيقة' });
    }

    const { message } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ message: 'اكتب مشكلتك الأول' });
    }

    // تنظيف رسالة العميل من محاولات prompt injection
    const safeMessage = sanitizeUserMessage(message);

    // نبني سياق المنتجات (لو DB مش شغالة، نكمل بالـ fallback)
    const storeContext = await buildStoreContext().catch(() => null);

    let aiResponse = null;
    let usedLLM = null;
    const storeProducts = storeContext ? storeContext.products : [];

    // نجرب كل LLMs بالترتيب (لو فيه مفتاح + سياق متاح)
    try {
      if (OPENAI_API_KEY && storeContext) {
        aiResponse = await callOpenAI(safeMessage, storeContext);
        usedLLM = 'openai';
      } else if (GEMINI_API_KEY && storeContext) {
        aiResponse = await callGemini(safeMessage, storeContext);
        usedLLM = 'gemini';
      } else if (DEEPSEEK_API_KEY && storeContext) {
        aiResponse = await callDeepSeek(safeMessage, storeContext);
        usedLLM = 'deepseek';
      }
    } catch (err) {
      console.error('LLM error:', err.message);
      // لو في خطأ، نستخدم الـ fallback
    }

    // نجهّز المنتجات النهائية
    let finalMessage = '';
    let finalProducts = [];

    if (aiResponse && aiResponse.message) {
      finalMessage = aiResponse.message;
      // لو الـ AI رجع productIds، نختار المنتجات بـ IDs
      if (aiResponse.productIds && aiResponse.productIds.length > 0) {
        finalProducts = storeProducts
          .filter(p => aiResponse.productIds.includes(p.id))
          .slice(0, 4);
      } else if (usedLLM) {
        // لو مفيش productIds (fallback للنص)، نبحث بالـ keywords في الرد
        const words = finalMessage.split(/\s+/).filter(w => w.length > 3);
        finalProducts = storeProducts.filter(p =>
          words.some(w => (p.name || '').includes(w) || (p.description || '').includes(w))
        ).slice(0, 4);
      }
    } else {
      // fallback محلي
      const fb = fallbackResponse(safeMessage, storeProducts);
      finalMessage = fb.message;
      finalProducts = fb.products.map(p => ({
        id: p.id,
        name: p.name,
        price: p.price,
        category: p.category,
        description: p.description,
      }));
    }

    // ننسّق المنتجات بنفس الصيغة اللي Flutter بيتوقعها
    const productsForApp = finalProducts.map(p => {
      // لو المنتج من buildStoreContext نعيد query الصورة
      return {
        _id: p.id,
        nameAr: p.name,
        price: p.price,
        description: p.description || '',
        category: p.category || '',
      };
    });

    // لو في matching، نجيب بيانات المنتجات كاملة من DB عشان نرفق الصور
    if (finalProducts.length > 0) {
      const ids = finalProducts.map(p => p.id);
      const fullProducts = await Product.find({ _id: { $in: ids } })
        .populate('categoryId')
        .select('nameAr nameEn price discountPrice images description icon color categoryId');
      return res.json({
        message: finalMessage,
        products: fullProducts,
        usedLLM: usedLLM || 'fallback',
      });
    }

    res.json({
      message: finalMessage,
      products: [],
      usedLLM: usedLLM || 'fallback',
    });
  } catch (error) {
    console.error('Assistant error:', error);
    res.status(500).json({ message: 'حصل خطأ، حاول تاني' });
  }
});

module.exports = router;
