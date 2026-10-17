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
      'Sorted by cumulative traffic (top 8); share = cumulative bytes share.';

  @override
  String get bandixSummaryNote =>
      'Values come from bandix statistics (device-side WAN totals); pull to refresh.';
}
