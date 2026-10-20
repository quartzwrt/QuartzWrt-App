#!/usr/bin/env dart

// UI 风格门禁：feature 层禁止 Material 可见组件（视觉统一由 Quartz UI kit 提供）。
//
// 说明：QzLegacyButton / QzLegacyIconButton 是迁移桥，渲染结果仍是 Quartz；
// 脚本把它们与硬编码色/字号列为 warning（棘轮），不阻塞合并。
import 'dart:io';

const banned = <String>[
  'AppBar(',
  'ListTile(',
  'Switch(',
  'SwitchListTile(',
  'TextField(',
  'FilledButton(',
  'OutlinedButton(',
  'TextButton(',
  'IconButton(',
  'InkWell(',
  'SnackBar(',
  'AlertDialog(',
  'showDialog(',
  'showModalBottomSheet(',
  'RefreshIndicator(',
  'CircularProgressIndicator(',
  'LinearProgressIndicator(',
  'Divider(',
  'PopupMenuButton(',
  'ActionChip(',
  'ChoiceChip(',
  'FilterChip(',
  'Chip(',
  'Checkbox(',
  'CheckboxListTile(',
  'Radio(',
  'RadioListTile(',
  'Slider(',
  'DropdownButton(',
  'Card(',
  'Material(',
];

const warnPatterns = <String>[
  'QzLegacyButton',
  'QzLegacyIconButton',
  'withValues(alpha',
  'fontSize:',
  'Color(0x',
  'Icons.',
];

void main() {
  final root = Directory('lib/features');
  if (!root.existsSync()) {
    stderr.writeln(
      'ui_lint: run from the QuartzWrt-App root (lib/features not found)',
    );
    exit(2);
  }
  var violations = 0;
  final warnings = <String, int>{for (final w in warnPatterns) w: 0};
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final f in files) {
    final rel = f.path;
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final b in banned) {
        if (RegExp(r'\b' + RegExp.escape(b)).hasMatch(line)) {
          // 允许注释里提到旧组件名（文档/迁移说明）。
          if (line.trimLeft().startsWith('//')) continue;
          violations++;
          stderr.writeln('$rel:${i + 1}: banned Material widget: $b');
        }
      }
      for (final w in warnPatterns) {
        if (line.contains(w)) warnings[w] = (warnings[w] ?? 0) + 1;
      }
    }
  }

  final warnTotal = warnings.values.fold<int>(0, (a, b) => a + b);
  stdout.writeln(
    'ui_lint: ${files.length} files, $violations banned, $warnTotal legacy/hardcoded markers',
  );
  for (final e in warnings.entries) {
    if (e.value > 0) stdout.writeln('  warn ${e.key}: ${e.value}');
  }
  if (violations > 0) {
    stderr.writeln(
      '\nFix: use lib/widgets/quartz.dart (QzAppBar / QzListRow / QzToggle / '
      'QzField / QzButton / QzIconButton / showQzSheet / showQzToast / QzRefresh).',
    );
    exit(1);
  }
}
