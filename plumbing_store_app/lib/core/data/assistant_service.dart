import 'package:dio/dio.dart';
import 'package:plumbing_store_app/core/network/api_service.dart';
import 'package:plumbing_store_app/core/models/assistant_message.dart';

class AssistantResponse {
  final String message;
  final List<AssistantProduct> products;

  AssistantResponse({required this.message, required this.products});

  factory AssistantResponse.fromJson(Map<String, dynamic> j) {
    final products = (j['products'] as List?)
            ?.map((p) => AssistantProduct.fromJson(p as Map<String, dynamic>))
            .toList() ?? [];
    return AssistantResponse(
      message: j['message'] as String? ?? '',
      products: products,
    );
  }
}

class AssistantService {
  static final AssistantService _instance = AssistantService._internal();
  factory AssistantService() => _instance;
  AssistantService._internal();

  /// يبعت رسالة للسيرفر ويرجع الرد + المنتجات المقترحة
  Future<AssistantResponse> sendMessage(String userMessage) async {
    await ApiService().init();
    try {
      final res = await ApiService().dio.post(
        '/assistant/message',
        data: {'message': userMessage},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      return AssistantResponse.fromJson(res.data as Map<String, dynamic>);
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
}
