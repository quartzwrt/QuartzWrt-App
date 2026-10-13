// 配对（DESIGN §3）：TOFU + 证书指纹 + 管理员密码一次输入。
//
// 流程：capture 模式握手（记录 sha256(DER)）→ 与 mDNS TXT `fp` 比对（有则强
// 校验）→ info 检查 password_set → login 换双令牌 → 生成 PairedRouter。
// 指纹不匹配/口令未设置/凭据错误 → PairException（带机器码，UI 映射文案）。
import '../api/client.dart';
import '../api/models.dart';

class PairException implements Exception {
  PairException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PairException($code: $message)';
}

class PairOutcome {
  const PairOutcome({required this.router, required this.tokens});

  final PairedRouter router;
  final Tokens tokens;
}

/// 执行配对。[expectedFingerprint] 来自 mDNS TXT（可空=未验证设备，TOFU）。
Future<PairOutcome> pairRouter({
  required String host,
  required int port,
  required String password,
  required String deviceName,
  String? expectedFingerprint,
  QuartzApiClient Function(String baseUrl, PinPolicy pin)? clientFactory,
  DateTime Function()? now,
}) async {
  final pin = PinPolicy(captureMode: true);
  final baseUrl = 'https://$host:$port';
  final client = clientFactory != null
      ? clientFactory(baseUrl, pin)
      : QuartzApiClient.withPolicy(baseUrl, pin);

  final infoR = await client.info();
  if (!infoR.ok) {
    throw PairException(infoR.error!.code, infoR.error!.message);
  }
  final info = RouterInfo.fromPayload(infoR.data);

  final captured = pin.capturedHex;
  if (captured == null || captured.isEmpty) {
    throw PairException('tls', 'no server certificate captured');
  }
  final expected = expectedFingerprint?.toLowerCase();
  if (expected != null && expected.isNotEmpty && expected != captured) {
    throw PairException('fingerprint_mismatch', 'router identity changed');
  }
  if (!info.passwordSet) {
    throw PairException('password_not_set', 'router admin password is not set');
  }

  final loginR = await client.login(
    username: 'root',
    password: password,
    deviceName: deviceName,
  );
  if (!loginR.ok) {
    throw PairException(loginR.error!.code, loginR.error!.message);
  }
  final tokens = Tokens.fromPayload(loginR.data);
  if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty || tokens.deviceId.isEmpty) {
    throw PairException('token_invalid', 'malformed login response');
  }

  final when = (now ?? DateTime.now)().millisecondsSinceEpoch;
  return PairOutcome(
    router: PairedRouter(
      id: tokens.deviceId,
      name: info.name.isEmpty ? host : info.name,
      model: info.model,
      host: host,
      port: port,
      fingerprint: captured,
      deviceId: tokens.deviceId,
      addedAt: when,
    ),
    tokens: tokens,
  );
}

/// 已配对路由器建客户端（严格 pin）。
QuartzApiClient clientFor(PairedRouter r, {PinPolicy? policy}) {
  final pin = policy ?? PinPolicy(expectedHex: r.fingerprint);
  pin.expectedHex ??= r.fingerprint;
  return QuartzApiClient.withPolicy(r.baseUrl, pin);
}

/// 探测一个候选端点是否就是本路由器（W6.5 远程地址「测试并保存」）。
///
/// 严格 pin：证书指纹须与已配对记录一致（同一台路由器同一张证书）；
/// 只调未认证的 `info`，不产生登录/令牌副作用。
Future<RouterInfo> probeEndpoint(
  PairedRouter r, {
  required String host,
  required int port,
}) async {
  final client = QuartzApiClient.withPolicy(
    'https://$host:$port',
    PinPolicy(expectedHex: r.fingerprint),
  );
  final infoR = await client.info();
  if (!infoR.ok) {
    throw PairException(infoR.error!.code, infoR.error!.message);
  }
  return RouterInfo.fromPayload(infoR.data);
}
