// 蜂窝（qmodem）模型：AGGREGATE-API v1 §3.9 的 `cellular` 节。
//
// 契约消费者纪律（契约 §5，与 models.dart 同款）：未知字段容忍、节/叶 null 降级、
// 解析失败不抛穿 UI；**能力协商**——`capabilities` / `traffic.available` /
// `signal.rsrp` 等缺失即隐藏对应 UI 块，不展示 0 值（契约 §3.9 明示义务）。
library;

import '../format.dart';

/// 端级能力（任一模组具备即为真）。
class CellularCaps {
  const CellularCaps({
    this.at = false,
    this.sms = false,
    this.simSwitch = false,
    this.stats = false,
    this.temp = false,
  });

  final bool at;
  final bool sms;
  final bool simSwitch;
  final bool stats;
  final bool temp;

  factory CellularCaps.fromJson(Map<String, dynamic> j) => CellularCaps(
    at: (j['at'] as bool?) ?? false,
    sms: (j['sms'] as bool?) ?? false,
    simSwitch: (j['sim_switch'] as bool?) ?? false,
    stats: (j['stats'] as bool?) ?? false,
    temp: (j['temp'] as bool?) ?? false,
  );
}

/// 单模组能力（不支持项由 UI 灰显并注明原因）。
class CellularModemCaps {
  const CellularModemCaps({
    this.at = true,
    this.sms = true,
    this.simSwitch = false,
    this.stats = false,
    this.currentBand = false,
    this.temp = false,
  });

  final bool at;
  final bool sms;
  final bool simSwitch;
  final bool stats;
  final bool currentBand;
  final bool temp;

  factory CellularModemCaps.fromJson(Map<String, dynamic> j) =>
      CellularModemCaps(
        at: (j['at'] as bool?) ?? true,
        sms: (j['sms'] as bool?) ?? true,
        simSwitch: (j['sim_switch'] as bool?) ?? false,
        stats: (j['stats'] as bool?) ?? false,
        currentBand: (j['current_band'] as bool?) ?? false,
        temp: (j['temp'] as bool?) ?? false,
      );
}

/// RSRP 历史序列（daemon 侧累积，≤60 点，step 秒/点）。
class CellularSeries {
  const CellularSeries({required this.step, required this.rsrp});

  final int step;
  final List<double> rsrp;

  factory CellularSeries.fromJson(Map<String, dynamic> j) => CellularSeries(
    step: (j['step'] as int?) ?? 10,
    rsrp: (j['rsrp'] as List? ?? const [])
        .whereType<num>()
        .map((e) => e.toDouble())
        .toList(growable: false),
  );
}

/// 信号指标（缺失即隐藏；`qualityPct` 用上游同一条目的标尺归一）。
class CellularSignal {
  const CellularSignal({
    this.rsrp,
    this.rsrq,
    this.sinr,
    this.rssi,
    this.qualityPct,
    this.series,
  });

  final double? rsrp;
  final double? rsrq;
  final double? sinr;
  final double? rssi;
  final double? qualityPct;
  final CellularSeries? series;

  factory CellularSignal.fromJson(Map<String, dynamic> j) => CellularSignal(
    rsrp: (j['rsrp'] as num?)?.toDouble(),
    rsrq: (j['rsrq'] as num?)?.toDouble(),
    sinr: (j['sinr'] as num?)?.toDouble(),
    rssi: (j['rssi'] as num?)?.toDouble(),
    qualityPct: (j['quality_pct'] as num?)?.toDouble(),
    series: j['series'] is Map<String, dynamic>
        ? CellularSeries.fromJson(j['series'] as Map<String, dynamic>)
        : null,
  );
}

/// 服务小区（PCC / NSA 等；band 已由 daemon 归一为显示名如 "LTE B3"）。
class CellularCell {
  const CellularCell({
    this.role = '',
    this.rat = '',
    this.band = '',
    this.channel = '',
    this.pci = '',
    this.ulBandwidth = '',
    this.dlBandwidth = '',
    this.scs = '',
  });

  final String role;
  final String rat;
  final String band;
  final String channel;
  final String pci;
  final String ulBandwidth;
  final String dlBandwidth;
  final String scs;

  factory CellularCell.fromJson(Map<String, dynamic> j) => CellularCell(
    role: (j['role'] as String?) ?? '',
    rat: (j['rat'] as String?) ?? '',
    band: (j['band'] as String?) ?? '',
    channel: (j['channel'] as String?) ?? '',
    pci: (j['pci'] as String?) ?? '',
    ulBandwidth: (j['ul_bandwidth'] as String?) ?? '',
    dlBandwidth: (j['dl_bandwidth'] as String?) ?? '',
    scs: (j['scs'] as String?) ?? '',
  );
}

/// qmodem 首页 Cell Information 段（结构字段；缺失即空串）。
class CellularCellInfo {
  const CellularCellInfo({
    this.networkMode = '',
    this.duplex = '',
    this.mcc = '',
    this.mnc = '',
    this.tac = '',
    this.cellId = '',
    this.pci = '',
    this.arfcn = '',
    this.band = '',
    this.ulBandwidth = '',
    this.dlBandwidth = '',
    this.scs = '',
  });

  final String networkMode;
  final String duplex;
  final String mcc;
  final String mnc;
  final String tac;
  final String cellId;
  final String pci;
  final String arfcn;
  final String band;
  final String ulBandwidth;
  final String dlBandwidth;
  final String scs;

  factory CellularCellInfo.fromJson(Map<String, dynamic> j) => CellularCellInfo(
    networkMode: (j['network_mode'] as String?) ?? '',
    duplex: (j['duplex'] as String?) ?? '',
    mcc: (j['mcc'] as String?) ?? '',
    mnc: (j['mnc'] as String?) ?? '',
    tac: (j['tac'] as String?) ?? '',
    cellId: (j['cell_id'] as String?) ?? '',
    pci: (j['pci'] as String?) ?? '',
    arfcn: (j['arfcn'] as String?) ?? '',
    band: (j['band'] as String?) ?? '',
    ulBandwidth: (j['ul_bandwidth'] as String?) ?? '',
    dlBandwidth: (j['dl_bandwidth'] as String?) ?? '',
    scs: (j['scs'] as String?) ?? '',
  );
}

/// 拨号状态。
class CellularDial {
  const CellularDial({
    this.running = false,
    this.ipv4 = '',
    this.rxBps = 0,
    this.txBps = 0,
  });

  final bool running;
  final String ipv4;
  final int rxBps;
  final int txBps;

  factory CellularDial.fromJson(Map<String, dynamic> j) => CellularDial(
    running: (j['running'] as bool?) ?? false,
    ipv4: (j['ipv4'] as String?) ?? '',
    rxBps: (j['rx_bps'] as num?)?.toInt() ?? 0,
    txBps: (j['tx_bps'] as num?)?.toInt() ?? 0,
  );
}

/// 流量统计（`available=false` = 本模组不支持 → **不得展示 0 值**）。
class CellularTraffic {
  const CellularTraffic({
    this.available = false,
    this.updatedAt = 0,
    this.rxBytes = 0,
    this.txBytes = 0,
    this.resetEnabled = false,
    this.resetType = '',
    this.resetHour = 0,
    this.resetDay = 0,
  });

  final bool available;
  final int updatedAt;
  final int rxBytes;
  final int txBytes;
  final bool resetEnabled;
  final String resetType;
  final int resetHour;
  final int resetDay;

  factory CellularTraffic.fromJson(Map<String, dynamic> j) {
    final reset = j['reset'] is Map<String, dynamic>
        ? j['reset'] as Map<String, dynamic>
        : const {};
    return CellularTraffic(
      available: (j['available'] as bool?) ?? false,
      updatedAt: (j['updated_at'] as num?)?.toInt() ?? 0,
      rxBytes: (j['rx_bytes'] as num?)?.toInt() ?? 0,
      txBytes: (j['tx_bytes'] as num?)?.toInt() ?? 0,
      resetEnabled: (reset['enabled'] as bool?) ?? false,
      resetType: (reset['type'] as String?) ?? '',
      resetHour: (reset['hour'] as num?)?.toInt() ?? 0,
      resetDay: (reset['day'] as num?)?.toInt() ?? 0,
    );
  }
}

/// SIM 摘要（存储容量与未读短信属页面级读，不在节内）。
class CellularSim {
  const CellularSim({
    this.status = '',
    this.slot = '',
    this.isp = '',
    this.switchable = false,
  });

  final String status;
  final String slot;

  /// 运营商 PLMN（qmodem 首页 SIM Information；偶有模组只在这里给）。
  final String isp;
  final bool switchable;

  factory CellularSim.fromJson(Map<String, dynamic> j) => CellularSim(
    status: (j['status'] as String?) ?? '',
    slot: (j['slot'] as String?) ?? '',
    isp: (j['isp'] as String?) ?? '',
    switchable: (j['switchable'] as bool?) ?? false,
  );
}

/// 设置回显（usb_mode = **USB 拨号模式**，非网络模式；prefer 如 "4G+5G"）。
class CellularSettings {
  const CellularSettings({
    this.usbMode = '',
    this.prefer = '',
    this.lockband = const [],
  });

  final String usbMode;
  final String prefer;
  final List<String> lockband;

  factory CellularSettings.fromJson(Map<String, dynamic> j) => CellularSettings(
    usbMode: (j['usb_mode'] as String?) ?? '',
    prefer: (j['prefer'] as String?) ?? '',
    lockband: (j['lockband'] as List? ?? const []).whereType<String>().toList(
      growable: false,
    ),
  );
}

/// 单模组。
class CellularModem {
  const CellularModem({
    required this.id,
    this.model = '',
    this.vendor = '',
    this.firmware = '',
    this.tempC,
    this.registered = false,
    this.operator = '',
    this.networkMode = '',
    this.atPort = '',
    this.voltageMv,
    this.connectStatus = '',
    this.networkType = '',
    this.cqiUl,
    this.cqiDl,
    this.ambrUl,
    this.ambrDl,
    this.cellInfo,
    this.signal,
    this.servingCells = const [],
    this.dial,
    this.traffic,
    this.sim,
    this.settings,
    this.capabilities = const CellularModemCaps(),
  });

  final String id;
  final String model;
  final String vendor;
  final String firmware;
  final double? tempC;
  final bool registered;
  final String operator;
  final String networkMode;

  /// 2026-10-19 加法（Dashboard QModem 卡同源字段；全部可缺省）。
  final String atPort;
  final int? voltageMv;
  final String connectStatus;
  final String networkType;
  final int? cqiUl;
  final int? cqiDl;
  final int? ambrUl;
  final int? ambrDl;
  final CellularCellInfo? cellInfo;
  final CellularSignal? signal;
  final List<CellularCell> servingCells;
  final CellularDial? dial;
  final CellularTraffic? traffic;
  final CellularSim? sim;
  final CellularSettings? settings;
  final CellularModemCaps capabilities;

  /// 显示名（型号缺失时回退 section id，避免空白）。
  String get title => model.isNotEmpty ? model : id;

  /// 主服务小区（PCC 优先，否则首条）。
  CellularCell? get primaryCell {
    for (final c in servingCells) {
      if (c.role.toLowerCase() == 'pcc') return c;
    }
    return servingCells.isEmpty ? null : servingCells.first;
  }

  factory CellularModem.fromJson(Map<String, dynamic> j) => CellularModem(
    id: (j['id'] as String?) ?? '',
    model: (j['model'] as String?) ?? '',
    vendor: (j['vendor'] as String?) ?? '',
    firmware: (j['firmware'] as String?) ?? '',
    tempC: (j['temp_c'] as num?)?.toDouble(),
    registered: (j['registered'] as bool?) ?? false,
    operator: (j['operator'] as String?) ?? '',
    networkMode: (j['network_mode'] as String?) ?? '',
    atPort: (j['at_port'] as String?) ?? '',
    voltageMv: (j['voltage_mv'] as num?)?.toInt(),
    connectStatus: (j['connect_status'] as String?) ?? '',
    networkType: (j['network_type'] as String?) ?? '',
    cqiUl: (j['cqi_ul'] as num?)?.toInt(),
    cqiDl: (j['cqi_dl'] as num?)?.toInt(),
    ambrUl: (j['ambr_ul'] as num?)?.toInt(),
    ambrDl: (j['ambr_dl'] as num?)?.toInt(),
    cellInfo: j['cell_info'] is Map<String, dynamic>
        ? CellularCellInfo.fromJson(j['cell_info'] as Map<String, dynamic>)
        : null,
    signal: j['signal'] is Map<String, dynamic>
        ? CellularSignal.fromJson(j['signal'] as Map<String, dynamic>)
        : null,
    servingCells: (j['serving_cells'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CellularCell.fromJson)
        .toList(growable: false),
    dial: j['dial'] is Map<String, dynamic>
        ? CellularDial.fromJson(j['dial'] as Map<String, dynamic>)
        : null,
    traffic: j['traffic'] is Map<String, dynamic>
        ? CellularTraffic.fromJson(j['traffic'] as Map<String, dynamic>)
        : null,
    sim: j['sim'] is Map<String, dynamic>
        ? CellularSim.fromJson(j['sim'] as Map<String, dynamic>)
        : null,
    settings: j['settings'] is Map<String, dynamic>
        ? CellularSettings.fromJson(j['settings'] as Map<String, dynamic>)
        : null,
    capabilities: j['capabilities'] is Map<String, dynamic>
        ? CellularModemCaps.fromJson(j['capabilities'] as Map<String, dynamic>)
        : const CellularModemCaps(),
  );
}

/// cellular 节（快照 §3.9）。
class Cellular {
  const Cellular({
    required this.available,
    this.updated = 0,
    this.capabilities = const CellularCaps(),
    this.modems = const [],
    this.errors = const [],
  });

  final bool available;
  final int updated;
  final CellularCaps capabilities;
  final List<CellularModem> modems;
  final List<String> errors;

  /// 节可用且至少一个模组（= 蜂窝 tab 的显隐判据，配合粘性标记）。
  bool get shown => available && modems.isNotEmpty;

  factory Cellular.fromJson(Map<String, dynamic> j) => Cellular(
    available: (j['available'] as bool?) ?? false,
    updated: (j['updated'] as num?)?.toInt() ?? 0,
    capabilities: j['capabilities'] is Map<String, dynamic>
        ? CellularCaps.fromJson(j['capabilities'] as Map<String, dynamic>)
        : const CellularCaps(),
    modems: (j['modems'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CellularModem.fromJson)
        .toList(growable: false),
    errors: (j['errors'] as List? ?? const []).whereType<String>().toList(
      growable: false,
    ),
  );
}

/// 一条短信（`qmodem.sms.list` 条目；字段名按上游，容错处理）。
class CellularSmsMessage {
  const CellularSmsMessage({
    required this.id,
    required this.index,
    required this.received,
    required this.peer,
    required this.content,
    required this.timestampMs,
    required this.read,
  });

  final String id;
  final String index;
  final bool received;
  final String peer;
  final String content;
  final int timestampMs;
  final bool read;

  static CellularSmsMessage? fromJson(Map<String, dynamic> j) {
    final content = (j['content'] as String?) ?? '';
    final sent = j['type'] == 'sent';
    final peer = ((sent ? j['recipient'] : j['sender']) as String?) ?? '';
    if (content.isEmpty && peer.isEmpty) return null;
    final raw = (j['timestamp'] as num?)?.toInt() ?? 0;
    // 秒/毫秒双形态（上游混用；< 1e12 视为秒）
    final ms = raw == 0 ? 0 : (raw < 1000000000000 ? raw * 1000 : raw);
    return CellularSmsMessage(
      id: '${j['id'] ?? ''}',
      index: '${j['index'] ?? ''}',
      received: !sent,
      peer: peer,
      content: content,
      timestampMs: ms,
      // 未读语义只对收到的消息成立；发出的短信缺字段时默认「已读」
      read: (j['is_read'] as bool?) ?? sent,
    );
  }

  /// 从 `qmodem.sms.list` 结果里取消息列表（上游三形态：messages/msg/received；
  /// 与网页端 `messagesFrom()` 同款容错）。
  static List<CellularSmsMessage> listFrom(Map<String, dynamic> result) {
    final raw =
        result['messages'] ?? result['msg'] ?? result['received'] ?? const [];
    if (raw is! List) return const [];
    final out = <CellularSmsMessage>[];
    for (final m in raw) {
      if (m is Map<String, dynamic>) {
        final parsed = CellularSmsMessage.fromJson(m);
        if (parsed != null) out.add(parsed);
      }
    }
    out.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return out;
  }
}

// ---------------- 展示助手（纯函数，单测覆盖） ----------------

/// 信号质量档位（用 daemon 归一后的 quality_pct；缺失 → null）。
/// 阈值与设计稿一致：≥70 良（绿）/ ≥40 中（橙）/ 其余弱（红）。
String? qualityTier(double? pct) {
  if (pct == null) return null;
  if (pct >= 70) return 'good';
  if (pct >= 40) return 'fair';
  return 'poor';
}

/// 质量段数（5 段条；pct 缺失 → 0）。
int qualityBars(double? pct) {
  if (pct == null) return 0;
  final n = (pct / 20).round();
  return n < 0 ? 0 : (n > 5 ? 5 : n);
}

/// 地址打码（Dashboard `maskIp` 同口径）：IPv4 保留前两段，IPv6 保留前两组。
///
/// 例：`100.64.7.23` → `100.64.*.*`；`240e:3a1:0:1::d1f` → `240e:3a1:*:*:*:*:*:*`。
/// 完整值由 App 的 `QzIpValue` 点击展开。
String maskAddress(String addr) => maskIp(addr);

/// 速率格式化（Byte/s → 人类可读）。
String fmtRate(int bps) {
  if (bps <= 0) return '0 B/s';
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var v = bps.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  final digits = v >= 100 ? 0 : (v >= 10 ? 1 : 1);
  return '${v.toStringAsFixed(digits)} ${units[i]}';
}

/// 字节格式化（累计流量）。
String fmtBytes(int b) {
  if (b <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = b.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}

/// 拨号时长（秒 → "12h 04m" / "3m 12s"）。
String fmtDuration(int seconds) {
  if (seconds <= 0) return '';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}
