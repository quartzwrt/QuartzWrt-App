import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/features/overview/registry.dart';

void main() {
  group('battery card', () {
    final spec = overviewCards.firstWhere((c) => c.id == 'battery');

    test('节缺失（无电池设备/新 daemon）→ 隐藏', () {
      expect(spec.isVisible(Snapshot({'v': 1})), isFalse);
    });

    test('available=false → 隐藏', () {
      final s = Snapshot({
        'v': 1,
        'battery': {'available': false, 'capacity': 0},
      });
      expect(spec.isVisible(s), isFalse);
    });

    test('available=true → 显示', () {
      final s = Snapshot({
        'v': 1,
        'battery': {'available': true, 'capacity': 82},
      });
      expect(spec.isVisible(s), isTrue);
    });
  });

  group('通用兜底节', () {
    test('已消费节不渲染', () {
      expect(shouldRenderGenericSection('battery', {'available': true}), isFalse);
      expect(shouldRenderGenericSection('system', {'load': [1]}), isFalse);
    });

    test('未知可选节 available=false 不渲染（防假卡）', () {
      expect(
        shouldRenderGenericSection('ups', {'available': false, 'charge': 0}),
        isFalse,
      );
    });

    test('未知节无 available 标记仍渲染（L1 兜底）', () {
      expect(
        shouldRenderGenericSection('ups', {'charge': 42, 'status': 'ok'}),
        isTrue,
      );
    });

    test('非对象节不渲染', () {
      expect(shouldRenderGenericSection('foo', 'bar'), isFalse);
      expect(shouldRenderGenericSection('foo', null), isFalse);
    });
  });
}
