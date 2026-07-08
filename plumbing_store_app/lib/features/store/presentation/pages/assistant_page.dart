import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plumbing_store_app/core/models/assistant_message.dart';
import 'package:plumbing_store_app/core/data/assistant_service.dart';
import 'package:plumbing_store_app/core/data/store_api_service.dart';
import 'package:plumbing_store_app/core/models/store_product.dart';
import 'product_details_page.dart';
import '../../../../core/widgets/page_transitions.dart';

const _navy = Color(0xFF0D1B3E);
const _orange = Color(0xFFFF6B00);
const _bg = Color(0xFFF2F3F7);

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
    // رسالة ترحيب
    _messages.add(AssistantMessage(
      id: 'welcome',
      text: 'أهلاً! 🤖 أنا مساعد MARCELINO الذكي. اشرحلي المشكلة اللى عندك وأنا هقترحلك المنتجات المناسبة من المتجر. \n\nمثلاً:\n• "الحنفية بتقطّر مية"\n• "محتاج بويا للحيط"\n• "الصرف ممسود"\n• "محتاج دريل للحفر"',
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
    ));
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _navy,
          elevation: 0,
          toolbarHeight: 64,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
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
            if (_messages.length > 1)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _messages.removeRange(1, _messages.length);
                  });
                },
                tooltip: 'محادثة جديدة',
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildChatList()),
            _buildTypingIndicator(),
            _buildInputBar(),
          ],
        ),
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
                child: Icon(
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
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
