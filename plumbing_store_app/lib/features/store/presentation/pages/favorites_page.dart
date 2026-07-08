import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/data/store_products.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/providers/favorites_provider.dart';
import 'package:plumbing_store_app/core/widgets/product_image.dart';
import 'package:plumbing_store_app/core/models/store_product.dart';
import 'product_details_page.dart';
import '../../../../core/widgets/page_transitions.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favIds = context.watch<FavoritesProvider>().ids;
    final allProducts = StoreApiService().products.isNotEmpty
        ? StoreApiService().products
        : StoreProducts.products;
    final products = allProducts.where((p) => favIds.contains(p.id)).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: const Text('المفضلة'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: products.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 72, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد منتجات في المفضلة',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) {
                  final product = products[index];
                  return _FavoriteCard(product: product);
                },
              ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final StoreProduct product;
  const _FavoriteCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            AppTransitions.details(ProductDetailsPage(product: product)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ProductImage(
                product: product,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                iconSize: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            context.read<FavoritesProvider>().toggle(product.id),
                        icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                      ),
                      Text(
                        '${product.price.toInt()} ج.م',
                        style: const TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
