// quartz-app-api 客户端骨架（DESIGN §2.2 transport 层）。
//
// W6.1 范围：/ubus JSON-RPC 调用 + 信封解析；令牌注入（拦截器）与
// 单飞刷新队列在 W6.2 落地（DESIGN §4 硬要求：refresh 旋转 + 复用检测
// 要求 App 侧并发刷新必须串行化，否则会自触发吊销）。
import 'package:dio/dio.dart';

import 'envelope.dart';

/// rpcd 默认（未认证）会话 id——App 的调用一律以此 sid 调 quartz-app-api 对象，
/// 认证由 access_token 参数承载（WP-5 DESIGN §2.3）。
const kDefaultUbusSid = '00000000000000000000000000000000';

/// WP-5 ubus 对象名（= rpcd 插件文件名）。
const kApiObject = 'quartz-app-api';

class QuartzApiClient {
  QuartzApiClient(String baseUrl, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 8),
              // 证书 pinning（DESIGN §3）：W6.2 起以自定义校验接管
              // （badCertificateCallback + sha256(DER) 与 mDNS TXT fp 比对）。
            ));

  final Dio _dio;

  /// 调一个 quartz-app-api 方法。
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        '/ubus',
        data: {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'call',
          'params': [kDefaultUbusSid, kApiObject, method, args ?? <String, dynamic>{}],
        },
      );
      final body = resp.data;
      if (body == null) {
        return const ApiResult.fail(0, ApiError('transport', 'empty response'));
      }
      return parseUbusResponse(body);
    } on DioException catch (e) {
      final code = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          'timeout',
        DioExceptionType.badCertificate => 'bad_certificate',
        DioExceptionType.connectionError => 'connection_refused',
        _ => 'transport',
      };
      return ApiResult.fail(0, ApiError(code, e.message ?? 'network error'));
    }
  }
}
