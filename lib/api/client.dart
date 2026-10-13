// quartz-app-api 客户端（DESIGN §2.2 transport 层 + §3 证书 pinning）。
//
// - /ubus JSON-RPC：https://<host>:<port>/ubus，方法面=WP-5 八方法；
// - TLS：自签证书 + **pin=sha256(DER)**（WP-5 §6.2）。Dio 走自定义 HttpClient：
//   配对模式（captureMode）接受任意证书并记录哈希（与 mDNS TXT 的 fp 比对，
//   TOFU）；已配对模式只接受指纹一致的证书，否则握手失败（阻断降级 MITM）。
// - 令牌生命周期（access 注入 / 单飞刷新）在 auth/token_manager.dart。
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'envelope.dart';

/// rpcd 默认（未认证）会话 id——认证由 access_token 参数承载（WP-5 §2.3）。
const kDefaultUbusSid = '00000000000000000000000000000000';

/// WP-5 ubus 对象名。
const kApiObject = 'quartz-app-api';

/// 证书 pin 策略（跨请求可变：配对时 capture，配对后 strict）。
class PinPolicy {
  PinPolicy({this.expectedHex, this.captureMode = false});

  /// 期望的证书 sha256(DER) hex（小写）；空=无 pin。
  String? expectedHex;

  /// 配对中：接受并记录本次连接证书。
  bool captureMode;

  /// 最近一次连接看到的证书哈希（capture 模式下由回调写入）。
  String? capturedHex;
}

String hexOf(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

HttpClient createPinnedHttpClient(PinPolicy policy, {String? proxyAddr}) {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  if (proxyAddr != null && proxyAddr.isNotEmpty) {
    // 内嵌直连：经 App 进程内的 tsnet CONNECT 代理出站（TLS/pin 仍在本层端到端校验）。
    final proxy = proxyAddr;
    client.findProxy = (uri) => 'PROXY $proxy';
  }
  client.badCertificateCallback = (X509Certificate cert, String host, int port) {
    // 与路由器侧 `sha256sum /etc/uhttpd.crt`（DER 字节）一致。
    final hex = hexOf(Uint8List.fromList(sha256.convert(cert.der).bytes));
    policy.capturedHex = hex;
    if (policy.captureMode) return true; // TOFU：配对握手记录指纹
    final expected = policy.expectedHex?.toLowerCase();
    if (expected == null || expected.isEmpty) return false;
    return hex == expected;
  };
  return client;
}

/// 传输层抽象（测试注入用）。
abstract interface class ApiTransport {
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]);
}

class QuartzApiClient implements ApiTransport {
  QuartzApiClient(String baseUrl, {PinPolicy? pin, String? proxyAddr})
      : this.withPolicy(baseUrl, pin ?? PinPolicy(), proxyAddr: proxyAddr);

  QuartzApiClient.withPolicy(String baseUrl, this.pin, {String? proxyAddr})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => createPinnedHttpClient(pin, proxyAddr: proxyAddr),
    );
  }

  final Dio _dio;
  final PinPolicy pin;

  /// 调一个 quartz-app-api 方法（信封解析、传输错误归一化）。
  @override
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

  // ---- 便捷封装（认证类方法不注入令牌；数据/动作类由 TokenManager 注入）----

  Future<ApiResult> info() => call('info');

  Future<ApiResult> login({
    required String username,
    required String password,
    required String deviceName,
  }) =>
      call('login', {
        'username': username,
        'password': password,
        'device_name': deviceName,
      });

  Future<ApiResult> refresh({required String deviceId, required String refreshToken}) =>
      call('refresh', {'device_id': deviceId, 'refresh_token': refreshToken});

  Future<ApiResult> logout({required String deviceId, required String refreshToken}) =>
      call('logout', {'device_id': deviceId, 'refresh_token': refreshToken});

  Future<ApiResult> status({required String accessToken}) =>
      call('status', {'access_token': accessToken});

  Future<ApiResult> action({
    required String accessToken,
    required String action,
    Map<String, dynamic> args = const {},
  }) =>
      call('action', {'access_token': accessToken, 'action': action, 'args': args});

  Future<ApiResult> devices({required String accessToken}) =>
      call('devices', {'access_token': accessToken});

  Future<ApiResult> revoke({required String accessToken, required String deviceId}) =>
      call('revoke', {'access_token': accessToken, 'device_id': deviceId});

  /// 软件包面（WP-6 登记项；路由器未实现时返回 `bad_request` → 上层降级展示）。
  Future<ApiResult> packages({
    required String accessToken,
    required String scope,
    String? query,
  }) =>
      call('packages', {
        'access_token': accessToken,
        'scope': scope,
        'query': ?query,
      });
}
