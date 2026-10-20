// 服务富化注册表（UI-DESIGN §4.2 ServiceRowSpec 的最小落地）——新增服务的
// 列表富化 / 详情扩展 = 本表加一条，页面只渲染注册表、不写死单项。
//
// 首个条目 = bandix（WP-8 bridge 链路；WP-6 L2）：
//   enrich     —— 应用列表行副标题追加密文本（快照 bandix 节的在线设备数）
//   detailCard —— 应用详情页追加「流量与限速」卡（动作条目 → WP-5 转发项）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/app_localizations.dart';
import 'bandix/bandix_panel.dart';

class ServiceRowSpec {
  const ServiceRowSpec({required this.id, this.enrich, this.detailCard});

  /// 服务 id（= 快照 `services` 开放映射键，如 `bandix`）。
  final String id;

  /// 列表副标题追加密文本（版本/状态之后）；返回 null = 不追加。
  final String? Function(
    AppL10n l10n,
    Map<String, dynamic> entry,
    Snapshot? snap,
  )?
  enrich;

  /// 详情页追加卡。
  final Widget Function(BuildContext context, WidgetRef ref)? detailCard;
}

final List<ServiceRowSpec> serviceRowSpecs = <ServiceRowSpec>[
  ServiceRowSpec(
    id: 'bandix',
    enrich: (l10n, entry, snap) {
      if (snap?.bandixAvailable != true) return null;
      final online = (snap!.bandix!['online'] as num?)?.toInt() ?? 0;
      final devices = (snap.bandix!['devices'] as num?)?.toInt() ?? 0;
      return l10n.bandixRowOnline(online, devices);
    },
    detailCard: (context, ref) => const BandixPanel(),
  ),
];

ServiceRowSpec? serviceRowFor(String id) {
  for (final s in serviceRowSpecs) {
    if (s.id == id) return s;
  }
  return null;
}
