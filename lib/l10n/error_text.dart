// PairException 机器码 → 本地化文案（配对与远程地址测试共用）。
import '../auth/pairing.dart';
import 'app_localizations.dart';

String pairErrorText(AppL10n l10n, PairException e) => switch (e.code) {
  'invalid_credentials' => l10n.errInvalidCredentials,
  'rate_limited' => l10n.errRateLimited(300),
  'password_not_set' => l10n.errPasswordNotSet,
  'fingerprint_mismatch' => l10n.errFingerprintMismatch,
  'bad_certificate' => l10n.errBadCert,
  'timeout' => l10n.errTimeout,
  _ => l10n.errConnect,
};
