const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User');
const Category = require('../models/Category');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Coupon = require('../models/Coupon');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/marcelino_store';

// نصدّر الدالة عشان نقدر نستدعيها من مسار داخل السيرفر (زرع عن بعد لو القاعدة بتعاند من جهازك)
const seedData = async () => {
  try {
    console.log('🔌 جاري الاتصال بـ MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ متصل');

    // مسح البيانات القديمة
    console.log('\n🧹 مسح البيانات القديمة...');
    await Promise.all([
      User.deleteMany({}),
      Category.deleteMany({}),
      Product.deleteMany({}),
      Order.deleteMany({}),
      Coupon.deleteMany({}),
    ]);
    console.log('✅ تم المسح');

    // 1) المستخدمون
    console.log('\n👥 إضافة المستخدمين...');
    const admin = await User.create({
      name: 'Admin Marcell',
      email: 'admin@marcelino.com',
      phone: '01110140517',
      password: 'sameh123',
      role: 'admin',
    });

    const ahmed = await User.create({
      name: 'أحمد محمد',
      email: 'ahmed@example.com',
      phone: '01012345678',
      password: '123456',
      role: 'customer',
    });

    const sara = await User.create({
      name: 'سارة علي',
      email: 'sara@example.com',
      phone: '01123456789',
      password: '123456',
      role: 'customer',
    });
    console.log('✅ 3 مستخدمين (1 أدمن + 2 عملاء)');

    // 2) الأقسام
    console.log('\n📂 إضافة الأقسام...');
    const categories = await Category.insertMany([
      { nameAr: 'سباكة', nameEn: 'Plumbing', icon: 'water_drop', color: '#1565C0', description: 'مستلزمات السباكة والصرف', order: 1 },
      { nameAr: 'كهرباء', nameEn: 'Electrical', icon: 'flash_on', color: '#F57F17', description: 'أدوات ومعدات كهربائية', order: 2 },
      { nameAr: 'عدد وأدوات', nameEn: 'Tools', icon: 'handyman', color: '#6A1B9A', description: 'أدوات تشغيل احترافية', order: 3 },
      { nameAr: 'دهانات', nameEn: 'Paints', icon: 'format_paint', color: '#2E7D32', description: 'بويات ودهانات', order: 4 },
      { nameAr: 'أدوات يدوية', nameEn: 'Hand Tools', icon: 'construction', color: '#880E4F', description: 'أدوات يدوية متنوعة', order: 5 },
      { nameAr: 'مواد بناء', nameEn: 'Building', icon: 'home_repair_service', color: '#4E342E', description: 'مواد البناء والإنشاء', order: 6 },
      { nameAr: 'معدات', nameEn: 'Equipment', icon: 'precision_manufacturing', color: '#00695C', description: 'معدات احترافية', order: 7 },
      { nameAr: 'أكثر', nameEn: 'More', icon: 'more_horiz', color: '#546E7A', description: 'منتجات متنوعة', order: 8 },
    ]);
    console.log('✅ 8 أقسام');

    // 3) المنتجات
    console.log('\n📦 إضافة المنتجات...');
    const products = await Product.insertMany([
      {
        categoryId: categories[0]._id,
        nameAr: 'مضخة ماء أوتوماتيك 1 حصان',
        nameEn: 'Automatic Water Pump 1 HP',
        description: 'مضخة مياه أوتوماتيك بقوة 1 حصان، مناسبة للمنازل والفلل، ضغط قوي وأداء مستقر.',
        price: 1250, stock: 24, unit: 'piece', isFeatured: true, rating: 4.8,
        images: ['https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=800'],
        specifications: { 'القوة': '1 حصان', 'الجهد': '220 فولت', 'الاستهلاك': '750 واط', 'الضمان': 'سنتان' },
        color: '#1565C0', icon: 'water_drop',
      },
      {
        categoryId: categories[0]._id,
        nameAr: 'خلاط حوض ستانلس',
        nameEn: 'Stainless Sink Mixer',
        description: 'خلاط حوض مطبخ ستانلس ستيل، تصميم عصري مع رأس قابل للسحب.',
        price: 650, stock: 40, unit: 'piece', isFeatured: false, rating: 4.6,
        images: ['https://images.unsplash.com/photo-1607414496173-1e4f8cd4b8f8?w=800'],
        specifications: { 'المادة': 'ستانلس ستيل 304', 'اللون': 'فضي', 'الضمان': '5 سنوات' },
        color: '#1565C0', icon: 'water_drop',
      },
      {
        categoryId: categories[2]._id,
        nameAr: 'دريل شحن 21 فولت',
        nameEn: '21V Cordless Drill',
        description: 'دريل شحن لاسلكي 21 فولت، 2 بطارية، عزم قابل للتعديل، مناسب لجميع الأعمال.',
        price: 1100, stock: 15, unit: 'piece', isFeatured: true, rating: 4.7,
        images: ['https://images.unsplash.com/photo-1504148455659-2b0d2f3a4f7c?w=800'],
        specifications: { 'الجهد': '21 فولت', 'السرعة': '0-1500 RPM', 'البطاريات': '2' },
        color: '#6A1B9A', icon: 'handyman',
      },
      {
        categoryId: categories[0]._id,
        nameAr: 'ماسورة PVC 4 بوصة',
        nameEn: '4" PVC Pipe',
        description: 'ماسورة PVC قطر 4 بوصة لصرف المياه، مقاومة للتآكل والصدأ.',
        price: 75, discountPrice: 60, stock: 200, unit: 'meter', isFeatured: false, rating: 4.4,
        images: ['https://images.unsplash.com/photo-1581094288338-e5e7e7f8b5c1?w=800'],
        specifications: { 'القطر': '4 بوصة', 'الطول': '6 متر', 'المادة': 'PVC' },
        color: '#1565C0', icon: 'water_drop',
      },
      {
        categoryId: categories[3]._id,
        nameAr: 'فرشة بويا مقاس 4',
        nameEn: '4" Paint Brush',
        description: 'فرشة بويا مقاس 4 إنش، شعيرات صناعية عالية الجودة، مناسبة لجميع أنواع الدهانات.',
        price: 45, stock: 80, unit: 'piece', isFeatured: false, rating: 4.2,
        images: ['https://images.unsplash.com/photo-1562259929-b4134b9f3f93?w=800'],
        specifications: { 'المقاس': '4 إنش', 'النوع': 'شعيرات صناعية' },
        color: '#2E7D32', icon: 'format_paint',
      },
      {
        categoryId: categories[2]._id,
        nameAr: 'مفك براغي كهربائي',
        nameEn: 'Electric Screwdriver',
        description: 'مفك براغي كهربائي يعمل بالبطارية، خفيف الوزن وسهل الاستخدام.',
        price: 320, stock: 30, unit: 'piece', isFeatured: false, rating: 4.5,
        images: ['https://images.unsplash.com/photo-1530124566582-a3bc27df4f7c?w=800'],
        specifications: { 'الجهد': '3.6 فولت', 'الوزن': '0.5 كجم', 'العزم': '5 N.m' },
        color: '#6A1B9A', icon: 'handyman',
      },
      {
        categoryId: categories[1]._id,
        nameAr: 'عازل كهربائي 10 متر',
        nameEn: '10m Electrical Tape',
        description: 'شريط عازل كهربائي بولي فينيل chloride، عازل ممتاز للكهرباء، مقاوم للحرارة.',
        price: 85, stock: 60, unit: 'pack', isFeatured: false, rating: 4.3,
        images: ['https://images.unsplash.com/photo-16219054175909-7ce2e0d4f8c2?w=800'],
        specifications: { 'الطول': '10 متر', 'العرض': '18 مم', 'اللون': 'متعدد' },
        color: '#F57F17', icon: 'flash_on',
      },
      {
        categoryId: categories[5]._id,
        nameAr: 'ماسورة حديد 1 بوصة',
        nameEn: '1" Iron Pipe',
        description: 'ماسورة حديد مجلفن قطر 1 بوصة، مقاومة للصدأ والتآكل.',
        price: 180, discountPrice: 150, stock: 150, unit: 'meter', isFeatured: false, rating: 4.1,
        images: ['https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=800'],
        specifications: { 'القطر': '1 بوصة', 'الطول': '6 متر', 'النوع': 'مجلفن' },
        color: '#4E342E', icon: 'home_repair_service',
      },
      {
        categoryId: categories[0]._id,
        nameAr: 'صنبور مطبخ ستانلس',
        nameEn: 'Stainless Kitchen Faucet',
        description: 'صنبور مطبخ عالي النوع ستانلس ستيل، خرطوم مرن وجسم متين.',
        price: 350, stock: 35, unit: 'piece', isFeatured: true, rating: 4.7,
        images: ['https://images.unsplash.com/photo-1607414496173-1e4f8cd4b8f8?w=800'],
        specifications: { 'المادة': 'ستانلس 304', 'اللون': 'فضي' },
        color: '#1565C0', icon: 'water_drop',
      },
      {
        categoryId: categories[1]._id,
        nameAr: 'لمبة LED 15 وات',
        nameEn: '15W LED Bulb',
        description: 'لمبة LED 15 وات، إضاءة عالية ووفرة في الطاقة، عمر افتراضي طويل.',
        price: 25, stock: 100, unit: 'piece', isFeatured: false, rating: 4.6,
        images: ['https://images.unsplash.com/photo-1565814329452-e1efa11c5b87?w=800'],
        specifications: { 'القدرة': '15 وات', 'اللون': 'أبيض دافئ', 'العمر': '25000 ساعة' },
        color: '#F57F17', icon: 'flash_on',
      },
      {
        categoryId: categories[2]._id,
        nameAr: 'شريط قياس 5 متر',
        nameEn: '5m Tape Measure',
        description: 'شريط قياس 5 متر مع قفل أوتوماتيك وكلاب تثبيت قوية.',
        price: 45, stock: 55, unit: 'piece', isFeatured: false, rating: 4.4,
        images: ['https://images.unsplash.com/photo-1607414496173-1e4f8cd4b8f8?w=800'],
        specifications: { 'الطول': '5 متر', 'العرض': '25 مم' },
        color: '#6A1B9A', icon: 'handyman',
      },
      {
        categoryId: categories[3]._id,
        nameAr: 'بوية بيضاء 5 لتر',
        nameEn: '5L White Paint',
        description: 'بوية بلاستيك بيضاء، تغطية ممتازة، خالية من الرصاص، رائحة منخفضة.',
        price: 120, stock: 45, unit: 'gallon', isFeatured: false, rating: 4.5,
        images: ['https://images.unsplash.com/photo-1562259929-b4134b9f3f93?w=800'],
        specifications: { 'الحجم': '5 لتر', 'النوع': 'بلاستيك', 'اللون': 'أبيض' },
        color: '#2E7D32', icon: 'format_paint',
      },
      {
        categoryId: categories[4]._id,
        nameAr: 'مطرقة ثقيلة 1.5 كجم',
        nameEn: '1.5kg Heavy Hammer',
        description: 'مطرقة ثقيلة بدون ريطة وزن 1.5 كجم، مقبض مطاطي مضاد للانزلاق.',
        price: 60, stock: 70, unit: 'piece', isFeatured: false, rating: 4.0,
        images: ['https://images.unsplash.com/photo-1530124566582-a3bc27df4f7c?w=800'],
        specifications: { 'الوزن': '1.5 كجم', 'المقبض': 'مطاطي' },
        color: '#880E4F', icon: 'construction',
      },
    ]);
    console.log('✅ 13 منتج');

    // 4) الكوبونات
    console.log('\n🎟️ إضافة الكوبونات...');
    const now = new Date();
    await Coupon.insertMany([
      {
        code: 'MARCEL20',
        description: 'خصم 20% على جميع المنتجات',
        discount: 20, type: 'percent', minOrder: 0,
        expiresAt: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
      {
        code: 'SAMEH50',
        description: 'خصم 50 جنيه على الطلبات فوق 300',
        discount: 50, type: 'fixed', minOrder: 300,
        expiresAt: new Date(now.getTime() + 15 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
      {
        code: 'FREESHIP',
        description: 'شحن مجاني لأي طلب',
        discount: 0, type: 'shipping', minOrder: 0,
        expiresAt: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
      {
        code: 'WELCOME10',
        description: 'خصم ترحيبي 10% للعملاء الجدد',
        discount: 10, type: 'percent', minOrder: 100,
        expiresAt: new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
      {
        code: 'TOOLS30',
        description: 'خصم 30 جنيه على الأدوات اليدوية',
        discount: 30, type: 'fixed', minOrder: 200,
        expiresAt: new Date(now.getTime() + 45 * 24 * 60 * 60 * 1000),
        isActive: true,
      },
      {
        code: 'SUMMER15',
        description: 'عرض صيفي منتهي',
        discount: 15, type: 'percent', minOrder: 200,
        expiresAt: new Date(now.getTime() - 24 * 60 * 60 * 1000),
        isActive: false,
      },
    ]);
    console.log('✅ 6 كوبونات');

    // 5) طلبات تجريبية
    console.log('\n🛒 إضافة طلبات تجريبية...');
    await Order.create({
      userId: ahmed._id,
      items: [
        { productId: products[0]._id, name: products[0].nameAr, price: 1250, quantity: 1, imageUrl: products[0].images[0] },
        { productId: products[2]._id, name: products[2].nameAr, price: 1100, quantity: 1, imageUrl: products[2].images[0] },
        { productId: products[9]._id, name: products[9].nameAr, price: 25, quantity: 2, imageUrl: products[9].images[0] },
      ],
      subtotal: 2800, shipping: 0, total: 2800,
      status: 'delivered',
      customerName: 'أحمد محمد', customerPhone: '01012345678',
      address: 'القاهرة، مدينة نصر',
    });

    await Order.create({
      userId: sara._id,
      items: [
        { productId: products[1]._id, name: products[1].nameAr, price: 650, quantity: 1, imageUrl: products[1].images[0] },
        { productId: products[8]._id, name: products[8].nameAr, price: 350, quantity: 1, imageUrl: products[8].images[0] },
        { productId: products[11]._id, name: products[11].nameAr, price: 120, quantity: 1, imageUrl: products[11].images[0] },
      ],
      subtotal: 1120, shipping: 30, total: 1150,
      status: 'processing',
      customerName: 'سارة علي', customerPhone: '01123456789',
      address: 'الجيزة، الهرم',
    });
    console.log('✅ 2 طلبات تجريبية');

    console.log('\n🎉 تم بنجاح! البيانات جاهزة');
    console.log('\n📋 بيانات الدخول:');
    console.log('  👑 Admin: phone=01110140517, password=sameh123');
    console.log('  👤 Customer 1: phone=01012345678, password=123456');
    console.log('  👤 Customer 2: phone=01123456789, password=123456');

    console.log('\n✨ تم زرع كل البيانات بنجاح');
  } catch (error) {
    console.error('❌ خطأ في seed:', error);
    throw error;
  }
};

// نصدّر الدالة للاستخدام من داخل السيرفر
module.exports = { seedData };

// لو شغلنا السكريبت مباشرة (npm run seed) نشغّل الدالة ونغلق العملية
if (require.main === module) {
  seedData()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
