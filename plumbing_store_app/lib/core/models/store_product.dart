import 'package:flutter/material.dart';

class StoreProduct {
  final String id;
  final String name;
  final double price;
  final double? oldPrice;
  final Color color;
  final IconData icon;
  final String categoryId;
  final String categoryName;
  final String description;
  final Map<String, String> specifications;
  final double rating;
  final int stock;
  final bool isFeatured;
  final String? imageUrl;
  final List<String> galleryUrls;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.color,
    required this.icon,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.specifications,
    this.rating = 4.5,
    this.stock = 50,
    this.isFeatured = false,
    this.imageUrl,
    this.galleryUrls = const [],
  });

  List<String> get allImages {
    if (galleryUrls.isNotEmpty) return galleryUrls;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  bool get inStock => stock > 0;
  double get discountPercent =>
      hasDiscount ? ((oldPrice! - price) / oldPrice! * 100).roundToDouble() : 0;
}

class StoreCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final String? imageUrl;

  const StoreCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    this.imageUrl,
  });
}
