import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plumbing_store_app/core/network/api_service.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class Coupon {
  final String id;
  final String code;
  final String description;
  final String discount;
  final String type; // 'percent' أو 'fixed' أو 'shipping'
  final DateTime expiresAt;
  final double minOrder;
  final bool isActive;

  const Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discount,
    required this.type,
    required this.expiresAt,
    this.minOrder = 0,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get discountLabel {
    if (type == 'percent') return '$discount% خصم';
    if (type == 'fixed') return '$discount جنيه خصم';
    return 'شحن مجاني';
  }

  factory Coupon.fromJson(Map<String, dynamic> j) {
    return Coupon(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      code: j['code'] as String,
      description: j['description'] as String,
      discount: (j['discount'] ?? 0).toString(),
      type: j['type'] as String,
      expiresAt: j['expiresAt'] != null ? DateTime.parse(j['expiresAt']) : DateTime.now(),
      minOrder: (j['minOrder'] as num?)?.toDouble() ?? 0,
      isActive: j['isActive'] as bool? ?? true,
    );
  }
}

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  List<Coupon> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _loading = true);
    try {
      await ApiService().init();
      final res = await ApiService().get('/coupons');
      final list = res.data['coupons'] as List<dynamic>;
      setState(() {
        _coupons = list.map((j) => Coupon.fromJson(j as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      // fallback للكوبونات المحلية
      setState(() {
        _coupons = _defaultCoupons();
        _loading = false;
      });
    }
  }

  List<Coupon> _defaultCoupons() {
    return [
      Coupon(
        id: '1', code: 'MARCEL20', description: 'خصم 20% على جميع المنتجات',
        discount: '20', type: 'percent',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
      Coupon(
        id: '2', code: 'SAMEH50', description: 'خصم 50 جنيه فوق 300',
        discount: '50', type: 'fixed', minOrder: 300,
        expiresAt: DateTime.now().add(const Duration(days: 15)),
      ),
      Coupon(
        id: '3', code: 'FREESHIP', description: 'شحن مجاني لأي طلب',
        discount: '0', type: 'shipping',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeCoupons = _coupons.where((c) => c.isActive && !c.isExpired).toList();
    final expiredCoupons = _coupons.where((c) => !c.isActive || c.isExpired).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: const Text('كوبونات الخصم'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2A4A)))
            : ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // رأس القسم
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_navy, Color(0xFF152040)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_offer, color: _orange, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'وفّر أكتر مع كوبوناتنا!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عندك ${activeCoupons.length} كوبون صالح للاستخدام',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // الكوبونات النشطة
            if (activeCoupons.isNotEmpty) ...[
              const Text(
                'الكوبونات النشطة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 12),
              ...activeCoupons.map((coupon) => _CouponCard(coupon: coupon)),
            ],

            // الكوبونات المنتهية
            if (expiredCoupons.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'منتهية الصلاحية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[500]),
              ),
              const SizedBox(height: 12),
              ...expiredCoupons.map((coupon) => _CouponCard(coupon: coupon, isExpired: true)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isExpired;

  const _CouponCard({required this.coupon, this.isExpired = false});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الكود: ${coupon.code}'),
        backgroundColor: _navy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.local_offer, size: 50, color: isExpired ? Colors.grey : _orange),
              const SizedBox(height: 12),
              Text(
                coupon.discountLabel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.grey : _navy,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: isExpired ? Colors.grey : _orange, width: 2, strokeAlign: BorderSide.strokeAlignOutside),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  coupon.code,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: isExpired ? Colors.grey : _navy,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                coupon.description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('الحد الأدنى للطلب', '${coupon.minOrder.toString()} جنيه'),
              _buildInfoRow('تاريخ الانتهاء', '${coupon.expiresAt.day}/${coupon.expiresAt.month}/${coupon.expiresAt.year}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'شروط الاستخدام:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navy),
              ),
              const SizedBox(height: 4),
              Text(
                '• لا يمكن استخدام أكثر من كوبون في نفس الطلب\n'
                '• الكوبون غير قابل للاستبدال أو التحويل\n'
                '• يمكن إلغاء العرض في أي وقت\n'
                '• الحد الأدنى للطلب يجب أن يكون بعد الخصم',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isExpired ? null : () => _copyCode(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExpired ? Colors.grey : _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isExpired ? 'منتهي الصلاحية' : 'نسخ الكود',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isExpired ? Colors.grey[300]! : Colors.transparent),
        boxShadow: isExpired
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // جزء الخصم
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey[200]
                        : _orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (coupon.type == 'percent')
                        Text(coupon.discount, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isExpired ? Colors.grey : _orange))
                      else if (coupon.type == 'fixed')
                        Text(coupon.discount, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isExpired ? Colors.grey : _orange))
                      else
                        Icon(Icons.local_shipping, size: 28, color: isExpired ? Colors.grey : _orange),
                      if (coupon.type == 'percent')
                        Text('%', style: TextStyle(fontSize: 12, color: isExpired ? Colors.grey : _orange))
                      else if (coupon.type == 'fixed')
                        Text('جنيه', style: TextStyle(fontSize: 10, color: isExpired ? Colors.grey : _orange)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.code,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: isExpired ? Colors.grey : _navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: isExpired ? Colors.grey : Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'ينتهي: ${coupon.expiresAt.day}/${coupon.expiresAt.month}/${coupon.expiresAt.year}',
                            style: TextStyle(fontSize: 11, color: isExpired ? Colors.grey : Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // زر النسخ
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.grey[200] : _navy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.copy, size: 18, color: isExpired ? Colors.grey : _navy),
                    onPressed: isExpired ? null : () => _copyCode(context),
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
