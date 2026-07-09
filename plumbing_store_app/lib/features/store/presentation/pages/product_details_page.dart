import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/store_product.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/providers/favorites_provider.dart';
import '../../../../core/data/tracking_service.dart';
import '../../../../core/widgets/product_image.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class ProductDetailsPage extends StatefulWidget {
  final StoreProduct product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  StoreProduct get product => widget.product;

  List<String> get _gallery =>
      product.allImages.isNotEmpty ? product.allImages : [''];

  @override
  void initState() {
    super.initState();
    // تتبع مشاهدة المنتج (fire-and-forget)
    if (product.id.isNotEmpty) {
      TrackingService().trackProductView(product.id);
    }
  }

  void _addToCart({bool showMessage = true}) {
    HapticFeedback.lightImpact();
    final cart = context.read<CartProvider>();
    for (var i = 0; i < _quantity; i++) {
      cart.addItem(CartItem.fromProduct(product));
    }
    if (showMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('تمت إضافة $_quantity × ${product.name} للسلة'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inCart = context.watch<CartProvider>().isInCart(product.id);
    final isFavorite = context.watch<FavoritesProvider>().isFavorite(product.id);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'تفاصيل المنتج',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                // نسخ تفاصيل المنتج للحافظة بدل假装 النسخ
                final text =
                    '🛍️ ${product.name}\n💵 السعر: ${product.price.toStringAsFixed(0)} ج.م\n\n— تطبيق MARCELINO';
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ تفاصيل المنتج للحافظة'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              onPressed: () => context.read<FavoritesProvider>().toggle(product.id),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : Colors.white,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGallery(),
                    _buildInfoSection(inCart),
                    _buildDescriptionSection(),
                    _buildSpecsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(inCart),
      ),
    );
  }

  Widget _buildGallery() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                    _gallery[_selectedImageIndex].isNotEmpty
                      ? Hero(
                          tag: 'product_${product.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: _gallery[_selectedImageIndex],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ProductImage(
                                product: product,
                                height: 220,
                                iconSize: 80,
                              ),
                              errorWidget: (_, __, ___) => ProductImage(
                                product: product,
                                height: 220,
                                iconSize: 80,
                              ),
                            ),
                          ),
                        )
                      : ProductImage(
                          product: product,
                          height: 220,
                          iconSize: 80,
                        ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${product.discountPercent.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_gallery.length > 1) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_gallery.length, (index) {
                if (_gallery[index].isEmpty) return const SizedBox.shrink();
                final selected = _selectedImageIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _orange : Colors.grey.withValues(alpha: 0.2),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _gallery[index],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Icon(product.icon, color: product.color, size: 26),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool inCart) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: product.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.categoryName,
              style: TextStyle(
                color: product.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (i) {
                final filled = i < product.rating.floor();
                final half = i == product.rating.floor() && product.rating % 1 >= 0.5;
                return Icon(
                  filled
                      ? Icons.star
                      : half
                          ? Icons.star_half
                          : Icons.star_border,
                  color: const Color(0xFFFFB300),
                  size: 20,
                );
              }),
              const SizedBox(width: 6),
              Text(
                '${product.rating}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.price.toInt()} جنيه',
                style: const TextStyle(
                  color: _orange,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 10),
                Text(
                  '${product.oldPrice!.toInt()} جنيه',
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: product.inStock
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product.inStock ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: product.inStock
                          ? const Color(0xFF2E7D32)
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.inStock ? 'متوفر (${product.stock})' : 'غير متوفر',
                      style: TextStyle(
                        color: product.inStock
                            ? const Color(0xFF2E7D32)
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (inCart) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'في السلة',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          title: const Text(
            'الوصف',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                product.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          title: const Text(
            'المواصفات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                children: product.specifications.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          entry.key,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool inCart) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _quantity < product.stock
                      ? () => setState(() => _quantity++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: product.inStock ? () => _addToCart() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: inCart ? const Color(0xFF2E7D32) : _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(inCart ? Icons.check : Icons.shopping_cart_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      inCart ? 'إضافة المزيد' : 'إضافة للسلة',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
