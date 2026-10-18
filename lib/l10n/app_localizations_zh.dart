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
  String get opLogRetain => '仅保留最近 30 条（升级 / 卸载 / 刷新索引）。';

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

  @override
  String get embedTitle => '内嵌直连（实验）';

  @override
  String get embedBody =>
      '在本机内嵌一个 tailnet 节点：手机无需安装 Tailscale 客户端，也能经 tailnet 远程访问路由器。开启后会为本机在 tailnet 中创建一台设备（需登录授权）；关闭即回退为普通直连方式。';

  @override
  String get embedUnavailable => '此构建未包含内嵌引擎（发布包默认包含）。';

  @override
  String get embedEnable => '开启内嵌直连';

  @override
  String get embedStateLabel => '状态';

  @override
  String get embedPhaseStarting => '启动中…';

  @override
  String get embedPhaseNeedsLogin => '等待登录';

  @override
  String get embedPhaseRunning => '已连接';

  @override
  String get embedPhaseStopped => '未启用';

  @override
  String get embedPhaseError => '错误';

  @override
  String get embedSelfIpLabel => '本机 tailnet 地址';

  @override
  String get embedLoginBtn => '登录 Tailscale';

  @override
  String get embedLoginHint => '登录后本机即成为 tailnet 设备，远程地址将自动优先经内嵌节点连接。';

  @override
  String get embedCopyBtn => '复制链接';

  @override
  String get embedCopied => '已复制';

  @override
  String get embedErrorDetail => '错误信息';

  @override
  String get pkgViewUpgradable => '可升级';

  @override
  String pkgViewUpgradableN(int n) {
    return '可升级 ($n)';
  }

  @override
  String get pkgViewInstalled => '已安装';

  @override
  String get pkgViewAll => '全部';

  @override
  String get pkgSearchHint => '搜索软件包（名称）';

  @override
  String get pkgSearchPrompt => '输入名称搜索软件包；「已安装 / 可升级」在其它两个分段。';

  @override
  String get pkgSearchNone => '未找到匹配的软件包。';

  @override
  String get pkgEmptyUpgradable => '全部软件包均为最新。';

  @override
  String get pkgEmptyInstalled => '未读取到已安装软件包。';

  @override
  String pkgRefreshDone(int s) {
    return '索引已刷新（${s}s）';
  }

  @override
  String get pkgUpgrade => '升级';

  @override
  String pkgUpgradeTo(String version) {
    return '升级到 $version';
  }

  @override
  String pkgUpgraded(String name) {
    return '已升级 $name';
  }

  @override
  String get pkgRemove => '卸载';

  @override
  String pkgRemoved(String name) {
    return '已卸载 $name';
  }

  @override
  String pkgRemoveConfirmTitle(String name) {
    return '卸载 $name？';
  }

  @override
  String get pkgRemoveConfirmBody => '将从路由器移除该软件包；依赖它的组件可能失效，相关服务会停止。此操作不可撤销。';

  @override
  String get pkgUpgradeAllConfirmTitle => '全部升级？';

  @override
  String pkgUpgradeAllConfirmBody(int n) {
    return '将升级全部可升级软件包（$n 个），期间可能重启相关服务并占用网络；请勿断电。';
  }

  @override
  String get pkgBadgeInstalled => '已安装';

  @override
  String get pkgBadgeUpgrade => '可升级';

  @override
  String pkgLoadMore(int shown, int total) {
    return '加载更多（$shown/$total）';
  }

  @override
  String pkgShownOf(int shown, int total) {
    return '已显示 $shown/$total';
  }

  @override
  String get pkgCardName => '名称';

  @override
  String pkgCardUpgradeTo(String version) {
    return '可升级到 $version';
  }

  @override
  String get pkgCardNotInstalled => '该应用未以软件包形式安装（或名称不匹配）；可在「软件包」分段搜索确认。';

  @override
  String opLogMeta(String status, String dur) {
    return '$status · 耗时 $dur';
  }

  @override
  String get save => '保存';

  @override
  String bandixRowOnline(int online, int devices) {
    return '在线 $online/$devices';
  }

  @override
  String get bandixTitle => 'Bandix 流量与限速';

  @override
  String get bandixTrafficTitle => '流量明细';

  @override
  String get bandixUnavailable => '流量数据暂不可用（采集器未返回或上游暂不可用）。';

  @override
  String get bandixNotEnabled => 'bandix 流量监控未启用或未安装；可在网页端 bandix 设置页开启。';

  @override
  String get bandixOnlineDevices => '在线设备';

  @override
  String get bandixWanRate => 'WAN 速率';

  @override
  String get bandixDownload => '下行';

  @override
  String get bandixUpload => '上行';

  @override
  String get bandixDnsQueriesLabel => 'DNS 查询';

  @override
  String get connectionsLabel => '连接';

  @override
  String get notEnabled => '未启用';

  @override
  String get bandixLimitTitle => '默认限速';

  @override
  String get bandixLimitBody => '对未单独限速的设备生效；0 = 不限速。单位 KB/s。';

  @override
  String get bandixLimitRx => '下行限速（KB/s）';

  @override
  String get bandixLimitTx => '上行限速（KB/s）';

  @override
  String get bandixLimitsUnavailable => '未能读取当前配置（bridge 暂不可用）；保存仍会尝试。';

  @override
  String get bandixInvalidNumber => '请输入非负整数。';

  @override
  String get bandixWhitelistTitle => '限速白名单';

  @override
  String get bandixWhitelistBody => '白名单内设备不受限速；开关即时生效。';

  @override
  String get bandixWhitelistEnabled => '启用白名单';

  @override
  String get bandixAdd => '添加';

  @override
  String get bandixHostnameTitle => '主机名绑定';

  @override
  String get bandixHostnameBody => '为设备绑定显示名（留空 = 清除绑定）；生效可能有数秒延迟。';

  @override
  String get bandixHostnameField => '主机名';

  @override
  String get bandixHostnameHint => '如 living-room-tv';

  @override
  String get bandixMacRequired => '请先填写或选择设备 MAC。';

  @override
  String get bandixPanelNote =>
      '数据经 bridge 契约 quartz.bandix（与网页同源）；引擎参数（端口/网卡/数据目录）请在网页设置页修改。';

  @override
  String get bandixTopTitle => '设备流量 Top';

  @override
  String get bandixTopNote =>
      '速率 = 设备侧 WAN；累计 = 总流量；占比 = 累计份额；按累计降序（前 8 台）；策略 = 白名单/时段限速/配额。';

  @override
  String get bandixSummaryNote => '默认限速对未单独限速的设备生效；白名单豁免限速（完整规则见网页 Bandix 页）。';

  @override
  String get bandixDefaultLimitLabel => '默认限速';

  @override
  String get bandixWhitelistState => '白名单';

  @override
  String get bandixUnlimited => '不限';

  @override
  String get bandixOn => '开';

  @override
  String get bandixOff => '关';

  @override
  String bandixRulesCount(int n) {
    return '规则 $n';
  }

  @override
  String bandixQuotasCount(int n) {
    return '配额 $n';
  }

  @override
  String bandixWlDevicesCount(int n) {
    return '设备 $n';
  }

  @override
  String get bandixPolicyWhitelisted => '白名单';

  @override
  String bandixPolicyLimits(int n) {
    return '限速 $n';
  }

  @override
  String get bandixPolicyQuota => '配额';

  @override
  String get bandixPolicyDefault => '默认';

  @override
  String get bandixTotalLabel => '累计';

  @override
  String get navRouter => '路由器';

  @override
  String get navCellular => '蜂窝';

  @override
  String get cellularUnavailableBody => '蜂窝数据不可用：路由器未安装 QModem 或无模组。';

  @override
  String cellularMonthUsage(String size) {
    return '本月 $size';
  }

  @override
  String get cellularSignal => '信号';

  @override
  String get cellularSignalQuality => '信号质量';

  @override
  String get cellularSignalUnsupported => '本模组不支持信号指标';

  @override
  String get cellularQualityGood => '良';

  @override
  String get cellularQualityFair => '中';

  @override
  String get cellularQualityPoor => '弱';

  @override
  String get cellularRsrpHistory => 'RSRP 历史';

  @override
  String cellularSeriesHint(String step, String points) {
    return '${step}s/点 · $points 点';
  }

  @override
  String get cellularNetworkSim => '网络 · SIM';

  @override
  String get cellularServingCell => '服务小区';

  @override
  String get cellularSimLabel => 'SIM';

  @override
  String get cellularSimSlot => '槽位';

  @override
  String get cellularFirmware => '固件';

  @override
  String get cellularDial => '拨号';

  @override
  String get cellularDialConnected => '已连接';

  @override
  String get cellularDialDisconnected => '未连接';

  @override
  String get cellularDialNow => '拨号';

  @override
  String get cellularHang => '断开';

  @override
  String get cellularRedial => '重拨';

  @override
  String get cellularHangWarning => '断开会使模组的网络连接下线；若局域网走该模组，本机可能失联。';

  @override
  String get cellularRedialWarning => '重拨会短暂中断模组连接。';

  @override
  String get cellularEntryNetwork => '网络配置';

  @override
  String get cellularEntryAt => 'AT 调试';

  @override
  String get cellularEntryLog => '拨号日志';

  @override
  String get cellularMoreEntriesPlanned => 'SIM 切换 · 短信 · 高级 将在后续轮次补齐';

  @override
  String get cellularNetworkPrefer => '网络偏好';

  @override
  String get cellularNetworkPreferHint => '可多选；取消某档即禁止注册该制式（上游以数组接收）。';

  @override
  String get cellularApplyPrefer => '应用网络偏好';

  @override
  String get cellularLockband => '频段锁定';

  @override
  String get cellularLockbandUnlocked => '未锁定（使用全部可用频段）';

  @override
  String get cellularLockbandHint =>
      '频段锁定为厂商方言参数，锁定错误频段可能失联；v1 仅提供\"解除锁定\"，完整锁定请用网页端。';

  @override
  String get cellularLockbandUnlock => '解除锁定';

  @override
  String get cellularAdvanced => '高级';

  @override
  String get cellularUsbMode => 'USB 拨号模式';

  @override
  String get cellularTemp => '模组温度';

  @override
  String get cellularSettingsHint => '读取当前设置失败，可下拉刷新后重试。';

  @override
  String get cellularDangerWarning => '该操作会改写模组配置，可能导致连接中断。';

  @override
  String get cellularAtSend => '发送';

  @override
  String get cellularAtPresets => '预置命令';

  @override
  String get cellularAtWarningTitle => '命令面与网页端一致，风险自担';

  @override
  String get cellularAtWarningBody =>
      '预置命令与网页端同一份（路由器提供）；任意 AT 指令会真实下发到模组，误用可能改 NV/锁频段/致失联。发送前二次确认，全部动作记入审计。';

  @override
  String cellularAtConfirmTitle(String at) {
    return '发送 $at？';
  }

  @override
  String get clearAction => '清空';

  @override
  String get cellularLogHintTitle => '日志来自模组拨号脚本（尾部 100 行）';

  @override
  String get cellularLogHintBody => '内容可能包含运营商信息与号码，请勿随截图外发。';

  @override
  String get cellularLogEmpty => '（暂无日志）';

  @override
  String get model => '型号';

  @override
  String get deleteAction => '删除';

  @override
  String get cellularEntrySim => 'SIM 管理';

  @override
  String get cellularEntrySms => '短信';

  @override
  String get cellularSimNoSwitchTitle => '本模组不支持 SIM 切换';

  @override
  String get cellularSimNoSwitchBody =>
      '硬件/固件未提供 SIM 槽位切换能力（`supportSwitch=0`），此处只读展示。';

  @override
  String get cellularSimStatus => '状态';

  @override
  String get cellularSimSwitch => '切换 SIM 槽位';

  @override
  String get cellularSimSwitchApply => '应用切换';

  @override
  String cellularSimSwitchConfirm(String slot) {
    return '切换到 SIM $slot？';
  }

  @override
  String get cellularSimSwitchWarning => '切换会重启模组数据通道，期间网络中断。';

  @override
  String get cellularSmsStorage => '短信存储';

  @override
  String get cellularSmsPrivacyTitle => '短信内容只在本机内存';

  @override
  String get cellularSmsPrivacyBody => '不落盘、不上传；退出页面即清空。';

  @override
  String get cellularSmsEmpty => '（暂无短信）';

  @override
  String cellularSmsCount(String total, String unread) {
    return '$total 条 · $unread 未读';
  }

  @override
  String get cellularSmsSentTag => '已发';

  @override
  String get cellularSmsDeleteConfirm => '删除这条短信？';

  @override
  String get cellularSmsDeleteBody => '删除后无法恢复。';

  @override
  String get cellularSmsCompose => '写短信';

  @override
  String get cellularSmsRecipient => '收件号码';

  @override
  String get cellularSmsContent => '短信内容';

  @override
  String get cellularSmsSendAction => '发送';

  @override
  String get cellularModule => '模组';

  @override
  String get cellularUsbModeSection => 'USB 拨号模式';

  @override
  String get cellularUsbModeWarningTitle => '会重新枚举 USB 数据通道';

  @override
  String get cellularUsbModeWarningBody =>
      '模式（qmi/ecm/mbim/rndis/ncm）决定模组以何种形态提供数据口，切换会断开当前连接并重新枚举；与\"5G/4G 网络偏好\"无关。';

  @override
  String get cellularUsbModeApply => '应用 USB 模式';

  @override
  String get cellularReboot => '模组重启';

  @override
  String get cellularRebootSoft => '软重启（软复位模组）';

  @override
  String get cellularRebootHard => '硬重启（断电级复位）';

  @override
  String get cellularRebootUnsupported => '本模组未声明重启能力。';

  @override
  String get cellularRebootWarning => '重启会中断数据连接数十秒。';

  @override
  String get cellularImeiSection => 'IMEI（敏感）';

  @override
  String get cellularImeiWarningTitle => '更改 IMEI 有法律与合规风险';

  @override
  String get cellularImeiWarningBody =>
      '与网页端一致：我们不屏蔽该能力，风险由使用者自担；请确认当地法规允许后再操作，改动会记入审计。';

  @override
  String get cellularImeiInput => '新 IMEI（15 位）';

  @override
  String get cellularImeiApply => '写入 IMEI';

  @override
  String get cellularMaintenance => '统计与日志';

  @override
  String get cellularSaveStats => '保存统计到 NVM';

  @override
  String get cellularClearStats => '清零流量统计';

  @override
  String get cellularClearDialLog => '清空拨号日志';

  @override
  String cellularDisabledFeatures(String list) {
    return '本模组禁用特性：$list';
  }

  @override
  String get routerGroupNetwork => '网络';

  @override
  String get routerGroupSecurity => '安全';

  @override
  String get routerGroupSystem => '系统';

  @override
  String get routerGroupLan => '局域网';

  @override
  String get routerEntryInterfaces => '接口';

  @override
  String get routerEntryInterfacesSub => '管理 LAN/WAN 接口与协议';

  @override
  String get routerEntryWireless => '无线';

  @override
  String get routerEntryWirelessSub => '无线电与 SSID 配置';

  @override
  String get routerEntryDhcp => 'DHCP 与 DNS';

  @override
  String get routerEntryDhcpSub => '地址池、租期与 dnsmasq';

  @override
  String get routerEntryRoutes => '静态路由';

  @override
  String get routerEntryRoutesSub => '路由与规则';

  @override
  String get routerEntryFirewall => '防火墙';

  @override
  String get routerEntryFirewallSub => '区域、规则与端口转发';

  @override
  String get routerEntrySystem => '系统';

  @override
  String get routerEntrySystemSub => '主机名、时间与日志';

  @override
  String get routerEntryAdmin => '管理权';

  @override
  String get routerEntryAdminSub => '密码与 SSH';

  @override
  String get routerEntryInit => '启动项';

  @override
  String get routerEntryInitSub => '开机自启与服务控制';

  @override
  String routerEntryClientsSub(int n) {
    return '$n 台在线';
  }

  @override
  String get routerChipReady => '可用';

  @override
  String get routerChipSoon => '待后续版本';

  @override
  String get routerMoreHint => '更多路由器设置将在后续版本提供。';

  @override
  String get configSessionUnavailable => '配置会话不可用，请重新登录路由器以启用配置功能。';

  @override
  String get configForbidden => '该配置项未开放。';

  @override
  String configBadValue(String detail) {
    return '值不合法：$detail';
  }

  @override
  String configApplyFailed(String detail) {
    return '应用失败：$detail';
  }

  @override
  String get configWebPending => '网页端有未确认的更改，请先在网页端确认或回滚。';

  @override
  String get configNoChanges => '没有需要保存的更改。';

  @override
  String get configDirtyChip => '未保存';

  @override
  String get configSaving => '保存中…';

  @override
  String get configUnset => '未设置';

  @override
  String get configChoose => '选择';

  @override
  String get configSensitiveHint => '已设置，留空表示不修改';

  @override
  String get configSaved => '已保存并确认。';

  @override
  String get configRollbackDone => '已回滚。';

  @override
  String get configAutoRolledBack => '未确认，已自动回滚。';

  @override
  String get configDangerTitle => '确认更改';

  @override
  String get configDangerBody => '该更改可能中断本机与路由器的连接；未确认会在 90 秒后自动回滚。';

  @override
  String get configApplyTitle => '确认应用更改';

  @override
  String configApplyCountdown(int sec) {
    return '$sec 秒后自动回滚';
  }

  @override
  String get configApplyBody => '若修改了 IP 或无线设置，本机连接可能断开；路由器会在倒计时结束时自动回滚。';

  @override
  String get configRollbackNow => '立即回滚';

  @override
  String get configKeepChanges => '保留更改';

  @override
  String get configLoadFailedTitle => '读取配置失败';

  @override
  String get configSectionUnavailable => '该配置节不可用。';

  @override
  String get ipv6Label => 'IPv6';

  @override
  String get systemGeneral => '常规';

  @override
  String get systemHostname => '主机名';

  @override
  String get systemDescription => '描述';

  @override
  String get systemTimezone => '时区';

  @override
  String get systemTimezoneHint => '时间由路由器按所选时区解释。';

  @override
  String get systemTimezonePicker => '选择时区';

  @override
  String get systemTimezoneSearch => '搜索时区';

  @override
  String get systemLogging => '日志';

  @override
  String get systemLogSize => '日志大小（KB）';

  @override
  String get systemLogProto => '日志协议';

  @override
  String get systemLogIp => '远程日志地址';

  @override
  String get systemLogIpHint => '留空表示不发送远程日志';

  @override
  String get systemLogPort => '远程日志端口';

  @override
  String get systemAdvanced => '高级';

  @override
  String get systemConsoleLogLevel => '控制台日志级别';

  @override
  String get systemCronLogLevel => '计划任务日志级别';

  @override
  String get systemTtyLogin => '串口终端登录';

  @override
  String get initSearch => '搜索服务';

  @override
  String get initEmpty => '未找到启动项。';

  @override
  String initIndex(int n) {
    return '启动顺序 $n';
  }

  @override
  String initStopIndex(int n) {
    return '停止顺序 $n';
  }

  @override
  String get initEnabled => '已启用';

  @override
  String get initDisabled => '已禁用';

  @override
  String get initEnable => '启用';

  @override
  String get initDisable => '禁用';

  @override
  String get initStart => '启动';

  @override
  String get initStop => '停止';

  @override
  String get initRestart => '重启';

  @override
  String initActionDone(String action, String name) {
    return '已执行$action：$name';
  }

  @override
  String get initToggleWarning => '禁用该服务后，下次开机将不会自动启动。';

  @override
  String get initStopWarning => '停止或重启该服务可能中断路由器功能或本机连接。';

  @override
  String get interfaceProto => '协议';

  @override
  String get interfaceDevice => '设备';

  @override
  String get interfaceDisabled => '禁用';

  @override
  String get interfaceAuto => '开机自动启用';

  @override
  String get interfaceIpaddr => 'IP 地址';

  @override
  String get interfaceNetmask => '子网掩码';

  @override
  String get interfaceGateway => '网关';

  @override
  String get interfaceDns => 'DNS 服务器';

  @override
  String get interfaceDnsHint => '多个地址用空格分隔';

  @override
  String get interfaceIp6addr => 'IPv6 地址';

  @override
  String get interfaceIp6Hint => '可留空';

  @override
  String get interfaceIp6assign => 'IPv6 前缀长度';

  @override
  String get interfaceUsername => 'PPPoE 用户名';

  @override
  String get interfacePassword => 'PPPoE 密码';

  @override
  String get interfaceStatic => '静态地址';

  @override
  String get interfaceDhcpClient => 'DHCP 客户端';

  @override
  String get interfaceNone => '无';

  @override
  String get interfacePppoe => 'PPPoE';

  @override
  String get wirelessEmpty => '未检测到无线设备（或无线未启用）。';

  @override
  String get wirelessIface => '无线接口';

  @override
  String get wirelessDevice => '无线电';

  @override
  String get wirelessMode => '模式';

  @override
  String get wirelessEncryption => '加密';

  @override
  String get wirelessBand => '频段';

  @override
  String get wirelessChannel => '信道';

  @override
  String get wirelessSsid => 'SSID';

  @override
  String get wirelessKey => '密码';

  @override
  String get wirelessNetwork => '绑定网络';

  @override
  String get wirelessHidden => '隐藏 SSID';

  @override
  String get wirelessIsolate => '客户端隔离';

  @override
  String get wirelessWmm => 'WMM';

  @override
  String get wirelessHtmode => '频宽模式';

  @override
  String get wirelessTxpower => '发射功率（dBm）';

  @override
  String get wirelessCountry => '国家代码';

  @override
  String get wirelessCellDensity => '小区密度';

  @override
  String get wirelessDistance => '距离（米）';

  @override
  String get dhcpEmpty => '未检测到 DHCP 配置。';

  @override
  String get dhcpDnsmasq => 'DNS 与 DHCP（dnsmasq）';

  @override
  String get dhcpServer => 'DHCP 服务器';

  @override
  String get dhcpServerHint => '地址池与租期';

  @override
  String get dhcpDomain => '域名';

  @override
  String get dhcpLocal => '本地域';

  @override
  String get dhcpDomainNeeded => '强制本地域名';

  @override
  String get dhcpBogusPriv => '过滤私有域';

  @override
  String get dhcpAuthoritative => '权威模式';

  @override
  String get dhcpLocalService => '仅本地服务';

  @override
  String get dhcpRebindProtection => '重绑定保护';

  @override
  String get dhcpExpandHosts => '展开主机名';

  @override
  String get dhcpCacheSize => '缓存大小';

  @override
  String get dhcpLogQueries => '记录查询';

  @override
  String get dhcpStart => '起始地址（末段）';

  @override
  String get dhcpLimit => '地址池大小';

  @override
  String get dhcpLeasetime => '租期';

  @override
  String get dhcpIgnore => '禁用 DHCP';

  @override
  String get dhcpDynamicDhcp => '动态 DHCP';

  @override
  String get dhcpForce => '强制';

  @override
  String get dhcpRa => 'IPv6 RA';

  @override
  String get dhcpRaManagement => 'RA 管理级别';

  @override
  String get dhcpDhcpv6 => 'DHCPv6';

  @override
  String get dhcpMaster => '主服务器';

  @override
  String get dhcpDnsService => '通告 DNS';

  @override
  String get dhcpStaticLeases => '静态租约';

  @override
  String get dhcpAddLease => '添加静态租约';

  @override
  String get dhcpLeaseName => '名称';

  @override
  String get dhcpLeaseMac => 'MAC 地址';

  @override
  String get dhcpLeaseIp => 'IP 地址';

  @override
  String get dhcpNoLeases => '暂无静态租约';

  @override
  String get dhcpDeleteLease => '删除静态租约';

  @override
  String get dhcpDeleteLeaseBody => '删除后 DHCP 将按动态地址分配。';

  @override
  String get dhcpLeaseHint => '名称/静态 IP 可留空；MAC 必填。';

  @override
  String get dhcpLeaseInvalidMac => 'MAC 地址格式无效';
}
