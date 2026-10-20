// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuartzWrt';

  @override
  String get navOverview => 'Overview';

  @override
  String get navNetwork => 'Network';

  @override
  String get navApps => 'Apps';

  @override
  String get navSettings => 'Settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading…';

  @override
  String get unknownValue => '—';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get notInstalled => 'Not installed';

  @override
  String get running => 'Running';

  @override
  String get stopped2 => 'Stopped';

  @override
  String get actionDone => 'Done';

  @override
  String actionFailed(String detail) {
    return 'Action failed: $detail';
  }

  @override
  String get discoverTitle => 'Connect a router';

  @override
  String get discoverScanning => 'Scanning local network (mDNS)…';

  @override
  String get discoverNone =>
      'No other devices found — make sure your phone is on the same network.';

  @override
  String get addByAddress => 'Add by address…';

  @override
  String get addByAddressTitle => 'Add router by address';

  @override
  String get hostLabel => 'Address';

  @override
  String get portLabel => 'Port';

  @override
  String get badgeVerifiable => 'Fingerprint verifiable';

  @override
  String get badgeUnverified => 'Fingerprint unverified';

  @override
  String get noTabAfterPair => 'Main screen appears after pairing';

  @override
  String pairTitle(String name) {
    return 'Connect to $name';
  }

  @override
  String get certFingerprint => 'Certificate fingerprint (SHA-256)';

  @override
  String get firmwareLabel => 'Firmware';

  @override
  String get routerPassword => 'Router admin password';

  @override
  String get routerPasswordHint =>
      'Used once to pair; the app then signs in with a revocable token.';

  @override
  String get pairButton => 'Pair';

  @override
  String get pairing => 'Pairing…';

  @override
  String get errInvalidCredentials => 'Wrong password';

  @override
  String errRateLimited(int sec) {
    return 'Too many attempts, retry in ${sec}s';
  }

  @override
  String get errPasswordNotSet =>
      'Set the router admin password first (LuCI → System → Administration).';

  @override
  String get errFingerprintMismatch =>
      'Router identity changed — pairing blocked.';

  @override
  String get errConnect => 'Cannot reach the router.';

  @override
  String get errBadCert => 'Certificate check failed.';

  @override
  String get errTimeout => 'Connection timed out.';

  @override
  String get overviewTitle => 'Overview';

  @override
  String get connectedLan => 'Connected · LAN';

  @override
  String get connectedRemote => 'Connected · Remote';

  @override
  String runFor(int d, int h, String m) {
    return 'Up $d days $h:$m';
  }

  @override
  String runForShort(int h, String m) {
    return 'Up $h:$m';
  }

  @override
  String get systemCardTitle => 'System';

  @override
  String get cpuLabel => 'CPU';

  @override
  String get memLabel => 'Memory';

  @override
  String get storageLabel => 'Storage';

  @override
  String get tempLabel => 'Temperature';

  @override
  String get loadLabel => 'Load';

  @override
  String get tempUnavailable => 'Unavailable (no sensor)';

  @override
  String get networkCardTitle => 'Network · WAN';

  @override
  String get clientsCardTitle => 'Clients';

  @override
  String get appsCardTitle => 'Apps';

  @override
  String get dockerCardTitle => 'Docker';

  @override
  String get dockerRunning => 'Running containers';

  @override
  String get dockerImages => 'Images';

  @override
  String get dockerUnhealthy => 'Unhealthy';

  @override
  String get bannerCollectorDown => 'Collector not running';

  @override
  String get bannerCollectorDownBody =>
      'Router data service unavailable (quartz-daemon not running or starting). It refreshes automatically.';

  @override
  String get bannerConnectionLost => 'Connection lost';

  @override
  String get bannerConnectionLostBody =>
      'Showing the last known data. Retrying automatically.';

  @override
  String get bannerNeedRepair => 'Pairing revoked or expired';

  @override
  String get bannerNeedRepairBody => 'Re-pair this router to continue.';

  @override
  String otherClientsCount(int n) {
    return '+$n more';
  }

  @override
  String get networkTitle => 'Network';

  @override
  String get wanNetworkCardTitle => 'WAN · Network';

  @override
  String get wanDown => 'Offline';

  @override
  String get wirelessCardTitle => 'Wireless';

  @override
  String get noiseLabel => 'Noise';

  @override
  String clientsOnlineHeader(int n) {
    return '$n online';
  }

  @override
  String allClientsEntry(int n) {
    return 'All clients ($n)';
  }

  @override
  String get clientsPageTitle => 'Clients';

  @override
  String get clientsEmpty => 'No clients online.';

  @override
  String get networkServicesTitle => 'Network services';

  @override
  String get dnsServiceLabel => 'DNS (dnsmasq)';

  @override
  String get wanReconnectPlanned => 'Planned';

  @override
  String get lastSeenNow => 'just now';

  @override
  String lastSeenMin(int n) {
    return '$n min ago';
  }

  @override
  String lastSeenHour(int n) {
    return '$n h ago';
  }

  @override
  String lastSeenDay(int n) {
    return '$n d ago';
  }

  @override
  String get appsTitle => 'Apps';

  @override
  String get segApps => 'Apps';

  @override
  String get segPackages => 'Packages';

  @override
  String get appsControllableIntro =>
      'Installed apps with in-app control; tap for details.';

  @override
  String get appsNone => 'No controllable apps installed.';

  @override
  String get appsNotInstalledTitle => 'Not installed';

  @override
  String get appsNotInstalledBody =>
      'Docker, Tailscale and others appear here automatically once installed.';

  @override
  String get appDetailStatusTitle => 'Status';

  @override
  String get appDetailStatusRunning => 'Running';

  @override
  String get coreLabel => 'Core';

  @override
  String get statusSourceLabel => 'Status source';

  @override
  String get statusSourceProbe => 'Router probe (no rebuild)';

  @override
  String get actionsTitle => 'Actions';

  @override
  String get actionsNote =>
      'Actions follow router capability registry (WP-5 allowlist / WP-8 bridge).';

  @override
  String get actionRestart => 'Restart service';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionStart => 'Start';

  @override
  String get packageCardTitle => 'Package';

  @override
  String get packageVersion => 'Version';

  @override
  String get packageSource => 'Source';

  @override
  String get packageSize => 'Installed size';

  @override
  String get packageRemove => 'Remove…';

  @override
  String get packagesApiMissingTitle => 'Package management not available';

  @override
  String get packagesApiMissingBody =>
      'The router API has no package support yet (requires quartz-app-api update). Installed/upgrade list will appear here automatically.';

  @override
  String upgradableHeader(int n) {
    return 'Upgradable · $n';
  }

  @override
  String upgradeAllBtn(int n) {
    return 'Upgrade all ($n)';
  }

  @override
  String installedHeader(int n) {
    return 'Installed · $n';
  }

  @override
  String allPackagesEntry(int n) {
    return 'All packages ($n) · search';
  }

  @override
  String get installNewTitle => 'Install a new package';

  @override
  String get installNewBody =>
      'Browsing and installing new packages is planned (v1 focuses on installed/upgrade/records).';

  @override
  String get opLogEntry => 'Records';

  @override
  String get opLogTitle => 'Operation records';

  @override
  String get opLogEmpty => 'No recent operations.';

  @override
  String get opLogRetain =>
      'Only the latest 30 operations are kept (upgrade / remove / update lists).';

  @override
  String get opReindex => 'Software index refreshed';

  @override
  String opUpgradeAll(int n) {
    return 'Upgraded packages ($n)';
  }

  @override
  String opUpgrade(String name) {
    return 'Upgrade $name';
  }

  @override
  String opRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get opResultOk => 'Success';

  @override
  String get opResultFail => 'Failed';

  @override
  String get opResultPartial => 'Partial';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sysSettingsGroup => 'System settings · Router';

  @override
  String get appSettingsGroup => 'App settings · This phone';

  @override
  String get pairedLan => 'Paired · LAN';

  @override
  String get pairedRemote => 'Paired · Remote';

  @override
  String get fingerprintLabel => 'Certificate fingerprint';

  @override
  String get pairedDevicesEntry => 'Paired devices';

  @override
  String get addRouterEntry => 'Add a router';

  @override
  String get deviceControlTitle => 'Device control';

  @override
  String get rebootRouter => 'Reboot router';

  @override
  String get restartService => 'Restart service…';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get followSystem => 'System';

  @override
  String get modeDark => 'Dark';

  @override
  String get modeLight => 'Light';

  @override
  String get languageTitle => 'Language';

  @override
  String get aboutTitle => 'About';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get apiLabel => 'API';

  @override
  String get devicesPageTitle => 'Paired devices';

  @override
  String get devicesCurrentBadge => 'this phone';

  @override
  String get devicesRevokedBadge => 'revoked';

  @override
  String get revokeBtn => 'Revoke';

  @override
  String get revokeConfirmTitle => 'Revoke this device?';

  @override
  String get revokeConfirmBody =>
      'The device must pair again to regain access.';

  @override
  String get rebootConfirmTitle => 'Reboot router?';

  @override
  String rebootConfirmBody(String name) {
    return '$name will reboot now. Network drops for about 1–2 minutes; the app reconnects automatically.';
  }

  @override
  String get removeRouterTitle => 'Remove this router from the app?';

  @override
  String get removeRouterBody =>
      'Also revoke this phone on the router (recommended).';

  @override
  String get removeRouterBtn => 'Remove';

  @override
  String get kernelLabel => 'kernel';

  @override
  String get rePair => 'Re-pair';

  @override
  String get collectorErrors => 'Collector messages';

  @override
  String get remoteEntry => 'Remote access';

  @override
  String get remotePageTitle => 'Remote access';

  @override
  String get remoteRouterStatusTitle => 'Router · Tailscale';

  @override
  String get remoteTsIpLabel => 'Tailscale address';

  @override
  String get remoteUseThisAddr => 'Add remote access with this address';

  @override
  String get remoteNotDetected =>
      'Tailscale not detected — install and enable it from the router\'s Apps page.';

  @override
  String get remoteStepsTitle => 'Setup steps';

  @override
  String get remoteStep1 =>
      'Install and enable Tailscale on the router (Apps → Tailscale).';

  @override
  String get remoteStep2 =>
      'Sign in to your tailnet on the router\'s Tailscale page.';

  @override
  String get remoteStep3 =>
      'Install the Tailscale client on your phone and sign in to the same tailnet.';

  @override
  String get remoteStep4 =>
      'Add the tailnet address here (100.x.y.z or a MagicDNS name); the certificate pin is reused from the LAN pairing.';

  @override
  String get remoteAddrTitle => 'Remote address';

  @override
  String get remoteAddrNone =>
      'Not set — direct LAN connection at home; add a tailnet address here to manage the router from anywhere.';

  @override
  String get remoteAddBtn => 'Add remote address…';

  @override
  String get remoteEditBtn => 'Edit';

  @override
  String get remoteTestBtn => 'Test';

  @override
  String get remoteInUse => 'In use';

  @override
  String get remoteHostLabel => 'Address (100.x.y.z or hostname)';

  @override
  String get remoteTestSave => 'Test & save';

  @override
  String get remoteTesting => 'Testing…';

  @override
  String get remoteTestOk => 'Remote connection works — saved.';

  @override
  String remoteTestFail(String detail) {
    return 'Connection failed: $detail';
  }

  @override
  String get remoteHostRequired => 'Please enter an address.';

  @override
  String get remoteRemoveBtn => 'Remove remote address';

  @override
  String get remoteRemoveShort => 'Remove';

  @override
  String get remoteRemoveTitle => 'Remove remote address?';

  @override
  String get remoteRemoveBody =>
      'The app will connect over LAN only; pairing and tokens are unaffected.';

  @override
  String get remoteRemoved => 'Remote address removed.';

  @override
  String get remoteAutoTitle => 'Automatic switching';

  @override
  String get remoteAutoBody =>
      'LAN is preferred on the same network; on failure the app falls back to the remote address and switches back once LAN is reachable again.';

  @override
  String get remoteSecurityTitle => 'Security';

  @override
  String get remoteSecurityBody =>
      'Remote connections use the same certificate pinning as LAN (MITM-resistant). Rebooting or disconnecting the router remotely may briefly drop the connection; the router recovers on its own. Removing the remote address never affects the LAN pairing.';

  @override
  String get embedTitle => 'Embedded direct (experimental)';

  @override
  String get embedBody =>
      'Runs a tailnet node inside the app: reach the router over your tailnet without installing the Tailscale client on this phone. Enabling creates a device in your tailnet (login required); disabling falls back to the regular direct connection.';

  @override
  String get embedUnavailable =>
      'This build does not include the embedded engine (release builds do).';

  @override
  String get embedEnable => 'Enable embedded direct';

  @override
  String get embedStateLabel => 'Status';

  @override
  String get embedPhaseStarting => 'Starting…';

  @override
  String get embedPhaseNeedsLogin => 'Waiting for login';

  @override
  String get embedPhaseRunning => 'Connected';

  @override
  String get embedPhaseStopped => 'Off';

  @override
  String get embedPhaseError => 'Error';

  @override
  String get embedSelfIpLabel => 'This device tailnet address';

  @override
  String get embedLoginBtn => 'Sign in to Tailscale';

  @override
  String get embedLoginHint =>
      'After signing in, this device joins your tailnet and remote addresses prefer the embedded node automatically.';

  @override
  String get embedCopyBtn => 'Copy link';

  @override
  String get embedCopied => 'Copied';

  @override
  String get embedErrorDetail => 'Error detail';

  @override
  String get pkgViewUpgradable => 'Upgradable';

  @override
  String pkgViewUpgradableN(int n) {
    return 'Upgradable ($n)';
  }

  @override
  String get pkgViewInstalled => 'Installed';

  @override
  String get pkgViewAll => 'All';

  @override
  String get pkgSearchHint => 'Search packages (by name)';

  @override
  String get pkgSearchPrompt =>
      'Type a name to search packages. Installed / Upgradable live in the other two tabs.';

  @override
  String get pkgSearchNone => 'No matching packages.';

  @override
  String get pkgEmptyUpgradable => 'All packages are up to date.';

  @override
  String get pkgEmptyInstalled => 'No installed packages found.';

  @override
  String pkgRefreshDone(int s) {
    return 'Package lists updated (${s}s)';
  }

  @override
  String get pkgUpgrade => 'Upgrade';

  @override
  String pkgUpgradeTo(String version) {
    return 'Upgrade to $version';
  }

  @override
  String pkgUpgraded(String name) {
    return 'Upgraded $name';
  }

  @override
  String get pkgRemove => 'Remove';

  @override
  String pkgRemoved(String name) {
    return 'Removed $name';
  }

  @override
  String pkgRemoveConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get pkgRemoveConfirmBody =>
      'Removes the package from the router. Dependent components may break and related services stop. This cannot be undone.';

  @override
  String get pkgUpgradeAllConfirmTitle => 'Upgrade all?';

  @override
  String pkgUpgradeAllConfirmBody(int n) {
    return 'Upgrades all upgradable packages ($n). Related services may restart and network is used; do not power off.';
  }

  @override
  String get pkgBadgeInstalled => 'Installed';

  @override
  String get pkgBadgeUpgrade => 'Upgrade';

  @override
  String pkgLoadMore(int shown, int total) {
    return 'Load more ($shown/$total)';
  }

  @override
  String pkgShownOf(int shown, int total) {
    return 'Showing $shown/$total';
  }

  @override
  String get pkgCardName => 'Name';

  @override
  String pkgCardUpgradeTo(String version) {
    return 'Upgrade available: $version';
  }

  @override
  String get pkgCardNotInstalled =>
      'This app is not installed as a package (or the name differs). Search in the Packages tab to confirm.';

  @override
  String opLogMeta(String status, String dur) {
    return '$status · $dur';
  }

  @override
  String get save => 'Save';

  @override
  String bandixRowOnline(int online, int devices) {
    return 'Online $online/$devices';
  }

  @override
  String get bandixTitle => 'Bandix traffic & limits';

  @override
  String get bandixTrafficTitle => 'Traffic detail';

  @override
  String get bandixUnavailable =>
      'Traffic data unavailable (collector did not return it or upstream is down).';

  @override
  String get bandixNotEnabled =>
      'Bandix traffic monitoring is not enabled or not installed — enable it on the web settings page.';

  @override
  String get bandixOnlineDevices => 'Online devices';

  @override
  String get bandixWanRate => 'WAN rate';

  @override
  String get bandixDownload => 'Download';

  @override
  String get bandixUpload => 'Upload';

  @override
  String get bandixDnsQueriesLabel => 'DNS queries';

  @override
  String get connectionsLabel => 'Connections';

  @override
  String get notEnabled => 'Not enabled';

  @override
  String get ipClickToReveal => 'Click to reveal';

  @override
  String get ipClickToHide => 'Click to hide';

  @override
  String get bandixLimitTitle => 'Default rate limit';

  @override
  String get bandixLimitBody =>
      'Applies to devices without an individual limit; 0 = unlimited. Unit: KB/s.';

  @override
  String get bandixLimitRx => 'Download limit (KB/s)';

  @override
  String get bandixLimitTx => 'Upload limit (KB/s)';

  @override
  String get bandixLimitsUnavailable =>
      'Could not read current config (bridge unavailable); saving will still be attempted.';

  @override
  String get bandixInvalidNumber => 'Enter a non-negative integer.';

  @override
  String get bandixWhitelistTitle => 'Rate-limit whitelist';

  @override
  String get bandixWhitelistBody =>
      'Whitelisted devices are not rate-limited; the switch applies immediately.';

  @override
  String get bandixWhitelistEnabled => 'Enable whitelist';

  @override
  String get bandixAdd => 'Add';

  @override
  String get bandixHostnameTitle => 'Hostname binding';

  @override
  String get bandixHostnameBody =>
      'Bind a display name to a device (leave empty to clear); it may take a few seconds to apply.';

  @override
  String get bandixHostnameField => 'Hostname';

  @override
  String get bandixHostnameHint => 'e.g. living-room-tv';

  @override
  String get bandixMacRequired => 'Enter or pick a device MAC first.';

  @override
  String get bandixPanelNote =>
      'Data comes from the bridge contract quartz.bandix (same source as the web UI); engine params (port/interface/data dir) stay on the web settings page.';

  @override
  String get bandixTopTitle => 'Top devices by traffic';

  @override
  String get bandixTopNote =>
      'Rate = device-side WAN; Total = all traffic; share = cumulative; sorted by total (top 8); policy = whitelist/schedule/quota.';

  @override
  String get bandixSummaryNote =>
      'The default rate limit applies to devices without an individual limit; whitelisted devices are exempt (full rules on the web Bandix page).';

  @override
  String get bandixDefaultLimitLabel => 'Default rate limit';

  @override
  String get bandixWhitelistState => 'Whitelist';

  @override
  String get bandixUnlimited => 'unlimited';

  @override
  String get bandixOn => 'On';

  @override
  String get bandixOff => 'Off';

  @override
  String bandixRulesCount(int n) {
    return 'rules $n';
  }

  @override
  String bandixQuotasCount(int n) {
    return 'quotas $n';
  }

  @override
  String bandixWlDevicesCount(int n) {
    return 'devices $n';
  }

  @override
  String get bandixPolicyWhitelisted => 'Whitelisted';

  @override
  String bandixPolicyLimits(int n) {
    return 'Limits $n';
  }

  @override
  String get bandixPolicyQuota => 'Quota';

  @override
  String get bandixPolicyDefault => 'Default';

  @override
  String get bandixTotalLabel => 'Total';

  @override
  String get navRouter => 'Router';

  @override
  String get navCellular => 'Cellular';

  @override
  String get cellularUnavailableBody =>
      'Cellular data unavailable: QModem is not installed or no modem is present.';

  @override
  String cellularMonthUsage(String size) {
    return 'This month $size';
  }

  @override
  String get cellularSignal => 'Signal';

  @override
  String get cellularSignalQuality => 'Signal quality';

  @override
  String get cellularSignalUnsupported =>
      'Signal metrics not supported by this modem';

  @override
  String get cellularQualityGood => 'Good';

  @override
  String get cellularQualityFair => 'Fair';

  @override
  String get cellularQualityPoor => 'Weak';

  @override
  String get cellularRsrpHistory => 'RSRP history';

  @override
  String cellularSeriesHint(String step, String points) {
    return 'every ${step}s · $points points';
  }

  @override
  String get cellularOperatorChinaMobile => 'China Mobile';

  @override
  String get cellularOperatorChinaUnicom => 'China Unicom';

  @override
  String get cellularOperatorChinaTelecom => 'China Telecom';

  @override
  String get cellularNoResetPlan => 'No reset plan';

  @override
  String cellularResetMonthly(int day, String time) {
    return 'Monthly $day · $time';
  }

  @override
  String cellularResetWeekly(String time) {
    return 'Weekly · $time';
  }

  @override
  String cellularResetDaily(String time) {
    return 'Daily · $time';
  }

  @override
  String get tcpLabel => 'TCP';

  @override
  String get udpLabel => 'UDP';

  @override
  String get cellularNetworkSim => 'Network · SIM';

  @override
  String get cellularServingCell => 'Serving cell';

  @override
  String get cellularRadioSection => 'Radio';

  @override
  String get cellularCellSimSection => 'Cell & SIM';

  @override
  String get cellularConnectionSection => 'Connection';

  @override
  String get cellularHardwareSection => 'Hardware';

  @override
  String get cellularBandLabel => 'Band';

  @override
  String get cellularArfcnLabel => 'ARFCN';

  @override
  String get cellularPciLabel => 'PCI';

  @override
  String get cellularBwLabel => 'UL / DL BW';

  @override
  String get cellularScsLabel => 'SCS';

  @override
  String get cellularDuplexLabel => 'Duplex';

  @override
  String get cellularMccMncLabel => 'MCC / MNC';

  @override
  String get cellularTacLabel => 'TAC';

  @override
  String get cellularCellIdLabel => 'Cell ID';

  @override
  String get cellularSimStatusLabel => 'SIM status';

  @override
  String get cellularSimSlotLabel => 'SIM slot';

  @override
  String get cellularSwitchableLabel => 'Switchable';

  @override
  String get cellularCqiLabel => 'CQI UL / DL';

  @override
  String get cellularAmbrLabel => 'AMBR UL / DL';

  @override
  String get cellularPreferenceLabel => 'Preference';

  @override
  String get cellularManufacturerLabel => 'Manufacturer';

  @override
  String get cellularRevisionLabel => 'Revision';

  @override
  String get cellularVoltageLabel => 'Voltage';

  @override
  String get cellularConnectStatusLabel => 'Connect status';

  @override
  String get simStatusReady => 'Ready';

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get unlockedLabel => 'Unlocked';

  @override
  String get lockedLabel => 'Locked';

  @override
  String get cellularNeighborIntra => 'Intra-frequency';

  @override
  String get cellularNeighborInter => 'Inter-frequency';

  @override
  String get cellularSimLabel => 'SIM';

  @override
  String get cellularSimSlot => 'slot';

  @override
  String get cellularFirmware => 'Firmware';

  @override
  String get cellularDial => 'Dial-up';

  @override
  String get cellularDialConnected => 'Connected';

  @override
  String get cellularDialDisconnected => 'Disconnected';

  @override
  String get cellularDialNow => 'Connect';

  @override
  String get cellularHang => 'Disconnect';

  @override
  String get cellularRedial => 'Reconnect';

  @override
  String get cellularHangWarning =>
      'Disconnecting takes the modem offline; if your LAN routes through it, this device may lose connectivity.';

  @override
  String get cellularRedialWarning =>
      'Reconnecting briefly interrupts the modem link.';

  @override
  String get cellularEntryNetwork => 'Network';

  @override
  String get cellularEntryAt => 'AT debug';

  @override
  String get cellularEntryLog => 'Dial log';

  @override
  String get cellularGroupDial => 'Dial';

  @override
  String get cellularGroupAdvanced => 'Advanced modem settings';

  @override
  String get cellularGroupMessages => 'SMS & SIM';

  @override
  String get cellularEntryNetworkSub => 'Network preference and band lock';

  @override
  String get cellularEntryNeighbor => 'Neighbor cells';

  @override
  String get cellularEntryNeighborSub => 'LTE / NR measurements (read-only)';

  @override
  String get cellularEntryAtSub => 'Port, presets and response history';

  @override
  String get cellularEntryMaintenance => 'Modem maintenance';

  @override
  String get cellularEntryMaintenanceSub => 'Dial mode, IMEI, reboot, counters';

  @override
  String get cellularEntryLogSub => 'Dial and link events';

  @override
  String get cellularEntrySmsSub => 'Messages, storage and sync';

  @override
  String get cellularEntrySimSub => 'SIM state and slot switch';

  @override
  String get cellularNeighborReadonly =>
      'Cell locking stays in the web UI; the app only shows neighbor measurements.';

  @override
  String get cellularNeighborEmpty =>
      'No neighbor cells reported (unsupported by the modem or none visible).';

  @override
  String get cellularNeighborLte => 'LTE neighbors';

  @override
  String get cellularNeighborNr => 'NR neighbors';

  @override
  String get cellularNeighborLock => 'Cell lock state';

  @override
  String get cellularRetryHint => 'Refresh or try again later.';

  @override
  String get cellularStatsResetTitle => 'Traffic reset schedule';

  @override
  String get cellularStatsResetHint =>
      'Clears traffic counters on schedule (monthly uses day 1–28).';

  @override
  String get cellularStatsResetEnable => 'Enable automatic reset';

  @override
  String get cellularStatsResetType => 'Reset cycle';

  @override
  String get cellularStatsDaily => 'Daily';

  @override
  String get cellularStatsMonthly => 'Monthly';

  @override
  String get cellularStatsHour => 'Reset hour';

  @override
  String get cellularStatsDay => 'Reset day';

  @override
  String get cellularStatsApply => 'Save reset schedule';

  @override
  String get cellularStatsSaved => 'Reset schedule saved';

  @override
  String get cellularAtPort => 'AT port';

  @override
  String cellularAtPortInvalid(String port) {
    return '$port (invalid)';
  }

  @override
  String cellularAtPortOther(String port) {
    return '$port (not this modem)';
  }

  @override
  String get cellularAtOutput => 'Output';

  @override
  String get cellularAtOutputEmpty =>
      'Commands and responses accumulate here after you send an AT command.';

  @override
  String get cellularAtClearOutput => 'Clear output';

  @override
  String get cellularAtNoPorts => 'No AT ports found';

  @override
  String get cellularAtSelectPort => 'Select AT port';

  @override
  String get cellularAtInvalidPortWarning =>
      'This port is invalid or does not belong to this modem; sending is disabled.';

  @override
  String get cellularMoreEntriesPlanned =>
      'SIM switch · SMS · Advanced are planned for later rounds';

  @override
  String get cellularNetworkPrefer => 'Network preference';

  @override
  String get cellularNetworkPreferHint =>
      'Multiple choices allowed; disabling a RAT forbids registering it (sent as an array).';

  @override
  String get cellularApplyPrefer => 'Apply preference';

  @override
  String get cellularLockband => 'Band lock';

  @override
  String get cellularLockbandUnlocked => 'Not locked (all bands available)';

  @override
  String get cellularLockbandHint =>
      'Band lock uses vendor-specific parameters; locking a wrong band can drop the link. v1 only offers \"unlock\" — use the web UI for full locking.';

  @override
  String get cellularLockbandUnlock => 'Unlock bands';

  @override
  String get cellularAdvanced => 'Advanced';

  @override
  String get cellularUsbMode => 'USB dial mode';

  @override
  String get cellularUsbSpeed => 'USB speed';

  @override
  String get cellularTemp => 'Modem temperature';

  @override
  String get cellularSettingsHint =>
      'Failed to read current settings; pull to refresh and retry.';

  @override
  String get cellularDangerWarning =>
      'This rewrites modem configuration and may interrupt connectivity.';

  @override
  String get cellularAtSend => 'Send';

  @override
  String get cellularAtPresets => 'Quick commands';

  @override
  String get cellularAtWarningTitle =>
      'Same command surface as the web UI; use at your own risk';

  @override
  String get cellularAtWarningBody =>
      'Quick commands come from the router (same source as the web UI). Any AT command is sent to the modem for real and can modify NV items, lock bands, or drop the link. Each send is confirmed and audited.';

  @override
  String cellularAtConfirmTitle(String at) {
    return 'Send $at?';
  }

  @override
  String get clearAction => 'Clear';

  @override
  String get cellularLogHintTitle =>
      'Log comes from the modem dial script (last 100 lines)';

  @override
  String get cellularLogHintBody =>
      'May contain carrier details and phone numbers; avoid sharing screenshots.';

  @override
  String get cellularLogEmpty => '(no log yet)';

  @override
  String get model => 'Model';

  @override
  String get deleteAction => 'Delete';

  @override
  String get cellularEntrySim => 'SIM';

  @override
  String get cellularEntrySms => 'SMS';

  @override
  String get cellularSimNoSwitchTitle =>
      'SIM switching is not supported by this modem';

  @override
  String get cellularSimNoSwitchBody =>
      'The modem does not expose SIM slot switching (`supportSwitch=0`); read-only.';

  @override
  String get cellularSimStatus => 'Status';

  @override
  String get cellularSimSwitch => 'Switch SIM slot';

  @override
  String get cellularSimSwitchApply => 'Apply switch';

  @override
  String cellularSimSwitchConfirm(String slot) {
    return 'Switch to SIM $slot?';
  }

  @override
  String get cellularSimSwitchWarning =>
      'Switching restarts the modem data path; the network drops during the switch.';

  @override
  String get cellularSmsStorage => 'SMS storage';

  @override
  String get cellularSmsPrivacyTitle => 'Messages stay in device memory only';

  @override
  String get cellularSmsPrivacyBody =>
      'Not persisted or uploaded; cleared when you leave the page.';

  @override
  String get cellularSmsEmpty => '(no messages)';

  @override
  String cellularSmsCount(String total, String unread) {
    return '$total messages · $unread unread';
  }

  @override
  String get cellularSmsSentTag => 'sent';

  @override
  String get cellularSmsDeleteConfirm => 'Delete this message?';

  @override
  String get cellularSmsDeleteBody => 'This cannot be undone.';

  @override
  String get cellularSmsCompose => 'New message';

  @override
  String get cellularSmsRecipient => 'Recipient';

  @override
  String get cellularSmsContent => 'Message';

  @override
  String get cellularSmsSendAction => 'Send';

  @override
  String get cellularModule => 'Modem';

  @override
  String get cellularUsbModeSection => 'USB dial mode';

  @override
  String get cellularUsbModeWarningTitle => 'Re-enumerates the USB data path';

  @override
  String get cellularUsbModeWarningBody =>
      'The mode (qmi/ecm/mbim/rndis/ncm) decides how the modem exposes its data port; switching drops the current link and re-enumerates. Unrelated to 5G/4G network preference.';

  @override
  String get cellularUsbModeApply => 'Apply USB mode';

  @override
  String get cellularReboot => 'Modem reboot';

  @override
  String get cellularRebootSoft => 'Soft reboot';

  @override
  String get cellularRebootHard => 'Hard reboot';

  @override
  String get cellularRebootUnsupported =>
      'This modem declares no reboot capability.';

  @override
  String get cellularRebootWarning =>
      'Rebooting interrupts the data link for tens of seconds.';

  @override
  String get cellularImeiSection => 'IMEI (sensitive)';

  @override
  String get cellularImeiWarningTitle =>
      'Changing IMEI carries legal and compliance risk';

  @override
  String get cellularImeiWarningBody =>
      'Same as the web UI: the capability is not blocked; the risk is yours. Verify local regulations first — the change is audited.';

  @override
  String get cellularImeiInput => 'New IMEI (15 digits)';

  @override
  String get cellularImeiApply => 'Write IMEI';

  @override
  String get cellularMaintenance => 'Statistics & logs';

  @override
  String get cellularSaveStats => 'Save stats to NVM';

  @override
  String get cellularClearStats => 'Clear traffic stats';

  @override
  String get cellularClearDialLog => 'Clear dial log';

  @override
  String cellularDisabledFeatures(String list) {
    return 'Disabled features: $list';
  }

  @override
  String get routerGroupNetwork => 'Network';

  @override
  String get routerGroupSecurity => 'Security';

  @override
  String get routerGroupSystem => 'System';

  @override
  String get routerGroupLan => 'LAN';

  @override
  String get routerEntryInterfaces => 'Interfaces';

  @override
  String get routerEntryInterfacesSub =>
      'Manage LAN/WAN interfaces and protocols';

  @override
  String get routerEntryWireless => 'Wireless';

  @override
  String get routerEntryWirelessSub => 'Radios and SSID settings';

  @override
  String get routerEntryDhcp => 'DHCP & DNS';

  @override
  String get routerEntryDhcpSub => 'Address pool, leases and dnsmasq';

  @override
  String get routerEntryRoutes => 'Static routes';

  @override
  String get routerEntryRoutesSub => 'Routes and rules';

  @override
  String get routerEntryFirewall => 'Firewall';

  @override
  String get routerEntryFirewallSub => 'Zones, rules and port forwarding';

  @override
  String get routerEntrySystem => 'System';

  @override
  String get routerEntrySystemSub => 'Hostname, time and logs';

  @override
  String get routerEntryAdmin => 'Administration';

  @override
  String get routerEntryAdminSub => 'Password and SSH';

  @override
  String get adminPasswordTitle => 'Root password';

  @override
  String get adminPasswordHint =>
      'After changing, SSH and web login use the new password immediately; the current App session is unaffected.';

  @override
  String get adminNewPassword => 'New password';

  @override
  String get adminConfirmPassword => 'Confirm new password';

  @override
  String get adminChangePassword => 'Change password';

  @override
  String get adminPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get adminPasswordMismatch => 'The two passwords do not match';

  @override
  String get adminPasswordChanged => 'Password updated';

  @override
  String get adminPasswordFailed => 'Password update failed';

  @override
  String get adminPasswordWarning =>
      'Change the root password? Verify SSH/web login with the new password immediately; a forgotten password requires a reset or reflash.';

  @override
  String get adminShowPassword => 'Show password';

  @override
  String get adminHidePassword => 'Hide password';

  @override
  String get adminSshTitle => 'SSH access';

  @override
  String get adminSshHint =>
      'dropbear settings; restart the SSH service after saving.';

  @override
  String get adminSshEnable => 'Enable SSH';

  @override
  String get adminSshEnableHint =>
      'Disabling makes SSH unavailable (web/App still work).';

  @override
  String get adminSshInterface => 'Listen interface';

  @override
  String get adminSshInterfaceHint => 'Empty = all interfaces; e.g. lan';

  @override
  String get adminSshPort => 'Port';

  @override
  String get adminPasswordAuth => 'Password authentication';

  @override
  String get adminRootPasswordAuth => 'Allow root password login';

  @override
  String get adminGatewayPorts => 'GatewayPorts';

  @override
  String get adminOn => 'On';

  @override
  String get adminOff => 'Off';

  @override
  String get adminSshService => 'SSH service';

  @override
  String get adminSshRestart => 'Restart SSH service';

  @override
  String get adminSshRestartHint =>
      'Restart after changing the port/authentication; current SSH sessions drop, the App is unaffected.';

  @override
  String get adminSshRestartWarning =>
      'Restarting dropbear disconnects current SSH sessions. Verify the port/password settings first or you may lock yourself out of SSH.';

  @override
  String get adminSshRestarted => 'SSH service restarted';

  @override
  String get adminSshUnavailable =>
      'No dropbear configuration found (SSH not installed).';

  @override
  String get adminNote =>
      'A forgotten root password requires a factory reset or reflash; keep a working SSH key or backup login method.';

  @override
  String get routerEntryInit => 'Startup';

  @override
  String get routerEntryInitSub => 'Boot services and control';

  @override
  String routerEntryClientsSub(int n) {
    return '$n online';
  }

  @override
  String get firewallDefaults => 'Default policy';

  @override
  String get firewallZones => 'Zones';

  @override
  String get firewallForwards => 'Zone forwarding';

  @override
  String get firewallRules => 'Traffic rules';

  @override
  String get firewallRedirects => 'Port forwards';

  @override
  String get firewallAddZone => 'Add zone';

  @override
  String get firewallAddForward => 'Add forwarding';

  @override
  String get firewallAddRule => 'Add rule';

  @override
  String get firewallAddRedirect => 'Add port forward';

  @override
  String get firewallEdit => 'Edit';

  @override
  String get firewallDelete => 'Delete';

  @override
  String firewallDeleteBody(String title) {
    return 'Delete \"$title\"? It takes effect immediately; it will auto-rollback if not confirmed within 90 seconds.';
  }

  @override
  String get firewallEmptyZones => 'No zones';

  @override
  String get firewallEmptyForwards => 'No zone forwarding';

  @override
  String get firewallEmptyRules => 'No rules';

  @override
  String get firewallEmptyRedirects => 'No port forwards';

  @override
  String get firewallHint =>
      'Common fields only; ipset, time windows and raw arguments remain in the web UI.';

  @override
  String get firewallInput => 'Input';

  @override
  String get firewallOutput => 'Output';

  @override
  String get firewallForward => 'Forward';

  @override
  String get firewallSynFlood => 'SYN-flood protection';

  @override
  String get firewallFullcone => 'FullCone NAT';

  @override
  String get firewallFlowOffloading => 'Software flow offloading';

  @override
  String get firewallFlowOffloadingHw => 'Hardware flow offloading';

  @override
  String get firewallName => 'Name';

  @override
  String get firewallNetwork => 'Covered networks';

  @override
  String get firewallDevice => 'Covered devices';

  @override
  String get firewallMasq => 'IPv4 masquerading';

  @override
  String get firewallMtuFix => 'MSS clamping';

  @override
  String get firewallEnabled => 'Enabled';

  @override
  String get firewallLog => 'Log';

  @override
  String get firewallFamily => 'Address family';

  @override
  String get firewallSrc => 'Source zone';

  @override
  String get firewallDest => 'Destination zone';

  @override
  String get firewallProto => 'Protocol';

  @override
  String get firewallSrcPort => 'Source port';

  @override
  String get firewallDestPort => 'Destination port';

  @override
  String get firewallSrcIp => 'Source address';

  @override
  String get firewallDestIp => 'Destination address';

  @override
  String get firewallDport => 'External port';

  @override
  String get firewallTarget => 'Action';

  @override
  String get firewallReflection => 'NAT reflection';

  @override
  String get firewallAccept => 'Accept';

  @override
  String get firewallReject => 'Reject';

  @override
  String get firewallDrop => 'Drop';

  @override
  String get firewallMark => 'Mark';

  @override
  String get firewallDnat => 'DNAT';

  @override
  String get firewallSnat => 'SNAT';

  @override
  String get firewallAny => 'Any';

  @override
  String get firewallIpv4 => 'IPv4';

  @override
  String get firewallIpv6 => 'IPv6';

  @override
  String get firewallZoneWarning =>
      'Changing a zone name/network/masquerading may disconnect the current session; unconfirmed changes auto-rollback within 90 seconds.';

  @override
  String get firewallAtLeastOne => 'Fill in at least one field';

  @override
  String get firewallDisabled => 'disabled';

  @override
  String get routerGroupAdvanced => 'Advanced';

  @override
  String get routerEntryMounts => 'Mount points';

  @override
  String get routerEntryMountsSub => 'Disks and swap';

  @override
  String get routerEntryCron => 'Scheduled tasks';

  @override
  String get routerEntryCronSub => 'Run commands on a schedule';

  @override
  String get cronHint =>
      'One cron job per line (minute hour day month weekday command); cron reloads after saving.';

  @override
  String get cronSave => 'Save and reload cron';

  @override
  String get cronSaved => 'Crontab saved and reloaded';

  @override
  String get cronReloadFailed => 'Crontab saved, but cron reload failed';

  @override
  String get cronDanger =>
      'Scheduled tasks run as root; a bad line can affect the system. Save anyway?';

  @override
  String cronLines(int n) {
    return 'Non-empty lines: $n';
  }

  @override
  String get routerEntryLed => 'LED configuration';

  @override
  String get routerEntryLedSub => 'Indicators and triggers';

  @override
  String get mountsCurrent => 'Current mounts';

  @override
  String get mountsConfigured => 'Mount configuration';

  @override
  String get mountsSwaps => 'Swap';

  @override
  String get mountsGlobal => 'Global mount options';

  @override
  String get mountsAddMount => 'Add mount';

  @override
  String get mountsAddSwap => 'Add swap';

  @override
  String get mountsEmptyMounts => 'No mount configuration';

  @override
  String get mountsEmptySwaps => 'No swap';

  @override
  String get mountsEmptyCurrent => 'No mount points to show';

  @override
  String get mountsDevice => 'Device';

  @override
  String get mountsTarget => 'Mount point';

  @override
  String get mountsFstype => 'Filesystem';

  @override
  String get mountsOptions => 'Mount options';

  @override
  String get mountsEnabled => 'Enabled';

  @override
  String get mountsFsck => 'Check on boot';

  @override
  String get mountsUuid => 'UUID';

  @override
  String get mountsLabel => 'Label';

  @override
  String get mountsGlobalAnonSwap => 'Auto-mount anonymous swap';

  @override
  String get mountsGlobalAnonMount => 'Auto-mount anonymous disks';

  @override
  String get mountsGlobalAutoSwap => 'Auto-mount swap';

  @override
  String get mountsGlobalAutoMount => 'Auto-mount configured disks';

  @override
  String get mountsGlobalCheckFsck => 'Check filesystems on boot';

  @override
  String get mountsGlobalDelayRoot => 'Root mount delay (s)';

  @override
  String mountsUsage(String used, String total) {
    return 'used $used / $total';
  }

  @override
  String get mountsHint =>
      'Mount/swap settings are written to fstab; they take effect on next boot or a manual fstab reload.';

  @override
  String mountsDeleteBody(String title) {
    return 'Delete the configuration for \"$title\"? Already-mounted filesystems are not unmounted.';
  }

  @override
  String get ledsConfigured => 'LED configuration';

  @override
  String get ledsAvailable => 'Available LEDs';

  @override
  String get ledsAdd => 'Add LED';

  @override
  String get ledsEmpty => 'No LED configuration';

  @override
  String get ledsEmptyAvailable => 'No LED devices available';

  @override
  String get ledsName => 'Name';

  @override
  String get ledsSysfs => 'Device (sysfs)';

  @override
  String get ledsTrigger => 'Trigger';

  @override
  String get ledsDefault => 'Default on';

  @override
  String get ledsDev => 'Trigger device';

  @override
  String get ledsInterval => 'Interval (ms)';

  @override
  String get ledsDelayOn => 'On delay (ms)';

  @override
  String get ledsDelayOff => 'Off delay (ms)';

  @override
  String get ledsHint =>
      'sysfs and triggers come from the current device; apply and confirm after editing.';

  @override
  String ledsDeleteBody(String title) {
    return 'Delete the LED configuration for \"$title\"?';
  }

  @override
  String get routerChipNative => 'Native';

  @override
  String get routerChipGeneric => 'Form';

  @override
  String get routerChipReady => 'Ready';

  @override
  String get routerChipSoon => 'Coming soon';

  @override
  String get routerMoreHint =>
      'More router settings are coming in a later version.';

  @override
  String get bandixPolicyLabel => 'Policy';

  @override
  String get viewAll => 'View all';

  @override
  String get clientHost => 'Hostname';

  @override
  String get clientIp => 'IP address';

  @override
  String get clientLastSeen => 'Last seen';

  @override
  String get servicesCardTitle => 'Services & cores';

  @override
  String get dockerContainers => 'Containers';

  @override
  String get dockerNetworks => 'Networks';

  @override
  String get dockerVolumes => 'Volumes';

  @override
  String get dockerEngine => 'Engine';

  @override
  String get dockerRoot => 'Root';

  @override
  String get dockerNoContainers => 'No containers';

  @override
  String get bandixCardNote => 'WAN rates; policy = whitelist / limit / quota';

  @override
  String get cellularRegistered => 'Registered';

  @override
  String get cellularNotRegistered => 'Not registered';

  @override
  String get cellularRate => 'Rate';

  @override
  String get cellularThisMonth => 'This month';

  @override
  String get heroUptime => 'Uptime';

  @override
  String get heroCollected => 'Collected';

  @override
  String get networkOnline => 'online';

  @override
  String get networkOffline => 'offline';

  @override
  String get networkCaption =>
      'Download (blue) / Upload (grey) — last 2 minutes';

  @override
  String get processesLabel => 'Processes';

  @override
  String get appearancePreview => 'Preview';

  @override
  String get appearanceMode => 'Appearance mode';

  @override
  String get appearanceModeHint =>
      'Follows the system on first use; the local choice takes precedence.';

  @override
  String get appearanceMaterial => 'Material';

  @override
  String get appearanceOpacity => 'Interface opacity';

  @override
  String get appearanceOpacityHint =>
      '50–100%; applies to panels, top bar and tab bar; below 100% enables backdrop blur.';

  @override
  String get appearanceBlur => 'Blur strength';

  @override
  String get appearanceBlurHint =>
      '0–40px; applies to chrome and translucent panels; 0 = off.';

  @override
  String get appearanceWallpaper => 'Wallpaper';

  @override
  String get appearanceWallpaperHint =>
      'Single image ≤1920px / JPEG / ≤2MB; removing falls back to noise; never uploaded.';

  @override
  String get appearanceWallpaperEmpty => 'No wallpaper';

  @override
  String get appearanceDefaultNoise => 'Default quartz noise';

  @override
  String get appearanceChangeWallpaper => 'Change';

  @override
  String get appearanceChooseWallpaper => 'Choose image';

  @override
  String get appearanceRemoveWallpaper => 'Remove';

  @override
  String get appearanceReset => 'Reset';

  @override
  String get appearanceResetDone => 'Appearance reset to defaults';

  @override
  String get appearanceLocalOnly =>
      'App appearance affects this device only; it never writes /etc/config/quartz on the router.';

  @override
  String appearanceWallpaperFailed(Object detail) {
    return 'Failed to save wallpaper: $detail';
  }

  @override
  String get appearanceWallpaperTooLarge =>
      'Image exceeds 2 MB. Choose a smaller image.';

  @override
  String get appearanceLocal => 'On device';

  @override
  String get configSessionUnavailable =>
      'Configuration session unavailable. Sign in to the router again to enable configuration.';

  @override
  String get configForbidden => 'This setting is not exposed.';

  @override
  String configBadValue(String detail) {
    return 'Invalid value: $detail';
  }

  @override
  String configApplyFailed(String detail) {
    return 'Apply failed: $detail';
  }

  @override
  String get configWebPending =>
      'The web UI has unconfirmed changes. Confirm or roll them back there first.';

  @override
  String get configNoChanges => 'No changes to save.';

  @override
  String get configDirtyChip => 'Unsaved';

  @override
  String get configSaving => 'Saving…';

  @override
  String get configSheetHint =>
      'Confirm within 90 seconds after saving, otherwise changes auto-rollback.';

  @override
  String get configUnset => 'Not set';

  @override
  String get configChoose => 'Choose';

  @override
  String get configSensitiveHint => 'Set; leave blank to keep';

  @override
  String get configSaved => 'Saved and confirmed.';

  @override
  String get configRollbackDone => 'Rolled back.';

  @override
  String get configAutoRolledBack =>
      'Not confirmed; rolled back automatically.';

  @override
  String get configDangerTitle => 'Confirm changes';

  @override
  String get configDangerBody =>
      'This change may interrupt this device\'s connection to the router; unconfirmed changes roll back after 90 seconds.';

  @override
  String get configApplyTitle => 'Confirm changes';

  @override
  String configApplyCountdown(int sec) {
    return 'Auto rollback in ${sec}s';
  }

  @override
  String get configApplyBody =>
      'If you changed IP or wireless settings, this device may disconnect; the router will roll back automatically when the countdown ends.';

  @override
  String get configRollbackNow => 'Roll back now';

  @override
  String get configKeepChanges => 'Keep changes';

  @override
  String get configLoadFailedTitle => 'Failed to load configuration';

  @override
  String get configSectionUnavailable =>
      'This configuration section is unavailable.';

  @override
  String get ipv6Label => 'IPv6';

  @override
  String get systemGeneral => 'General';

  @override
  String get systemHostname => 'Hostname';

  @override
  String get systemDescription => 'Description';

  @override
  String get systemTimezone => 'Time zone';

  @override
  String get systemTimezoneHint =>
      'Times are interpreted by the router using the selected zone.';

  @override
  String get systemTimezonePicker => 'Choose time zone';

  @override
  String get systemTimezoneSearch => 'Search time zones';

  @override
  String get systemLogging => 'Logging';

  @override
  String get systemLogSize => 'Log size (KB)';

  @override
  String get systemLogProto => 'Log protocol';

  @override
  String get systemLogIp => 'Remote log server';

  @override
  String get systemLogIpHint => 'Leave blank to disable remote logging';

  @override
  String get systemLogPort => 'Remote log port';

  @override
  String get systemAdvanced => 'Advanced';

  @override
  String get systemConsoleLogLevel => 'Console log level';

  @override
  String get systemCronLogLevel => 'Cron log level';

  @override
  String get systemTtyLogin => 'Serial console login';

  @override
  String get initSearch => 'Search services';

  @override
  String get initEmpty => 'No startup services found.';

  @override
  String initIndex(int n) {
    return 'Start order $n';
  }

  @override
  String initStopIndex(int n) {
    return 'Stop order $n';
  }

  @override
  String get initEnabled => 'Enabled';

  @override
  String get initDisabled => 'Disabled';

  @override
  String get initEnable => 'Enable';

  @override
  String get initDisable => 'Disable';

  @override
  String get initStart => 'Start';

  @override
  String get initStop => 'Stop';

  @override
  String get initRestart => 'Restart';

  @override
  String initActionDone(String action, String name) {
    return '$action done: $name';
  }

  @override
  String get initToggleWarning =>
      'If disabled, this service will not start automatically on next boot.';

  @override
  String get initStopWarning =>
      'Stopping or restarting this service may interrupt router functions or this device\'s connection.';

  @override
  String get interfaceProto => 'Protocol';

  @override
  String get interfaceDevice => 'Device';

  @override
  String get interfaceDisabled => 'Disable';

  @override
  String get interfaceAuto => 'Enable on boot';

  @override
  String get interfaceIpaddr => 'IP address';

  @override
  String get interfaceNetmask => 'Netmask';

  @override
  String get interfaceGateway => 'Gateway';

  @override
  String get interfaceDns => 'DNS servers';

  @override
  String get interfaceDnsHint => 'Separate multiple addresses with spaces';

  @override
  String get interfaceIp6addr => 'IPv6 address';

  @override
  String get interfaceIp6Hint => 'May be left blank';

  @override
  String get interfaceIp6assign => 'IPv6 prefix size';

  @override
  String get interfaceUsername => 'PPPoE username';

  @override
  String get interfacePassword => 'PPPoE password';

  @override
  String get interfaceStatic => 'Static address';

  @override
  String get interfaceDhcpClient => 'DHCP client';

  @override
  String get interfaceNone => 'None';

  @override
  String get interfacePppoe => 'PPPoE';

  @override
  String get wirelessEmpty =>
      'No wireless radios detected (or wireless is disabled).';

  @override
  String get wirelessIface => 'Wireless interface';

  @override
  String get wirelessDevice => 'Radio';

  @override
  String get wirelessMode => 'Mode';

  @override
  String get wirelessEncryption => 'Encryption';

  @override
  String get wirelessBand => 'Band';

  @override
  String get wirelessChannel => 'Channel';

  @override
  String get wirelessSsid => 'SSID';

  @override
  String get wirelessKey => 'Password';

  @override
  String get wirelessNetwork => 'Network';

  @override
  String get wirelessHidden => 'Hide SSID';

  @override
  String get wirelessIsolate => 'Client isolation';

  @override
  String get wirelessWmm => 'WMM';

  @override
  String get wirelessHtmode => 'HT mode';

  @override
  String get wirelessTxpower => 'TX power (dBm)';

  @override
  String get wirelessCountry => 'Country code';

  @override
  String get wirelessCellDensity => 'Cell density';

  @override
  String get wirelessDistance => 'Distance (m)';

  @override
  String get dhcpEmpty => 'No DHCP configuration found.';

  @override
  String get dhcpDnsmasq => 'DNS & DHCP (dnsmasq)';

  @override
  String get dhcpServer => 'DHCP server';

  @override
  String get dhcpServerHint => 'Address pool and leases';

  @override
  String get dhcpDomain => 'Domain';

  @override
  String get dhcpLocal => 'Local domain';

  @override
  String get dhcpDomainNeeded => 'Domain required';

  @override
  String get dhcpBogusPriv => 'Filter private domains';

  @override
  String get dhcpAuthoritative => 'Authoritative';

  @override
  String get dhcpLocalService => 'Local service only';

  @override
  String get dhcpRebindProtection => 'Rebind protection';

  @override
  String get dhcpExpandHosts => 'Expand hosts';

  @override
  String get dhcpCacheSize => 'Cache size';

  @override
  String get dhcpLogQueries => 'Log queries';

  @override
  String get dhcpStart => 'Start address (last octet)';

  @override
  String get dhcpLimit => 'Pool size';

  @override
  String get dhcpLeasetime => 'Lease time';

  @override
  String get dhcpIgnore => 'Disable DHCP';

  @override
  String get dhcpDynamicDhcp => 'Dynamic DHCP';

  @override
  String get dhcpForce => 'Force';

  @override
  String get dhcpRa => 'IPv6 RA';

  @override
  String get dhcpRaManagement => 'RA management';

  @override
  String get dhcpDhcpv6 => 'DHCPv6';

  @override
  String get dhcpMaster => 'Master';

  @override
  String get dhcpDnsService => 'Advertise DNS';

  @override
  String get dhcpStaticLeases => 'Static leases';

  @override
  String get dhcpAddLease => 'Add static lease';

  @override
  String get dhcpLeaseName => 'Name';

  @override
  String get dhcpLeaseMac => 'MAC address';

  @override
  String get dhcpLeaseIp => 'IP address';

  @override
  String get dhcpNoLeases => 'No static leases';

  @override
  String get dhcpDeleteLease => 'Delete static lease';

  @override
  String get dhcpDeleteLeaseBody =>
      'After deletion, DHCP will assign a dynamic address.';

  @override
  String get dhcpLeaseHint =>
      'Name/static IP may be left blank; MAC is required.';

  @override
  String get dhcpLeaseInvalidMac => 'Invalid MAC address';

  @override
  String get routesStatic => 'Static routes';

  @override
  String get routesRules => 'Routing rules';

  @override
  String get routesAddRoute => 'Add static route';

  @override
  String get routesAddRule => 'Add routing rule';

  @override
  String get routesTarget => 'Target network';

  @override
  String get routesNetmask => 'Netmask';

  @override
  String get routesGateway => 'Gateway';

  @override
  String get routesInterface => 'Interface';

  @override
  String get routesMetric => 'Metric';

  @override
  String get routesRuleIn => 'In interface';

  @override
  String get routesRuleSrc => 'Source';

  @override
  String get routesRuleDest => 'Destination';

  @override
  String get routesRuleLookup => 'Table';

  @override
  String get routesRulePriority => 'Priority';

  @override
  String get routesNone => 'No entries';

  @override
  String get routesDelete => 'Delete entry';

  @override
  String get routesDeleteBody =>
      'Takes effect immediately; you can roll back from the 90s confirmation bar.';

  @override
  String get routesHint =>
      'Static routes/rules apply immediately; use the 90s confirmation bar to roll back.';

  @override
  String routesRequiredField(String field) {
    return '$field is required';
  }
}
