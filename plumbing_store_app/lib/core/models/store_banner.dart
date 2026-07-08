class StoreBanner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? productId; // لو موجود، الضغط على الإعلان يفتح تفاصيل المنتج
  final int order;
  final bool isActive;

  const StoreBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.productId,
    this.order = 0,
    this.isActive = true,
  });
}
