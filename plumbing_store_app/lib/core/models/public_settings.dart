import '../models/order_model.dart';

/// بيانات الإعدادات العامة المتاحة للعامة (من GET /api/settings/public).
///
/// نستخدمها في الـ checkout لعرض رقم/حساب اللي حوّل عليه العميل حسب
/// طريقة الدفع المختارة (etisalat_cash / instapay / bank_transfer).
class PublicSettings {
  final String storeName;
  final String currency;
  final double shippingFee;
  final double freeShippingThreshold;
  final String shippingNote;
  final String contactPhone;
  final String contactEmail;
  final String welcomeMessage;
  final String whatsappNumber;
  final PaymentAccounts paymentMethods;

  const PublicSettings({
    this.storeName = 'MARCELINO',
    this.currency = 'ج.م',
    this.shippingFee = 30,
    this.freeShippingThreshold = 500,
    this.shippingNote = 'الشحن خلال 2-4 أيام عمل',
    this.contactPhone = '',
    this.contactEmail = '',
    this.welcomeMessage = '',
    this.whatsappNumber = '',
    this.paymentMethods = const PaymentAccounts(),
  });

  factory PublicSettings.fromJson(Map<String, dynamic> j) {
    final pm = (j['paymentMethods'] as Map<String, dynamic>?) ?? const {};
    return PublicSettings(
      storeName: j['storeName'] as String? ?? 'MARCELINO',
      currency: j['currency'] as String? ?? 'ج.م',
      shippingFee: (j['shippingFee'] as num?)?.toDouble() ?? 30,
      freeShippingThreshold:
          (j['freeShippingThreshold'] as num?)?.toDouble() ?? 500,
      shippingNote: j['shippingNote'] as String? ?? '',
      contactPhone: j['contactPhone'] as String? ?? '',
      contactEmail: j['contactEmail'] as String? ?? '',
      welcomeMessage: j['welcomeMessage'] as String? ?? '',
      whatsappNumber: j['whatsappNumber'] as String? ?? '',
      paymentMethods: PaymentAccounts.fromJson(pm),
    );
  }

  static const PublicSettings fallback = PublicSettings();
}

class PaymentAccounts {
  final EtisalatCashAccount etisalatCash;
  final InstapayAccount instapay;
  final BankAccount bankTransfer;

  const PaymentAccounts({
    this.etisalatCash = const EtisalatCashAccount(),
    this.instapay = const InstapayAccount(),
    this.bankTransfer = const BankAccount(),
  });

  factory PaymentAccounts.fromJson(Map<String, dynamic> j) {
    return PaymentAccounts(
      etisalatCash: EtisalatCashAccount.fromJson(
        (j['etisalatCash'] as Map<String, dynamic>?) ?? const {},
      ),
      instapay: InstapayAccount.fromJson(
        (j['instapay'] as Map<String, dynamic>?) ?? const {},
      ),
      bankTransfer: BankAccount.fromJson(
        (j['bankTransfer'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class EtisalatCashAccount {
  final String number;
  final String name;
  const EtisalatCashAccount({this.number = '', this.name = ''});
  factory EtisalatCashAccount.fromJson(Map<String, dynamic> j) {
    return EtisalatCashAccount(
      number: j['number'] as String? ?? '',
      name: j['name'] as String? ?? '',
    );
  }
}

class InstapayAccount {
  final String handle;
  const InstapayAccount({this.handle = ''});
  factory InstapayAccount.fromJson(Map<String, dynamic> j) {
    return InstapayAccount(handle: j['handle'] as String? ?? '');
  }
}

class BankAccount {
  final String bankName;
  final String accountName;
  final String accountNumber;
  const BankAccount({
    this.bankName = '',
    this.accountName = '',
    this.accountNumber = '',
  });
  factory BankAccount.fromJson(Map<String, dynamic> j) {
    return BankAccount(
      bankName: j['bankName'] as String? ?? '',
      accountName: j['accountName'] as String? ?? '',
      accountNumber: j['accountNumber'] as String? ?? '',
    );
  }
}

/// امتداد للوصول لحساب الدفع المناسب حسب طريقة الدفع
extension PaymentMethodAccountX on PaymentMethod {
  /// عنوان العنصر بصيغة نص واحد يسهل عرضه/نسخه
  String accountLabel(PublicSettings s) {
    switch (this) {
      case PaymentMethod.cod:
        return '';
      case PaymentMethod.etisalatCash:
        final n = s.paymentMethods.etisalatCash.number;
        final nm = s.paymentMethods.etisalatCash.name;
        return nm.isEmpty ? n : '$n ($nm)';
      case PaymentMethod.instapay:
        return s.paymentMethods.instapay.handle;
      case PaymentMethod.bankTransfer:
        final b = s.paymentMethods.bankTransfer;
        return [
          if (b.bankName.isNotEmpty) b.bankName,
          if (b.accountName.isNotEmpty) b.accountName,
          if (b.accountNumber.isNotEmpty) b.accountNumber,
        ].join(' • ');
    }
  }
}
