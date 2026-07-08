import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/providers/cart_provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/features/auth/presentation/pages/login_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'checkout_page.dart';
import '../../../../core/widgets/page_transitions.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: const Text('سلة المشتريات'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (items.isNotEmpty)
              IconButton(
                onPressed: () => _confirmClear(context, cart),
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: items.isEmpty
            ? _EmptyCart(
                onShop: () => context.read<NavigationProvider>().goToTab(0),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        return _CartItemCard(
                          item: items[index],
                          cart: cart,
                        );
                      },
                    ),
                  ),
                  _CartSummary(cart: cart),
                ],
              ),
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إفراغ السلة'),
        content: const Text('هل أنت متأكد من إفراغ السلة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            child: const Text('إفراغ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyCart({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: _orange,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'سلة فارغة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف منتجات إلى السلة وابدأ التسوق',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final CartProvider cart;

  const _CartItemCard({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _itemIcon(),
                    )
                  : _itemIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.price.toInt()} ج.م',
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => cart.removeItem(item.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => cart.decrementQuantity(item.id),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.remove, size: 18),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () => cart.incrementQuantity(item.id),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(item.icon, color: item.color, size: 32),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;

  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('مجموع المنتجات', '${cart.subtotal.toInt()} ج.م'),
          const SizedBox(height: 8),
          _summaryRow(
            'تكلفة الشحن',
            cart.shipping == 0 ? 'مجاني' : '${cart.shipping.toInt()} ج.م',
            valueColor: cart.shipping == 0 ? const Color(0xFF2E7D32) : null,
          ),
          if (cart.subtotal > 0 && cart.subtotal < CartProvider.freeShippingThreshold)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'أضف ${(CartProvider.freeShippingThreshold - cart.subtotal).toInt()} ج.م للشحن المجاني',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          const Divider(height: 24),
          _summaryRow(
            'الإجمالي',
            '${cart.totalPrice.toInt()} ج.م',
            bold: true,
            valueColor: _orange,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _checkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'إتمام الطلب',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.of(context).push(
        AppTransitions.slideUp(const LoginPage()),
      ) as bool?;
      if (loggedIn != true || !context.mounted) return;
      if (!context.read<AuthProvider>().isLoggedIn) return;
    }

    // نروح لصفحة الـ checkout الكاملة (اختيار طريقة الدفع + العنوان)
    if (!context.mounted) return;
    Navigator.push(
      context,
      AppTransitions.slideUp(const CheckoutPage()),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? const Color(0xFF1A1A2E) : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 20 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
