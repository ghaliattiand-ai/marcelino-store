import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:plumbing_store_app/core/models/order_model.dart';
import 'package:plumbing_store_app/core/models/public_settings.dart';
import 'package:plumbing_store_app/core/theme/app_theme.dart';
import 'package:plumbing_store_app/core/providers/cart_provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/providers/addresses_provider.dart';
import 'package:plumbing_store_app/core/providers/orders_provider.dart';
import 'package:plumbing_store_app/core/providers/navigation_provider.dart';
import 'package:plumbing_store_app/core/providers/public_settings_provider.dart';
import 'package:plumbing_store_app/core/data/store_config_service.dart';
import 'addresses_page.dart';
import '../../../../core/widgets/page_transitions.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaymentMethod _selectedMethod = PaymentMethod.cod;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  // حقول إثبات الدفع (للمسارات غير COD)
  final TextEditingController _proofFromNumberController = TextEditingController();
  final TextEditingController _proofFromNameController = TextEditingController();
  final TextEditingController _proofDateController = TextEditingController();
  String? _proofImageBase64;
  File? _proofImageFile;
  StoreConfig? _config;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadPublicSettings();
    _prefillData();
    _proofDateController.text = _todayIso();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _proofFromNumberController.dispose();
    _proofFromNameController.dispose();
    _proofDateController.dispose();
    super.dispose();
  }

  String _todayIso() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadConfig() async {
    final config = await StoreConfigService().load();
    if (mounted) setState(() => _config = config);
  }

  Future<void> _loadPublicSettings() async {
    await context.read<PublicSettingsProvider>().load();
  }

  void _prefillData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final addresses = context.read<AddressesProvider>();
      _phoneController.text = auth.phone ?? '';
      final defaultAddr = addresses.defaultAddress;
      if (defaultAddr != null) {
        final fullAddr =
            '${defaultAddr.street}${defaultAddr.street.isNotEmpty && defaultAddr.city.isNotEmpty ? '، ' : ''}${defaultAddr.city}';
        _addressController.text = fullAddr;
        if (_phoneController.text.isEmpty) {
          _phoneController.text = defaultAddr.phone;
        }
      } else {
        _addressController.text = 'القاهرة، مصر';
      }
    });
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    try {
      final x = await picker.pickImage(
        imageQuality: 75,
        maxWidth: 1280,
        source: ImageSource.gallery,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final base64 = bytes.buffer.asUint8List();
      // نقوم بتكوين data URI
      final dataUri = 'data:image/jpeg;base64,${base64Encode(base64)}';
      if (!mounted) return;
      setState(() {
        _proofImageFile = File(x.path);
        _proofImageBase64 = dataUri;
      });
    } catch (e) {
      _toast('تعذّر اختيار الصورة', error: true);
    }
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();
    if (address.isEmpty) {
      _toast('اكتب عنوان التوصيل', error: true);
      return;
    }
    if (phone.isEmpty) {
      _toast('اكتب رقم الهاتف', error: true);
      return;
    }

    // للمسارات غير COD — نتحقق من وجود إثبات الدفع
    if (_selectedMethod != PaymentMethod.cod) {
      if (_proofFromNumberController.text.trim().isEmpty) {
        _toast('اكتب رقم المحفظة/الحساب اللي حوّلت منه', error: true);
        return;
      }
      if (_proofImageBase64 == null) {
        _toast('ارفع صورة إثبات التحويل (سكرين شوت)', error: true);
        return;
      }
    }

    setState(() => _placing = true);
    final cart = context.read<CartProvider>();
    final order = await context.read<OrdersProvider>().placeOrder(
          cart: cart,
          auth: context.read<AuthProvider>(),
          address: address,
          paymentMethod: _selectedMethod,
          // للمسارات غير COD — نمرّر إثبات الدفع
          proofFromNumber: _selectedMethod == PaymentMethod.cod
              ? null
              : _proofFromNumberController.text.trim(),
          proofFromName: _selectedMethod == PaymentMethod.cod
              ? null
              : _proofFromNameController.text.trim(),
          proofDate: _selectedMethod == PaymentMethod.cod
              ? null
              : _proofDateController.text.trim(),
          proofImage: _selectedMethod == PaymentMethod.cod ? null : _proofImageBase64,
        );

    if (!mounted) return;
    setState(() => _placing = false);

    if (order == null) {
      _toast('حصل خطأ، حاول تاني', error: true);
      return;
    }

    // لو الدفع عند الاستلام → نحوّل للواتساب
    if (_selectedMethod == PaymentMethod.cod) {
      await _openWhatsApp(order);
    }
    if (!mounted) return;
    _showSuccessDialog(order);
  }

  Future<void> _openWhatsApp(StoreOrder order) async {
    final config = _config ?? StoreConfigService().config;
    final storeNumber = config.whatsappNumber;
    if (storeNumber.isEmpty) return;

    final msg = OrdersProvider.buildWhatsAppMessage(order);
    final normalized = StoreConfigService().normalizeWhatsappNumber(storeNumber);
    final url = 'https://wa.me/$normalized?text=${Uri.encodeComponent(msg)}';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // نتجاهل لو واتساب مش موجود
    }
  }

  void _showSuccessDialog(StoreOrder order) {
    final isCod = _selectedMethod == PaymentMethod.cod;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(
            CurvedAnimation(parent: ModalRoute.of(_)!.animation!, curve: Curves.easeOutBack),
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تم استلام طلبك! 🎉',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'طلب رقم ${order.displayId}',
                  style: const TextStyle(color: AppTheme.textLightMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'الإجمالي: ${order.total.toInt()} ج.م',
                  style: const TextStyle(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isCod) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'تم تحويلك للواتساب لتأكيد الطلب',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLightMuted, fontSize: 12),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text(
                    'تم إرسال إثبات التحويل للمراجعة، سيؤكد الأدمن الطلب بعد التحقق',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLightMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Checkout page
                    context.read<NavigationProvider>().goToTab(4); // طلباتي
                  },
                  child: const Text('تتبع الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.error : AppTheme.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final t = AppTheme.of(context);
    final settings = context.watch<PublicSettingsProvider>().settings;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
          backgroundColor: AppTheme.navy,
          elevation: 0,
          title: const Text('إتمام الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _SectionCard(
              title: 'ملخص السلة',
              icon: Icons.shopping_cart_outlined,
              child: _OrderSummary(cart: cart),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'بيانات التوصيل',
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  _buildTextField(controller: _addressController, label: 'عنوان التوصيل', icon: Icons.location_on_outlined, maxLines: 2),
                  const SizedBox(height: 10),
                  _buildTextField(controller: _phoneController, label: 'رقم الهاتف', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(context, AppTransitions.slideUp(const AddressesPage())),
                      icon: const Icon(Icons.bookmark_outline, size: 18),
                      label: const Text('عناويني المحفوظة'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'طريقة الدفع',
              icon: Icons.payments_outlined,
              child: _buildPaymentMethods(),
            ),
            // لو الطريقة غير كاش → نعرض بيانات التحويل + حقول الإثبات
            if (_selectedMethod != PaymentMethod.cod) ...[
              const SizedBox(height: 12),
              _PaymentInfoCard(method: _selectedMethod, settings: settings, config: _config),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'إثبات التحويل',
                icon: Icons.receipt_long_outlined,
                child: _buildProofFields(),
              ),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              title: 'الإجمالي',
              icon: Icons.receipt_long_outlined,
              child: _TotalSummary(cart: cart),
            ),
            const SizedBox(height: 100),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(cart),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: PaymentMethod.values.map((m) {
        final selected = m == _selectedMethod;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: InkWell(
            onTap: () => setState(() => _selectedMethod = m),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? m.color.withValues(alpha: 0.06) : AppTheme.of(context).card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? m.color : AppTheme.of(context).border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m.icon, color: m.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.labelAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(m.description, style: const TextStyle(color: AppTheme.textLightMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? m.color : AppTheme.of(context).textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProofFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _proofFromNumberController,
          label: 'رقم المحفظة/الحساب اللي حوّلت منه',
          icon: Icons.account_balance_wallet_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _proofFromNameController,
          label: 'اسم صاحب الحساب (اختياري)',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _proofDateController,
                label: 'تاريخ التحويل',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.datetime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // رفع صورة السكرين شوت
        InkWell(
          onTap: _pickProofImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.of(context).fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _proofImageFile != null ? AppTheme.orange : AppTheme.of(context).border,
                width: _proofImageFile != null ? 2 : 1,
                style: _proofImageFile != null ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _proofImageFile != null ? Icons.check_circle : Icons.add_a_photo_outlined,
                  color: _proofImageFile != null ? AppTheme.success : AppTheme.navy,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _proofImageFile != null ? 'تم اختيار صورة الإثبات ✓' : 'اضغط لرفع صورة إثبات التحويل',
                    style: TextStyle(
                      color: _proofImageFile != null ? AppTheme.success : AppTheme.of(context).textMuted,
                      fontWeight: _proofImageFile != null ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_proofImageFile != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_proofImageFile!, height: 160, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _proofImageFile = null;
                _proofImageBase64 = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              label: const Text('إزالة الصورة', style: TextStyle(color: AppTheme.error)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سنرسل صورة الإيصال وبيانات التحويل للإدارة للمراجعة. سيتم تأكيد طلبك بعد التحقق فقط.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLightPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.navy),
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        boxShadow: [
          BoxShadow(
            color: AppTheme.of(context).shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الإجمالي', style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 12)),
                  Text(
                    '${cart.totalPrice.toInt()} ج.م',
                    style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _placing ? null : _placeOrder,
                child: _placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _selectedMethod == PaymentMethod.cod ? 'تأكيد الطلب + واتساب' : 'تأكيد الطلب + إثبات',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== قسم البطاقات =====
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.orange, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  const _OrderSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      children: [
        ...cart.items.take(3).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} (${item.quantity}×)',
                      style: TextStyle(fontSize: 13, color: t.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.lineTotal.toInt()} ج.م',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: t.textPrimary),
                  ),
                ],
              ),
            )),
        if (cart.items.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('و ${cart.items.length - 3} منتج آخر...', style: TextStyle(color: t.textMuted, fontSize: 12)),
          ),
      ],
    );
  }
}

class _TotalSummary extends StatelessWidget {
  final CartProvider cart;
  const _TotalSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('المجموع', '${cart.subtotal.toInt()} ج.م', context: context),
        _row('الشحن', cart.shipping == 0 ? 'مجاني' : '${cart.shipping.toInt()} ج.م', context: context),
        const Divider(height: 16),
        _row('الإجمالي', '${cart.totalPrice.toInt()} ج.م', bold: true, color: AppTheme.orange, context: context),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color, required BuildContext context}) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: t.textMuted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 18 : 14,
              color: color ?? t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== بطاقة بيانات التحويل (تجمع بياناتها من PublicSettingsProvider) =====
class _PaymentInfoCard extends StatelessWidget {
  final PaymentMethod method;
  final PublicSettings settings;
  final StoreConfig? config; // fallback لو PublicSettings مش متاح

  const _PaymentInfoCard({required this.method, required this.settings, this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: method.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: method.color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: method.color, size: 20),
              const SizedBox(width: 8),
              Text('حوّل على هذا الحساب', style: TextStyle(color: method.color, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'انسخ الرقم/الحساب واعمل تحويل لقيمته، ثم ارفع صورة الإيصال بالأسفل',
            style: TextStyle(fontSize: 11, color: AppTheme.textLightMuted),
          ),
          const SizedBox(height: 12),
          ..._buildInfoRows(),
        ],
      ),
    );
  }

  List<Widget> _buildInfoRows() {
    // نعتمد PublicSettings أولاً، ولو فاضي fallback للـ legacy StoreConfig
    switch (method) {
      case PaymentMethod.etisalatCash:
        final number = settings.paymentMethods.etisalatCash.number.isNotEmpty
            ? settings.paymentMethods.etisalatCash.number
            : (config?.etisalatCashNumber ?? 'غير محدد');
        final name = settings.paymentMethods.etisalatCash.name.isNotEmpty
            ? settings.paymentMethods.etisalatCash.name
            : (config?.etisalatCashName ?? '');
        return [
          _infoLine('رقم المحفظة', number, copyable: number != 'غير محدد'),
          if (name.isNotEmpty) _infoLine('الاسم', name, copyable: true),
        ];
      case PaymentMethod.instapay:
        final handle = settings.paymentMethods.instapay.handle.isNotEmpty
            ? settings.paymentMethods.instapay.handle
            : (config?.instapayHandle ?? 'غير محدد');
        return [_infoLine('معال إنستا باي', handle, copyable: handle != 'غير محدد')];
      case PaymentMethod.bankTransfer:
        final b = settings.paymentMethods.bankTransfer;
        final bankName = b.bankName.isNotEmpty ? b.bankName : (config?.bankName ?? '');
        final accName = b.accountName.isNotEmpty ? b.accountName : (config?.bankAccountName ?? '');
        final accNum = b.accountNumber.isNotEmpty ? b.accountNumber : (config?.bankAccountNumber ?? 'غير محدد');
        return [
          if (bankName.isNotEmpty) _infoLine('البنك', bankName, copyable: true),
          if (accName.isNotEmpty) _infoLine('اسم صاحب الحساب', accName, copyable: true),
          _infoLine('رقم الحساب', accNum, copyable: accNum != 'غير محدد'),
        ];
      case PaymentMethod.cod:
        return [];
    }
  }

  Widget _infoLine(String label, String value, {bool copyable = false}) {
    final isEmpty = value.isEmpty || value == 'غير محدد';
    return Builder(builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textLightMuted, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: (copyable && !isEmpty)
                    ? () async {
                        await Clipboard.setData(ClipboardData(text: value));
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('تم نسخ الرقم ✓'), duration: Duration(seconds: 1)),
                        );
                      }
                    : null,
                child: Text(
                  value,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isEmpty ? AppTheme.textLightMuted : AppTheme.textLightPrimary,
                    decoration: (copyable && !isEmpty) ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
