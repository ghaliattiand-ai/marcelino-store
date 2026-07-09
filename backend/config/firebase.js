const admin = require('firebase-admin');

// نتأكد إننا بنعمل initialize مرة واحدة بس
// NOTE: firebase-admin@14 ما بيوفراش admin.apps - بنستعمل getApps() بدلها
const _isInitialized = (typeof admin.getApps === 'function')
  ? admin.getApps().length > 0
  : (Array.isArray(admin.apps) ? admin.apps.length > 0 : false);

if (!_isInitialized) {
  if (
    !process.env.FIREBASE_PROJECT_ID ||
    !process.env.FIREBASE_CLIENT_EMAIL ||
    !process.env.FIREBASE_PRIVATE_KEY
  ) {
    throw new Error(
      '❌ متغيرات Firebase ناقصة في .env — تأكد من:\n' +
      '  FIREBASE_PROJECT_ID\n  FIREBASE_CLIENT_EMAIL\n  FIREBASE_PRIVATE_KEY'
    );
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId:   process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      // الـ .env بيحفظ \n كـ نص — نحوّلها لـ newline حقيقي
      privateKey:  process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    }),
  });
}

module.exports = admin;