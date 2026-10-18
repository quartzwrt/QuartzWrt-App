// 系统 crontab（/etc/crontabs/root）读写：app-api `cron.read` / `cron.write`。
//
// 非 UCI 配置；write 只接受固定路径 + 大小/控制字符校验（服务端），
// 保存后由 App 调 luci.init_action('cron','reload') 生效。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_manager.dart';
import '../state/app_state.dart';
import 'envelope.dart';

class CronResult {
  const CronResult(this.ok, {this.path = '', this.content = '', this.exists = false, this.error});

  final bool ok;
  final String path;
  final String content;
  final bool exists;
  final ApiError? error;
}

class CronClient {
  const CronClient(this._tm);

  final TokenManager _tm;

  Future<CronResult> read() async {
    final r = await _tm.call('cron.read', {});
    if (!r.ok) return CronResult(false, error: r.error);
    return CronResult(
      true,
      path: '${r.data['path'] ?? ''}',
      content: '${r.data['content'] ?? ''}',
      exists: r.data['exists'] == true,
    );
  }

  Future<ApiResult> write(String content) => _tm.call('cron.write', {'content': content});
}

final cronClientProvider = Provider<CronClient?>((ref) {
  final tm = ref.watch(tokenManagerProvider);
  return tm == null ? null : CronClient(tm);
});
