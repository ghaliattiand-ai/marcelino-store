import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plumbing_store_app/core/models/order_model.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class OrderDetailsPage extends StatelessWidget {
  final StoreOrder order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: Text('طلب ${order.displayId}'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _StatusCard(order: order),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'معلومات الطلب',
              children: [
                _infoRow('التاريخ', order.formattedDate),
                _infoRow('العنوان', order.address),
                if (order.customerName != null)
                  _infoRow('العميل', order.customerName!),
                if (order.customerPhone != null)
                  _infoRow('الهاتف', order.customerPhone!),
                _infoRow('طريقة الدفع', order.paymentMethod.labelAr),
              ],
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'المنتجات (${order.productsCount})',
              children: order.items.map((item) => _OrderItemRow(item: item)).toList(),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'ملخص الدفع',
              children: [
                _infoRow('مجموع المنتجات', '${order.subtotal.toInt()} ج.م'),
                _infoRow(
                  'الشحن',
                  order.shipping == 0 ? 'مجاني' : '${order.shipping.toInt()} ج.م',
                ),
                const Divider(height: 20),
                _infoRow(
                  'الإجمالي',
                  '${order.total.toInt()} ج.م',
                  valueStyle: const TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final StoreOrder order;
  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: order.status.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping, color: order.status.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.labelAr,
                  style: TextStyle(
                    color: order.status.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'طلب ${order.displayId} • ${order.formattedDate}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderLineItem item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _iconBox(),
                  )
                : _iconBox(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${item.quantity} × ${item.price.toInt()} ج.م',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${item.lineTotal.toInt()} ج.م',
            style: const TextStyle(
              color: _orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox() {
    return Container(
      width: 56,
      height: 56,
      color: item.color.withValues(alpha: 0.12),
      child: Icon(item.icon, color: item.color),
    );
  }
}
