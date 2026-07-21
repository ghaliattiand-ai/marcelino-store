import 'package:flutter/material.dart';
import '../models/store_product.dart';
import '../models/store_banner.dart';
import '../network/api_service.dart';
import '../constants/app_constants.dart';
import 'store_products.dart';

/// API layer that fetches products/categories from the backend
/// Falls back to local mock data if the server is unreachable
class StoreApiService {
  static final StoreApiService _instance = StoreApiService._internal();
  factory StoreApiService() => _instance;
  StoreApiService._internal();

  List<StoreCategory> _categoriesCache = [];
  List<StoreProduct> _productsCache = [];
  List<StoreBanner> _bannersCache = [];
  bool _initialized = false;

  /// تهيئة - تجيب الأقسام والمنتجات من السيرفر
  Future<void> init() async {
    if (_initialized) return;
    await refresh();
  }

  /// تحديث كل البيانات من السيرفر
  Future<void> refresh() async {
    try {
      await ApiService().init();

      final catsRes = await ApiService().get('/categories');
      _categoriesCache = _mapCategories(catsRes.data['categories']);

      final prodsRes = await ApiService().get('/products', queryParameters: {'limit': 100});
      _productsCache = _mapProducts(prodsRes.data['products']);

      // جلب الإعلانات (لو فشل نبقى الكاش فاضي ونعرض fallback)
      try {
        final bannersRes = await ApiService().get('/banners');
        _bannersCache = _mapBanners(bannersRes.data['banners']);
      } catch (_) {
        _bannersCache = [];
      }

      _initialized = true;
    } catch (e) {
      // fallback للبيانات المحلية
      _categoriesCache = StoreProducts.categories;
      _productsCache = StoreProducts.products;
      _bannersCache = [];
      _initialized = true;
    }
  }

  List<StoreBanner> get banners {
    if (!_initialized || _bannersCache.isEmpty) return [];
    return _bannersCache;
  }

  List<StoreCategory> get categories {
    if (!_initialized || _categoriesCache.isEmpty) {
      return StoreProducts.categories;
    }
    return _categoriesCache;
  }

  List<StoreProduct> get products {
    if (!_initialized || _productsCache.isEmpty) {
      return StoreProducts.products;
    }
    return _productsCache;
  }

  List<StoreProduct> get featured {
    return products.where((p) => p.isFeatured).toList();
  }

  StoreCategory? categoryById(String? id) {
    if (id == null) return null;
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// المنتجات في قسم معين
  /// لو categoryId == null أو 'more' → كل المنتجات
  Future<List<StoreProduct>> byCategory(String? categoryId) async {
    if (categoryId == null || categoryId == 'more') {
      return products;
    }
    try {
      final res = await ApiService().get('/products', queryParameters: {
        'category_id': categoryId,
      });
      return _mapProducts(res.data['products']);
    } catch (_) {
      return products.where((p) => p.categoryId == categoryId).toList();
    }
  }

  /// منتج واحد بالـ ID
  Future<StoreProduct?> byId(String id) async {
    // الأول في الكاش
    try {
      final cached = products.firstWhere((p) => p.id == id);
      return cached;
    } catch (_) {}

    // من السيرفر
    try {
      final res = await ApiService().get('/products/$id');
      return _mapProduct(res.data['product']);
    } catch (_) {
      return StoreProducts.byId(id);
    }
  }

  /// بحث
  Future<List<StoreProduct>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final res = await ApiService().get('/products', queryParameters: {
        'search': query.trim(),
      });
      return _mapProducts(res.data['products']);
    } catch (_) {
      return StoreProducts.search(query);
    }
  }

  // ===== Mappers =====

  List<StoreCategory> _mapCategories(List<dynamic> jsonList) {
    return jsonList.map((j) {
      final icon = _mapIcon(j['icon'] as String? ?? 'category');
      final color = _mapColor(j['color'] as String? ?? '#1565C0');
      final rawImage = j['imageUrl'] as String?;
      final imageUrl = (rawImage != null && rawImage.isNotEmpty)
          ? _resolveUrl(rawImage)
          : null;
      return StoreCategory(
        id: j['_id'] as String,
        label: j['nameAr'] as String,
        icon: icon,
        color: color,
        description: j['description'] as String? ?? '',
        imageUrl: imageUrl,
      );
    }).toList();
  }

  List<StoreProduct> _mapProducts(List<dynamic> jsonList) {
    return jsonList.map((j) => _mapProduct(j as Map<String, dynamic>)).toList();
  }

  StoreProduct _mapProduct(Map<String, dynamic> j) {
    final icon = _mapIcon(j['icon'] as String? ?? 'inventory_2');
    final color = _mapColor(j['color'] as String? ?? '#1565C0');

    final categoryId = j['categoryId'] is Map
        ? (j['categoryId']['_id'] as String)
        : (j['categoryId']?.toString() ?? '');
    final categoryName = j['categoryId'] is Map
        ? (j['categoryId']['nameAr'] as String)
        : '';

    // المواصفات
    Map<String, String> specs = {};
    if (j['specifications'] is Map) {
      (j['specifications'] as Map).forEach((k, v) {
        specs[k.toString()] = v.toString();
      });
    }

    // الصور
    final images = (j['images'] as List?)?.cast<String>() ?? [];
    final imageUrl = images.isNotEmpty ? _resolveUrl(images.first) : null;
    final galleryUrls = images.map(_resolveUrl).toList();

    final price = (j['price'] as num).toDouble();
    final oldPrice = j['discountPrice'] != null
        ? (j['discountPrice'] as num).toDouble()
        : null;

    return StoreProduct(
      id: j['_id'] as String,
      name: j['nameAr'] as String,
      price: price,
      oldPrice: oldPrice,
      color: color,
      icon: icon,
      categoryId: categoryId,
      categoryName: categoryName,
      description: j['description'] as String? ?? '',
      specifications: specs,
      rating: (j['rating'] as num?)?.toDouble() ?? 4.5,
      stock: (j['stock'] as num?)?.toInt() ?? 0,
      isFeatured: j['isFeatured'] as bool? ?? false,
      imageUrl: imageUrl,
      galleryUrls: galleryUrls,
    );
  }

  // تحويل اسم أيقونة لـ IconData
  IconData _mapIcon(String name) {
    const map = <String, IconData>{
      'water_drop': Icons.water_drop,
      'flash_on': Icons.flash_on,
      'handyman': Icons.handyman,
      'format_paint': Icons.format_paint,
      'construction': Icons.construction,
      'home_repair_service': Icons.home_repair_service,
      'precision_manufacturing': Icons.precision_manufacturing,
      'more_horiz': Icons.more_horiz,
      'inventory_2': Icons.inventory_2,
      'category': Icons.category,
      'electric_bolt': Icons.electric_bolt,
      'build': Icons.build,
      'hardware': Icons.hardware,
    };
    return map[name] ?? Icons.inventory_2;
  }

  // تحويل hex string لـ Color
  Color _mapColor(String hex) {
    try {
      final code = hex.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return const Color(0xFF1565C0);
    }
  }

  // حل الرابط للصورة (لو نسبي /uploads/... يكمّله بأصل الـ API الحالي)
  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('/uploads/')) {
      return '${AppConstants.apiOrigin}$url';
    }
    return url;
  }

  // ===== Banners =====

  List<StoreBanner> _mapBanners(List<dynamic> jsonList) {
    return jsonList.map((j) {
      final map = j as Map<String, dynamic>;
      final productId = map['productId'];
      return StoreBanner(
        id: map['_id'] as String,
        title: map['title'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        imageUrl: _resolveUrl(map['image'] as String? ?? ''),
        productId: productId is Map
            ? (productId['_id'] as String?)
            : (productId?.toString()),
        order: (map['order'] as num?)?.toInt() ?? 0,
        isActive: map['isActive'] as bool? ?? true,
      );
    }).toList();
  }
}
