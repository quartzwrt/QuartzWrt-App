// Quartz 线稿图标：资产来自 tool/gen_ui_icons.py（设计稿内联 SVG + 同风格补图）。
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme.dart';

abstract final class QzIcons {
  static const add = 'add';
  static const admin = 'admin';
  static const advanced = 'advanced';
  static const arrowRight = 'arrow_right';
  static const at = 'at';
  static const bell = 'bell';
  static const bluetooth = 'bluetooth';
  static const briefcase = 'briefcase';
  static const calendar = 'calendar';
  static const check = 'check';
  static const checkUp = 'check_up';
  static const chevronDown = 'chevron_down';
  static const chevronLeft = 'chevron_left';
  static const chevronRight = 'chevron_right';
  static const clients = 'clients';
  static const clock = 'clock';
  static const close = 'close';
  static const cloud = 'cloud';
  static const copy = 'copy';
  static const cpu = 'cpu';
  static const database = 'database';
  static const delete = 'delete';
  static const dhcp = 'dhcp';
  static const display = 'display';
  static const dot = 'dot';
  static const download = 'download';
  static const downloadCloud = 'download_cloud';
  static const edit = 'edit';
  static const ethernet = 'ethernet';
  static const external = 'external';
  static const eye = 'eye';
  static const eyeOff = 'eye_off';
  static const file = 'file';
  static const filter = 'filter';
  static const firewall = 'firewall';
  static const folder = 'folder';
  static const folderOpen = 'folder_open';
  static const gem = 'gem';
  static const globe = 'globe';
  static const gps = 'gps';
  static const help = 'help';
  static const home = 'home';
  static const info = 'info';
  static const init = 'init';
  static const interfaces = 'interfaces';
  static const key = 'key';
  static const lan = 'lan';
  static const link = 'link';
  static const list = 'list';
  static const lock = 'lock';
  static const memory = 'memory';
  static const minus = 'minus';
  static const more = 'more';
  static const navApps = 'nav_apps';
  static const navCellular = 'nav_cellular';
  static const navOverview = 'nav_overview';
  static const navRouter = 'nav_router';
  static const navSettings = 'nav_settings';
  static const networkConfig = 'network_config';
  static const package = 'package';
  static const pause = 'pause';
  static const play = 'play';
  static const plusCircle = 'plus_circle';
  static const power = 'power';
  static const refresh = 'refresh';
  static const restart = 'restart';
  static const route = 'route';
  static const routeAlt = 'route_alt';
  static const routerAntenna = 'router_antenna';
  static const sd = 'sd';
  static const search = 'search';
  static const server = 'server';
  static const shield = 'shield';
  static const signal = 'signal';
  static const sim = 'sim';
  static const sliders = 'sliders';
  static const sms = 'sms';
  static const smsForward = 'sms_forward';
  static const sort = 'sort';
  static const spark = 'spark';
  static const switchIcon = 'switch';
  static const sync = 'sync';
  static const system = 'system';
  static const terminal = 'terminal';
  static const thermometer = 'thermometer';
  static const traffic = 'traffic';
  static const tune = 'tune';
  static const upload = 'upload';
  static const uploadCloud = 'upload_cloud';
  static const usb = 'usb';
  static const user = 'user';
  static const warning = 'warning';
  static const wifi = 'wifi';
  static const wifiOff = 'wifi_off';
}

class QzIcon extends StatelessWidget {
  const QzIcon(
    this.name, {
    super.key,
    this.size = 18,
    this.color,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = QuartzTokens.of(context);
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? t.muted, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

/// 品牌切面宝石（渐变蓝底 + 白色宝石 + 高光），对齐设计稿 hero 图标。
class QzBrandMark extends StatelessWidget {
  const QzBrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * .25);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7FB2FF),
                    Color(0xFF007AFF),
                    Color(0xFF3D5AFE),
                  ],
                  stops: [0, .42, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-.35, -1),
                  end: const Alignment(.4, .2),
                  colors: [
                    Colors.white.withValues(alpha: .55),
                    Colors.transparent,
                  ],
                  stops: const [0, .42],
                ),
              ),
            ),
            Center(
              child: QzIcon(QzIcons.gem, size: size * .58, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
