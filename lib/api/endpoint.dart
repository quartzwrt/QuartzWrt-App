// 端点与故障切换（W6.5 远程链路，DESIGN §7）。
//
// 一台路由器可有多个端点：局域网（配对时地址/发现地址）+ 远程（手动添加的
// tailnet 100.x / MagicDNS 域名）。同一 API、同一证书 pin（同一台路由器）。
//
// [FailoverTransport]：当前端点**传输级**失败（超时/拒连/证书不匹配）→ 换另
// 一端点重试一次；成功即固化（由回调切换当前端点）。应用级错误（如
// access_denied）不触发切换——那是路由器在线且明确作答的场景。
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

/// 端点客户端工厂（测试注入用；默认严格 pin）。
typedef EndpointClientFactory = ApiTransport Function(Endpoint e, String fingerprint);

ApiTransport pinnedClientFor(Endpoint e, String fingerprint) =>
    QuartzApiClient.withPolicy(e.baseUrl, PinPolicy(expectedHex: fingerprint));

/// 传输级失败码（可触发端点轮换；与 client.dart 的错误归一化对应）。
const kTransportFailureCodes = {'timeout', 'connection_refused', 'transport', 'bad_certificate'};

bool isTransportFailure(ApiResult r) => !r.ok && kTransportFailureCodes.contains(r.error?.code);

/// 当前端点 → 备选端点轮换传输。
class FailoverTransport implements ApiTransport {
  FailoverTransport({
    required this.endpoints,
    required this.fingerprint,
    required this.current,
    required this.onSwitch,
    this.clientFactory = pinnedClientFor,
  });

  final List<Endpoint> endpoints;
  final String fingerprint;

  /// 读取当前端点（每次调用取最新值——端点切换即时生效）。
  final Endpoint? Function() current;

  /// 切换成功回调（由状态层固化）。
  final void Function(Endpoint e) onSwitch;

  final EndpointClientFactory clientFactory;
  final Map<String, ApiTransport> _clients = {};

  ApiTransport _clientFor(Endpoint e) =>
      _clients.putIfAbsent(e.baseUrl, () => clientFactory(e, fingerprint));

  @override
  Future<ApiResult> call(String method, [Map<String, dynamic>? args]) async {
    if (endpoints.isEmpty) {
      return const ApiResult.fail(0, ApiError('transport', 'no endpoint'));
    }
    final cur = current();
    final first = (cur != null && endpoints.contains(cur)) ? cur : endpoints.first;
    final r = await _clientFor(first).call(method, args);
    if (!isTransportFailure(r) || endpoints.length < 2) return r;
    final alt = endpoints.firstWhere((e) => e != first);
    final r2 = await _clientFor(alt).call(method, args);
    if (!isTransportFailure(r2)) {
      onSwitch(alt);
      return r2;
    }
    return r2;
  }
}
