import 'package:flutter/material.dart';

enum OrderStatus { pending, processing, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get labelAr {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد المراجعة';
      case OrderStatus.processing:
        return 'جاري التجهيز';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFF1565C0);
      case OrderStatus.processing:
        return const Color(0xFFFF6B00);
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return const Color(0xFFC62828);
    }
  }

  static OrderStatus? fromLabel(String label) {
    for (final s in OrderStatus.values) {
      if (s.labelAr == label) return s;
    }
    return null;
  }
}

/// طرق الدفع المتاحة
enum PaymentMethod { cod, etisalatCash, instapay, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  /// الاسم بالعربي
  String get labelAr {
    switch (this) {
      case PaymentMethod.cod:
        return 'الدفع عند الاستلام';
      case PaymentMethod.etisalatCash:
        return 'اتصالات كاش';
      case PaymentMethod.instapay:
        return 'إنستا باي';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
    }
  }

  /// وصف مختصر
  String get description {
    switch (this) {
      case PaymentMethod.cod:
        return 'ادفع كاش لمندوب التوصيل';
      case PaymentMethod.etisalatCash:
        return 'حوّل عبر محفظة اتصالات كاش';
      case PaymentMethod.instapay:
        return 'حوّل عبر تطبيق إنستا باي';
      case PaymentMethod.bankTransfer:
        return 'حوّل عبر حسابك البنكي';
    }
  }

  /// الأيقونة
  IconData get icon {
    switch (this) {
      case PaymentMethod.cod:
        return Icons.payments_outlined;
      case PaymentMethod.etisalatCash:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.instapay:
        return Icons.bolt_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
    }
  }

  /// اللون
  Color get color {
    switch (this) {
      case PaymentMethod.cod:
        return const Color(0xFF2E7D32);
      case PaymentMethod.etisalatCash:
        return const Color(0xFF1565C0);
      case PaymentMethod.instapay:
        return const Color(0xFF6A1B9A);
      case PaymentMethod.bankTransfer:
        return const Color(0xFF455A64);
    }
  }

  /// المفتاح اللي بيتخزن في الباك-إند
  String get key {
    switch (this) {
      case PaymentMethod.cod:
        return 'cod';
      case PaymentMethod.etisalatCash:
        return 'etisalat_cash';
      case PaymentMethod.instapay:
        return 'instapay';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  static PaymentMethod fromKey(String? key) {
    switch (key) {
      case 'etisalat_cash':
        return PaymentMethod.etisalatCash;
      case 'instapay':
        return PaymentMethod.instapay;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cod':
      default:
        return PaymentMethod.cod;
    }
  }
}

class OrderLineItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;
  final IconData icon;
  final Color color;

  const OrderLineItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    required this.icon,
    required this.color,
  });

  double get lineTotal => price * quantity;
}

class StoreOrder {
  final String id;
  final DateTime date;
  final OrderStatus status;
  final List<OrderLineItem> items;
  final double subtotal;
  final double shipping;
  final double discount;
  final String? couponCode;
  // إثبات الدفع للمسارات غير COD
  final String proofFromNumber;
  final String proofFromName;
  final String proofImage; // Base64 dataURI أو رابط
  final String proofDate;
  final double total;
  final String? customerName;
  final String? customerPhone;
  final String address;
  final PaymentMethod paymentMethod;

  const StoreOrder({
    required this.id,
    required this.date,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shipping,
    this.discount = 0,
    this.couponCode,
    this.proofFromNumber = '',
    this.proofFromName = '',
    this.proofImage = '',
    this.proofDate = '',
    required this.total,
    this.customerName,
    this.customerPhone,
    this.address = 'القاهرة، مصر',
    this.paymentMethod = PaymentMethod.cod,
  });

  int get productsCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedDate {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get displayId => id.startsWith('#') ? id : '#$id';
}
