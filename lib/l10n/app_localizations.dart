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
  /// **'Sorted by cumulative traffic (top 8); share = cumulative bytes share.'**
  String get bandixTopNote;

  /// No description provided for @bandixSummaryNote.
  ///
  /// In en, this message translates to:
  /// **'Values come from bandix statistics (device-side WAN totals); pull to refresh.'**
  String get bandixSummaryNote;
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
