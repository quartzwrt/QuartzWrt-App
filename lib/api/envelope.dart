// quartz-app-api 响应信封的解析（WP-5 DESIGN §4.2；DESIGN §2.2 transport 层）。
//
// 传输形态：HTTPS POST /ubus，JSON-RPC：
//   {"jsonrpc":"2.0","id":1,"method":"call","params":[<sid>,"quartz-app-api",<method>,<args>]}
// 成功：{"jsonrpc":"2.0","id":1,"result":[0,{...WP-5 信封...}]}
// rpcd 层错误（如 ACL 拒绝）：{"jsonrpc":"2.0","id":1,"error":{"code":-32002,"message":"Access denied"}}
// WP-5 方法级错误一律 in-band：result[1] 为 {"ok":false,"error":{code,message,...}}。
//
// 本层把两种错误形态统一为 [ApiResult]，供上层（认证/数据/控制）分派。
library;

/// 机器可读错误（code 为 WP-5 错误码或用 'transport'/'jsonrpc' 前缀的传输层码）。
class ApiError {
  const ApiError(this.code, this.message, {this.retryAfter, this.detail});

  final String code;
  final String message;
  final int? retryAfter;
  final String? detail;

  @override
  String toString() => 'ApiError($code: $message)';
}

/// 统一结果：ok=true 时 [data] 为方法载荷；否则 [error] 非空。
class ApiResult {
  const ApiResult.ok(this.api, this.data) : ok = true, error = null;
  const ApiResult.fail(this.api, ApiError this.error)
    : ok = false,
      data = const {};

  final bool ok;
  final int api;
  final Map<String, dynamic> data;
  final ApiError? error;
}

/// 解析 /ubus JSON-RPC 响应体（resp.data 已解码为 Map）。
ApiResult parseUbusResponse(Map<String, dynamic> body) {
  final jrpcError = body['error'];
  if (jrpcError is Map<String, dynamic>) {
    final code = jrpcError['code'];
    final message = jrpcError['message'] as String? ?? 'json-rpc error';
    final mapped = switch (code) {
      -32002 => 'access_denied',
      -32001 => 'session_not_found',
      -32003 => 'timeout',
      _ => 'jsonrpc',
    };
    return ApiResult.fail(0, ApiError(mapped, message, detail: '$code'));
  }

  final result = body['result'];
  if (result is! List || result.length < 2) {
    return const ApiResult.fail(
      0,
      ApiError('transport', 'malformed ubus result'),
    );
  }
  final status = result[0];
  if (status != 0) {
    return ApiResult.fail(0, ApiError('transport', 'ubus status $status'));
  }
  final payload = result[1];
  if (payload is! Map<String, dynamic>) {
    return const ApiResult.fail(0, ApiError('transport', 'empty ubus reply'));
  }

  final api = payload['api'] is int ? payload['api'] as int : 0;
  if (payload['ok'] == true) {
    final data = Map<String, dynamic>.from(payload)..remove('ok');
    data.remove('api');
    return ApiResult.ok(api, data);
  }
  final err = payload['error'];
  if (err is Map<String, dynamic>) {
    return ApiResult.fail(
      api,
      ApiError(
        err['code'] as String? ?? 'unknown',
        err['message'] as String? ?? '',
        retryAfter: err['retry_after'] as int?,
        detail: err['detail'] as String?,
      ),
    );
  }
  return ApiResult.fail(
    api,
    const ApiError('unknown', 'envelope without error'),
  );
}
