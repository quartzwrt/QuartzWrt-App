// 已配对路由器注册表（非敏感元数据）+ 令牌存储抽象。
//
// 元数据（名称/地址/指纹/device_id）落 shared_preferences；
// refresh 令牌只进安全存储（Keychain/Keystore），键按路由器隔离。
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';

const _kRouters = 'qz.routers';
const _kActive = 'qz.active';
const _kRefreshPrefix = 'qz.refresh.';

class RouterRegistry {
  RouterRegistry(this._prefs);

  final SharedPreferences _prefs;

  /// 返回**可增长副本**（调用方会 removeWhere/拼接——曾因返回 const [] 在
  /// 首次配对时抛 "Cannot remove from an unmodifiable list"，回归测试见
  /// test/router_registry_test.dart）。
  List<PairedRouter> list() {
    final raw = _prefs.getString(_kRouters);
    if (raw == null || raw.isEmpty) return <PairedRouter>[];
    try {
      final arr = jsonDecode(raw);
      if (arr is! List) return <PairedRouter>[];
      return arr
          .whereType<Map<String, dynamic>>()
          .map(PairedRouter.fromJson)
          .whereType<PairedRouter>()
          .toList();
    } catch (_) {
      return <PairedRouter>[];
    }
  }

  PairedRouter? byId(String? id) {
    if (id == null) return null;
    for (final r in list()) {
      if (r.id == id) return r;
    }
    return null;
  }

  PairedRouter? get active => byId(activeId);

  String? get activeId => _prefs.getString(_kActive);

  Future<void> upsert(PairedRouter r) async {
    final all = [...list()]..removeWhere((x) => x.id == r.id);
    all.add(r);
    await _prefs.setString(_kRouters, jsonEncode(all.map((x) => x.toJson()).toList()));
  }

  Future<void> remove(String id) async {
    final all = [...list()]..removeWhere((x) => x.id == id);
    await _prefs.setString(_kRouters, jsonEncode(all.map((x) => x.toJson()).toList()));
    if (activeId == id) {
      await setActive(all.isEmpty ? null : all.first.id);
    }
  }

  /// 设置/更新远程端点（W6.5；tailnet 100.x 或 MagicDNS 域名）。
  Future<void> setRemote(String id, String host, int port) async {
    final r = byId(id);
    if (r == null) return;
    await upsert(r.copyWith(remoteHost: host, remotePort: port));
  }

  /// 移除远程端点（不影响局域网配对与令牌）。
  Future<void> clearRemote(String id) async {
    final r = byId(id);
    if (r == null) return;
    await upsert(r.copyWith(clearRemote: true));
  }

  /// 置位蜂窝 tab 粘性标记（幂等；仅首次会写盘）。
  Future<void> setCellularSeen(String id) async {
    final cur = list().where((r) => r.id == id).toList();
    if (cur.isEmpty || cur.first.cellularSeen) return;
    await upsert(cur.first.copyWith(cellularSeen: true));
  }

  Future<void> setActive(String? id) async {
    if (id == null) {
      await _prefs.remove(_kActive);
    } else {
      await _prefs.setString(_kActive, id);
    }
  }
}

/// refresh 令牌存取（抽象以便测试注入内存实现）。
abstract interface class TokenStore {
  Future<String?> readRefresh(String routerId);
  Future<void> writeRefresh(String routerId, String token);
  Future<void> clearRefresh(String routerId);
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  @override
  Future<String?> readRefresh(String routerId) => _s.read(key: '$_kRefreshPrefix$routerId');

  @override
  Future<void> writeRefresh(String routerId, String token) =>
      _s.write(key: '$_kRefreshPrefix$routerId', value: token);

  @override
  Future<void> clearRefresh(String routerId) => _s.delete(key: '$_kRefreshPrefix$routerId');
}

class MemoryTokenStore implements TokenStore {
  final Map<String, String> _m = {};

  @override
  Future<String?> readRefresh(String routerId) async => _m[routerId];

  @override
  Future<void> writeRefresh(String routerId, String token) async => _m[routerId] = token;

  @override
  Future<void> clearRefresh(String routerId) async => _m.remove(routerId);
}
