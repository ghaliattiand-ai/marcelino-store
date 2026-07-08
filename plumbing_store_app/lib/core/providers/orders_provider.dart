import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../network/api_service.dart';
import 'cart_provider.dart';
import 'auth_provider.dart';

class OrdersProvider extends ChangeNotifier {
  final List<StoreOrder> _orders = [];
  bool _loading = false;
  String? _errorMessage;

  List<StoreOrder> get orders => List.unmodifiable(_orders);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  OrdersProvider() {
    _seedDemoOrders();
  }

  // بيانات تجريبية للحالات اللي السيرفر مش شغال
  void _seedDemoOrders() {
    _orders.addAll([
      StoreOrder(
        id: '1256',
        date: DateTime(2024, 6, 18),
        status: OrderStatus.delivered,
        subtotal: 2770,
        shipping: 30,
        total: 2800,
        customerName: 'أحمد محمد',
        customerPhone: '01012345678',
        items: const [
          OrderLineItem(
            productId: 'p1',
            name: 'مضخة ماء أوتوماتيك 1 حصان',
            price: 1250,
            quantity: 1,
            icon: Icons.water_drop,
            color: Color(0xFF1565C0),
          ),
          OrderLineItem(
            productId: 'p3',
            name: 'دريل شحن 21 فولت',
            price: 1100,
            quantity: 1,
            icon: Icons.handyman,
            color: Color(0xFF6A1B9A),
          ),
          OrderLineItem(
            productId: 'p10',
            name: 'لمبة LED 15 وات',
            price: 25,
            quantity: 2,
            icon: Icons.flash_on,
            color: Color(0xFFF57F17),
          ),
        ],
      ),
      StoreOrder(
        id: '1257',
        date: DateTime(2024, 6, 22),
        status: OrderStatus.processing,
        subtotal: 1020,
        shipping: 30,
        discount: 120,
        couponCode: 'SAMEH50',
        total: 930,
        customerName: 'سارة علي',
        customerPhone: '01123456789',
        items: const [
          OrderLineItem(
            productId: 'p2',
            name: 'خلاط حوض ستانلس',
            price: 650,
            quantity: 1,
            icon: Icons.water_drop,
            color: Color(0xFF1565C0),
          ),
          OrderLineItem(
            productId: 'p9',
            name: 'صنبور مطبخ ستانلس',
            price: 250,
            quantity: 1,
            icon: Icons.water_drop,
            color: Color(0xFF1565C0),
          ),
          OrderLineItem(
            productId: 'p12',
            name: 'بوية بيضاء 5 لتر',
            price: 120,
            quantity: 1,
            icon: Icons.format_paint,
            color: Color(0xFF2E7D32),
          ),
        ],
      ),
    ]);
  }

  // تحميل الطلبات من الـ API
  Future<void> loadOrders() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await ApiService().init();
      final res = await ApiService().get('/orders');
      final ordersJson = res.data['orders'] as List<dynamic>;

      final apiOrders = <StoreOrder>[];
      for (final j in ordersJson) {
        apiOrders.add(_mapOrder(j as Map<String, dynamic>));
      }

      _orders
        ..clear()
        ..addAll(apiOrders);
      _loading = false;
      notifyListeners();
    } catch (e) {
      // لو فشل، نحتفظ بالبيانات المحلية
      _loading = false;
      notifyListeners();
    }
  }

  // إنشاء طلب جديد عن طريق الـ API
  Future<StoreOrder?> placeOrder({
    required CartProvider cart,
    AuthProvider? auth,
    String address = 'القاهرة، مصر',
    PaymentMethod paymentMethod = PaymentMethod.cod,
    String? couponCode,
    // إثبات الدفع للمسارات غير COD
    String? proofFromNumber,
    String? proofFromName,
    String? proofImage,
    String? proofDate,
  }) async {
    // تحضير items للإرسال
    final items = cart.items.map((item) => {
      'productId': item.id,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'imageUrl': item.imageUrl,
    }).toList();

    try {
      await ApiService().init();
      final body = <String, dynamic>{
        'items': items,
        'shipping': cart.shipping,
        'address': address,
        'customerPhone': auth?.phone,
        'paymentMethod': paymentMethod.key,
      };
      if (couponCode != null && couponCode.trim().isNotEmpty) {
        body['couponCode'] = couponCode.trim();
      }
      // للمسارات غير COD — إثبات التحويل
      if (paymentMethod != PaymentMethod.cod) {
        if (proofFromNumber != null && proofFromNumber.trim().isNotEmpty) {
          body['proofFromNumber'] = proofFromNumber.trim();
        }
        if (proofFromName != null && proofFromName.trim().isNotEmpty) {
          body['proofFromName'] = proofFromName.trim();
        }
        if (proofImage != null && proofImage.isNotEmpty) {
          body['proofImage'] = proofImage;
        }
        if (proofDate != null && proofDate.trim().isNotEmpty) {
          body['proofDate'] = proofDate.trim();
        }
      }
      final res = await ApiService().post('/orders', data: body);
      final newOrder = _mapOrder(res.data['order'] as Map<String, dynamic>);

      // أضف الطلب في أول القائمة (محلياً)
      _orders.insert(0, newOrder);
      // امسح السلة
      cart.clearCart();
      notifyListeners();
      return newOrder;
    } catch (e) {
      // fallback: لو السيرفر مش شغال، نعمل الطلب محلياً
      final localOrder = _createLocalOrder(
        cart: cart,
        auth: auth,
        address: address,
        paymentMethod: paymentMethod,
        couponCode: couponCode,
      );
      _orders.insert(0, localOrder);
      cart.clearCart();
      notifyListeners();
      return localOrder;
    }
  }

  // إنشاء طلب محلي (لو السيرفر مش شغال)
  StoreOrder _createLocalOrder({
    required CartProvider cart,
    AuthProvider? auth,
    String address = 'القاهرة، مصر',
    PaymentMethod paymentMethod = PaymentMethod.cod,
    String? couponCode,
  }) {
    final items = cart.items
        .map((item) => OrderLineItem(
              productId: item.id,
              name: item.name,
              price: item.price,
              quantity: item.quantity,
              imageUrl: item.imageUrl,
              icon: item.icon,
              color: item.color,
            ))
        .toList();

    double discount = 0;
    double total = cart.totalPrice;
    if (couponCode != null && couponCode.trim().isNotEmpty) {
      // خصم بسيط 50 ج.م كقيمة افتراضية للـ fallback المحلي
      discount = 50;
      total = (total - discount).clamp(0, double.infinity);
    }

    return StoreOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      status: OrderStatus.pending,
      subtotal: cart.subtotal,
      shipping: cart.shipping,
      discount: discount,
      couponCode: couponCode,
      total: total,
      customerName: auth?.name,
      customerPhone: auth?.phone,
      address: address,
      paymentMethod: paymentMethod,
      items: items,
    );
  }

  List<StoreOrder> byStatus(OrderStatus? status) {
    if (status == null) return orders;
    return _orders.where((o) => o.status == status).toList();
  }

  /// بناء رسالة واتساب بتفاصيل الطلب (للدفع عند الاستلام)
  static String buildWhatsAppMessage(StoreOrder order) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *طلب جديد من متجر MARCELINO*');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 رقم الطلب: ${order.displayId}');
    buffer.writeln('📅 التاريخ: ${order.formattedDate}');
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      buffer.writeln('👤 الاسم: ${order.customerName}');
    }
    if (order.customerPhone != null && order.customerPhone!.isNotEmpty) {
      buffer.writeln('📞 الهاتف: ${order.customerPhone}');
    }
    buffer.writeln('📍 العنوان: ${order.address}');
    buffer.writeln('💳 الدفع: ${order.paymentMethod.labelAr}');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('🛍️ *المنتجات:*');
    for (final item in order.items) {
      buffer.writeln('• ${item.name} (${item.quantity}×) = ${item.lineTotal.toInt()} ج.م');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('المجموع: ${order.subtotal.toInt()} ج.م');
    buffer.writeln('الشحن: ${order.shipping == 0 ? "مجاني" : "${order.shipping.toInt()} ج.م"}');
    buffer.writeln('✅ *الإجمالي: ${order.total.toInt()} ج.م*');
    buffer.writeln('━━━━━━━━━━━━━━━━');
    buffer.writeln('تم الطلب من تطبيق MARCELINO 🙏');
    return buffer.toString();
  }

  StoreOrder? byId(String id) {
    final cleanId = id.startsWith('#') ? id.substring(1) : id;
    try {
      return _orders.firstWhere((o) => o.id == cleanId);
    } catch (_) {
      return null;
    }
  }

  // تحويل JSON لـ StoreOrder
  StoreOrder _mapOrder(Map<String, dynamic> j) {
    final items = (j['items'] as List).map((it) {
      final item = it as Map<String, dynamic>;
      return OrderLineItem(
        productId: item['productId']?.toString() ?? '',
        name: item['name'] as String,
        price: (item['price'] as num).toDouble(),
        quantity: (item['quantity'] as num).toInt(),
        imageUrl: item['imageUrl'] as String?,
        icon: Icons.inventory_2,
        color: const Color(0xFF1565C0),
      );
    }).toList();

    OrderStatus status;
    switch (j['status']) {
      case 'processing':
        status = OrderStatus.processing;
        break;
      case 'delivered':
        status = OrderStatus.delivered;
        break;
      case 'cancelled':
        status = OrderStatus.cancelled;
        break;
      case 'pending':
      default:
        status = OrderStatus.pending;
    }

    return StoreOrder(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      date: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : DateTime.now(),
      status: status,
      subtotal: (j['subtotal'] as num).toDouble(),
      shipping: (j['shipping'] as num).toDouble(),
      discount: (j['discount'] as num?)?.toDouble() ?? 0,
      couponCode: j['couponCode'] as String?,
      proofFromNumber: (j['proofFromNumber'] as String?) ?? '',
      proofFromName: (j['proofFromName'] as String?) ?? '',
      proofImage: (j['proofImage'] as String?) ?? '',
      proofDate: (j['proofDate'] as String?) ?? '',
      total: (j['total'] as num).toDouble(),
      customerName: j['customerName'] as String?,
      customerPhone: j['customerPhone'] as String?,
      address: j['address'] as String? ?? 'القاهرة، مصر',
      paymentMethod: PaymentMethodX.fromKey(j['paymentMethod'] as String?),
      items: items,
    );
  }
}
