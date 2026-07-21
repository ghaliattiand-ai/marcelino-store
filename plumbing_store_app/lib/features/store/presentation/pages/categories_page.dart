import 'package:flutter/material.dart';
import 'package:plumbing_store_app/core/data/store_products.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/models/store_product.dart';
import 'search_page.dart';
import 'category_products_page.dart';
import '../../../../core/widgets/page_transitions.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  // يجيب أحدث الأقسام من السيرفر ويعمل rebuild
  Future<void> _refreshCategories() async {
    try {
      await StoreApiService().refresh();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cats = StoreApiService().categories.isNotEmpty
        ? StoreApiService().categories
        : StoreProducts.categories;
    final categories = cats.where((c) => c.id != 'more').toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: const Text('الأقسام'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: _orange,
          onRefresh: _refreshCategories,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      AppTransitions.scale(const SearchPage()),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(7),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.search, color: Colors.white, size: 18),
                      ),
                      Expanded(
                        child: Text(
                          'ابحث في الأقسام...',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryCard(category: category),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final StoreCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final apiProducts = StoreApiService().products;
    final allProducts = apiProducts.isNotEmpty
        ? apiProducts
        : StoreProducts.products;
    final productCount = allProducts.where((p) =>
      p.categoryId == category.id
    ).length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            AppTransitions.slideUp(CategoryProductsPage(
              categoryId: category.id,
              categoryName: category.label,
            )),
          );
        },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                      ? Image.network(
                          category.imageUrl!,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          errorBuilder: (_, __, ___) => Icon(
                            category.icon,
                            color: category.color,
                            size: 36,
                          ),
                        )
                      : Icon(category.icon, color: category.color, size: 36),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'عرض المنتجات ($productCount)',
                          style: const TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_back_ios, size: 12, color: _orange),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
