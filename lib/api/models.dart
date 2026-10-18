// 数据模型（WP-5 接口面 + AGGREGATE-API v1 快照）。
//
// 契约消费者纪律（契约 §5）：未知字段/未知节容忍；节/叶 null → 降级；
// 解析失败不抛穿 UI——模型层保留 [Snapshot.raw] 供通用渲染与排障。
library;

import 'cellular.dart';

/// info 方法返回的路由器身份。
class RouterInfo {
  const RouterInfo({
    required this.name,
    required this.model,
    required this.release,
    required this.kernel,
    this.api = 0,
    this.passwordSet = true,
    this.features = const [],
  });

  final String name;
  final String model;
  final String release;
  final String kernel;
  final int api;
  final bool passwordSet;
  final List<String> features;

  factory RouterInfo.fromPayload(Map<String, dynamic> p) => RouterInfo(
        name: (p['name'] as String?) ?? '',
        model: (p['model'] as String?) ?? '',
        release: (p['release'] as String?) ?? '',
        kernel: (p['kernel'] as String?) ?? '',
        api: (p['api'] as int?) ?? 0,
        passwordSet: (p['password_set'] as bool?) ?? true,
        features: List<String>.from(p['features'] as List? ?? const []),
      );
}

/// login / refresh 返回的双令牌。
class Tokens {
  const Tokens({
    required this.accessToken,
    required this.accessExp,
    required this.refreshToken,
    required this.refreshExp,
    required this.deviceId,
  });

  final String accessToken;
  final int accessExp;
  final String refreshToken;
  final int refreshExp;
  final String deviceId;

  factory Tokens.fromPayload(Map<String, dynamic> p) => Tokens(
        accessToken: (p['access_token'] as String?) ?? '',
        accessExp: (p['access_exp'] as int?) ?? 0,
        refreshToken: (p['refresh_token'] as String?) ?? '',
        refreshExp: (p['refresh_exp'] as int?) ?? 0,
        deviceId: (p['device_id'] as String?) ?? '',
      );
}

/// 已配对路由器（元数据持久在 shared_preferences；refresh 令牌另存安全存储）。
///
/// 地址面（DESIGN §7）：[host]/[port] 为配对时的局域网端点；[remoteHost]/
/// [remotePort] 为手动添加的远程端点（tailnet 100.x / MagicDNS 域名）。
/// 证书指纹两者共用（同一台路由器、同一张证书）。
class PairedRouter {
  const PairedRouter({
    required this.id,
    required this.name,
    required this.model,
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.deviceId,
    required this.addedAt,
    this.remoteHost,
    this.remotePort,
    this.cellularSeen = false,
  });

  final String id; // = deviceId（唯一）
  final String name;
  final String model;
  final String host;
  final int port;
  final String fingerprint; // sha256(DER) hex，小写
  final String deviceId;
  final int addedAt;
  final String? remoteHost;
  final int? remotePort;

  /// 蜂窝 tab **粘性门控**（IA v2 定案）：一旦确认该路由器有 qmodem+模组即持久化，
  /// 此后仅"重新配对到另一台路由器"时重算——避免临时断网/采集降级导致 tab 忽隐忽现。
  final bool cellularSeen;

  String get baseUrl => 'https://$host:$port';

  bool get hasRemote => (remoteHost ?? '').isNotEmpty;

  PairedRouter copyWith({
    String? remoteHost,
    int? remotePort,
    bool clearRemote = false,
    bool? cellularSeen,
  }) =>
      PairedRouter(
        id: id,
        name: name,
        model: model,
        host: host,
        port: port,
        fingerprint: fingerprint,
        deviceId: deviceId,
        addedAt: addedAt,
        remoteHost: clearRemote ? null : (remoteHost ?? this.remoteHost),
        remotePort: clearRemote ? null : (remotePort ?? this.remotePort),
        cellularSeen: cellularSeen ?? this.cellularSeen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'model': model,
        'host': host,
        'port': port,
        'fingerprint': fingerprint,
        'device_id': deviceId,
        'added_at': addedAt,
        if (hasRemote) 'remote_host': remoteHost,
        if (hasRemote) 'remote_port': remotePort ?? 443,
        if (cellularSeen) 'cellular_seen': true,
      };

  static PairedRouter? fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String?;
    final host = j['host'] as String?;
    if (id == null || host == null || host.isEmpty) return null;
    final remoteHost = (j['remote_host'] as String?)?.trim();
    return PairedRouter(
      id: id,
      name: (j['name'] as String?) ?? host,
      model: (j['model'] as String?) ?? '',
      host: host,
      port: (j['port'] as int?) ?? 443,
      fingerprint: (j['fingerprint'] as String?) ?? '',
      deviceId: (j['device_id'] as String?) ?? id,
      addedAt: (j['added_at'] as int?) ?? 0,
      remoteHost: (remoteHost == null || remoteHost.isEmpty) ? null : remoteHost,
      remotePort: (j['remote_port'] as int?) ?? 443,
      cellularSeen: (j['cellular_seen'] as bool?) ?? false,
    );
  }
}

/// 已配对设备（devices 方法条目）。
class PairedDevice {
  const PairedDevice({
    required this.id,
    required this.name,
    required this.lastSeen,
    required this.revoked,
    required this.current,
  });

  final String id;
  final String name;
  final int lastSeen;
  final bool revoked;
  final bool current;

  factory PairedDevice.fromJson(Map<String, dynamic> j) => PairedDevice(
        id: (j['device_id'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        lastSeen: (j['last_seen'] as int?) ?? 0,
        revoked: (j['revoked'] as bool?) ?? false,
        current: (j['current'] as bool?) ?? false,
      );
}

/// 快照（AGGREGATE-API v1）——已知字段强类型 + raw 全量保留。
class Snapshot {
  Snapshot(this.raw);

  final Map<String, dynamic> raw;

  int get version => (raw['v'] as int?) ?? 0;
  int get ts => (raw['ts'] as int?) ?? 0;
  int get interval => (raw['interval'] as int?) ?? 5;
  List<String> get errors => List<String>.from(raw['errors'] as List? ?? const []);

  Map<String, dynamic>? _sec(String k) {
    final v = raw[k];
    return v is Map<String, dynamic> ? v : null;
  }

  Map<String, dynamic> get host => _sec('host') ?? const {};
  Map<String, dynamic> get system => _sec('system') ?? const {};
  Map<String, dynamic> get net => _sec('net') ?? const {};
  Map<String, dynamic>? get docker => _sec('docker');

  /// 蜂窝节（契约 §3.9；未装 qmodem / 无模组时为 null 或 available=false）。
  Cellular? get cellular {
    final c = _sec('cellular');
    return c == null ? null : Cellular.fromJson(c);
  }

  Map<String, dynamic>? get clients => _sec('clients');
  Map<String, dynamic>? get services => _sec('services');

  /// services 开放映射 → 稳定排序列表（含未知键的通用数据）。
  List<(String, Map<String, dynamic>)> get serviceEntries {
    final svc = services;
    if (svc == null) return const [];
    final entries = <(String, Map<String, dynamic>)>[];
    for (final e in svc.entries) {
      final v = e.value;
      entries.add((e.key, v is Map<String, dynamic> ? v : <String, dynamic>{'running': v == true}));
    }
    entries.sort((a, b) {
      final ra = a.$2['running'] == true ? 0 : 1;
      final rb = b.$2['running'] == true ? 0 : 1;
      if (ra != rb) return ra - rb;
      return a.$1.compareTo(b.$1);
    });
    return entries;
  }

  /// 在线设备条目（契约 3.5；raw 条目保留未知字段）。
  List<Map<String, dynamic>> get clientItems {
    final c = clients;
    final items = c?['items'];
    if (items is! List) return const [];
    return items.whereType<Map<String, dynamic>>().toList();
  }

  int get clientsTotal => (clients?['total'] as int?) ?? clientItems.length;

  /// bandix 节（契约 §3.7；WP-8 bridge 链路，慢刷 10s——与 Dashboard 同字节）。
  /// 整节缺失 = 上游暂不可用；`available != true` = 未装/未开流量监控。
  Map<String, dynamic>? get bandix => _sec('bandix');

  bool get bandixAvailable => bandix?['available'] == true;

  /// bandix Top 设备（≤8；按累计流量降序）。
  List<Map<String, dynamic>> get bandixTop {
    final t = bandix?['top'];
    if (t is! List) return const [];
    return t.whereType<Map<String, dynamic>>().toList();
  }

  /// WAN 摘要（net.wan；缺失 → 空 map）。
  Map<String, dynamic> get wan {
    final w = net['wan'];
    return w is Map<String, dynamic> ? w : const {};
  }

  /// 速率序列（net.series；缺失返回空）。
  (String, List<num>, List<num>)? get series {
    final s = net['series'];
    if (s is! Map<String, dynamic>) return null;
    final rx = (s['rx'] as List?)?.whereType<num>().toList() ?? const <num>[];
    final tx = (s['tx'] as List?)?.whereType<num>().toList() ?? const <num>[];
    if (rx.isEmpty && tx.isEmpty) return null;
    return ((s['step'] as int?)?.toString() ?? '?', rx, tx);
  }

  /// 解析快照 JSON（对象）；失败返回 null（交由状态层展示「数据损坏」）。
  static Snapshot? parse(Object? body) {
    if (body is Map<String, dynamic>) return Snapshot(body);
    return null;
  }
}

/// 通用 KV 抽取：从未知节取展示用标量行（L1 泛化渲染兜底）。
/// 规则：string/num/bool 直出；短数组 join；嵌套对象展平一层（k: v1/v2）；
/// 最多 [max] 行（由卡层决定超限进详情）；null 跳过。
List<MapEntry<String, String>> genericFields(Map<String, dynamic> section, {int max = 6}) {
  final out = <MapEntry<String, String>>[];
  for (final e in section.entries) {
    if (out.length >= max) break;
    final v = e.value;
    String? text;
    if (v == null) {
      continue;
    } else if (v is String || v is num || v is bool) {
      text = '$v';
    } else if (v is List) {
      text = v.where((x) => x is String || x is num).map((x) => '$x').join(' · ');
      if (text.isEmpty) continue;
    } else if (v is Map<String, dynamic>) {
      final inner = v.entries
          .where((x) => x.value is String || x.value is num || x.value is bool)
          .take(4)
          .map((x) => '${x.key}: ${x.value}')
          .join(' · ');
      if (inner.isEmpty) continue;
      text = inner;
    } else {
      continue;
    }
    out.add(MapEntry(e.key, text));
  }
  return out;
}
