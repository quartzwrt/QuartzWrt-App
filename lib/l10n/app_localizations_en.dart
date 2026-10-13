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
  String get notConnectedTitle => 'No router connected';

  @override
  String get notConnectedBody =>
      'Discover QuartzWrt routers on your local network, or add one by address.';

  @override
  String get actionScan => 'Scan network';

  @override
  String get actionAddByAddress => 'Add by address';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutBody => 'QuartzWrt companion app';
}
