// 软件包管理面模型（WP-5 §4.5 接口的 App 侧消费者；UI-DESIGN §5 ⑤b/⑫）。
//
// 契约消费者纪律：未知字段容忍、缺字段降级（不抛穿 UI）。
// items 形态两族：
//   - 包 scope（installed/upgradable/available）→ [PackageItem]；
//   - history → [PackageOp]（{ts,action,target,ok,output,duration_ms}）。
library;

/// 一个软件包条目（统一超集，字段按 scope 存在性渲染）。
class PackageItem {
  const PackageItem({
    required this.name,
    required this.version,
    this.installedVersion = '',
    this.targetVersion = '',
    this.description = '',
    this.arch = '',
    this.license = '',
    this.origin = '',
    this.installedSize = 0,
    this.fileSize = 0,
    this.installed = false,
    this.upgradable = false,
  });

  final String name;

  /// installed 范围=已装版本；upgradable 范围=目标版本；available 范围=仓库版本。
  final String version;
  final String installedVersion;
  final String targetVersion;
  final String description;
  final String arch;
  final String license;
  final String origin;
  final int installedSize; // 磁盘占用（installed/upgradable）
  final int fileSize; // 安装包体积（available/upgradable）
  final bool installed;
  final bool upgradable;

  factory PackageItem.fromJson(Map<String, dynamic> j) => PackageItem(
        name: _str(j['name']),
        version: _str(j['version']),
        installedVersion: _str(j['installed_version']),
        targetVersion: _str(j['target_version']),
        description: _str(j['description']),
        arch: _str(j['arch']),
        license: _str(j['license']),
        origin: _str(j['origin']),
        installedSize: _int(j['installed_size']),
        fileSize: _int(j['file_size']),
        installed: j['installed'] == true,
        upgradable: j['upgradable'] == true,
      );
}

/// 一条软件包操作记录（history scope）。
class PackageOp {
  const PackageOp({
    required this.ts,
    required this.action,
    this.target = '',
    required this.ok,
    this.output = '',
    this.durationMs = 0,
  });

  final int ts;
  final String action; // packages.refresh|upgrade|remove
  final String target; // 目标包名（刷新为空）
  final bool ok;
  final String output; // stdout/stderr 摘录（尾部）
  final int durationMs;

  /// 动作短名（packages.xyz → xyz；未知原样）。
  String get op => action.startsWith('packages.') ? action.substring('packages.'.length) : action;

  factory PackageOp.fromJson(Map<String, dynamic> j) => PackageOp(
        ts: _int(j['ts']),
        action: _str(j['action']),
        target: _str(j['target']),
        ok: j['ok'] == true,
        output: _str(j['output']),
        durationMs: _int(j['duration_ms']),
      );
}

/// packages 方法分页回包。
class PackagesPage {
  const PackagesPage({
    required this.scope,
    required this.page,
    required this.perPage,
    required this.total,
    required this.pages,
    required this.raw,
  });

  final String scope;
  final int page;
  final int perPage;
  final int total;
  final int pages;
  final List<Object> raw; // PackageItem | PackageOp

  List<PackageItem> get items => raw.whereType<PackageItem>().toList();
  List<PackageOp> get ops => raw.whereType<PackageOp>().toList();

  bool get hasMore => page < pages;

  factory PackagesPage.fromPayload(Map<String, dynamic> p) {
    final scope = (p['scope'] as String?) ?? '';
    final list = p['items'];
    final raw = <Object>[];
    if (list is List) {
      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        raw.add(scope == 'history' ? PackageOp.fromJson(e) : PackageItem.fromJson(e));
      }
    }
    return PackagesPage(
      scope: scope,
      page: _int(p['page'], fallback: 1),
      perPage: _int(p['per_page'], fallback: raw.length),
      total: _int(p['total'], fallback: raw.length),
      pages: _int(p['pages'], fallback: raw.isEmpty ? 0 : 1),
      raw: raw,
    );
  }

  /// 追加下一页（分页列表累积）。
  PackagesPage appended(PackagesPage next) => PackagesPage(
        scope: scope,
        page: next.page,
        perPage: next.perPage,
        total: next.total,
        pages: next.pages,
        raw: [...raw, ...next.raw],
      );
}

// ---- 契约容忍取值（错类型/缺字段一律降级，绝不抛穿 UI）----

String _str(Object? v) => v is String ? v : '';
int _int(Object? v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}
