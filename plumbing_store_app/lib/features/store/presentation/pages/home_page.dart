import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/cart_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/core/data/store_products.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/models/store_product.dart';
import 'package:plumbing_store_app/core/widgets/product_image.dart';
import 'package:plumbing_store_app/features/store/presentation/widgets/banner_carousel.dart';
import 'product_details_page.dart';
import 'search_page.dart';
import '../../../../core/widgets/page_transitions.dart';

// ── الألوان ──
const _navy = Color(0xFF0D1B3E);
const _navyL = Color(0xFF152040);
const _orange = Color(0xFFFF6B00);
const _bg = Color(0xFFF2F3F7);

class HomePage extends StatefulWidget {
  final String? initialCategoryId;
  final VoidCallback? onOpenDrawer;
  const HomePage({super.key, this.initialCategoryId, this.onOpenDrawer});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? _selectedCategoryId;

  final List<StoreProduct> _displayedProducts = [];
  int _currentPage = 0;
  static const int _pageSize = 4;
  bool _isLoading = false;
  bool _hasMore = true;
  late ScrollController _scrollController;

  late final AnimationController _cartCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _cartScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 40),
  ]).animate(CurvedAnimation(parent: _cartCtrl, curve: Curves.easeOut));

  String get _selectedCategoryName {
    if (_selectedCategoryId == null) return 'جميع المنتجات';
    if (_selectedCategoryId == 'more') return 'جميع المنتجات';
    return StoreApiService().categoryById(_selectedCategoryId!)?.label
        ?? StoreProducts.categoryById(_selectedCategoryId!)?.label
        ?? 'جميع المنتجات';
  }

  bool get _isFiltered =>
      _selectedCategoryId != null && _selectedCategoryId != 'more';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
    _loadMoreProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cartCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      // نجيب المنتجات من الـ API
      final allFiltered = await StoreApiService().byCategory(_selectedCategoryId);
      final start = _currentPage * _pageSize;
      if (start >= allFiltered.length) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }
      final end = (start + _pageSize).clamp(0, allFiltered.length);
      final newItems = allFiltered.sublist(start, end);

      setState(() {
        _displayedProducts.addAll(newItems);
        _currentPage++;
        _hasMore = end < allFiltered.length;
        _isLoading = false;
      });
    } catch (e) {
      // fallback للبيانات المحلية لو السيرفر مش شغال
      final allFiltered = StoreProducts.byCategory(_selectedCategoryId);
      final start = _currentPage * _pageSize;
      if (start >= allFiltered.length) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }
      final end = (start + _pageSize).clamp(0, allFiltered.length);
      final newItems = allFiltered.sublist(start, end);

      setState(() {
        _displayedProducts.addAll(newItems);
        _currentPage++;
        _hasMore = end < allFiltered.length;
        _isLoading = false;
      });
    }
  }

  void _selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) categoryId = null;
    setState(() {
      _selectedCategoryId = categoryId;
      _displayedProducts.clear();
      _currentPage = 0;
      _hasMore = true;
      _isLoading = false;
    });
    _loadMoreProducts();
  }

  void _openProductDetails(StoreProduct product) {
    Navigator.push(
      context,
      AppTransitions.details(
        ProductDetailsPage(product: product),
      ),
    );
  }

  void _onAddToCart(StoreProduct product) {
    context.read<CartProvider>().addItem(CartItem.fromProduct(product));
    _cartCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              if (StoreApiService().banners.isNotEmpty)
                BannerCarousel(banners: StoreApiService().banners)
              else
                _buildHeroBanner(),
              const SizedBox(height: 10),
              _buildCategoriesSection(),
              const SizedBox(height: 10),
              _buildFeaturedSection(),
              const SizedBox(height: 10),
              _buildProductsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final cartCount = context.watch<CartProvider>().totalItems;

    return AppBar(
      backgroundColor: _navy,
      elevation: 0,
      toolbarHeight: 58,
      leading: _BouncyTap(
        scaleFactor: 0.80,
        onTap: () {
          if (widget.onOpenDrawer != null) {
            widget.onOpenDrawer!();
          } else {
            Scaffold.of(context).openEndDrawer();
          }
        },
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.menu, color: Colors.white, size: 26),
        ),
      ),
      centerTitle: true,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hardware, color: _orange, size: 20),
          SizedBox(width: 6),
          Text(
            'مارسيلينو',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _BouncyTap(
            scaleFactor: 0.80,
            onTap: () => context.read<NavigationProvider>().goToTab(3),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ScaleTransition(
                    scale: _cartScale,
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      top: -4,
                      left: -6,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, AppTransitions.scale(const SearchPage()));
      },
      child: Container(
        color: _navy,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
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
                  'ابحث عن منتج...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      color: _navyL,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -50,
            bottom: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
            ),
          ),
          Positioned(
            right: 100,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _orange.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 14,
            bottom: 14,
            child: SizedBox(
              width: 160,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 30,
                    top: 10,
                    child: _toolBox(Icons.hardware, _orange, 76, 76, 40),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 16,
                    child: _toolBox(Icons.plumbing, Colors.white60, 56, 56, 28),
                  ),
                  Positioned(
                    left: 90,
                    bottom: 22,
                    child: _toolBox(Icons.build, _orange, 48, 48, 24),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'كل ما تحتاجه',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Text(
                  'في مكان واحد',
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'جودة عالية - أسعار مناسبة',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _BouncyTap(
                  onTap: () => _selectCategory(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'تسوق الآن',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBox(IconData icon, Color color, double w, double h, double size) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.80,
          crossAxisSpacing: 6,
          mainAxisSpacing: 8,
        ),
        itemCount: StoreApiService().categories.isNotEmpty
            ? StoreApiService().categories.length
            : StoreProducts.categories.length,
        itemBuilder: (_, i) {
          final cats = StoreApiService().categories.isNotEmpty
              ? StoreApiService().categories
              : StoreProducts.categories;
          final c = cats[i];
          final isSelected = _selectedCategoryId == c.id;
          return _BouncyTap(
            scaleFactor: 0.84,
            onTap: () {
              HapticFeedback.selectionClick();
              _selectCategory(c.id == 'more' ? 'more' : c.id);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isSelected ? c.color : c.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? c.color : c.color.withValues(alpha: 0.15),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    c.icon,
                    color: isSelected ? Colors.white : c.color,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? c.color : const Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final featured = StoreApiService().featured.isNotEmpty
        ? StoreApiService().featured
        : StoreProducts.featured;
    if (featured.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الأكثر مبيعاً',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final product = featured[index];
                return SizedBox(
                  width: 150,
                  child: _ProductGridCard(
                    product: product,
                    compact: true,
                    onTap: () => _openProductDetails(product),
                    onAdd: () => _onAddToCart(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (_isFiltered)
                  _BouncyTap(
                    onTap: () => _selectCategory(null),
                    child: const Text(
                      'إلغاء التصفية',
                      style: TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _displayedProducts.isEmpty && !_isLoading
              ? const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('لا توجد منتجات في هذا القسم')),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _displayedProducts.length + (_hasMore ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    if (index == _displayedProducts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: _orange),
                        ),
                      );
                    }
                    final prod = _displayedProducts[index];
                    return _ProductGridCard(
                      product: prod,
                      onTap: () => _openProductDetails(prod),
                      onAdd: () => _onAddToCart(prod),
                    );
                  },
                ),
          if (!_hasMore && _displayedProducts.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'تم تحميل جميع المنتجات',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onAdd;
  final VoidCallback onTap;
  final bool compact;

  const _ProductGridCard({
    required this.product,
    required this.onAdd,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'product_${product.id}',
      child: Material(
        color: Colors.transparent,
        child: _BouncyTap(
          scaleFactor: 0.96,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProductImage(
                        product: product,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        iconSize: compact ? 40 : 48,
                      ),
                      if (product.hasDiscount)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${product.discountPercent.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _AddToCartBtn(onAdd: onAdd, size: compact ? 26 : 28),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.price.toInt()} ج.م',
                                style: TextStyle(
                                  color: _orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: compact ? 12 : 13,
                                ),
                              ),
                              if (product.hasDiscount)
                                Text(
                                  '${product.oldPrice!.toInt()} ج.م',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddToCartBtn extends StatefulWidget {
  final VoidCallback onAdd;
  final double size;
  const _AddToCartBtn({required this.onAdd, this.size = 34});

  @override
  State<_AddToCartBtn> createState() => _AddToCartBtnState();
}

class _AddToCartBtnState extends State<_AddToCartBtn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.78).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn, reverseCurve: Curves.elasticOut),
  );
  bool _added = false;
  Timer? _resetTimer;

  void _handleTap() {
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    setState(() => _added = true);
    widget.onAdd();
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _added ? const Color(0xFF2E7D32) : _orange,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (_added ? const Color(0xFF2E7D32) : _orange).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              _added ? Icons.check : Icons.add,
              key: ValueKey(_added),
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  const _BouncyTap({required this.child, this.onTap, this.scaleFactor = 0.93});

  @override
  State<_BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<_BouncyTap> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn, reverseCurve: Curves.elasticOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
