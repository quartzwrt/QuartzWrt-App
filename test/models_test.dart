import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/models.dart';

const _sample = {
  'v': 1,
  'ts': 1760000000,
  'interval': 2,
  'collect_ms': 12,
  'host': {'hostname': 'QuartzWrt-R4S', 'model': 'FriendlyElec NanoPi R4S'},
  'system': {
    'load': [0.42, 0.31, 0.25],
    'cpu_pct': 7.8,
    'mem': {'total': 4294967296, 'used': 1374389535, 'pct': 32.0},
    'temp_c': null,
  },
  'net': {
    'wan': {
      'up': true,
      'ifname': 'eth0',
      'proto': 'dhcp',
      'ipv4': '100.64.7.23',
    },
    'series': {
      'step': 2,
      'rx': [1, 2, 3],
      'tx': [1, 1, 1],
    },
  },
  'docker': null,
  'clients': {
    'total': 12,
    'items': [
      {'mac': '00:11:32:7d:55:60', 'ip': '192.168.1.10', 'host': 'NAS'},
    ],
  },
  'services': {
    'openclash': {'running': true, 'core': 'mihomo 1.19.2'},
    'unknown_app': {'running': false, 'vendor_field': 'x'},
  },
  'errors': [],
  // 未知节（L1 泛化渲染的来源）
  'usb_storage': {
    'mount': '/mnt/usb',
    'total_gb': 128,
    'unknown_obj': {'a': 1, 'b': 2},
  },
};

void main() {
  test('snapshot parses known sections with tolerance', () {
    final s = Snapshot.parse(Map<String, dynamic>.from(_sample))!;
    expect(s.version, 1);
    expect(s.host['hostname'], 'QuartzWrt-R4S');
    expect(s.docker, isNull); // null 节 → 可空
    expect(s.clientsTotal, 12);
    expect(s.clientItems.single['host'], 'NAS');
    expect(s.wan['up'], true);
    expect(s.series!.$2, [1, 2, 3]);
    // 未知节保留在 raw（通用卡数据源）
    expect(s.raw['usb_storage'], isA<Map<String, dynamic>>());
  });

  test(
    'service entries: running first, unknown keys kept, malformed tolerated',
    () {
      final s = Snapshot.parse({
        'v': 1,
        'services': {
          'b_stopped': {'running': false},
          'a_running': {'running': true, 'core': 'x 1.0'},
          'legacy_bool': true, // 非 map 值容错
        },
      })!;
      final entries = s.serviceEntries;
      expect(entries.first.$1, 'a_running'); // running 优先
      final names = entries.map((e) => e.$1).toList();
      expect(names, containsAll(['a_running', 'b_stopped', 'legacy_bool']));
      expect(
        entries.firstWhere((e) => e.$1 == 'legacy_bool').$2['running'],
        true,
      );
    },
  );

  test('malformed snapshot → null (degrade to 数据损坏)', () {
    expect(Snapshot.parse(null), isNull);
    expect(Snapshot.parse('nope'), isNull);
    expect(Snapshot.parse(<String, dynamic>{}), isNotNull); // 空对象合法（降级由节级处理）
  });

  test('genericFields extracts scalars, lists and flattens one level', () {
    final fields = genericFields({
      'mount': '/mnt/usb',
      'total_gb': 128,
      'flags': ['a', 'b'],
      'nested': {
        'a': 1,
        'b': 2,
        'deep': {'x': 1},
      },
      'nothing': null,
    });
    final m = {for (final e in fields) e.key: e.value};
    expect(m['mount'], '/mnt/usb');
    expect(m['total_gb'], '128');
    expect(m['flags'], 'a · b');
    expect(m['nested'], 'a: 1 · b: 2'); // 嵌套只展平一层，深层跳过
    expect(m.containsKey('nothing'), isFalse);
  });

  test('genericFields respects max rows', () {
    final fields = genericFields({'a': 1, 'b': 2, 'c': 3, 'd': 4}, max: 2);
    expect(fields.length, 2);
  });
}
