import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_product.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final double? oldPrice;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.quantity = 1,
  });

  factory CartItem.fromProduct(StoreProduct product) {
    return CartItem(
      id: product.id,
      name: product.name,
      price: product.price,
      oldPrice: product.oldPrice,
      icon: product.icon,
      color: product.color,
      imageUrl: product.imageUrl,
    );
  }

  double get lineTotal => price * quantity;

  /// تحويل إلى JSON قابل للتخزين في SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'oldPrice': oldPrice,
        'icon': icon.codePoint,
        'color': color.toARGB32(),
        'imageUrl': imageUrl,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) {
    return CartItem(
      id: j['id'] as String,
      name: j['name'] as String,
      price: (j['price'] as num).toDouble(),
      oldPrice: (j['oldPrice'] as num?)?.toDouble(),
      icon: IconData(j['icon'] as int, fontFamily: 'MaterialIcons'), // ignore: non_const_argument_for_const_parameter
      color: Color((j['color'] as num).toInt()),
      imageUrl: j['imageUrl'] as String?,
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartProvider extends ChangeNotifier {
  static const String _storageKey = 'cart_items_v1';
  final List<CartItem> _items = [];
  bool _loaded = false;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  static const double shippingCost = 30.0;
  static const double freeShippingThreshold = 500.0;

  double get shipping =>
      subtotal >= freeShippingThreshold || subtotal == 0 ? 0 : shippingCost;

  double get totalPrice => subtotal + shipping;

  bool isInCart(String id) => _items.any((i) => i.id == id);

  int quantityInCart(String id) {
    for (final item in _items) {
      if (item.id == id) return item.quantity;
    }
    return 0;
  }

  /// تحميل السلة المحفوظة من SharedPreferences — يُستدعى مرة عند إقلاع التطبيق
  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(list.map((j) => CartItem.fromJson(j as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {
      // تجاهل أي خطأ — السلة ستبدأ فارغة
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (_) {}
  }

  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
    _persist();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    _persist();
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
      _persist();
    }
  }

  void decrementQuantity(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
      _persist();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _persist();
  }
}
