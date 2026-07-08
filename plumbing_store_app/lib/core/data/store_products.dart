import 'package:flutter/material.dart';
import '../models/store_product.dart';

class StoreProducts {
  static const categories = [
    StoreCategory(
      id: 'plumbing',
      label: 'سباكة',
      icon: Icons.water_drop,
      color: Color(0xFF1565C0),
      description: 'مضخات، مواسير، خلاطات، وصنابير عالية الجودة',
    ),
    StoreCategory(
      id: 'electrical',
      label: 'كهرباء',
      icon: Icons.flash_on,
      color: Color(0xFFF57F17),
      description: 'إضاءة، كابلات، ومستلزمات كهربائية آمنة',
    ),
    StoreCategory(
      id: 'tools',
      label: 'عدد وأدوات',
      icon: Icons.handyman,
      color: Color(0xFF6A1B9A),
      description: 'أدوات كهربائية ومعدات احترافية للورش',
    ),
    StoreCategory(
      id: 'paints',
      label: 'دهانات',
      icon: Icons.format_paint,
      color: Color(0xFF2E7D32),
      description: 'بويات داخلية وخارجية بألوان متعددة',
    ),
    StoreCategory(
      id: 'hand_tools',
      label: 'أدوات يدوية',
      icon: Icons.construction,
      color: Color(0xFF880E4F),
      description: 'مطارق، مفكات، وعدد يدوية للاستخدام اليومي',
    ),
    StoreCategory(
      id: 'building',
      label: 'مواد بناء',
      icon: Icons.home_repair_service,
      color: Color(0xFF4E342E),
      description: 'حديد، أسمنت، وزوايا بناء بأسعار منافسة',
    ),
    StoreCategory(
      id: 'equipment',
      label: 'معدات',
      icon: Icons.precision_manufacturing,
      color: Color(0xFF00695C),
      description: 'معدات صناعية ومعدات مواقع',
    ),
    StoreCategory(
      id: 'more',
      label: 'أكثر',
      icon: Icons.more_horiz,
      color: Color(0xFF546E7A),
      description: 'تصفح جميع المنتجات والعروض',
    ),
  ];

  static const products = [
    StoreProduct(
      id: 'p1',
      name: 'مضخة ماء أوتوماتيك 1 حصان',
      price: 1250,
      categoryId: 'plumbing',
      categoryName: 'سباكة',
      color: Color(0xFF1565C0),
      icon: Icons.water_drop,
      rating: 4.8,
      stock: 24,
      isFeatured: true,
      imageUrl:
          'https://images.unsplash.com/photo-1607472586893-edb57bdc0e38?w=600&h=600&fit=crop',
      galleryUrls: [
        'https://images.unsplash.com/photo-1607472586893-edb57bdc0e38?w=600&h=600&fit=crop',
        'https://images.unsplash.com/photo-1558618666-fcd25c85f933?w=600&h=600&fit=crop',
      ],
      description:
          'مضخة مياه أوتوماتيك بقوة 1 حصان، مناسبة للمنازل والمزارع. تعمل بكفاءة عالية مع حماية من الجفاف وتشغيل تلقائي عند فتح الصنبور.',
      specifications: {
        'القدرة': '1 حصان',
        'الجهد': '220 فولت',
        'التدفق': '35 لتر/دقيقة',
        'الضمان': 'سنتان',
      },
    ),
    StoreProduct(
      id: 'p2',
      name: 'خلاط حوض ستانلس',
      price: 650,
      categoryId: 'plumbing',
      categoryName: 'سباكة',
      color: Color(0xFF546E7A),
      icon: Icons.plumbing,
      rating: 4.6,
      stock: 40,
      imageUrl:
          'https://images.unsplash.com/photo-1584622780116-993a426afbf0?w=600&h=600&fit=crop',
      description:
          'خلاط حوض من الستانلس ستيل مقاوم للصدأ، تصميم عصري مع خرطوم مرن وسهولة في التركيب.',
      specifications: {
        'المادة': 'ستانلس 304',
        'اللون': 'فضي',
        'الضمان': '3 سنوات',
      },
    ),
    StoreProduct(
      id: 'p3',
      name: 'دريل شحن 21 فولت',
      price: 1100,
      categoryId: 'tools',
      categoryName: 'عدد وأدوات',
      color: Color(0xFF4E342E),
      icon: Icons.hardware,
      rating: 4.7,
      stock: 15,
      isFeatured: true,
      imageUrl:
          'https://images.unsplash.com/photo-1572981776309-884b7701477c?w=600&h=600&fit=crop',
      description:
          'دريل لاسلكي ببطارية لithium-ion، مناسب للخشب والمعادن. يأتي مع شاحن وبطاريتين.',
      specifications: {
        'الجهد': '21 فولت',
        'السرعة': '0-1500 دورة/د',
        'العزم': '45 نيوتن',
      },
    ),
    StoreProduct(
      id: 'p4',
      name: 'ماسورة PVC 4 بوصة',
      price: 75,
      oldPrice: 95,
      categoryId: 'plumbing',
      categoryName: 'سباكة',
      color: Color(0xFF00695C),
      icon: Icons.plumbing,
      rating: 4.4,
      stock: 200,
      imageUrl:
          'https://images.unsplash.com/photo-1558618666-fcd25c85f933?w=600&h=600&fit=crop',
      description:
          'ماسورة PVC مقاومة للضغط والتآكل، مناسبة لشبكات الصرف والمياه.',
      specifications: {
        'القطر': '4 بوصة',
        'الطول': '6 متر',
        'الضغط': '10 بار',
      },
    ),
    StoreProduct(
      id: 'p5',
      name: 'فرشة بويا مقاس 4',
      price: 45,
      categoryId: 'paints',
      categoryName: 'دهانات',
      color: Color(0xFF880E4F),
      icon: Icons.brush,
      rating: 4.2,
      stock: 80,
      imageUrl:
          'https://images.unsplash.com/photo-1562259949-64690bb70015?w=600&h=600&fit=crop',
      description: 'فرشاة دهان احترافية بشعيرات صناعية، مناسبة للدهانات الزيتية والمائية.',
      specifications: {
        'المقاس': '4 بوصة',
        'النوع': 'صناعي',
      },
    ),
    StoreProduct(
      id: 'p6',
      name: 'مفك براغي كهربائي',
      price: 320,
      categoryId: 'tools',
      categoryName: 'عدد وأدوات',
      color: Color(0xFF6A1B9A),
      icon: Icons.build,
      rating: 4.5,
      stock: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1591227932313-7c9160addb1c?w=600&h=600&fit=crop',
      description: 'مفك براغي كهربائي خفيف الوزن مع LED للإضاءة، مثالي للتركيبات المنزلية.',
      specifications: {
        'الجهد': '3.6 فولت',
        'العزم': '5 نيوتن',
        'البطارية': '1500 mAh',
      },
    ),
    StoreProduct(
      id: 'p7',
      name: 'عازل كهربائي 10 متر',
      price: 85,
      categoryId: 'electrical',
      categoryName: 'كهرباء',
      color: Color(0xFFF57F17),
      icon: Icons.electrical_services,
      rating: 4.3,
      stock: 60,
      imageUrl:
          'https://images.unsplash.com/photo-1621905251189-08cc45dbf283?w=600&h=600&fit=crop',
      description: 'شريط عازل كهربائي عالي الجودة، مقاوم للحرارة والرطوبة.',
      specifications: {
        'الطول': '10 متر',
        'العرض': '19 مم',
        'اللون': 'أسود',
      },
    ),
    StoreProduct(
      id: 'p8',
      name: 'ماسورة حديد 1 بوصة',
      price: 180,
      oldPrice: 220,
      categoryId: 'building',
      categoryName: 'مواد بناء',
      color: Color(0xFF4E342E),
      icon: Icons.settings,
      rating: 4.1,
      stock: 150,
      imageUrl:
          'https://images.unsplash.com/photo-1504328345606-18bbc8c543ab?w=600&h=600&fit=crop',
      description: 'ماسورة حديد مجلفن للاستخدام في البناء والتركيبات الصناعية.',
      specifications: {
        'القطر': '1 بوصة',
        'الطول': '6 متر',
        'السماكة': '2 مم',
      },
    ),
    StoreProduct(
      id: 'p9',
      name: 'صنبور مطبخ ستانلس',
      price: 350,
      categoryId: 'plumbing',
      categoryName: 'سباكة',
      color: Color(0xFF1565C0),
      icon: Icons.kitchen,
      rating: 4.7,
      stock: 35,
      isFeatured: true,
      imageUrl:
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d4046?w=600&h=600&fit=crop',
      description: 'صنبور مطبخ بتصميم حديث مع رأس قابل للدوران 360 درجة.',
      specifications: {
        'المادة': 'ستانلس',
        'الضمان': '5 سنوات',
      },
    ),
    StoreProduct(
      id: 'p10',
      name: 'لمبة LED 15 وات',
      price: 25,
      categoryId: 'electrical',
      categoryName: 'كهرباء',
      color: Color(0xFFF57F17),
      icon: Icons.lightbulb,
      rating: 4.6,
      stock: 100,
      imageUrl:
          'https://images.unsplash.com/photo-1550684848-fac1fc2051eb?w=600&h=600&fit=crop',
      description: 'لمبة LED موفرة للطاقة بإضاءة قوية وعمر تشغيل طويل.',
      specifications: {
        'القدرة': '15 وات',
        'اللون': 'أبيض نهاري',
        'العمر': '25000 ساعة',
      },
    ),
    StoreProduct(
      id: 'p11',
      name: 'شريط قياس 5 متر',
      price: 45,
      categoryId: 'tools',
      categoryName: 'عدد وأدوات',
      color: Color(0xFF6A1B9A),
      icon: Icons.straighten,
      rating: 4.4,
      stock: 55,
      imageUrl:
          'https://images.unsplash.com/photo-1504141935-fcd25c85f933?w=600&h=600&fit=crop',
      description: 'شريط قياس معدني بقفل تلقائي وعلامات واضحة بالسنتimeter.',
      specifications: {
        'الطول': '5 متر',
        'العرض': '19 مم',
      },
    ),
    StoreProduct(
      id: 'p12',
      name: 'بوية بيضاء 5 لتر',
      price: 120,
      categoryId: 'paints',
      categoryName: 'دهانات',
      color: Color(0xFF2E7D32),
      icon: Icons.format_paint,
      rating: 4.5,
      stock: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1589939705383-281693054dee?w=600&h=600&fit=crop',
      description: 'بوية بلاستيك بيضاء عالية التغطية، مناسبة للجدران الداخلية والخارجية.',
      specifications: {
        'الحجم': '5 لتر',
        'النوع': 'بلاستيك',
        'التغطية': '12 م²/لتر',
      },
    ),
    StoreProduct(
      id: 'p13',
      name: 'مطرقة ثقيلة 1.5 كجم',
      price: 60,
      categoryId: 'hand_tools',
      categoryName: 'أدوات يدوية',
      color: Color(0xFF880E4F),
      icon: Icons.cleaning_services,
      rating: 4.0,
      stock: 70,
      imageUrl:
          'https://images.unsplash.com/photo-1530124560971-5b5bb1b82456?w=600&h=600&fit=crop',
      description: 'مطرقة ثقيلة بمقبض مريح ومتوازن، مناسبة للبناء والنجارة.',
      specifications: {
        'الوزن': '1.5 كجم',
        'المقبض': 'خشب مع فيبر',
      },
    ),
  ];

  static StoreCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<StoreProduct> byCategory(String? categoryId) {
    if (categoryId == null || categoryId == 'more') return products;
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  static List<StoreProduct> get featured =>
      products.where((p) => p.isFeatured).toList();

  static StoreProduct? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<StoreProduct> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return products;
    final lower = q.toLowerCase();
    return products.where((p) {
      return p.name.contains(q) ||
          p.categoryName.contains(q) ||
          p.description.contains(q) ||
          p.name.toLowerCase().contains(lower) ||
          p.categoryId.contains(lower);
    }).toList();
  }
}
