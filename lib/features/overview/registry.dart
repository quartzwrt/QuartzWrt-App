// 概览卡片注册表（DESIGN §4.2）：新卡=加一条 CardSpec；
// 未被消费的顶层节自动经通用 KV 卡渲染（L1 泛化兜底）。
import 'package:flutter/material.dart';

import '../../api/models.dart';
import 'cards.dart';

typedef CardBuilder = Widget Function(BuildContext context, Snapshot snap);

class CardSpec {
  const CardSpec({required this.id, required this.build, this.visible});

  final String id;
  final CardBuilder build;
  final bool Function(Snapshot)? visible;

  bool isVisible(Snapshot s) => visible?.call(s) ?? true;
}

/// 概览卡顺序即此列表（拍板 3 的卡片集合）。
final List<CardSpec> overviewCards = [
  CardSpec(id: 'system', build: systemCard),
  CardSpec(id: 'network', build: networkCard),
  CardSpec(id: 'clients', build: clientsCard),
  CardSpec(id: 'apps', build: appsCard),
  CardSpec(
    id: 'docker',
    // Docker 条件卡：安装了才显示（拍板 2）
    visible: (s) => s.docker != null && s.docker!['available'] == true,
    build: dockerCard,
  ),
];

/// 已知顶层节（已被专属卡/框架消费；其余走通用兜底）。
const kConsumedSections = {
  'v', 'ts', 'interval', 'collect_ms', 'host', 'system', 'net', 'docker', 'clients', 'services', 'errors',
};

/// 组装概览主体：专属卡（按可见性）→ 通用兜底卡（未知节）→ errors 弱提示。
List<Widget> buildOverviewCards(BuildContext context, Snapshot s) {
  final out = <Widget>[];
  for (final c in overviewCards) {
    if (c.isVisible(s)) out.add(c.build(context, s));
  }
  for (final e in s.raw.entries) {
    if (kConsumedSections.contains(e.key)) continue;
    final v = e.value;
    if (v is! Map<String, dynamic>) continue;
    final fields = genericFields(v);
    if (fields.isEmpty) continue;
    out.add(genericCard(context, e.key, fields));
  }
  if (s.errors.isNotEmpty) {
    out.add(collectorErrorsCard(context, s));
  }
  return out;
}
