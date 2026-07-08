import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plumbing_store_app/core/models/store_banner.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/models/store_product.dart';
import '../pages/product_details_page.dart';

const _navy = Color(0xFF0D1B3E);
const _navyL = Color(0xFF152040);
const _orange = Color(0xFFFF6B00);

/// كاروسيل إعلانات ديناميكي
/// - يتحرك تلقائياً كل 4 ثواني
/// - المستخدم يقدر يسحب بالإيد
/// - نقاط مؤشر تحت
/// - الضغط على الإعلان بيربط بمنتج → يفتح تفاصيل المنتج
class BannerCarousel extends StatefulWidget {
  final List<StoreBanner> banners;
  final double height;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.height = 200,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // لو عدد الإعلانات اتغير، ن reset الصفحة
    if (oldWidget.banners.length != widget.banners.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.banners.length < 2) return; // لو إعلان واحد مفيش لازمة للحركة
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % widget.banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _onBannerTap(StoreBanner banner) async {
    final productId = banner.productId;
    if (productId == null || productId.isEmpty) return;

    // نجيب المنتج من الكاش أو السيرفر
    StoreProduct? product;
    try {
      product = await StoreApiService().byId(productId);
    } catch (_) {
      product = null;
    }

    if (product == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product!)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: banners.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _BannerSlide(
                banner: banner,
                onTap: () => _onBannerTap(banner),
              );
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          _buildDots(banners.length),
        ],
      ],
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? _orange : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// شريحة الإعلان الواحدة - فيها الصورة + النص + زر "تسوق الآن"
class _BannerSlide extends StatelessWidget {
  final StoreBanner banner;
  final VoidCallback onTap;

  const _BannerSlide({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: _navyL,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الصورة الخلفية
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: _navyL,
                child: const Center(
                  child: CircularProgressIndicator(color: _orange, strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => _buildFallback(banner),
            ),
            // تدرّج فوق الصورة لقراءة النص
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    _navy.withValues(alpha: 0.85),
                    _navy.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            // النص + زر CTA (يمين الشاشة لأن RTL)
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (banner.subtitle.isNotEmpty)
                    Text(
                      banner.subtitle,
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  if (banner.productId != null && banner.productId!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'تسوق الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // لو الصورة فشلت في التحميل - نعرض fallback بسيط
  Widget _buildFallback(StoreBanner banner) {
    return Container(
      color: _navyL,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (banner.subtitle.isNotEmpty)
            Text(banner.subtitle, style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            banner.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
