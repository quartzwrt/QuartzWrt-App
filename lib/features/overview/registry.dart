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
  // 电池条件卡：pcat-mgr 提供 battery.available 才显示（无电池设备隐藏）
  CardSpec(
    id: 'battery',
    visible: (s) => s.batteryAvailable,
    build: batteryCard,
  ),
  CardSpec(id: 'network', build: networkCard),
  CardSpec(id: 'cellular', build: cellularCard),
  CardSpec(id: 'clients', build: clientsCard),
  CardSpec(id: 'bandix', visible: (s) => s.bandixAvailable, build: bandixCard),
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
  'v',
  'ts',
  'interval',
  'collect_ms',
  'host',
  'system',
  'net',
  'battery',
  'docker',
  'clients',
  'bandix',
  'cellular',
  'services',
  'errors',
};

/// 通用兜底是否应渲染该节：未知顶层节、对象、且未显式声明 `available=false`。
///
/// 契约约定（§3.4/§3.7/§3.9/§3.10）：可选节以 `available=false` 表示当前不可用，
/// 专属卡据此隐藏；未知节若照常渲染原始字段，会在无电池等设备上冒出「假卡」
/// （如 daemon r15 的 battery 节点 + 旧版 App 的通用兜底）。
bool shouldRenderGenericSection(String key, dynamic value) {
  if (kConsumedSections.contains(key)) return false;
  if (value is! Map<String, dynamic>) return false;
  return value['available'] != false;
}

/// 组装概览主体：专属卡（按可见性）→ 通用兜底卡（未知节）→ errors 弱提示。
List<Widget> buildOverviewCards(BuildContext context, Snapshot s) {
  final out = <Widget>[];
  for (final c in overviewCards) {
    if (c.isVisible(s)) out.add(c.build(context, s));
  }
  for (final e in s.raw.entries) {
    if (!shouldRenderGenericSection(e.key, e.value)) continue;
    final v = e.value as Map<String, dynamic>;
    final fields = genericFields(v);
    if (fields.isEmpty) continue;
    out.add(genericCard(context, e.key, fields));
  }
  if (s.errors.isNotEmpty) {
    out.add(collectorErrorsCard(context, s));
  }
  return out;
}
