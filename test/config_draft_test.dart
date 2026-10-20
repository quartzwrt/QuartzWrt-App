// 配置文件草稿（ConfigDraft）纯逻辑：掩码/布尔/列表/协议可见性/整数。
import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/features/router/config_common.dart';

void main() {
  group('ConfigDraft', () {
    test('敏感字段掩码未修改不算 dirty，改写后 dirty，清空恢复掩码', () {
      const f = ConfigField(
        'key',
        'Key',
        kind: ConfigFieldKind.secret,
        sensitive: true,
      );
      final d = ConfigDraft(
        config: 'wireless',
        section: '@wifi-iface[0]',
        fields: const [f],
        initial: const {'key': '__masked__'},
      );
      expect(d.hasChanges, isFalse);
      d.setText(f, '');
      expect(d.hasChanges, isFalse);
      d.setText(f, 'new-secret');
      expect(d.hasChanges, isTrue);
      expect(d.edits().single.value, 'new-secret');
      d.setText(f, '');
      expect(d.hasChanges, isFalse);
      expect(d.edits(), isEmpty);
    });

    test('布尔值 1/true 归一，切到 false 才 dirty', () {
      const f = ConfigField('ignore', 'Ignore', kind: ConfigFieldKind.boolean);
      final d = ConfigDraft(
        config: 'dhcp',
        section: 'lan',
        fields: const [f],
        initial: const {'ignore': '1'},
      );
      expect(d.hasChanges, isFalse);
      d.set(f, true);
      expect(d.hasChanges, isFalse);
      d.set(f, false);
      expect(d.hasChanges, isTrue);
      expect(d.edits().single.value, isFalse);
    });

    test('列表字段空格串与数组等价', () {
      const f = ConfigField('dns', 'DNS', kind: ConfigFieldKind.list);
      final d = ConfigDraft(
        config: 'network',
        section: 'wan',
        fields: const [f],
        initial: const {'dns': '1.1.1.1 8.8.8.8'},
      );
      d.setText(f, '1.1.1.1  8.8.8.8');
      expect(d.hasChanges, isFalse);
      d.setText(f, '9.9.9.9');
      expect(d.edits().single.value, ['9.9.9.9']);
    });

    test('协议驱动的隐藏字段不参与 dirty/edits', () {
      final f = ConfigField(
        'ipaddr',
        'IP',
        visibleWhen: (v) => '${v['proto']}' == 'static',
      );
      final d = ConfigDraft(
        config: 'network',
        section: 'wan',
        fields: [f],
        initial: const {'proto': 'dhcp', 'ipaddr': '192.168.1.2'},
      );
      d.setText(f, '10.0.0.2');
      expect(d.hasChanges, isFalse);
      expect(d.edits(), isEmpty);
      d.set(const ConfigField('proto', 'Proto'), 'static');
      expect(d.hasChanges, isTrue);
      expect(d.edits().single.option, 'ipaddr');
    });

    test('整数字段解析（空值不写）', () {
      const f = ConfigField('log_size', 'Size', kind: ConfigFieldKind.integer);
      final d = ConfigDraft(
        config: 'system',
        section: '@system[0]',
        fields: const [f],
        initial: const {'log_size': '64'},
      );
      d.setText(f, '64');
      expect(d.hasChanges, isFalse);
      d.setText(f, '128');
      expect(d.edits().single.value, 128);
      d.setText(f, '');
      expect(d.hasChanges, isFalse);
      expect(d.edits(), isEmpty);
    });

    test('configValueText：数组空格连接 / null 空串', () {
      expect(configValueText(null), '');
      expect(configValueText(['a', 'b']), 'a b');
      expect(configValueText(1), '1');
    });
  });
}
