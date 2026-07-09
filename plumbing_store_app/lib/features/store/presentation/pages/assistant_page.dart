import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:plumbing_store_app/core/models/assistant_message.dart';
import 'package:plumbing_store_app/core/data/assistant_service.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/providers/auth_provider.dart';
import 'package:plumbing_store_app/core/models/store_product.dart';
import 'product_details_page.dart';
import '../../../../core/widgets/page_transitions.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);
const _bg = Color(0xFFF2F3F7);
const _chatStorageKey = 'assistant_chat_messages';

/// صفحة المساعد الذكي - chat UI مع عرض المنتجات المقترحة inline
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AssistantMessage> _messages = [];
  bool _isTyping = false; // المساعد "بيكتب..."

  @override
  void initState() {
    super.initState();
    // نحمّل المحادثات المحفوظة أولاً؛ لو مفيش، نظيف رسالة الترحيب
    _loadMessages();
  }

  /// تحميل المحادثات المحفوظة من جهاز المستخدم
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_chatStorageKey);
      if (stored != null && stored.isNotEmpty) {
        final list = jsonDecode(stored) as List<dynamic>;
        final messages = list
            .map((m) => AssistantMessage.fromJson(m as Map<String, dynamic>))
            .toList();
        if (messages.isNotEmpty && mounted) {
          setState(() {
            _messages
              ..clear()
              ..addAll(messages);
          });
          _scrollToBottom();
          return;
        }
      }
    } catch (_) {
      // لو في خطأ في القراءة، نكمل برسالة الترحيب
    }
    // لو مفيش محادثات محفوظة، نظيف رسالة الترحيب
    if (mounted && _messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(AssistantMessage(
        id: 'welcome',
        text: 'أهلاً! 🤖 أنا مساعد MARCELINO الذكي. اشرحلي المشكلة اللى عندك وأنا هقترحلك المنتجات المناسبة من المتجر. \n\nمثلاً:\n• "الحنفية بتقطّر مية"\n• "محتاج بويا للحيط"\n• "الصرف ممسود"\n• "محتاج دريل للحفر"',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      ));
    });
  }

  /// حفظ المحادثات الحالية على جهاز المستخدم
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _messages.where((m) => m.id != 'welcome').map((m) => m.toJson()).toList(),
      );
      await prefs.setString(_chatStorageKey, encoded);
    } catch (_) {
      // نتجاهل أخطاء الحفظ علشان ما نوقفش الشات
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    // نضيف رسالة المستخدم
    setState(() {
      _messages.add(AssistantMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _controller.clear();
    });
    _saveMessages();
    _scrollToBottom();

    // نطلب رد المساعد
    try {
      final response = await AssistantService().sendMessage(text);
      // محاكاة تأخير بسيط عشان يبان إن المساعد بيفكر
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _messages.add(AssistantMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: response.message.isEmpty
              ? 'مش قادر أفهم المشكلة دلوقتي، ممكن تشرحهالي بطريقة مختلفة؟'
              : response.message,
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
          products: response.products,
        ));
        _isTyping = false;
      });
      _saveMessages();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(AssistantMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'حصل خطأ. تأكد إن السيرفر شغال وحاول تاني.',
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _saveMessages();
      _scrollToBottom();
    }
  }

  Future<void> _openProduct(AssistantProduct p) async {
    // نحاول نجيب المنتج كامل من StoreApiService عشان نفتح صفحة التفاصيل
    StoreProduct? product;
    try {
      product = await StoreApiService().byId(p.id);
    } catch (_) {
      product = null;
    }
    if (product == null || !mounted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح المنتج'), backgroundColor: _orange),
      );
      return;
    }
    Navigator.push(
      context,
      AppTransitions.details(ProductDetailsPage(product: product)),
    );
  }

  /// يفتح قائمة المحادثات السابقة (للمستخدم المسجل فقط)
  Future<void> _openConversationsList() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّل الدخول عشان توصل لمحادثاتك السابقة'),
          backgroundColor: _navy,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ConversationsListSheet(
        onPick: (summary) async {
          Navigator.pop(context); // نقفل الـ sheet الأول
          await _loadSpecificConversation(summary.sessionId);
        },
      ),
    );
  }

  Future<void> _loadSpecificConversation(String sessionId) async {
    setState(() => _isTyping = true);
    try {
      final messages = await AssistantService().getConversation(sessionId);
      if (messages != null && messages.isNotEmpty && mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _isTyping = false;
        });
        // نحدّث المخزن المحلي كمان
        _saveMessages();
        _scrollToBottom();
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر تحميل المحادثة'), backgroundColor: _orange),
      );
    }
  }

  /// يحفظ المحادثة الحالية على السيرفر ويبدأ واحدة جديدة فارغة
  Future<void> _startNewConversation() async {
    final auth = context.read<AuthProvider>();
    // للزوار: نحفظ محلياً بس فقط ولا نرسل للسيرفر
    if (!auth.isLoggedIn) {
      // نحدّث الـ sessionId المحلي بس ونفضّي الشاشة
      await AssistantService().resetLocalSession();
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
      _saveMessages();
      return;
    }

    // للمسجلين: نبدأ محادثة جديدة على السيرفر ونفضّي الشاشة
    await AssistantService().startNewConversation();
    // لو ما فشلش إنشاء محادثة على السيرفر، نعتمد على sessionId المحلي بس
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
    _saveMessages();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _navy,
          elevation: 0,
          toolbarHeight: 64,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: _orange,
                radius: 18,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 22),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المساعد الذكي',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'MARCELINO Assistant',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // زر المحادثات القديمة (للمستخدمين المسجلين)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              tooltip: 'المحادثات السابقة',
              onPressed: _openConversationsList,
            ),
            if (_messages.length > 1)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _startNewConversation,
                tooltip: 'محادثة جديدة',
              ),
          ],
        ),
        body: Column(
          children: [
            // بانر تنبيه لو مش مسجل: محادثاته مش هتتحفظ على السيرفر
            if (!auth.isLoggedIn) _buildGuestBanner(),
            Expanded(child: _buildChatList()),
            _buildTypingIndicator(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: _orange.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'سجّل الدخول عشان تقدر توصل لمحادثاتك من أي جهاز',
              style: TextStyle(color: _orange.withValues(alpha: 0.9), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) => _MessageBubble(
        message: _messages[i],
        onProductTap: _openProduct,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isTyping) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('المساعد بيكتب', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          _TypingDots(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'اكتب المشكلة اللي عندك...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isTyping ? null : _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _isTyping ? Colors.grey : _orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== قائمة المحادثات السابقة (Bottom Sheet) =====
class _ConversationsListSheet extends StatefulWidget {
  final void Function(ConversationSummary) onPick;
  const _ConversationsListSheet({required this.onPick});

  @override
  State<_ConversationsListSheet> createState() => _ConversationsListSheetState();
}

class _ConversationsListSheetState extends State<_ConversationsListSheet> {
  List<ConversationSummary> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final items = await AssistantService().listConversations();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // مقبض السحب
            Container(
              width: 50,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'المحادثات السابقة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _navy),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('مفيش محادثات سابقة', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 16, color: Colors.grey[200]),
      itemBuilder: (context, i) {
        final it = _items[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _navy.withValues(alpha: 0.1),
            child: const Icon(Icons.smart_toy, color: _navy, size: 22),
          ),
          title: Text(
            it.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            '${it.messageCount} رسالة • ${_formatDate(it.updatedAt)}',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
          onTap: () => widget.onPick(it),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ===== Message Bubble =====
class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final void Function(AssistantProduct) onProductTap;

  const _MessageBubble({required this.message, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  backgroundColor: _orange,
                  radius: 14,
                  child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? _navy : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 4 : 16),
                      bottomRight: Radius.circular(isUser ? 16 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          // عرض المنتجات المقترحة (لو موجودة)
          if (message.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...message.products.map((p) => _ChatProductCard(
              product: p,
              onTap: () => onProductTap(p),
            )),
          ],
        ],
      ),
    );
  }
}

// ===== Product Card inside chat =====
class _ChatProductCard extends StatelessWidget {
  final AssistantProduct product;
  final VoidCallback onTap;

  const _ChatProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 30),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _orange.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة المنتج (أو أيقونة)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _iconPlaceholder(),
                        errorWidget: (_, __, ___) => _iconPlaceholder(),
                      )
                    : _iconPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            // الاسم + السعر
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toInt()} ج.م',
                    style: const TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // سهم → اقترح
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('عرض', style: TextStyle(color: _orange, fontSize: 11, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_back_ios, color: _orange, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
      color: _navy.withValues(alpha: 0.1),
      child: const Icon(Icons.inventory_2, color: _navy, size: 28),
    );
  }
}

// ===== Typing dots animation =====
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              // phase 0..1
              final phase = (_ctrl.value + i * 0.33) % 1;
              final scale = 0.5 + 0.5 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
