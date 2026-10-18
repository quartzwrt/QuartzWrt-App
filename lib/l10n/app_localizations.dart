import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuartzWrt'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get navNetwork;

  /// No description provided for @navApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get navApps;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unknownValue.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get unknownValue;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @notInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get notInstalled;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped2.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped2;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {detail}'**
  String actionFailed(String detail);

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a router'**
  String get discoverTitle;

  /// No description provided for @discoverScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning local network (mDNS)…'**
  String get discoverScanning;

  /// No description provided for @discoverNone.
  ///
  /// In en, this message translates to:
  /// **'No other devices found — make sure your phone is on the same network.'**
  String get discoverNone;

  /// No description provided for @addByAddress.
  ///
  /// In en, this message translates to:
  /// **'Add by address…'**
  String get addByAddress;

  /// No description provided for @addByAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Add router by address'**
  String get addByAddressTitle;

  /// No description provided for @hostLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get hostLabel;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @badgeVerifiable.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint verifiable'**
  String get badgeVerifiable;

  /// No description provided for @badgeUnverified.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint unverified'**
  String get badgeUnverified;

  /// No description provided for @noTabAfterPair.
  ///
  /// In en, this message translates to:
  /// **'Main screen appears after pairing'**
  String get noTabAfterPair;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to {name}'**
  String pairTitle(String name);

  /// No description provided for @certFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Certificate fingerprint (SHA-256)'**
  String get certFingerprint;

  /// No description provided for @firmwareLabel.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get firmwareLabel;

  /// No description provided for @routerPassword.
  ///
  /// In en, this message translates to:
  /// **'Router admin password'**
  String get routerPassword;

  /// No description provided for @routerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Used once to pair; the app then signs in with a revocable token.'**
  String get routerPasswordHint;

  /// No description provided for @pairButton.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pairButton;

  /// No description provided for @pairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing…'**
  String get pairing;

  /// No description provided for @errInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get errInvalidCredentials;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts, retry in {sec}s'**
  String errRateLimited(int sec);

  /// No description provided for @errPasswordNotSet.
  ///
  /// In en, this message translates to:
  /// **'Set the router admin password first (LuCI → System → Administration).'**
  String get errPasswordNotSet;

  /// No description provided for @errFingerprintMismatch.
  ///
  /// In en, this message translates to:
  /// **'Router identity changed — pairing blocked.'**
  String get errFingerprintMismatch;

  /// No description provided for @errConnect.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the router.'**
  String get errConnect;

  /// No description provided for @errBadCert.
  ///
  /// In en, this message translates to:
  /// **'Certificate check failed.'**
  String get errBadCert;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out.'**
  String get errTimeout;

  /// No description provided for @overviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// No description provided for @connectedLan.
  ///
  /// In en, this message translates to:
  /// **'Connected · LAN'**
  String get connectedLan;

  /// No description provided for @connectedRemote.
  ///
  /// In en, this message translates to:
  /// **'Connected · Remote'**
  String get connectedRemote;

  /// No description provided for @runFor.
  ///
  /// In en, this message translates to:
  /// **'Up {d} days {h}:{m}'**
  String runFor(int d, int h, String m);

  /// No description provided for @runForShort.
  ///
  /// In en, this message translates to:
  /// **'Up {h}:{m}'**
  String runForShort(int h, String m);

  /// No description provided for @systemCardTitle.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemCardTitle;

  /// No description provided for @cpuLabel.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cpuLabel;

  /// No description provided for @memLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memLabel;

  /// No description provided for @storageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageLabel;

  /// No description provided for @tempLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get tempLabel;

  /// No description provided for @loadLabel.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get loadLabel;

  /// No description provided for @tempUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable (no sensor)'**
  String get tempUnavailable;

  /// No description provided for @networkCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Network · WAN'**
  String get networkCardTitle;

  /// No description provided for @clientsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsCardTitle;

  /// No description provided for @appsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsCardTitle;

  /// No description provided for @dockerCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Docker'**
  String get dockerCardTitle;

  /// No description provided for @dockerRunning.
  ///
  /// In en, this message translates to:
  /// **'Running containers'**
  String get dockerRunning;

  /// No description provided for @dockerImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get dockerImages;

  /// No description provided for @dockerUnhealthy.
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get dockerUnhealthy;

  /// No description provided for @bannerCollectorDown.
  ///
  /// In en, this message translates to:
  /// **'Collector not running'**
  String get bannerCollectorDown;

  /// No description provided for @bannerCollectorDownBody.
  ///
  /// In en, this message translates to:
  /// **'Router data service unavailable (quartz-daemon not running or starting). It refreshes automatically.'**
  String get bannerCollectorDownBody;

  /// No description provided for @bannerConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get bannerConnectionLost;

  /// No description provided for @bannerConnectionLostBody.
  ///
  /// In en, this message translates to:
  /// **'Showing the last known data. Retrying automatically.'**
  String get bannerConnectionLostBody;

  /// No description provided for @bannerNeedRepair.
  ///
  /// In en, this message translates to:
  /// **'Pairing revoked or expired'**
  String get bannerNeedRepair;

  /// No description provided for @bannerNeedRepairBody.
  ///
  /// In en, this message translates to:
  /// **'Re-pair this router to continue.'**
  String get bannerNeedRepairBody;

  /// No description provided for @otherClientsCount.
  ///
  /// In en, this message translates to:
  /// **'+{n} more'**
  String otherClientsCount(int n);

  /// No description provided for @networkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkTitle;

  /// No description provided for @wanNetworkCardTitle.
  ///
  /// In en, this message translates to:
  /// **'WAN · Network'**
  String get wanNetworkCardTitle;

  /// No description provided for @wanDown.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get wanDown;

  /// No description provided for @wirelessCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Wireless'**
  String get wirelessCardTitle;

  /// No description provided for @noiseLabel.
  ///
  /// In en, this message translates to:
  /// **'Noise'**
  String get noiseLabel;

  /// No description provided for @clientsOnlineHeader.
  ///
  /// In en, this message translates to:
  /// **'{n} online'**
  String clientsOnlineHeader(int n);

  /// No description provided for @allClientsEntry.
  ///
  /// In en, this message translates to:
  /// **'All clients ({n})'**
  String allClientsEntry(int n);

  /// No description provided for @clientsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clientsPageTitle;

  /// No description provided for @clientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clients online.'**
  String get clientsEmpty;

  /// No description provided for @networkServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Network services'**
  String get networkServicesTitle;

  /// No description provided for @dnsServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'DNS (dnsmasq)'**
  String get dnsServiceLabel;

  /// No description provided for @wanReconnectPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get wanReconnectPlanned;

  /// No description provided for @lastSeenNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get lastSeenNow;

  /// No description provided for @lastSeenMin.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String lastSeenMin(int n);

  /// No description provided for @lastSeenHour.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String lastSeenHour(int n);

  /// No description provided for @lastSeenDay.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String lastSeenDay(int n);

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsTitle;

  /// No description provided for @segApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get segApps;

  /// No description provided for @segPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get segPackages;

  /// No description provided for @appsControllableIntro.
  ///
  /// In en, this message translates to:
  /// **'Installed apps with in-app control; tap for details.'**
  String get appsControllableIntro;

  /// No description provided for @appsNone.
  ///
  /// In en, this message translates to:
  /// **'No controllable apps installed.'**
  String get appsNone;

  /// No description provided for @appsNotInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get appsNotInstalledTitle;

  /// No description provided for @appsNotInstalledBody.
  ///
  /// In en, this message translates to:
  /// **'Docker, Tailscale and others appear here automatically once installed.'**
  String get appsNotInstalledBody;

  /// No description provided for @appDetailStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get appDetailStatusTitle;

  /// No description provided for @appDetailStatusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get appDetailStatusRunning;

  /// No description provided for @coreLabel.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get coreLabel;

  /// No description provided for @statusSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Status source'**
  String get statusSourceLabel;

  /// No description provided for @statusSourceProbe.
  ///
  /// In en, this message translates to:
  /// **'Router probe (no rebuild)'**
  String get statusSourceProbe;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTitle;

  /// No description provided for @actionsNote.
  ///
  /// In en, this message translates to:
  /// **'Actions follow router capability registry (WP-5 allowlist / WP-8 bridge).'**
  String get actionsNote;

  /// No description provided for @actionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart service'**
  String get actionRestart;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @packageCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packageCardTitle;

  /// No description provided for @packageVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get packageVersion;

  /// No description provided for @packageSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get packageSource;

  /// No description provided for @packageSize.
  ///
  /// In en, this message translates to:
  /// **'Installed size'**
  String get packageSize;

  /// No description provided for @packageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove…'**
  String get packageRemove;

  /// No description provided for @packagesApiMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Package management not available'**
  String get packagesApiMissingTitle;

  /// No description provided for @packagesApiMissingBody.
  ///
  /// In en, this message translates to:
  /// **'The router API has no package support yet (requires quartz-app-api update). Installed/upgrade list will appear here automatically.'**
  String get packagesApiMissingBody;

  /// No description provided for @upgradableHeader.
  ///
  /// In en, this message translates to:
  /// **'Upgradable · {n}'**
  String upgradableHeader(int n);

  /// No description provided for @upgradeAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Upgrade all ({n})'**
  String upgradeAllBtn(int n);

  /// No description provided for @installedHeader.
  ///
  /// In en, this message translates to:
  /// **'Installed · {n}'**
  String installedHeader(int n);

  /// No description provided for @allPackagesEntry.
  ///
  /// In en, this message translates to:
  /// **'All packages ({n}) · search'**
  String allPackagesEntry(int n);

  /// No description provided for @installNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Install a new package'**
  String get installNewTitle;

  /// No description provided for @installNewBody.
  ///
  /// In en, this message translates to:
  /// **'Browsing and installing new packages is planned (v1 focuses on installed/upgrade/records).'**
  String get installNewBody;

  /// No description provided for @opLogEntry.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get opLogEntry;

  /// No description provided for @opLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Operation records'**
  String get opLogTitle;

  /// No description provided for @opLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent operations.'**
  String get opLogEmpty;

  /// No description provided for @opLogRetain.
  ///
  /// In en, this message translates to:
  /// **'Only the latest 30 operations are kept (upgrade / remove / update lists).'**
  String get opLogRetain;

  /// No description provided for @opReindex.
  ///
  /// In en, this message translates to:
  /// **'Software index refreshed'**
  String get opReindex;

  /// No description provided for @opUpgradeAll.
  ///
  /// In en, this message translates to:
  /// **'Upgraded packages ({n})'**
  String opUpgradeAll(int n);

  /// No description provided for @opUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade {name}'**
  String opUpgrade(String name);

  /// No description provided for @opRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String opRemove(String name);

  /// No description provided for @opResultOk.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get opResultOk;

  /// No description provided for @opResultFail.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get opResultFail;

  /// No description provided for @opResultPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get opResultPartial;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sysSettingsGroup.
  ///
  /// In en, this message translates to:
  /// **'System settings · Router'**
  String get sysSettingsGroup;

  /// No description provided for @appSettingsGroup.
  ///
  /// In en, this message translates to:
  /// **'App settings · This phone'**
  String get appSettingsGroup;

  /// No description provided for @pairedLan.
  ///
  /// In en, this message translates to:
  /// **'Paired · LAN'**
  String get pairedLan;

  /// No description provided for @pairedRemote.
  ///
  /// In en, this message translates to:
  /// **'Paired · Remote'**
  String get pairedRemote;

  /// No description provided for @fingerprintLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate fingerprint'**
  String get fingerprintLabel;

  /// No description provided for @pairedDevicesEntry.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get pairedDevicesEntry;

  /// No description provided for @addRouterEntry.
  ///
  /// In en, this message translates to:
  /// **'Add a router'**
  String get addRouterEntry;

  /// No description provided for @deviceControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Device control'**
  String get deviceControlTitle;

  /// No description provided for @rebootRouter.
  ///
  /// In en, this message translates to:
  /// **'Reboot router'**
  String get rebootRouter;

  /// No description provided for @restartService.
  ///
  /// In en, this message translates to:
  /// **'Restart service…'**
  String get restartService;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get followSystem;

  /// No description provided for @modeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get modeDark;

  /// No description provided for @modeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get modeLight;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @apiLabel.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get apiLabel;

  /// No description provided for @devicesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get devicesPageTitle;

  /// No description provided for @devicesCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'this phone'**
  String get devicesCurrentBadge;

  /// No description provided for @devicesRevokedBadge.
  ///
  /// In en, this message translates to:
  /// **'revoked'**
  String get devicesRevokedBadge;

  /// No description provided for @revokeBtn.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeBtn;

  /// No description provided for @revokeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this device?'**
  String get revokeConfirmTitle;

  /// No description provided for @revokeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The device must pair again to regain access.'**
  String get revokeConfirmBody;

  /// No description provided for @rebootConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reboot router?'**
  String get rebootConfirmTitle;

  /// No description provided for @rebootConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will reboot now. Network drops for about 1–2 minutes; the app reconnects automatically.'**
  String rebootConfirmBody(String name);

  /// No description provided for @removeRouterTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this router from the app?'**
  String get removeRouterTitle;

  /// No description provided for @removeRouterBody.
  ///
  /// In en, this message translates to:
  /// **'Also revoke this phone on the router (recommended).'**
  String get removeRouterBody;

  /// No description provided for @removeRouterBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeRouterBtn;

  /// No description provided for @kernelLabel.
  ///
  /// In en, this message translates to:
  /// **'kernel'**
  String get kernelLabel;

  /// No description provided for @rePair.
  ///
  /// In en, this message translates to:
  /// **'Re-pair'**
  String get rePair;

  /// No description provided for @collectorErrors.
  ///
  /// In en, this message translates to:
  /// **'Collector messages'**
  String get collectorErrors;

  /// No description provided for @remoteEntry.
  ///
  /// In en, this message translates to:
  /// **'Remote access'**
  String get remoteEntry;

  /// No description provided for @remotePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote access'**
  String get remotePageTitle;

  /// No description provided for @remoteRouterStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Router · Tailscale'**
  String get remoteRouterStatusTitle;

  /// No description provided for @remoteTsIpLabel.
  ///
  /// In en, this message translates to:
  /// **'Tailscale address'**
  String get remoteTsIpLabel;

  /// No description provided for @remoteUseThisAddr.
  ///
  /// In en, this message translates to:
  /// **'Add remote access with this address'**
  String get remoteUseThisAddr;

  /// No description provided for @remoteNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Tailscale not detected — install and enable it from the router\'s Apps page.'**
  String get remoteNotDetected;

  /// No description provided for @remoteStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup steps'**
  String get remoteStepsTitle;

  /// No description provided for @remoteStep1.
  ///
  /// In en, this message translates to:
  /// **'Install and enable Tailscale on the router (Apps → Tailscale).'**
  String get remoteStep1;

  /// No description provided for @remoteStep2.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your tailnet on the router\'s Tailscale page.'**
  String get remoteStep2;

  /// No description provided for @remoteStep3.
  ///
  /// In en, this message translates to:
  /// **'Install the Tailscale client on your phone and sign in to the same tailnet.'**
  String get remoteStep3;

  /// No description provided for @remoteStep4.
  ///
  /// In en, this message translates to:
  /// **'Add the tailnet address here (100.x.y.z or a MagicDNS name); the certificate pin is reused from the LAN pairing.'**
  String get remoteStep4;

  /// No description provided for @remoteAddrTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote address'**
  String get remoteAddrTitle;

  /// No description provided for @remoteAddrNone.
  ///
  /// In en, this message translates to:
  /// **'Not set — direct LAN connection at home; add a tailnet address here to manage the router from anywhere.'**
  String get remoteAddrNone;

  /// No description provided for @remoteAddBtn.
  ///
  /// In en, this message translates to:
  /// **'Add remote address…'**
  String get remoteAddBtn;

  /// No description provided for @remoteEditBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get remoteEditBtn;

  /// No description provided for @remoteTestBtn.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get remoteTestBtn;

  /// No description provided for @remoteInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get remoteInUse;

  /// No description provided for @remoteHostLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (100.x.y.z or hostname)'**
  String get remoteHostLabel;

  /// No description provided for @remoteTestSave.
  ///
  /// In en, this message translates to:
  /// **'Test & save'**
  String get remoteTestSave;

  /// No description provided for @remoteTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get remoteTesting;

  /// No description provided for @remoteTestOk.
  ///
  /// In en, this message translates to:
  /// **'Remote connection works — saved.'**
  String get remoteTestOk;

  /// No description provided for @remoteTestFail.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {detail}'**
  String remoteTestFail(String detail);

  /// No description provided for @remoteHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address.'**
  String get remoteHostRequired;

  /// No description provided for @remoteRemoveBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove remote address'**
  String get remoteRemoveBtn;

  /// No description provided for @remoteRemoveShort.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remoteRemoveShort;

  /// No description provided for @remoteRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove remote address?'**
  String get remoteRemoveTitle;

  /// No description provided for @remoteRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The app will connect over LAN only; pairing and tokens are unaffected.'**
  String get remoteRemoveBody;

  /// No description provided for @remoteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Remote address removed.'**
  String get remoteRemoved;

  /// No description provided for @remoteAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic switching'**
  String get remoteAutoTitle;

  /// No description provided for @remoteAutoBody.
  ///
  /// In en, this message translates to:
  /// **'LAN is preferred on the same network; on failure the app falls back to the remote address and switches back once LAN is reachable again.'**
  String get remoteAutoBody;

  /// No description provided for @remoteSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get remoteSecurityTitle;

  /// No description provided for @remoteSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Remote connections use the same certificate pinning as LAN (MITM-resistant). Rebooting or disconnecting the router remotely may briefly drop the connection; the router recovers on its own. Removing the remote address never affects the LAN pairing.'**
  String get remoteSecurityBody;

  /// No description provided for @embedTitle.
  ///
  /// In en, this message translates to:
  /// **'Embedded direct (experimental)'**
  String get embedTitle;

  /// No description provided for @embedBody.
  ///
  /// In en, this message translates to:
  /// **'Runs a tailnet node inside the app: reach the router over your tailnet without installing the Tailscale client on this phone. Enabling creates a device in your tailnet (login required); disabling falls back to the regular direct connection.'**
  String get embedBody;

  /// No description provided for @embedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This build does not include the embedded engine (release builds do).'**
  String get embedUnavailable;

  /// No description provided for @embedEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable embedded direct'**
  String get embedEnable;

  /// No description provided for @embedStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get embedStateLabel;

  /// No description provided for @embedPhaseStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get embedPhaseStarting;

  /// No description provided for @embedPhaseNeedsLogin.
  ///
  /// In en, this message translates to:
  /// **'Waiting for login'**
  String get embedPhaseNeedsLogin;

  /// No description provided for @embedPhaseRunning.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get embedPhaseRunning;

  /// No description provided for @embedPhaseStopped.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get embedPhaseStopped;

  /// No description provided for @embedPhaseError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get embedPhaseError;

  /// No description provided for @embedSelfIpLabel.
  ///
  /// In en, this message translates to:
  /// **'This device tailnet address'**
  String get embedSelfIpLabel;

  /// No description provided for @embedLoginBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Tailscale'**
  String get embedLoginBtn;

  /// No description provided for @embedLoginHint.
  ///
  /// In en, this message translates to:
  /// **'After signing in, this device joins your tailnet and remote addresses prefer the embedded node automatically.'**
  String get embedLoginHint;

  /// No description provided for @embedCopyBtn.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get embedCopyBtn;

  /// No description provided for @embedCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get embedCopied;

  /// No description provided for @embedErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error detail'**
  String get embedErrorDetail;

  /// No description provided for @pkgViewUpgradable.
  ///
  /// In en, this message translates to:
  /// **'Upgradable'**
  String get pkgViewUpgradable;

  /// No description provided for @pkgViewUpgradableN.
  ///
  /// In en, this message translates to:
  /// **'Upgradable ({n})'**
  String pkgViewUpgradableN(int n);

  /// No description provided for @pkgViewInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get pkgViewInstalled;

  /// No description provided for @pkgViewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pkgViewAll;

  /// No description provided for @pkgSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search packages (by name)'**
  String get pkgSearchHint;

  /// No description provided for @pkgSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a name to search packages. Installed / Upgradable live in the other two tabs.'**
  String get pkgSearchPrompt;

  /// No description provided for @pkgSearchNone.
  ///
  /// In en, this message translates to:
  /// **'No matching packages.'**
  String get pkgSearchNone;

  /// No description provided for @pkgEmptyUpgradable.
  ///
  /// In en, this message translates to:
  /// **'All packages are up to date.'**
  String get pkgEmptyUpgradable;

  /// No description provided for @pkgEmptyInstalled.
  ///
  /// In en, this message translates to:
  /// **'No installed packages found.'**
  String get pkgEmptyInstalled;

  /// No description provided for @pkgRefreshDone.
  ///
  /// In en, this message translates to:
  /// **'Package lists updated ({s}s)'**
  String pkgRefreshDone(int s);

  /// No description provided for @pkgUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get pkgUpgrade;

  /// No description provided for @pkgUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {version}'**
  String pkgUpgradeTo(String version);

  /// No description provided for @pkgUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Upgraded {name}'**
  String pkgUpgraded(String name);

  /// No description provided for @pkgRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get pkgRemove;

  /// No description provided for @pkgRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String pkgRemoved(String name);

  /// No description provided for @pkgRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String pkgRemoveConfirmTitle(String name);

  /// No description provided for @pkgRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the package from the router. Dependent components may break and related services stop. This cannot be undone.'**
  String get pkgRemoveConfirmBody;

  /// No description provided for @pkgUpgradeAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade all?'**
  String get pkgUpgradeAllConfirmTitle;

  /// No description provided for @pkgUpgradeAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Upgrades all upgradable packages ({n}). Related services may restart and network is used; do not power off.'**
  String pkgUpgradeAllConfirmBody(int n);

  /// No description provided for @pkgBadgeInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get pkgBadgeInstalled;

  /// No description provided for @pkgBadgeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get pkgBadgeUpgrade;

  /// No description provided for @pkgLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more ({shown}/{total})'**
  String pkgLoadMore(int shown, int total);

  /// No description provided for @pkgShownOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown}/{total}'**
  String pkgShownOf(int shown, int total);

  /// No description provided for @pkgCardName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pkgCardName;

  /// No description provided for @pkgCardUpgradeTo.
  ///
  /// In en, this message translates to:
  /// **'Upgrade available: {version}'**
  String pkgCardUpgradeTo(String version);

  /// No description provided for @pkgCardNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'This app is not installed as a package (or the name differs). Search in the Packages tab to confirm.'**
  String get pkgCardNotInstalled;

  /// No description provided for @opLogMeta.
  ///
  /// In en, this message translates to:
  /// **'{status} · {dur}'**
  String opLogMeta(String status, String dur);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @bandixRowOnline.
  ///
  /// In en, this message translates to:
  /// **'Online {online}/{devices}'**
  String bandixRowOnline(int online, int devices);

  /// No description provided for @bandixTitle.
  ///
  /// In en, this message translates to:
  /// **'Bandix traffic & limits'**
  String get bandixTitle;

  /// No description provided for @bandixTrafficTitle.
  ///
  /// In en, this message translates to:
  /// **'Traffic detail'**
  String get bandixTrafficTitle;

  /// No description provided for @bandixUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Traffic data unavailable (collector did not return it or upstream is down).'**
  String get bandixUnavailable;

  /// No description provided for @bandixNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Bandix traffic monitoring is not enabled or not installed — enable it on the web settings page.'**
  String get bandixNotEnabled;

  /// No description provided for @bandixOnlineDevices.
  ///
  /// In en, this message translates to:
  /// **'Online devices'**
  String get bandixOnlineDevices;

  /// No description provided for @bandixWanRate.
  ///
  /// In en, this message translates to:
  /// **'WAN rate'**
  String get bandixWanRate;

  /// No description provided for @bandixDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get bandixDownload;

  /// No description provided for @bandixUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get bandixUpload;

  /// No description provided for @bandixDnsQueriesLabel.
  ///
  /// In en, this message translates to:
  /// **'DNS queries'**
  String get bandixDnsQueriesLabel;

  /// No description provided for @connectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connectionsLabel;

  /// No description provided for @notEnabled.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get notEnabled;

  /// No description provided for @bandixLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Default rate limit'**
  String get bandixLimitTitle;

  /// No description provided for @bandixLimitBody.
  ///
  /// In en, this message translates to:
  /// **'Applies to devices without an individual limit; 0 = unlimited. Unit: KB/s.'**
  String get bandixLimitBody;

  /// No description provided for @bandixLimitRx.
  ///
  /// In en, this message translates to:
  /// **'Download limit (KB/s)'**
  String get bandixLimitRx;

  /// No description provided for @bandixLimitTx.
  ///
  /// In en, this message translates to:
  /// **'Upload limit (KB/s)'**
  String get bandixLimitTx;

  /// No description provided for @bandixLimitsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not read current config (bridge unavailable); saving will still be attempted.'**
  String get bandixLimitsUnavailable;

  /// No description provided for @bandixInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-negative integer.'**
  String get bandixInvalidNumber;

  /// No description provided for @bandixWhitelistTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate-limit whitelist'**
  String get bandixWhitelistTitle;

  /// No description provided for @bandixWhitelistBody.
  ///
  /// In en, this message translates to:
  /// **'Whitelisted devices are not rate-limited; the switch applies immediately.'**
  String get bandixWhitelistBody;

  /// No description provided for @bandixWhitelistEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable whitelist'**
  String get bandixWhitelistEnabled;

  /// No description provided for @bandixAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get bandixAdd;

  /// No description provided for @bandixHostnameTitle.
  ///
  /// In en, this message translates to:
  /// **'Hostname binding'**
  String get bandixHostnameTitle;

  /// No description provided for @bandixHostnameBody.
  ///
  /// In en, this message translates to:
  /// **'Bind a display name to a device (leave empty to clear); it may take a few seconds to apply.'**
  String get bandixHostnameBody;

  /// No description provided for @bandixHostnameField.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get bandixHostnameField;

  /// No description provided for @bandixHostnameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. living-room-tv'**
  String get bandixHostnameHint;

  /// No description provided for @bandixMacRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter or pick a device MAC first.'**
  String get bandixMacRequired;

  /// No description provided for @bandixPanelNote.
  ///
  /// In en, this message translates to:
  /// **'Data comes from the bridge contract quartz.bandix (same source as the web UI); engine params (port/interface/data dir) stay on the web settings page.'**
  String get bandixPanelNote;

  /// No description provided for @bandixTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Top devices by traffic'**
  String get bandixTopTitle;

  /// No description provided for @bandixTopNote.
  ///
  /// In en, this message translates to:
  /// **'Rate = device-side WAN; Total = all traffic; share = cumulative; sorted by total (top 8); policy = whitelist/schedule/quota.'**
  String get bandixTopNote;

  /// No description provided for @bandixSummaryNote.
  ///
  /// In en, this message translates to:
  /// **'The default rate limit applies to devices without an individual limit; whitelisted devices are exempt (full rules on the web Bandix page).'**
  String get bandixSummaryNote;

  /// No description provided for @bandixDefaultLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Default rate limit'**
  String get bandixDefaultLimitLabel;

  /// No description provided for @bandixWhitelistState.
  ///
  /// In en, this message translates to:
  /// **'Whitelist'**
  String get bandixWhitelistState;

  /// No description provided for @bandixUnlimited.
  ///
  /// In en, this message translates to:
  /// **'unlimited'**
  String get bandixUnlimited;

  /// No description provided for @bandixOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get bandixOn;

  /// No description provided for @bandixOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get bandixOff;

  /// No description provided for @bandixRulesCount.
  ///
  /// In en, this message translates to:
  /// **'rules {n}'**
  String bandixRulesCount(int n);

  /// No description provided for @bandixQuotasCount.
  ///
  /// In en, this message translates to:
  /// **'quotas {n}'**
  String bandixQuotasCount(int n);

  /// No description provided for @bandixWlDevicesCount.
  ///
  /// In en, this message translates to:
  /// **'devices {n}'**
  String bandixWlDevicesCount(int n);

  /// No description provided for @bandixPolicyWhitelisted.
  ///
  /// In en, this message translates to:
  /// **'Whitelisted'**
  String get bandixPolicyWhitelisted;

  /// No description provided for @bandixPolicyLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits {n}'**
  String bandixPolicyLimits(int n);

  /// No description provided for @bandixPolicyQuota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get bandixPolicyQuota;

  /// No description provided for @bandixPolicyDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get bandixPolicyDefault;

  /// No description provided for @bandixTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bandixTotalLabel;

  /// No description provided for @navRouter.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get navRouter;

  /// No description provided for @navCellular.
  ///
  /// In en, this message translates to:
  /// **'Cellular'**
  String get navCellular;

  /// No description provided for @cellularUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Cellular data unavailable: QModem is not installed or no modem is present.'**
  String get cellularUnavailableBody;

  /// No description provided for @cellularMonthUsage.
  ///
  /// In en, this message translates to:
  /// **'This month {size}'**
  String cellularMonthUsage(String size);

  /// No description provided for @cellularSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get cellularSignal;

  /// No description provided for @cellularSignalQuality.
  ///
  /// In en, this message translates to:
  /// **'Signal quality'**
  String get cellularSignalQuality;

  /// No description provided for @cellularSignalUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Signal metrics not supported by this modem'**
  String get cellularSignalUnsupported;

  /// No description provided for @cellularQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get cellularQualityGood;

  /// No description provided for @cellularQualityFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get cellularQualityFair;

  /// No description provided for @cellularQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get cellularQualityPoor;

  /// No description provided for @cellularRsrpHistory.
  ///
  /// In en, this message translates to:
  /// **'RSRP history'**
  String get cellularRsrpHistory;

  /// No description provided for @cellularSeriesHint.
  ///
  /// In en, this message translates to:
  /// **'every {step}s · {points} points'**
  String cellularSeriesHint(String step, String points);

  /// No description provided for @cellularNetworkSim.
  ///
  /// In en, this message translates to:
  /// **'Network · SIM'**
  String get cellularNetworkSim;

  /// No description provided for @cellularServingCell.
  ///
  /// In en, this message translates to:
  /// **'Serving cell'**
  String get cellularServingCell;

  /// No description provided for @cellularSimLabel.
  ///
  /// In en, this message translates to:
  /// **'SIM'**
  String get cellularSimLabel;

  /// No description provided for @cellularSimSlot.
  ///
  /// In en, this message translates to:
  /// **'slot'**
  String get cellularSimSlot;

  /// No description provided for @cellularFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get cellularFirmware;

  /// No description provided for @cellularDial.
  ///
  /// In en, this message translates to:
  /// **'Dial-up'**
  String get cellularDial;

  /// No description provided for @cellularDialConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get cellularDialConnected;

  /// No description provided for @cellularDialDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get cellularDialDisconnected;

  /// No description provided for @cellularDialNow.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get cellularDialNow;

  /// No description provided for @cellularHang.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get cellularHang;

  /// No description provided for @cellularRedial.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get cellularRedial;

  /// No description provided for @cellularHangWarning.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting takes the modem offline; if your LAN routes through it, this device may lose connectivity.'**
  String get cellularHangWarning;

  /// No description provided for @cellularRedialWarning.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting briefly interrupts the modem link.'**
  String get cellularRedialWarning;

  /// No description provided for @cellularEntryNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get cellularEntryNetwork;

  /// No description provided for @cellularEntryAt.
  ///
  /// In en, this message translates to:
  /// **'AT debug'**
  String get cellularEntryAt;

  /// No description provided for @cellularEntryLog.
  ///
  /// In en, this message translates to:
  /// **'Dial log'**
  String get cellularEntryLog;

  /// No description provided for @cellularMoreEntriesPlanned.
  ///
  /// In en, this message translates to:
  /// **'SIM switch · SMS · Advanced are planned for later rounds'**
  String get cellularMoreEntriesPlanned;

  /// No description provided for @cellularNetworkPrefer.
  ///
  /// In en, this message translates to:
  /// **'Network preference'**
  String get cellularNetworkPrefer;

  /// No description provided for @cellularNetworkPreferHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple choices allowed; disabling a RAT forbids registering it (sent as an array).'**
  String get cellularNetworkPreferHint;

  /// No description provided for @cellularApplyPrefer.
  ///
  /// In en, this message translates to:
  /// **'Apply preference'**
  String get cellularApplyPrefer;

  /// No description provided for @cellularLockband.
  ///
  /// In en, this message translates to:
  /// **'Band lock'**
  String get cellularLockband;

  /// No description provided for @cellularLockbandUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Not locked (all bands available)'**
  String get cellularLockbandUnlocked;

  /// No description provided for @cellularLockbandHint.
  ///
  /// In en, this message translates to:
  /// **'Band lock uses vendor-specific parameters; locking a wrong band can drop the link. v1 only offers \"unlock\" — use the web UI for full locking.'**
  String get cellularLockbandHint;

  /// No description provided for @cellularLockbandUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock bands'**
  String get cellularLockbandUnlock;

  /// No description provided for @cellularAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cellularAdvanced;

  /// No description provided for @cellularUsbMode.
  ///
  /// In en, this message translates to:
  /// **'USB dial mode'**
  String get cellularUsbMode;

  /// No description provided for @cellularTemp.
  ///
  /// In en, this message translates to:
  /// **'Modem temperature'**
  String get cellularTemp;

  /// No description provided for @cellularSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Failed to read current settings; pull to refresh and retry.'**
  String get cellularSettingsHint;

  /// No description provided for @cellularDangerWarning.
  ///
  /// In en, this message translates to:
  /// **'This rewrites modem configuration and may interrupt connectivity.'**
  String get cellularDangerWarning;

  /// No description provided for @cellularAtSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get cellularAtSend;

  /// No description provided for @cellularAtPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick commands'**
  String get cellularAtPresets;

  /// No description provided for @cellularAtWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Same command surface as the web UI; use at your own risk'**
  String get cellularAtWarningTitle;

  /// No description provided for @cellularAtWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Quick commands come from the router (same source as the web UI). Any AT command is sent to the modem for real and can modify NV items, lock bands, or drop the link. Each send is confirmed and audited.'**
  String get cellularAtWarningBody;

  /// No description provided for @cellularAtConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send {at}?'**
  String cellularAtConfirmTitle(String at);

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @cellularLogHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Log comes from the modem dial script (last 100 lines)'**
  String get cellularLogHintTitle;

  /// No description provided for @cellularLogHintBody.
  ///
  /// In en, this message translates to:
  /// **'May contain carrier details and phone numbers; avoid sharing screenshots.'**
  String get cellularLogHintBody;

  /// No description provided for @cellularLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'(no log yet)'**
  String get cellularLogEmpty;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @cellularEntrySim.
  ///
  /// In en, this message translates to:
  /// **'SIM'**
  String get cellularEntrySim;

  /// No description provided for @cellularEntrySms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get cellularEntrySms;

  /// No description provided for @cellularSimNoSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'SIM switching is not supported by this modem'**
  String get cellularSimNoSwitchTitle;

  /// No description provided for @cellularSimNoSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'The modem does not expose SIM slot switching (`supportSwitch=0`); read-only.'**
  String get cellularSimNoSwitchBody;

  /// No description provided for @cellularSimStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get cellularSimStatus;

  /// No description provided for @cellularSimSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch SIM slot'**
  String get cellularSimSwitch;

  /// No description provided for @cellularSimSwitchApply.
  ///
  /// In en, this message translates to:
  /// **'Apply switch'**
  String get cellularSimSwitchApply;

  /// No description provided for @cellularSimSwitchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch to SIM {slot}?'**
  String cellularSimSwitchConfirm(String slot);

  /// No description provided for @cellularSimSwitchWarning.
  ///
  /// In en, this message translates to:
  /// **'Switching restarts the modem data path; the network drops during the switch.'**
  String get cellularSimSwitchWarning;

  /// No description provided for @cellularSmsStorage.
  ///
  /// In en, this message translates to:
  /// **'SMS storage'**
  String get cellularSmsStorage;

  /// No description provided for @cellularSmsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages stay in device memory only'**
  String get cellularSmsPrivacyTitle;

  /// No description provided for @cellularSmsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Not persisted or uploaded; cleared when you leave the page.'**
  String get cellularSmsPrivacyBody;

  /// No description provided for @cellularSmsEmpty.
  ///
  /// In en, this message translates to:
  /// **'(no messages)'**
  String get cellularSmsEmpty;

  /// No description provided for @cellularSmsCount.
  ///
  /// In en, this message translates to:
  /// **'{total} messages · {unread} unread'**
  String cellularSmsCount(String total, String unread);

  /// No description provided for @cellularSmsSentTag.
  ///
  /// In en, this message translates to:
  /// **'sent'**
  String get cellularSmsSentTag;

  /// No description provided for @cellularSmsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get cellularSmsDeleteConfirm;

  /// No description provided for @cellularSmsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cellularSmsDeleteBody;

  /// No description provided for @cellularSmsCompose.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get cellularSmsCompose;

  /// No description provided for @cellularSmsRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get cellularSmsRecipient;

  /// No description provided for @cellularSmsContent.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get cellularSmsContent;

  /// No description provided for @cellularSmsSendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get cellularSmsSendAction;

  /// No description provided for @cellularModule.
  ///
  /// In en, this message translates to:
  /// **'Modem'**
  String get cellularModule;

  /// No description provided for @cellularUsbModeSection.
  ///
  /// In en, this message translates to:
  /// **'USB dial mode'**
  String get cellularUsbModeSection;

  /// No description provided for @cellularUsbModeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enumerates the USB data path'**
  String get cellularUsbModeWarningTitle;

  /// No description provided for @cellularUsbModeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'The mode (qmi/ecm/mbim/rndis/ncm) decides how the modem exposes its data port; switching drops the current link and re-enumerates. Unrelated to 5G/4G network preference.'**
  String get cellularUsbModeWarningBody;

  /// No description provided for @cellularUsbModeApply.
  ///
  /// In en, this message translates to:
  /// **'Apply USB mode'**
  String get cellularUsbModeApply;

  /// No description provided for @cellularReboot.
  ///
  /// In en, this message translates to:
  /// **'Modem reboot'**
  String get cellularReboot;

  /// No description provided for @cellularRebootSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft reboot'**
  String get cellularRebootSoft;

  /// No description provided for @cellularRebootHard.
  ///
  /// In en, this message translates to:
  /// **'Hard reboot'**
  String get cellularRebootHard;

  /// No description provided for @cellularRebootUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This modem declares no reboot capability.'**
  String get cellularRebootUnsupported;

  /// No description provided for @cellularRebootWarning.
  ///
  /// In en, this message translates to:
  /// **'Rebooting interrupts the data link for tens of seconds.'**
  String get cellularRebootWarning;

  /// No description provided for @cellularImeiSection.
  ///
  /// In en, this message translates to:
  /// **'IMEI (sensitive)'**
  String get cellularImeiSection;

  /// No description provided for @cellularImeiWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Changing IMEI carries legal and compliance risk'**
  String get cellularImeiWarningTitle;

  /// No description provided for @cellularImeiWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Same as the web UI: the capability is not blocked; the risk is yours. Verify local regulations first — the change is audited.'**
  String get cellularImeiWarningBody;

  /// No description provided for @cellularImeiInput.
  ///
  /// In en, this message translates to:
  /// **'New IMEI (15 digits)'**
  String get cellularImeiInput;

  /// No description provided for @cellularImeiApply.
  ///
  /// In en, this message translates to:
  /// **'Write IMEI'**
  String get cellularImeiApply;

  /// No description provided for @cellularMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Statistics & logs'**
  String get cellularMaintenance;

  /// No description provided for @cellularSaveStats.
  ///
  /// In en, this message translates to:
  /// **'Save stats to NVM'**
  String get cellularSaveStats;

  /// No description provided for @cellularClearStats.
  ///
  /// In en, this message translates to:
  /// **'Clear traffic stats'**
  String get cellularClearStats;

  /// No description provided for @cellularClearDialLog.
  ///
  /// In en, this message translates to:
  /// **'Clear dial log'**
  String get cellularClearDialLog;

  /// No description provided for @cellularDisabledFeatures.
  ///
  /// In en, this message translates to:
  /// **'Disabled features: {list}'**
  String cellularDisabledFeatures(String list);

  /// No description provided for @routerGroupNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get routerGroupNetwork;

  /// No description provided for @routerGroupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get routerGroupSecurity;

  /// No description provided for @routerGroupSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get routerGroupSystem;

  /// No description provided for @routerGroupLan.
  ///
  /// In en, this message translates to:
  /// **'LAN'**
  String get routerGroupLan;

  /// No description provided for @routerEntryInterfaces.
  ///
  /// In en, this message translates to:
  /// **'Interfaces'**
  String get routerEntryInterfaces;

  /// No description provided for @routerEntryInterfacesSub.
  ///
  /// In en, this message translates to:
  /// **'Manage LAN/WAN interfaces and protocols'**
  String get routerEntryInterfacesSub;

  /// No description provided for @routerEntryWireless.
  ///
  /// In en, this message translates to:
  /// **'Wireless'**
  String get routerEntryWireless;

  /// No description provided for @routerEntryWirelessSub.
  ///
  /// In en, this message translates to:
  /// **'Radios and SSID settings'**
  String get routerEntryWirelessSub;

  /// No description provided for @routerEntryDhcp.
  ///
  /// In en, this message translates to:
  /// **'DHCP & DNS'**
  String get routerEntryDhcp;

  /// No description provided for @routerEntryDhcpSub.
  ///
  /// In en, this message translates to:
  /// **'Address pool, leases and dnsmasq'**
  String get routerEntryDhcpSub;

  /// No description provided for @routerEntryRoutes.
  ///
  /// In en, this message translates to:
  /// **'Static routes'**
  String get routerEntryRoutes;

  /// No description provided for @routerEntryRoutesSub.
  ///
  /// In en, this message translates to:
  /// **'Routes and rules'**
  String get routerEntryRoutesSub;

  /// No description provided for @routerEntryFirewall.
  ///
  /// In en, this message translates to:
  /// **'Firewall'**
  String get routerEntryFirewall;

  /// No description provided for @routerEntryFirewallSub.
  ///
  /// In en, this message translates to:
  /// **'Zones, rules and port forwarding'**
  String get routerEntryFirewallSub;

  /// No description provided for @routerEntrySystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get routerEntrySystem;

  /// No description provided for @routerEntrySystemSub.
  ///
  /// In en, this message translates to:
  /// **'Hostname, time and logs'**
  String get routerEntrySystemSub;

  /// No description provided for @routerEntryAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get routerEntryAdmin;

  /// No description provided for @routerEntryAdminSub.
  ///
  /// In en, this message translates to:
  /// **'Password and SSH'**
  String get routerEntryAdminSub;

  /// No description provided for @routerEntryInit.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get routerEntryInit;

  /// No description provided for @routerEntryInitSub.
  ///
  /// In en, this message translates to:
  /// **'Boot services and control'**
  String get routerEntryInitSub;

  /// No description provided for @routerEntryClientsSub.
  ///
  /// In en, this message translates to:
  /// **'{n} online'**
  String routerEntryClientsSub(int n);

  /// No description provided for @routerChipReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get routerChipReady;

  /// No description provided for @routerChipSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get routerChipSoon;

  /// No description provided for @routerMoreHint.
  ///
  /// In en, this message translates to:
  /// **'More router settings are coming in a later version.'**
  String get routerMoreHint;

  /// No description provided for @configSessionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Configuration session unavailable. Sign in to the router again to enable configuration.'**
  String get configSessionUnavailable;

  /// No description provided for @configForbidden.
  ///
  /// In en, this message translates to:
  /// **'This setting is not exposed.'**
  String get configForbidden;

  /// No description provided for @configBadValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid value: {detail}'**
  String configBadValue(String detail);

  /// No description provided for @configApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Apply failed: {detail}'**
  String configApplyFailed(String detail);

  /// No description provided for @configWebPending.
  ///
  /// In en, this message translates to:
  /// **'The web UI has unconfirmed changes. Confirm or roll them back there first.'**
  String get configWebPending;

  /// No description provided for @configNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes to save.'**
  String get configNoChanges;

  /// No description provided for @configDirtyChip.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get configDirtyChip;

  /// No description provided for @configSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get configSaving;

  /// No description provided for @configUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get configUnset;

  /// No description provided for @configChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get configChoose;

  /// No description provided for @configSensitiveHint.
  ///
  /// In en, this message translates to:
  /// **'Set; leave blank to keep'**
  String get configSensitiveHint;

  /// No description provided for @configSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved and confirmed.'**
  String get configSaved;

  /// No description provided for @configRollbackDone.
  ///
  /// In en, this message translates to:
  /// **'Rolled back.'**
  String get configRollbackDone;

  /// No description provided for @configAutoRolledBack.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed; rolled back automatically.'**
  String get configAutoRolledBack;

  /// No description provided for @configDangerTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm changes'**
  String get configDangerTitle;

  /// No description provided for @configDangerBody.
  ///
  /// In en, this message translates to:
  /// **'This change may interrupt this device\'s connection to the router; unconfirmed changes roll back after 90 seconds.'**
  String get configDangerBody;

  /// No description provided for @configApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm changes'**
  String get configApplyTitle;

  /// No description provided for @configApplyCountdown.
  ///
  /// In en, this message translates to:
  /// **'Auto rollback in {sec}s'**
  String configApplyCountdown(int sec);

  /// No description provided for @configApplyBody.
  ///
  /// In en, this message translates to:
  /// **'If you changed IP or wireless settings, this device may disconnect; the router will roll back automatically when the countdown ends.'**
  String get configApplyBody;

  /// No description provided for @configRollbackNow.
  ///
  /// In en, this message translates to:
  /// **'Roll back now'**
  String get configRollbackNow;

  /// No description provided for @configKeepChanges.
  ///
  /// In en, this message translates to:
  /// **'Keep changes'**
  String get configKeepChanges;

  /// No description provided for @configLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load configuration'**
  String get configLoadFailedTitle;

  /// No description provided for @configSectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This configuration section is unavailable.'**
  String get configSectionUnavailable;

  /// No description provided for @systemGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get systemGeneral;

  /// No description provided for @systemHostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get systemHostname;

  /// No description provided for @systemDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get systemDescription;

  /// No description provided for @systemTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get systemTimezone;

  /// No description provided for @systemTimezoneHint.
  ///
  /// In en, this message translates to:
  /// **'Times are interpreted by the router using the selected zone.'**
  String get systemTimezoneHint;

  /// No description provided for @systemTimezonePicker.
  ///
  /// In en, this message translates to:
  /// **'Choose time zone'**
  String get systemTimezonePicker;

  /// No description provided for @systemTimezoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search time zones'**
  String get systemTimezoneSearch;

  /// No description provided for @systemLogging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get systemLogging;

  /// No description provided for @systemLogSize.
  ///
  /// In en, this message translates to:
  /// **'Log size (KB)'**
  String get systemLogSize;

  /// No description provided for @systemLogProto.
  ///
  /// In en, this message translates to:
  /// **'Log protocol'**
  String get systemLogProto;

  /// No description provided for @systemLogIp.
  ///
  /// In en, this message translates to:
  /// **'Remote log server'**
  String get systemLogIp;

  /// No description provided for @systemLogIpHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to disable remote logging'**
  String get systemLogIpHint;

  /// No description provided for @systemLogPort.
  ///
  /// In en, this message translates to:
  /// **'Remote log port'**
  String get systemLogPort;

  /// No description provided for @systemAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get systemAdvanced;

  /// No description provided for @systemConsoleLogLevel.
  ///
  /// In en, this message translates to:
  /// **'Console log level'**
  String get systemConsoleLogLevel;

  /// No description provided for @systemCronLogLevel.
  ///
  /// In en, this message translates to:
  /// **'Cron log level'**
  String get systemCronLogLevel;

  /// No description provided for @systemTtyLogin.
  ///
  /// In en, this message translates to:
  /// **'Serial console login'**
  String get systemTtyLogin;

  /// No description provided for @initSearch.
  ///
  /// In en, this message translates to:
  /// **'Search services'**
  String get initSearch;

  /// No description provided for @initEmpty.
  ///
  /// In en, this message translates to:
  /// **'No startup services found.'**
  String get initEmpty;

  /// No description provided for @initIndex.
  ///
  /// In en, this message translates to:
  /// **'Start order {n}'**
  String initIndex(int n);

  /// No description provided for @initStopIndex.
  ///
  /// In en, this message translates to:
  /// **'Stop order {n}'**
  String initStopIndex(int n);

  /// No description provided for @initEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get initEnabled;

  /// No description provided for @initDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get initDisabled;

  /// No description provided for @initEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get initEnable;

  /// No description provided for @initDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get initDisable;

  /// No description provided for @initStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get initStart;

  /// No description provided for @initStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get initStop;

  /// No description provided for @initRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get initRestart;

  /// No description provided for @initActionDone.
  ///
  /// In en, this message translates to:
  /// **'{action} done: {name}'**
  String initActionDone(String action, String name);

  /// No description provided for @initToggleWarning.
  ///
  /// In en, this message translates to:
  /// **'If disabled, this service will not start automatically on next boot.'**
  String get initToggleWarning;

  /// No description provided for @initStopWarning.
  ///
  /// In en, this message translates to:
  /// **'Stopping or restarting this service may interrupt router functions or this device\'s connection.'**
  String get initStopWarning;

  /// No description provided for @interfaceProto.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get interfaceProto;

  /// No description provided for @interfaceDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get interfaceDevice;

  /// No description provided for @interfaceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get interfaceDisabled;

  /// No description provided for @interfaceAuto.
  ///
  /// In en, this message translates to:
  /// **'Enable on boot'**
  String get interfaceAuto;

  /// No description provided for @interfaceIpaddr.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get interfaceIpaddr;

  /// No description provided for @interfaceNetmask.
  ///
  /// In en, this message translates to:
  /// **'Netmask'**
  String get interfaceNetmask;

  /// No description provided for @interfaceGateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get interfaceGateway;

  /// No description provided for @interfaceDns.
  ///
  /// In en, this message translates to:
  /// **'DNS servers'**
  String get interfaceDns;

  /// No description provided for @interfaceDnsHint.
  ///
  /// In en, this message translates to:
  /// **'Separate multiple addresses with spaces'**
  String get interfaceDnsHint;

  /// No description provided for @interfaceIp6addr.
  ///
  /// In en, this message translates to:
  /// **'IPv6 address'**
  String get interfaceIp6addr;

  /// No description provided for @interfaceIp6Hint.
  ///
  /// In en, this message translates to:
  /// **'May be left blank'**
  String get interfaceIp6Hint;

  /// No description provided for @interfaceIp6assign.
  ///
  /// In en, this message translates to:
  /// **'IPv6 prefix size'**
  String get interfaceIp6assign;

  /// No description provided for @interfaceUsername.
  ///
  /// In en, this message translates to:
  /// **'PPPoE username'**
  String get interfaceUsername;

  /// No description provided for @interfacePassword.
  ///
  /// In en, this message translates to:
  /// **'PPPoE password'**
  String get interfacePassword;

  /// No description provided for @interfaceStatic.
  ///
  /// In en, this message translates to:
  /// **'Static address'**
  String get interfaceStatic;

  /// No description provided for @interfaceDhcpClient.
  ///
  /// In en, this message translates to:
  /// **'DHCP client'**
  String get interfaceDhcpClient;

  /// No description provided for @interfaceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get interfaceNone;

  /// No description provided for @interfacePppoe.
  ///
  /// In en, this message translates to:
  /// **'PPPoE'**
  String get interfacePppoe;

  /// No description provided for @wirelessEmpty.
  ///
  /// In en, this message translates to:
  /// **'No wireless radios detected (or wireless is disabled).'**
  String get wirelessEmpty;

  /// No description provided for @wirelessIface.
  ///
  /// In en, this message translates to:
  /// **'Wireless interface'**
  String get wirelessIface;

  /// No description provided for @wirelessDevice.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get wirelessDevice;

  /// No description provided for @wirelessMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get wirelessMode;

  /// No description provided for @wirelessEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get wirelessEncryption;

  /// No description provided for @wirelessBand.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get wirelessBand;

  /// No description provided for @wirelessChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get wirelessChannel;

  /// No description provided for @wirelessSsid.
  ///
  /// In en, this message translates to:
  /// **'SSID'**
  String get wirelessSsid;

  /// No description provided for @wirelessKey.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get wirelessKey;

  /// No description provided for @wirelessNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get wirelessNetwork;

  /// No description provided for @wirelessHidden.
  ///
  /// In en, this message translates to:
  /// **'Hide SSID'**
  String get wirelessHidden;

  /// No description provided for @wirelessIsolate.
  ///
  /// In en, this message translates to:
  /// **'Client isolation'**
  String get wirelessIsolate;

  /// No description provided for @wirelessWmm.
  ///
  /// In en, this message translates to:
  /// **'WMM'**
  String get wirelessWmm;

  /// No description provided for @wirelessHtmode.
  ///
  /// In en, this message translates to:
  /// **'HT mode'**
  String get wirelessHtmode;

  /// No description provided for @wirelessTxpower.
  ///
  /// In en, this message translates to:
  /// **'TX power (dBm)'**
  String get wirelessTxpower;

  /// No description provided for @wirelessCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get wirelessCountry;

  /// No description provided for @wirelessCellDensity.
  ///
  /// In en, this message translates to:
  /// **'Cell density'**
  String get wirelessCellDensity;

  /// No description provided for @wirelessDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance (m)'**
  String get wirelessDistance;

  /// No description provided for @dhcpEmpty.
  ///
  /// In en, this message translates to:
  /// **'No DHCP configuration found.'**
  String get dhcpEmpty;

  /// No description provided for @dhcpDnsmasq.
  ///
  /// In en, this message translates to:
  /// **'DNS & DHCP (dnsmasq)'**
  String get dhcpDnsmasq;

  /// No description provided for @dhcpServer.
  ///
  /// In en, this message translates to:
  /// **'DHCP server'**
  String get dhcpServer;

  /// No description provided for @dhcpServerHint.
  ///
  /// In en, this message translates to:
  /// **'Address pool and leases'**
  String get dhcpServerHint;

  /// No description provided for @dhcpDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get dhcpDomain;

  /// No description provided for @dhcpLocal.
  ///
  /// In en, this message translates to:
  /// **'Local domain'**
  String get dhcpLocal;

  /// No description provided for @dhcpDomainNeeded.
  ///
  /// In en, this message translates to:
  /// **'Domain required'**
  String get dhcpDomainNeeded;

  /// No description provided for @dhcpBogusPriv.
  ///
  /// In en, this message translates to:
  /// **'Filter private domains'**
  String get dhcpBogusPriv;

  /// No description provided for @dhcpAuthoritative.
  ///
  /// In en, this message translates to:
  /// **'Authoritative'**
  String get dhcpAuthoritative;

  /// No description provided for @dhcpLocalService.
  ///
  /// In en, this message translates to:
  /// **'Local service only'**
  String get dhcpLocalService;

  /// No description provided for @dhcpRebindProtection.
  ///
  /// In en, this message translates to:
  /// **'Rebind protection'**
  String get dhcpRebindProtection;

  /// No description provided for @dhcpExpandHosts.
  ///
  /// In en, this message translates to:
  /// **'Expand hosts'**
  String get dhcpExpandHosts;

  /// No description provided for @dhcpCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size'**
  String get dhcpCacheSize;

  /// No description provided for @dhcpLogQueries.
  ///
  /// In en, this message translates to:
  /// **'Log queries'**
  String get dhcpLogQueries;

  /// No description provided for @dhcpStart.
  ///
  /// In en, this message translates to:
  /// **'Start address (last octet)'**
  String get dhcpStart;

  /// No description provided for @dhcpLimit.
  ///
  /// In en, this message translates to:
  /// **'Pool size'**
  String get dhcpLimit;

  /// No description provided for @dhcpLeasetime.
  ///
  /// In en, this message translates to:
  /// **'Lease time'**
  String get dhcpLeasetime;

  /// No description provided for @dhcpIgnore.
  ///
  /// In en, this message translates to:
  /// **'Disable DHCP'**
  String get dhcpIgnore;

  /// No description provided for @dhcpDynamicDhcp.
  ///
  /// In en, this message translates to:
  /// **'Dynamic DHCP'**
  String get dhcpDynamicDhcp;

  /// No description provided for @dhcpForce.
  ///
  /// In en, this message translates to:
  /// **'Force'**
  String get dhcpForce;

  /// No description provided for @dhcpRa.
  ///
  /// In en, this message translates to:
  /// **'IPv6 RA'**
  String get dhcpRa;

  /// No description provided for @dhcpRaManagement.
  ///
  /// In en, this message translates to:
  /// **'RA management'**
  String get dhcpRaManagement;

  /// No description provided for @dhcpDhcpv6.
  ///
  /// In en, this message translates to:
  /// **'DHCPv6'**
  String get dhcpDhcpv6;

  /// No description provided for @dhcpMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get dhcpMaster;

  /// No description provided for @dhcpDnsService.
  ///
  /// In en, this message translates to:
  /// **'Advertise DNS'**
  String get dhcpDnsService;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'zh':
      return AppL10nZh();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
