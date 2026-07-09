import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';
import 'package:plumbing_store_app/core/providers/settings_provider.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/theme/app_theme.dart';
import '../../../../core/widgets/page_transitions.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: AppTheme.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const _SectionTitle(title: 'المظهر'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _NavigationTile(
                  icon: Icons.language,
                  title: 'اللغة',
                  subtitle: context.watch<SettingsProvider>().isArabic ? 'العربية' : 'English',
                  onTap: () => _showLanguageDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle(title: 'الإشعارات'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'تفعيل الإشعارات',
                  subtitle: 'استلام إشعارات الطلبات والعروض',
                  value: context.watch<SettingsProvider>().notificationsEnabled,
                  onChanged: (_) => context.read<SettingsProvider>().toggleNotifications(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle(title: 'الاتصال بالخادم'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _NavigationTile(
                  icon: Icons.dns_outlined,
                  title: 'عنوان الـ API',
                  subtitle: context.watch<SettingsProvider>().apiBaseUrl,
                  onTap: () => _showApiUrlDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle(title: 'التطبيق'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _NavigationTile(
                  icon: Icons.info_outline,
                  title: 'من نحن',
                  subtitle: 'تعرف على متجر مارسيلينو',
                  onTap: () => _showAboutDialog(context),
                ),
                _NavigationTile(
                  icon: Icons.contact_support_outlined,
                  title: 'تواصل معنا',
                  subtitle: 'اتصل بنا أو أرسل رسالة',
                  onTap: () => _showContactDialog(context),
                ),
                _NavigationTile(
                  icon: Icons.star_outline,
                  title: 'قيّم التطبيق',
                  subtitle: 'ساعدنا بالتقييم',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('شكراً لاهتمامك! ستتوفر هذه الميزة قريباً')),
                    );
                  },
                ),
                _NavigationTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'سياسة الخصوصية',
                  subtitle: 'كيف نحمي بياناتك',
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const _SectionTitle(title: 'الحساب'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _NavigationTile(
                  icon: Icons.delete_outline,
                  title: 'حذف حسابي',
                  subtitle: 'حذف الحساب وكل البيانات',
                  titleColor: AppTheme.error,
                  iconColor: AppTheme.error,
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'MARCELINO v1.0.0',
                style: AppTheme.caption(context),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اختر اللغة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  settings.isArabic ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: settings.isArabic ? AppTheme.orange : AppTheme.textLightMuted,
                ),
                title: const Text('العربية'),
                onTap: () {
                  settings.setLanguage('ar');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  !settings.isArabic ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: !settings.isArabic ? AppTheme.orange : AppTheme.textLightMuted,
                ),
                title: const Text('English'),
                onTap: () {
                  settings.setLanguage('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApiUrlDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final controller = TextEditingController(text: settings.apiBaseUrl);
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.dns, color: AppTheme.orange),
              SizedBox(width: 10),
              Text('عنوان الـ API'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حدّد عنوان الخادم الذي يتصل به التطبيق. مفيد للتجربة على جهاز حقيقي:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textLightMuted, height: 1.6),
                ),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: AppConstants.baseUrl,
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: AppConstants.suggestedBaseUrls
                      .map((u) => ActionChip(
                            label: Text(u, style: const TextStyle(fontSize: 11)),
                            onPressed: () => controller.text = u,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                final ok = await settings.setApiBaseUrl(controller.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'تم تحديث عنوان الـ API' : 'عنوان غير صالح')),
                );
              },
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.store, color: AppTheme.orange),
              SizedBox(width: 10),
              Text('من نحن'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'متجر مارسيلينو',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
              SizedBox(height: 8),
              Text(
                'متجرك الأول لكل ما تحتاجه من مستلزمات السباكة، الحدايد، البويات، والأدوات. نوفر لك أفضل المنتجات بأسعار تنافسية مع خدمة توصيل سريعة.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLightPrimary, height: 1.6),
              ),
              SizedBox(height: 12),
              Text(
                '✓ أكثر من 13 منتج متنوع\n'
                '✓ 8 أقسام رئيسية\n'
                '✓ شحن مجاني فوق 500 جنيه\n'
                '✓ كوبونات وعروض مستمرة\n'
                '✓ خدمة عملاء على مدار الساعة',
                style: TextStyle(fontSize: 14, color: AppTheme.textLightMuted, height: 1.8),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.contact_support, color: AppTheme.orange),
              SizedBox(width: 10),
              Text('تواصل معنا'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContactTile(icon: Icons.phone, label: 'الهاتف', value: '01012345678'),
              _ContactTile(icon: Icons.email_outlined, label: 'البريد الإلكتروني', value: 'support@marcelino.com'),
              _ContactTile(icon: Icons.location_on, label: 'العنوان', value: 'القاهرة، مصر'),
              _ContactTile(icon: Icons.access_time, label: 'ساعات العمل', value: 'السبت - الخميس: 9ص - 10م'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final t = AppTheme.of(context);
    Navigator.push(
      context,
      AppTransitions.fade(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: t.background,
            appBar: AppBar(
              title: const Text('سياسة الخصوصية'),
              backgroundColor: AppTheme.navy,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سياسة الخصوصية لمتجر مارسيلينو', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('1. جمع البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  Text('نجمع بياناتك الشخصية (الاسم، رقم الهاتف، العنوان) عند التسجيل أو تقديم طلب فقط. لا نشارك هذه البيانات مع أي طرف ثالث.', style: TextStyle(fontSize: 14, height: 1.6, color: t.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('2. استخدام البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  Text('نستخدم بياناتك لتسهيل عملية الطلب والتوصيل، وإرسال إشعارات حول طلباتك والعروض المتاحة.', style: TextStyle(fontSize: 14, height: 1.6, color: t.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('3. حماية البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  Text('نعتمد على أحدث تقنيات التشفير لحماية بياناتك أثناء التخزين والنقل.', style: TextStyle(fontSize: 14, height: 1.6, color: t.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('4. حذف البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  Text('يمكنك طلب حذف حسابك وبياناتك في أي وقت من خلال صفحة الإعدادات.', style: TextStyle(fontSize: 14, height: 1.6, color: t.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('5. التحديثات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 8),
                  Text('نحتفظ بحق تعديل سياسة الخصوصية في أي وقت. سنقوم بإشعارك بأي تغييرات جوهرية.', style: TextStyle(fontSize: 14, height: 1.6, color: t.textPrimary)),
                  const SizedBox(height: 30),
                  Center(child: Text('آخر تحديث: يوليو 2026', style: TextStyle(fontSize: 12, color: t.textMuted))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppTheme.error),
              SizedBox(width: 10),
              Text('حذف الحساب', style: TextStyle(color: AppTheme.error)),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من حذف حسابك؟ سيتم حذف جميع بياناتك وطلباتك نهائياً ولا يمكن استرجاعها.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pop(context);
                Navigator.pop(context); // الرجوع من الإعدادات
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الخروج. لل حذف نهائي، تواصل مع الإدارة.')),
                );
              },
              child: const Text('تأكيد', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: t.textPrimary)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppTheme.navy),
      title: Text(title, style: TextStyle(color: t.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: t.textMuted)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.orange,
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.navy),
      title: Text(title, style: TextStyle(color: titleColor ?? t.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: t.textMuted)),
      trailing: Icon(Icons.arrow_back_ios, size: 14, color: t.textMuted),
      onTap: onTap,
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.navy, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLightMuted)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textLightPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
