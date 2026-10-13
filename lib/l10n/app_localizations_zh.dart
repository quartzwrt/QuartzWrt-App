// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'QuartzWrt';

  @override
  String get notConnectedTitle => '未连接路由器';

  @override
  String get notConnectedBody => '在局域网中自动发现 QuartzWrt 路由器，或手动按地址添加。';

  @override
  String get actionScan => '扫描局域网';

  @override
  String get actionAddByAddress => '按地址添加';

  @override
  String get settingsTitle => '设置';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutBody => 'QuartzWrt 配套应用';
}
