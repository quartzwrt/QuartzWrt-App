// 端点与故障切换（W6.5 远程链路，DESIGN §7）。
//
// 一台路由器可有多个端点：局域网（配对时地址/发现地址）+ 远程（手动添加的
// tailnet 100.x / MagicDNS 域名）。同一 API、同一证书 pin（同一台路由器）。
//
// [FailoverTransport] 的尝试序列（首个非传输级失败者胜）：
//   当前端点〔代理 → 直连〕→ 另一端点〔代理 → 直连〕
// 代理 = 内嵌直连（native/tailnet）的本地 CONNECT 代理：远程端点优先经它出站
// （免手机端 Tailscale 客户端），失败回退直连（手机装了 Tailscale / 公网地址）。
// 应用级错误（如 access_denied）不触发切换——那是端点在线且明确作答的场景。
import 'client.dart';
import 'envelope.dart';
import 'models.dart';

enum EndpointKind { local, remote }

class Endpoint {
  const Endpoint({required this.host, required this.port, required this.kind});

  final String host;
  final int port;
  final EndpointKind kind;

  String get baseUrl => 'https://$host:$port';
  String get hostPort => '$host:$port';

  @override
  bool operator ==(Object other) =>
      other is Endpoint && other.host == host && other.port == port && other.kind == kind;

  @override
  int get hashCode => Object.hash(host, port, kind);

  @override
  String toString() => 'Endpoint(${kind.name}: $hostPort)';
}

/// 路由器可用端点：局域网在前、远程在后。
List<Endpoint> endpointsOf(PairedRouter r) => [
      Endpoint(host: r.host, port: r.port, kind: EndpointKind.local),
      if (r.hasRemote)
        Endpoint(host: r.remoteHost!, port: r.remotePort ?? 443, kind: EndpointKind.remote),
    ];

/// 端点客户端工厂（测试注入用；默认严格 pin + 可选本地代理）。
typedef EndpointClientFactory = ApiTransport Function(Endpoint e, String fingerprint, String? proxyAddr);

ApiTransport pinnedClientFor(Endpoint e, String fingerprint, String? proxyAddr) =>
    QuartzApiClient.withPolicy(e.baseUrl, PinPolicy(expectedHex: fingerprint), proxyAddr: proxyAddr);

/// 传输级失败码（可触发端点轮换；与 client.dart 的错误归一化对应）。
const kTransportFailureCodes = {'timeout', 'connection_refused', 'transport', 'bad_certificate'};

bool isTransportFailure(ApiResult r) => !r.ok && kTransportFailureCodes.contains(r.error?.code);

/// 当前端点 → 备选端点轮换传输（远程端点可经本地代理，见文件头注释）。
class FailoverTransport implements ApiTransport {
  FailoverTransport({
    required this.endpoints,
    required this.fingerprint,
    required this.current,
    required this.onSwitch,
    this.clientFactory = pinnedClientFor,
    this.proxyFor,
  });

  final List<Endpoint> endpoints;
  final String fingerprint;

  /// 读取当前端点（每次调用取最新值——端点切换即时生效）。
  final Endpoint? Function() current;

  /// 切换成功回调（由状态层固化）。
  final void Function(Endpoint e) onSwitch;

  final EndpointClientFactory clientFactory;

  /// 某端点可用的本地代理地址（空/null=直连）。
  final String? Function(Endpoint e)? proxyFor;

  final Map<String, ApiTransport> _clients = {};

  ApiTransport _clientFor(Endpoint e, String? proxy) => _clients.putIfAbsent(
        '${e.baseUrl}|${proxy ?? ''}',
        () => clientFactory(e, fingerprint, proxy),
      );

  /// 尝试序列：当前端点〔代理→直连〕→ 另一端点〔代理→直连〕。
  List<(Endpoint, String?)> attempts() {
    if (endpoints.isEmpty) return const [];
    final cur = current();
    final first = (cur != null && endpoints.contains(cur)) ? cur : endpoints.first;
    final out = <(Endpoint, String?)>[];
    void addFor(Endpoint e) {
      // 仅远程端点可走代理：局域网地址经 tailnet 出站没有意义（结构性约束）。
      final proxy = e.kind == EndpointKind.remote ? proxyFor?.call(e) : null;
      if (proxy != null && proxy.isNotEmpty) {
        out.add((e, proxy));
        out.add((e, null)); // 代理失败回退直连
      } else {
        out.add((e, null));
      }
    }

    addFor(first);
    if (endpoints.length > 1) {
      addFor(endpoints.firstWhere((e) => e != first));
    }
    return out;
  }

  @override
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async {
    final list = attempts();
    if (list.isEmpty) {
      return const ApiResult.fail(0, ApiError('transport', 'no endpoint'));
    }
    ApiResult r = const ApiResult.fail(0, ApiError('transport', 'no attempt'));
    for (final (e, proxy) in list) {
      r = await _clientFor(e, proxy).call(method, args);
      if (!isTransportFailure(r)) {
        final cur = current();
        final effective = (cur != null && endpoints.contains(cur)) ? cur : endpoints.first;
        if (e != effective) onSwitch(e);
        return r;
      }
    }
    return r;
  }
}
