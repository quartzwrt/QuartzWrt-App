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
  String get navOverview => '概览';

  @override
  String get navNetwork => '网络';

  @override
  String get navApps => '应用';

  @override
  String get navSettings => '设置';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get retry => '重试';

  @override
  String get refresh => '刷新';

  @override
  String get close => '关闭';

  @override
  String get loading => '加载中…';

  @override
  String get unknownValue => '—';

  @override
  String get unavailable => '不可用';

  @override
  String get notInstalled => '未安装';

  @override
  String get running => '运行中';

  @override
  String get stopped2 => '已停止';

  @override
  String get actionDone => '已完成';

  @override
  String actionFailed(String detail) {
    return '操作失败：$detail';
  }

  @override
  String get discoverTitle => '连接路由器';

  @override
  String get discoverScanning => '正在扫描局域网（mDNS）…';

  @override
  String get discoverNone => '未发现其他设备——确认手机与路由器在同一网络。';

  @override
  String get addByAddress => '按地址添加…';

  @override
  String get addByAddressTitle => '按地址添加路由器';

  @override
  String get hostLabel => '地址';

  @override
  String get portLabel => '端口';

  @override
  String get badgeVerifiable => '指纹可验证';

  @override
  String get badgeUnverified => '未验证指纹';

  @override
  String get noTabAfterPair => '配对后进入主界面';

  @override
  String pairTitle(String name) {
    return '连接到 $name';
  }

  @override
  String get certFingerprint => '证书指纹（SHA-256）';

  @override
  String get firmwareLabel => '固件';

  @override
  String get routerPassword => '路由器管理密码';

  @override
  String get routerPasswordHint => '使用路由器 root 管理密码；配对后手机以独立令牌免密登录，可在路由器上随时吊销。';

  @override
  String get pairButton => '配对';

  @override
  String get pairing => '配对中…';

  @override
  String get errInvalidCredentials => '密码错误';

  @override
  String errRateLimited(int sec) {
    return '尝试过多，请 $sec 秒后重试';
  }

  @override
  String get errPasswordNotSet => '请先在路由器上设置管理密码（LuCI → 系统 → 管理权）。';

  @override
  String get errFingerprintMismatch => '路由器身份已变化——已阻断配对。';

  @override
  String get errConnect => '无法连接路由器。';

  @override
  String get errBadCert => '证书校验失败。';

  @override
  String get errTimeout => '连接超时。';

  @override
  String get overviewTitle => '概览';

  @override
  String get connectedLan => '已连接 · 局域网';

  @override
  String get connectedRemote => '已连接 · 远程';

  @override
  String runFor(int d, int h, String m) {
    return '运行 $d 天 $h:$m';
  }

  @override
  String runForShort(int h, String m) {
    return '运行 $h:$m';
  }

  @override
  String get systemCardTitle => '系统';

  @override
  String get cpuLabel => 'CPU';

  @override
  String get memLabel => '内存';

  @override
  String get storageLabel => '存储';

  @override
  String get tempLabel => '温度';

  @override
  String get loadLabel => '负载';

  @override
  String get tempUnavailable => '不可用（无传感器）';

  @override
  String get networkCardTitle => '网络 · WAN';

  @override
  String get clientsCardTitle => '上网设备';

  @override
  String get appsCardTitle => '应用';

  @override
  String get dockerCardTitle => 'Docker';

  @override
  String get dockerRunning => '运行容器';

  @override
  String get dockerImages => '镜像';

  @override
  String get dockerUnhealthy => '非健康容器';

  @override
  String get bannerCollectorDown => '采集器未运行';

  @override
  String get bannerCollectorDownBody =>
      '路由器数据聚合服务不可用（quartz-daemon 未运行或正在启动）。数据恢复后自动刷新。';

  @override
  String get bannerConnectionLost => '连接中断';

  @override
  String get bannerConnectionLostBody => '显示最后一次数据，正在自动重试。';

  @override
  String get bannerNeedRepair => '配对已失效';

  @override
  String get bannerNeedRepairBody => '请重新配对以继续。';

  @override
  String otherClientsCount(int n) {
    return '另有 $n 台';
  }

  @override
  String get networkTitle => '网络';

  @override
  String get wanNetworkCardTitle => 'WAN · 网络管理';

  @override
  String get wanDown => '离线';

  @override
  String get wirelessCardTitle => '无线';

  @override
  String get noiseLabel => '噪声';

  @override
  String clientsOnlineHeader(int n) {
    return '$n 在线';
  }

  @override
  String allClientsEntry(int n) {
    return '全部上网设备（$n）';
  }

  @override
  String get clientsPageTitle => '上网设备';

  @override
  String get clientsEmpty => '暂无在线设备。';

  @override
  String get networkServicesTitle => '网络服务';

  @override
  String get dnsServiceLabel => 'DNS（dnsmasq）';

  @override
  String get wanReconnectPlanned => '规划中';

  @override
  String get lastSeenNow => '刚刚';

  @override
  String lastSeenMin(int n) {
    return '$n 分钟前';
  }

  @override
  String lastSeenHour(int n) {
    return '$n 小时前';
  }

  @override
  String lastSeenDay(int n) {
    return '$n 天前';
  }

  @override
  String get appsTitle => '应用';

  @override
  String get segApps => '应用';

  @override
  String get segPackages => '软件包';

  @override
  String get appsControllableIntro => '已安装且支持 App 内控制的应用；点入详情操作。';

  @override
  String get appsNone => '暂无支持控制的应用。';

  @override
  String get appsNotInstalledTitle => '未安装的应用';

  @override
  String get appsNotInstalledBody => 'Docker / Tailscale 等安装后将自动出现在列表（探针机制）。';

  @override
  String get appDetailStatusTitle => '状态';

  @override
  String get appDetailStatusRunning => '运行中';

  @override
  String get coreLabel => '核心';

  @override
  String get statusSourceLabel => '状态来源';

  @override
  String get statusSourceProbe => '路由器探针（零重编）';

  @override
  String get actionsTitle => '动作';

  @override
  String get actionsNote => '动作按路由器能力提供（WP-5 白名单 / WP-8 Bridge）。';

  @override
  String get actionRestart => '重启服务';

  @override
  String get actionStop => '停止';

  @override
  String get actionStart => '启动';

  @override
  String get packageCardTitle => '软件包';

  @override
  String get packageVersion => '版本';

  @override
  String get packageSource => '来源';

  @override
  String get packageSize => '安装大小';

  @override
  String get packageRemove => '卸载…';

  @override
  String get packagesApiMissingTitle => '软件包管理暂不可用';

  @override
  String get packagesApiMissingBody =>
      '路由器 API 尚未包含软件包管理（需 quartz-app-api 后续版本）。支持后此页自动出现已安装/可升级列表。';

  @override
  String upgradableHeader(int n) {
    return '可升级 · $n';
  }

  @override
  String upgradeAllBtn(int n) {
    return '全部升级（$n）';
  }

  @override
  String installedHeader(int n) {
    return '已安装 · $n';
  }

  @override
  String allPackagesEntry(int n) {
    return '全部软件包（$n）· 搜索';
  }

  @override
  String get installNewTitle => '安装新软件包';

  @override
  String get installNewBody => '浏览可用软件源、安装新包为后续功能；v1 先做「已安装 / 升级 / 记录」闭环。';

  @override
  String get opLogEntry => '记录';

  @override
  String get opLogTitle => '操作记录';

  @override
  String get opLogEmpty => '暂无操作记录。';

  @override
  String get opLogRetain => '仅保留最近 30 条；点条目查看逐包结果。';

  @override
  String get opReindex => '刷新软件源';

  @override
  String opUpgradeAll(int n) {
    return '升级（$n）';
  }

  @override
  String opUpgrade(String name) {
    return '升级 $name';
  }

  @override
  String opRemove(String name) {
    return '卸载 $name';
  }

  @override
  String get opResultOk => '成功';

  @override
  String get opResultFail => '失败';

  @override
  String get opResultPartial => '部分失败';

  @override
  String get settingsTitle => '设置';

  @override
  String get sysSettingsGroup => '系统设置 · 路由器';

  @override
  String get appSettingsGroup => '应用设置 · 本机';

  @override
  String get pairedLan => '已配对 · 局域网';

  @override
  String get pairedRemote => '已配对 · 远程';

  @override
  String get fingerprintLabel => '证书指纹';

  @override
  String get pairedDevicesEntry => '已配对设备';

  @override
  String get addRouterEntry => '添加路由器';

  @override
  String get deviceControlTitle => '设备控制';

  @override
  String get rebootRouter => '重启路由器';

  @override
  String get restartService => '重启服务…';

  @override
  String get appearanceTitle => '外观';

  @override
  String get followSystem => '跟随系统';

  @override
  String get modeDark => '深色';

  @override
  String get modeLight => '浅色';

  @override
  String get languageTitle => '语言';

  @override
  String get aboutTitle => '关于';

  @override
  String get appVersionLabel => '应用版本';

  @override
  String get apiLabel => 'API';

  @override
  String get devicesPageTitle => '已配对设备';

  @override
  String get devicesCurrentBadge => '本机';

  @override
  String get devicesRevokedBadge => '已吊销';

  @override
  String get revokeBtn => '吊销';

  @override
  String get revokeConfirmTitle => '吊销该设备？';

  @override
  String get revokeConfirmBody => '该设备将立即失去访问权限，需重新配对。';

  @override
  String get rebootConfirmTitle => '重启路由器？';

  @override
  String rebootConfirmBody(String name) {
    return '$name 将立即重启，网络中断约 1–2 分钟；恢复后自动重连。';
  }

  @override
  String get removeRouterTitle => '从 App 中移除该路由器？';

  @override
  String get removeRouterBody => '同时吊销本机在路由器上的登录（推荐）。';

  @override
  String get removeRouterBtn => '移除';

  @override
  String get kernelLabel => '内核';

  @override
  String get rePair => '重新配对';

  @override
  String get collectorErrors => '采集器消息';

  @override
  String get remoteEntry => '远程访问';

  @override
  String get remotePageTitle => '远程访问';

  @override
  String get remoteRouterStatusTitle => '路由器端 · Tailscale';

  @override
  String get remoteTsIpLabel => 'Tailscale 地址';

  @override
  String get remoteUseThisAddr => '使用此地址添加远程连接';

  @override
  String get remoteNotDetected => '未检测到 Tailscale——可在路由器「应用」中安装并启用。';

  @override
  String get remoteStepsTitle => '使用步骤';

  @override
  String get remoteStep1 => '在路由器「应用 → Tailscale」中安装并启用。';

  @override
  String get remoteStep2 => '在路由器 Tailscale 页面登录 tailnet。';

  @override
  String get remoteStep3 => '手机安装 Tailscale 客户端并登录同一 tailnet。';

  @override
  String get remoteStep4 =>
      '在此页添加 tailnet 地址（100.x.y.z 或 MagicDNS 域名）；证书指纹与局域网配对相同，自动复用。';

  @override
  String get remoteAddrTitle => '远程地址';

  @override
  String get remoteAddrNone => '未设置——在家经局域网直连；外出后在本页添加 tailnet 地址即可远程管理。';

  @override
  String get remoteAddBtn => '添加远程地址…';

  @override
  String get remoteEditBtn => '修改';

  @override
  String get remoteTestBtn => '测试';

  @override
  String get remoteInUse => '使用中';

  @override
  String get remoteHostLabel => '地址（100.x.y.z 或域名）';

  @override
  String get remoteTestSave => '测试并保存';

  @override
  String get remoteTesting => '测试中…';

  @override
  String get remoteTestOk => '远程连接可用，已保存。';

  @override
  String remoteTestFail(String detail) {
    return '连接失败：$detail';
  }

  @override
  String get remoteHostRequired => '请填写地址。';

  @override
  String get remoteRemoveBtn => '移除远程地址';

  @override
  String get remoteRemoveShort => '移除';

  @override
  String get remoteRemoveTitle => '移除远程地址？';

  @override
  String get remoteRemoveBody => '之后仅通过局域网连接路由器；不影响配对与令牌。';

  @override
  String get remoteRemoved => '已移除远程地址。';

  @override
  String get remoteAutoTitle => '自动切换';

  @override
  String get remoteAutoBody => '同网时优先局域网直连；连接失败自动改用远程地址；回到局域网后自动切回。';

  @override
  String get remoteSecurityTitle => '安全说明';

  @override
  String get remoteSecurityBody =>
      '远程与局域网同样经证书指纹校验（防中间人）。远程执行重启/断网类操作可能暂时失联，路由器会自行恢复。移除远程地址不影响局域网配对。';
}
