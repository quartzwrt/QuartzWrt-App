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
}
