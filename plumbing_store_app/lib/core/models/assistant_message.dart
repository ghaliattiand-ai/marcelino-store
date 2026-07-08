import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum MessageSender { user, assistant }

class AssistantMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<AssistantProduct> products; // المنتجات المقترحة

  AssistantMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.products = const [],
  });
}

// نسخة مبسطة من المنتج للعرض جوه الدردشة
class AssistantProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String icon;
  final Color color;

  AssistantProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.icon = 'inventory_2',
    this.color = const Color(0xFF1565C0),
  });

  factory AssistantProduct.fromJson(Map<String, dynamic> j) {
    final images = (j['images'] as List?)?.cast<String>() ?? [];
    String? imageUrl;
    if (images.isNotEmpty) {
      final first = images.first;
      if (first.startsWith('http')) {
        imageUrl = first;
      } else if (first.startsWith('/uploads/')) {
        imageUrl = '${AppConstants.apiOrigin}$first';
      }
    }
    return AssistantProduct(
      id: j['_id'] as String? ?? '',
      name: j['nameAr'] as String? ?? '',
      description: (j['description'] as String?) ?? '',
      price: (j['price'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
      icon: j['icon'] as String? ?? 'inventory_2',
    );
  }
}
