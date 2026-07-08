import 'package:plumbing_store_app/core/network/api_service.dart';

/// بيانات إعدادات المتجر (طرق الدفع + واتساب) اللي بتجي من /settings/public
class StoreConfig {
  final String whatsappNumber;
  final String etisalatCashNumber;
  final String etisalatCashName;
  final String instapayHandle;
  final String bankName;
  final String bankAccountName;
  final String bankAccountNumber;
  final String currency;
  final double shippingFee;
  final double freeShippingThreshold;

  const StoreConfig({
    this.whatsappNumber = '',
    this.etisalatCashNumber = '',
    this.etisalatCashName = '',
    this.instapayHandle = '',
    this.bankName = '',
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.currency = 'ج.م',
    this.shippingFee = 30,
    this.freeShippingThreshold = 500,
  });

  factory StoreConfig.fromJson(Map<String, dynamic> j) {
    final pm = (j['paymentMethods'] as Map?) ?? {};
    final etisalat = (pm['etisalatCash'] as Map?) ?? {};
    final instapay = (pm['instapay'] as Map?) ?? {};
    final bank = (pm['bankTransfer'] as Map?) ?? {};
    return StoreConfig(
      whatsappNumber: j['whatsappNumber'] as String? ?? '',
      etisalatCashNumber: etisalat['number'] as String? ?? '',
      etisalatCashName: etisalat['name'] as String? ?? '',
      instapayHandle: instapay['handle'] as String? ?? '',
      bankName: bank['bankName'] as String? ?? '',
      bankAccountName: bank['accountName'] as String? ?? '',
      bankAccountNumber: bank['accountNumber'] as String? ?? '',
      currency: j['currency'] as String? ?? 'ج.م',
      shippingFee: (j['shippingFee'] as num?)?.toDouble() ?? 30,
      freeShippingThreshold:
          (j['freeShippingThreshold'] as num?)?.toDouble() ?? 500,
    );
  }
}

class StoreConfigService {
  static final StoreConfigService _instance = StoreConfigService._internal();
  factory StoreConfigService() => _instance;
  StoreConfigService._internal();

  StoreConfig _config = const StoreConfig();
  StoreConfig get config => _config;

  /// نجيب الإعدادات العامة من السيرفر
  Future<StoreConfig> load() async {
    try {
      await ApiService().init();
      final res = await ApiService().get('/settings/public');
      _config = StoreConfig.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      // نفضل على الإعدادات الافتراضية
    }
    return _config;
  }

  /// نحول الرقم لصيغة دولية (مثلاً 01001234567 → 201001234567)
  String normalizeWhatsappNumber(String number) {
    var n = number.replaceAll(RegExp(r'[^\d]'), '');
    if (n.startsWith('00')) n = n.substring(2);
    if (n.startsWith('0')) n = '20${n.substring(1)}';
    return n;
  }
}
