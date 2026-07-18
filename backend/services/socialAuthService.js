const axios = require('axios');
const { OAuth2Client } = require('google-auth-library');

// npm install google-auth-library axios   (لو axios مش متثبت أصلاً)

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

/**
 * التحقق من idToken جوجل (اللي الفلاتر بيبعته بعد نجاح تسجيل الدخول من الـ SDK)
 * وإرجاع بيانات البروفايل بشكل موحّد.
 */
async function verifyGoogleIdToken(idToken) {
  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID,
  });
  const payload = ticket.getPayload();

  return {
    providerId: payload.sub,
    email: payload.email || null,
    name: payload.name || 'مستخدم',
    avatar: payload.picture || null,
  };
}

/**
 * التحقق من accessToken فيسبوك (Graph API debug_token) وجلب بيانات البروفايل.
 */
async function verifyFacebookAccessToken(accessToken) {
  const appAccessToken = `${process.env.FACEBOOK_APP_ID}|${process.env.FACEBOOK_APP_SECRET}`;

  const debugResp = await axios.get('https://graph.facebook.com/debug_token', {
    params: { input_token: accessToken, access_token: appAccessToken },
  });
  const debugData = debugResp.data.data;

  if (!debugData.is_valid || String(debugData.app_id) !== String(process.env.FACEBOOK_APP_ID)) {
    throw new Error('Invalid Facebook token');
  }

  const profileResp = await axios.get('https://graph.facebook.com/me', {
    params: { fields: 'id,name,email,picture', access_token: accessToken },
  });
  const profile = profileResp.data;

  return {
    providerId: profile.id,
    email: profile.email || null, // ممكن تبقى null لو المستخدم رفض صلاحية الإيميل
    name: profile.name || 'مستخدم',
    avatar: profile.picture?.data?.url || null,
  };
}

function isGoogleConfigured() {
  return Boolean(process.env.GOOGLE_CLIENT_ID);
}

function isFacebookConfigured() {
  return Boolean(process.env.FACEBOOK_APP_ID && process.env.FACEBOOK_APP_SECRET);
}

module.exports = {
  verifyGoogleIdToken,
  verifyFacebookAccessToken,
  isGoogleConfigured,
  isFacebookConfigured,
};