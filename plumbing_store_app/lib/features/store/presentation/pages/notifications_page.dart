import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String icon;
  final DateTime time;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.time,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'icon': icon,
    'time': time.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    icon: json['icon'] as String,
    time: DateTime.parse(json['time'] as String),
    isRead: json['isRead'] as bool? ?? false,
  );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('app_notifications');

    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      setState(() {
        _notifications = list.map((j) => AppNotification.fromJson(j)).toList();
      });
    } else {
      // بيانات تجريبية أول مرة
      _notifications = _defaultNotifications();
      await _save();
    }
  }

  List<AppNotification> _defaultNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        title: 'تم تأكيد طلبك #1257',
        body: 'طلبك في الطريق وسيصلك خلال 2-3 أيام عمل.',
        icon: 'local_shipping',
        time: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        title: 'عرض خاص! خصم 20%',
        body: 'استخدم كود MARCEL20 للحصول على خصم 20% على جميع المنتجات. العرض ساري حتى نهاية الشهر.',
        icon: 'local_offer',
        time: now.subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        title: 'تم تسليم طلبك #1256',
        body: 'تم تسليم طلبك بنجاح. شكراً لاختيارك مارسيلينو!',
        icon: 'check_circle',
        time: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        title: 'منتجات جديدة متوفرة',
        body: 'تم إضافة مجموعة جديدة من الأدوات اليدوية والمعدات الكهربائية.',
        icon: 'new_releases',
        time: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '5',
        title: 'شحن مجاني للطلبات فوق 500 جنيه',
        body: 'الآن يمكنك الاستفادة من الشحن المجاني عند طلب منتجات بقيمة 500 جنيه أو أكثر.',
        icon: 'card_giftcard',
        time: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_notifications',
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    await _save();
  }

  Future<void> _toggleRead(int index) async {
    setState(() {
      _notifications[index].isRead = !_notifications[index].isRead;
    });
    await _save();
  }

  void _deleteNotification(int index) {
    setState(() => _notifications.removeAt(index));
    _save();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'local_shipping': return Icons.local_shipping;
      case 'local_offer': return Icons.local_offer;
      case 'check_circle': return Icons.check_circle;
      case 'new_releases': return Icons.new_releases;
      case 'card_giftcard': return Icons.card_giftcard;
      default: return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          title: const Text('الإشعارات'),
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllRead,
                child: const Text('تحديد الكل كمقروء', style: TextStyle(color: _orange, fontSize: 13)),
              ),
          ],
        ),
        body: _notifications.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ستصلك إشعارات حول طلباتك والعروض',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final n = _notifications[index];
                  return _NotificationTile(
                    notification: n,
                    icon: _getIcon(n.icon),
                    timeText: _formatTime(n.time),
                    onTap: () => _toggleRead(index),
                    onDelete: () => _deleteNotification(index),
                  );
                },
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final String timeText;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.timeText,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : _navy.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: notification.isRead
                ? null
                : Border.all(color: _navy.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey[100]
                      : _orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: notification.isRead ? Colors.grey : _orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeText,
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
