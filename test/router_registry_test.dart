import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/storage/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

PairedRouter _r(String id) => PairedRouter(
      id: id,
      name: 'r-$id',
      model: 'm',
      host: '127.0.0.1',
      port: 8443,
      fingerprint: 'ab' * 32,
      deviceId: id,
      addedAt: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('upsert on empty store works (first pairing regression)', () async {
    SharedPreferences.setMockInitialValues({});
    final reg = RouterRegistry(await SharedPreferences.getInstance());
    await reg.upsert(_r('dev1')); // 曾抛 Unsupported operation（const [] + removeWhere）
    expect(reg.list().length, 1);
    expect(reg.byId('dev1')?.name, 'r-dev1');
  });

  test('upsert replaces same id and appends new ids', () async {
    SharedPreferences.setMockInitialValues({});
    final reg = RouterRegistry(await SharedPreferences.getInstance());
    await reg.upsert(_r('a'));
    await reg.upsert(_r('b'));
    await reg.upsert(_r('a'));
    expect(reg.list().length, 2);
  });

  test('remove drops entry and repairs active pointer', () async {
    SharedPreferences.setMockInitialValues({});
    final reg = RouterRegistry(await SharedPreferences.getInstance());
    await reg.upsert(_r('a'));
    await reg.upsert(_r('b'));
    await reg.setActive('a');
    await reg.remove('a');
    expect(reg.byId('a'), isNull);
    expect(reg.activeId, 'b'); // 自动指向剩余条目
    await reg.remove('b');
    expect(reg.activeId, isNull);
  });

  test('corrupt store yields empty list and recovers on upsert', () async {
    SharedPreferences.setMockInitialValues({'qz.routers': '{not json'});
    final reg = RouterRegistry(await SharedPreferences.getInstance());
    expect(reg.list(), isEmpty);
    await reg.upsert(_r('x'));
    expect(reg.list().single.id, 'x');
  });

  test('setRemote/clearRemote persist and preserve other fields', () async {
    SharedPreferences.setMockInitialValues({});
    final reg = RouterRegistry(await SharedPreferences.getInstance());
    await reg.upsert(_r('dev1'));
    await reg.setRemote('dev1', '100.1.2.3', 443);
    final r = reg.byId('dev1')!;
    expect(r.remoteHost, '100.1.2.3');
    expect(r.remotePort, 443);
    expect(r.host, '127.0.0.1'); // 局域网端点不受影响
    expect(r.fingerprint, 'ab' * 32);
    expect(r.deviceId, 'dev1');

    await reg.clearRemote('dev1');
    expect(reg.byId('dev1')!.hasRemote, isFalse);
  });

  test('setRemote on unknown id is a no-op', () async {
    SharedPreferences.setMockInitialValues({});
    final reg = RouterRegistry(await SharedPreferences.getInstance());
    await reg.setRemote('nope', '100.1.2.3', 443);
    expect(reg.list(), isEmpty);
  });

  test('PairedRouter json roundtrip with and without remote (backward compat)', () {
    final withRemote = _r('dev1').copyWith(remoteHost: '100.1.2.3', remotePort: 8443);
    final back = PairedRouter.fromJson(withRemote.toJson())!;
    expect(back.remoteHost, '100.1.2.3');
    expect(back.remotePort, 8443);

    // 旧记录（无 remote_* 键）→ 空远程
    final legacy = PairedRouter.fromJson(_r('old').toJson())!;
    expect(legacy.hasRemote, isFalse);
    expect(legacy.remotePort, 443);

    // 空串/空白不算远程
    final blank = PairedRouter.fromJson({..._r('b').toJson(), 'remote_host': '  '})!;
    expect(blank.hasRemote, isFalse);
  });
}
