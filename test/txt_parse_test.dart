import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/discovery/mdns.dart';

void main() {
  group('parseTxt', () {
    test('segments joined by newlines (multicast_dns behavior)', () {
      final m = parseTxt(
        'v=1\npath=/ubus\nname=QuartzWrt-R4S\nfp=9d79d120\nrel=QuartzWrt 0.1.0 (ImmortalWrt 25.12)\n',
      );
      expect(m['v'], '1');
      expect(m['path'], '/ubus');
      expect(m['name'], 'QuartzWrt-R4S');
      expect(m['fp'], '9d79d120');
      expect(m['rel'], 'QuartzWrt 0.1.0 (ImmortalWrt 25.12)');
    });

    test('tolerates blank lines, junk and missing values', () {
      final m = parseTxt('\n  \njunk\nv=1\n=oops\nKey=Value\n');
      expect(m['v'], '1');
      expect(m['key'], 'Value'); // 键小写
      expect(m.containsKey(''), isFalse);
      expect(m.containsKey('junk'), isFalse);
    });

    test('empty text', () {
      expect(parseTxt(''), isEmpty);
    });
  });
}
