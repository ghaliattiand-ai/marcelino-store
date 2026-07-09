import 'package:dio/dio.dart';
import 'package:plumbing_store_app/core/network/api_service.dart';
import 'package:plumbing_store_app/core/constants/app_constants.dart';
import 'package:plumbing_store_app/core/models/assistant_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssistantResponse {
  final String message;
  final List<AssistantProduct> products;
  final String? sessionId;
  final String? conversationId;

  AssistantResponse({
    required this.message,
    required this.products,
    this.sessionId,
    this.conversationId,
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> j) {
    final products = (j['products'] as List?)
            ?.map((p) => AssistantProduct.fromJson(p as Map<String, dynamic>))
            .toList() ?? [];
    return AssistantResponse(
      message: j['message'] as String? ?? '',
      products: products,
      sessionId: j['sessionId'] as String?,
      conversationId: j['conversationId'] as String?,
    );
  }
}

/// ملخص محادثة في قائمة المحادثات
class ConversationSummary {
  final String id;
  final String sessionId;
  final String title;
  final int messageCount;
  final DateTime updatedAt;

  ConversationSummary({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.messageCount,
    required this.updatedAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j) {
    return ConversationSummary(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      sessionId: (j['sessionId'] ?? '').toString(),
      title: (j['title'] as String?) ?? 'محادثة جديدة',
      messageCount: (j['messageCount'] as num?)?.toInt() ?? 0,
      updatedAt: j['updatedAt'] != null
          ? (DateTime.tryParse(j['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class AssistantService {
  static final AssistantService _instance = AssistantService._internal();
  factory AssistantService() => _instance;
  AssistantService._internal();

  static const _sessionIdKey = 'assistant_session_id';

  /// معرف جلسة ثابت لكل عملية تشغيل — نستخدمه لربط المحادثة على السيرفر
  Future<String> _ensureSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var sid = prefs.getString(_sessionIdKey);
      if (sid == null || sid.length < 8) {
        sid = 'asess_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
        await prefs.setString(_sessionIdKey, sid);
      }
      return sid;
    } catch (_) {
      return 'asess_${DateTime.now().millisecondsSinceEpoch}_fb';
    }
  }

  /// يبعت رسالة للسيرفر ويرجع الرد + المنتجات المقترحة
  Future<AssistantResponse> sendMessage(String userMessage) async {
    await ApiService().init();
    try {
      final sessionId = await _ensureSessionId();
      final token = await _readToken();
      final headers = <String, dynamic>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await ApiService().dio.post(
        '/assistant/message',
        data: {'message': userMessage, 'sessionId': sessionId},
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final json = res.data as Map<String, dynamic>;
      // لو السيرفر رجّع sessionId مختلف، نحدث المخزن المحلي
      final returnedSid = json['sessionId'] as String?;
      if (returnedSid != null && returnedSid != sessionId) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionIdKey, returnedSid);
        } catch (_) {}
      }
      return AssistantResponse.fromJson(json);
    } on DioException catch (e) {
      // لو السيرفر رجع JSON error نجيب الرسالة
      if (e.response?.data is Map) {
        return AssistantResponse(
          message: e.response!.data['message'] as String? ?? 'حصل خطأ، حاول تاني',
          products: [],
        );
      }
      return AssistantResponse(
        message: 'تعذّر الاتصال بالمساعد. تأكد إن السيرفر شغال وحاول تاني.',
        products: [],
      );
    } catch (e) {
      return AssistantResponse(
        message: 'حصل مشكلة غير متوقعة، حاول تاني',
        products: [],
      );
    }
  }

  /// يرجع قائمة محادثات المستخدم المسجل (لو فاضي يرجّع [])
  Future<List<ConversationSummary>> listConversations() async {
    await ApiService().init();
    try {
      final token = await _readToken();
      if (token == null || token.isEmpty) return [];
      final res = await ApiService().dio.get(
        '/assistant/conversations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final list = (res.data['conversations'] as List?) ?? [];
      return list
          .map((c) => ConversationSummary.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// يرجع محادثة كاملة بمعرف الـ sessionId (للمستخدم المسجل)
  Future<List<AssistantMessage>?> getConversation(String sessionId) async {
    await ApiService().init();
    try {
      final token = await _readToken();
      if (token == null || token.isEmpty) return null;
      final res = await ApiService().dio.get(
        '/assistant/conversations/$sessionId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final conversation = res.data['conversation'] as Map<String, dynamic>?;
      if (conversation == null) return null;
      final messages = (conversation['messages'] as List?) ?? const [];
      return messages
          .map((m) => AssistantMessage.fromServerMessage(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// يبدأ محادثة جديدة على السيرفر لو المستخدم مسجل دخول
  /// يرجّع sessionId الجديد (أو null لو مش مسجل)
  Future<String?> startNewConversation() async {
    await ApiService().init();
    try {
      final token = await _readToken();
      if (token == null || token.isEmpty) return null;
      final sid = await _ensureSessionId();
      final res = await ApiService().dio.post(
        '/assistant/conversations',
        data: {'sessionId': sid},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final newSid = (res.data['sessionId'] as String?) ?? sid;
      // نحدّث الـ sessionId المحلي عشان السيرفر يربط الرسايل الجديدة بالمحادثة دي
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionIdKey, newSid);
      } catch (_) {}
      return newSid;
    } catch (_) {
      return null;
    }
  }

  /// ننشئ sessionId جديد محلياً (للزوار أو لو startNewConversation فشل)
  /// ترجّع الـ sessionId الجديد
  Future<String> resetLocalSession() async {
    final newSid = 'asess_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionIdKey, newSid);
    } catch (_) {}
    return newSid;
  }

  Future<String?> _readToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenKey);
    } catch (_) {
      return null;
    }
  }
}
