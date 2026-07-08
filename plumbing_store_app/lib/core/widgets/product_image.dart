import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/store_product.dart';

class ProductImage extends StatelessWidget {
  final StoreProduct product;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final bgColor = product.color.withValues(alpha: 0.10);

    Widget child;
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: product.imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _shimmer(bgColor),
        errorWidget: (_, __, ___) => _iconFallback(bgColor),
      );
    } else {
      child = _iconFallback(bgColor);
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _shimmer(Color bgColor) {
    return Shimmer.fromColors(
      baseColor: bgColor,
      highlightColor: Colors.white.withValues(alpha: 0.6),
      child: Container(
        width: width,
        height: height,
        color: bgColor,
      ),
    );
  }

  Widget _iconFallback(Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: Icon(product.icon, color: product.color, size: iconSize),
      ),
    );
  }
}
