// 蜂窝模型 / 展示助手 / 粘性门控（W6.12）。
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:quartzwrt_app/api/cellular.dart';
import 'package:quartzwrt_app/api/models.dart';
import 'package:quartzwrt_app/features/cellular/cellular_display.dart';
import 'package:quartzwrt_app/l10n/app_localizations.dart';
import 'package:quartzwrt_app/storage/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一份真实量级的 cellular 节（两模组：Quectel 全量 + Fibocom 部分信号）。
Map<String, dynamic> _snapshotJson() => {
  'v': 1,
  'ts': 1760000000,
  'interval': 2,
  'errors': <String>[],
  'cellular': {
    'available': true,
    'updated': 1760000000,
    'capabilities': {
      'at': true,
      'sms': true,
      'sim_switch': false,
      'stats': true,
      'temp': true,
    },
    'modems': [
      {
        'id': 'modem1',
        'model': 'RM500U-CN',
        'vendor': 'quectel',
        'firmware': 'RM500UCNCAR03A09M4G',
        'temp_c': 42.5,
        'registered': true,
        'operator': '46001',
        'network_mode': '5G NSA',
        'network_type': '5G NSA',
        'at_port': '/dev/ttyUSB2',
        'voltage_mv': 3900,
        'connect_status': 'connected',
        'cqi_ul': 6,
        'cqi_dl': 5,
        'ambr_ul': 100,
        'ambr_dl': 500,
        'cell_info': {
          'network_mode': '5G NSA',
          'duplex': 'TDD',
          'mcc': '460',
          'mnc': '01',
          'tac': '1234',
          'cell_id': '987654',
          'pci': '293',
          'arfcn': '627264',
          'band': 'NR n78',
          'ul_bandwidth': '100',
          'dl_bandwidth': '100',
          'scs': '30',
        },
        'signal': {
          'rsrp': -78,
          'rsrq': -11.0,
          'sinr': 22.0,
          'rssi': -51,
          'quality_pct': 64.6,
          'series': {
            'step': 10,
            'rsrp': [-80, -78, -77],
          },
        },
        'serving_cells': [
          {
            'role': 'pcc',
            'rat': 'LTE',
            'band': 'LTE B3',
            'channel': '1300',
            'pci': '293',
            'ul_bandwidth': '20',
            'dl_bandwidth': '20',
          },
          {
            'role': 'nsa',
            'rat': 'NR',
            'band': 'NR n78',
            'channel': '627264',
            'pci': '293',
            'dl_bandwidth': '100',
          },
        ],
        'dial': {
          'running': true,
          'ipv4': '10.42.7.23',
          'rx_bps': 18200000,
          'tx_bps': 2400000,
        },
        'traffic': {
          'available': true,
          'updated_at': 1760000000,
          'rx_bytes': 46180000000,
          'tx_bytes': 3320000000,
          'reset': {'enabled': true, 'type': 'monthly', 'hour': 0, 'day': 1},
        },
        'sim': {
          'status': 'ready',
          'slot': '1',
          'isp': '46001',
          'switchable': false,
        },
        'settings': {
          'usb_mode': 'qmi',
          'prefer': '4G+5G',
          'lockband': ['NR:41,78,79'],
        },
        'capabilities': {
          'at': true,
          'sms': true,
          'sim_switch': false,
          'stats': true,
          'current_band': true,
          'temp': true,
        },
      },
      {
        'id': 'modem2',
        'model': '',
        'registered': false,
        'signal': {'rssi': -67, 'rsrq': -13.0},
        'capabilities': {'at': true, 'sms': true},
      },
    ],
    'errors': ['cellular: modem2.get_stats failed'],
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cellular 模型解析', () {
    test('完整节：字段、能力、主小区、序列', () {
      final snap = Snapshot.parse(_snapshotJson())!;
      final c = snap.cellular!;
      expect(c.shown, isTrue);
      expect(c.capabilities.stats, isTrue);
      expect(c.modems.length, 2);

      final m = c.modems.first;
      expect(m.id, 'modem1');
      expect(m.title, 'RM500U-CN');
      expect(m.tempC, 42.5);
      expect(m.registered, isTrue);
      expect(m.operator, '46001');
      expect(m.networkMode, '5G NSA');
      expect(m.networkType, '5G NSA');
      expect(m.atPort, '/dev/ttyUSB2');
      expect(m.voltageMv, 3900);
      expect(m.connectStatus, 'connected');
      expect(m.cqiUl, 6);
      expect(m.cqiDl, 5);
      expect(m.ambrUl, 100);
      expect(m.ambrDl, 500);
      expect(m.cellInfo!.mcc, '460');
      expect(m.cellInfo!.tac, '1234');
      expect(m.cellInfo!.cellId, '987654');
      expect(m.cellInfo!.duplex, 'TDD');
      expect(m.signal!.rsrp, -78);
      expect(m.signal!.qualityPct, 64.6);
      expect(m.signal!.series!.step, 10);
      expect(m.signal!.series!.rsrp, [-80, -78, -77]);
      expect(m.primaryCell!.band, 'LTE B3'); // PCC 优先于 NSA
      expect(m.dial!.running, isTrue);
      expect(m.dial!.rxBps, 18200000);
      expect(m.traffic!.available, isTrue);
      expect(m.traffic!.resetType, 'monthly');
      expect(m.sim!.slot, '1');
      expect(m.settings!.usbMode, 'qmi');
      expect(m.settings!.prefer, '4G+5G');
      expect(m.settings!.lockband, ['NR:41,78,79']);
      expect(c.errors.single, contains('modem2'));
    });

    test('容错：型号缺失回退 id；无信号块不崩；节缺失返回 null', () {
      final snap = Snapshot.parse(_snapshotJson())!;
      final m2 = snap.cellular!.modems[1];
      expect(m2.title, 'modem2');
      expect(m2.signal?.rsrp, isNull);
      expect(m2.signal?.qualityPct, isNull);
      expect(m2.signal?.series, isNull);
      expect(m2.primaryCell, isNull);
      expect(m2.traffic, isNull); // 未提供 → null，不展示 0 值
      expect(m2.capabilities.stats, isFalse);

      final bare = Snapshot.parse({
        'v': 1,
        'ts': 1,
        'interval': 2,
        'errors': <String>[],
      })!;
      expect(bare.cellular, isNull);
    });

    test('available=false → shown=false（tab 与卡片一起隐藏）', () {
      final json = _snapshotJson();
      (json['cellular'] as Map<String, dynamic>)['available'] = false;
      final c = Snapshot.parse(json)!.cellular!;
      expect(c.available, isFalse);
      expect(c.shown, isFalse);
    });

    test('字段类型异常（字符串数字/未知键）不崩且按缺失处理', () {
      final c = Cellular.fromJson({
        'available': true,
        'modems': [
          {
            'id': 'm1',
            'signal': 'oops',
            'dial': 3,
            'serving_cells': ['x'],
            'unknown_key': 1,
          },
        ],
      });
      expect(c.shown, isTrue);
      expect(c.modems.single.signal, isNull);
      expect(c.modems.single.dial, isNull);
      expect(c.modems.single.servingCells, isEmpty);
    });
  });

  group('展示口径（与 Dashboard QModem 卡对齐）', () {
    final l10n = lookupAppL10n(const Locale('zh'));

    test('运营商 PLMN → 名称；已是名称则原样；SIM.isp 兜底', () {
      expect(
        cellularOperatorText(
          l10n,
          const CellularModem(id: 'm', operator: '46001'),
        ),
        '46001 · 中国联通',
      );
      expect(
        cellularOperatorText(
          l10n,
          const CellularModem(id: 'm', operator: '中国联通'),
        ),
        '中国联通',
      );
      expect(
        cellularOperatorText(
          l10n,
          const CellularModem(
            id: 'm',
            sim: CellularSim(isp: '46011'),
          ),
        ),
        '46011 · 中国电信',
      );
      expect(cellularOperatorText(l10n, const CellularModem(id: 'm')), isEmpty);
    });

    test('重置计划：月/周/日/未启用', () {
      expect(
        cellularResetText(
          l10n,
          const CellularTraffic(
            available: true,
            resetEnabled: true,
            resetType: 'monthly',
            resetHour: 3,
            resetDay: 1,
          ),
        ),
        '每月 1 日 · 03:00',
      );
      expect(
        cellularResetText(
          l10n,
          const CellularTraffic(
            available: true,
            resetEnabled: true,
            resetType: 'weekly',
            resetHour: 0,
          ),
        ),
        '每周 · 00:00',
      );
      expect(
        cellularResetText(
          l10n,
          const CellularTraffic(available: true, resetEnabled: true),
        ),
        '未设置重置计划',
      );
      expect(cellularResetText(l10n, null), '—');
    });

    test('信号带单位；compact 省略 RSSI；CQI/AMBR 缺省为 —', () {
      const sig = CellularSignal(rsrq: -11, sinr: 22, rssi: -51);
      expect(cellularSignalText(sig), 'RSRQ -11 dB · SINR 22 dB\nRSSI -51 dBm');
      expect(
        cellularSignalText(sig, compact: true),
        'RSRQ -11 dB · SINR 22 dB',
      );
      const bare = CellularModem(id: 'm');
      expect(cellularCqiText(bare), '—');
      expect(cellularAmbrText(bare), '—');
    });
  });

  group('短信解析（qmodem.sms.list）', () {
    test('messages 形态：字段、已读、排序、秒级时间戳', () {
      final list = CellularSmsMessage.listFrom({
        'status': 'ok',
        'messages': [
          {
            'id': 1,
            'index': 3,
            'type': 'received',
            'sender': '10086',
            'content': 'a',
            'timestamp': 1760000000,
            'is_read': false,
          },
          {
            'id': 2,
            'index': 4,
            'type': 'sent',
            'recipient': '+8613800138000',
            'content': 'b',
            'timestamp': 1760000600,
          },
          {'id': 3, 'content': '', 'sender': ''}, // 空条目 → 丢弃
        ],
      });
      expect(list.length, 2);
      expect(list.first.content, 'b'); // 时间戳大者在前
      expect(list.first.received, isFalse);
      expect(list.first.read, isTrue); // 发出默认已读
      expect(list.last.received, isTrue);
      expect(list.last.read, isFalse);
      expect(list.last.peer, '10086');
      expect(list.last.timestampMs, 1760000000000);
    });

    test('msg / received 形态与毫秒时间戳', () {
      final a = CellularSmsMessage.listFrom({
        'msg': [
          {'id': 9, 'sender': 'x', 'content': 'hi', 'timestamp': 1760000000000},
        ],
      });
      expect(a.single.timestampMs, 1760000000000);
      final b = CellularSmsMessage.listFrom({
        'received': [
          {'sender': 'y', 'content': 'ho'},
        ],
      });
      expect(b.single.content, 'ho');
      expect(b.single.timestampMs, 0);
    });

    test('非列表/缺字段不崩', () {
      expect(CellularSmsMessage.listFrom({'messages': 'oops'}), isEmpty);
      expect(CellularSmsMessage.listFrom(const {}), isEmpty);
      expect(
        CellularSmsMessage.fromJson({'id': 1, 'sender': 'x', 'content': 'y'})
            ?.id,
        '1',
      );
    });
  });

  group('展示助手', () {
    test('质量档位与段数', () {
      expect(qualityTier(null), isNull);
      expect(qualityTier(70), 'good');
      expect(qualityTier(69.9), 'fair');
      expect(qualityTier(40), 'fair');
      expect(qualityTier(39.9), 'poor');
      expect(qualityBars(null), 0);
      expect(qualityBars(0), 0);
      expect(qualityBars(50), 3); // 四舍五入
      expect(qualityBars(100), 5);
      expect(qualityBars(120), 5);
    });

    test('地址打码与 Dashboard 一致：IPv4 前两段；IPv6 前两组', () {
      expect(maskAddress('100.64.7.23'), '100.64.*.*');
      expect(maskAddress('240e:3a1:0:1::d1f'), '240e:3a1:*:*:*:*:*:*');
      expect(maskAddress('100.64.7.23/24'), '100.64.*.*');
      expect(maskAddress(''), '');
    });

    test('速率 / 字节 / 时长格式化', () {
      expect(fmtRate(0), '0 B/s');
      expect(fmtRate(18200000), '17.4 MB/s');
      expect(fmtBytes(46180000000), '43.0 GB');
      expect(fmtDuration(43440), '12h 04m');
      expect(fmtDuration(192), '3m 12s');
      expect(fmtDuration(9), '9s');
      expect(fmtDuration(0), '');
    });
  });

  group('粘性门控（PairedRouter.cellularSeen）', () {
    test('JSON 往返 + 旧数据兼容（缺键=false）', () {
      final r = PairedRouter(
        id: 'a',
        name: 'n',
        model: 'm',
        host: 'h',
        port: 443,
        fingerprint: 'f',
        deviceId: 'd',
        addedAt: 1,
        cellularSeen: true,
      );
      expect(r.toJson()['cellular_seen'], isTrue);
      final back = PairedRouter.fromJson(r.toJson())!;
      expect(back.cellularSeen, isTrue);

      final json = r.toJson()..remove('cellular_seen');
      expect(PairedRouter.fromJson(json)!.cellularSeen, isFalse);
    });

    test('registry.setCellularSeen 幂等置位', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final reg = RouterRegistry(prefs);
      await reg.upsert(
        PairedRouter(
          id: 'a',
          name: 'n',
          model: 'm',
          host: 'h',
          port: 443,
          fingerprint: 'f',
          deviceId: 'd',
          addedAt: 1,
        ),
      );
      expect(reg.byId('a')!.cellularSeen, isFalse);
      await reg.setCellularSeen('a');
      expect(reg.byId('a')!.cellularSeen, isTrue);
      // 幂等 + 不破坏其他字段
      await reg.setCellularSeen('a');
      expect(reg.byId('a')!.host, 'h');
      await reg.setCellularSeen('missing'); // 不存在的 id 静默
      expect(reg.list().length, 1);
    });
  });
}
