// Localizable strings: English (default), Urdu, Pashto.
// Urdu and Pashto are RTL. Keys are stable contracts — screens import
// appStringsProvider, never hard-code user-visible text.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/settings_model.dart';

/// Currently active strings, resolved from the language setting.
final appStringsProvider = Provider<AppStrings>((Ref ref) {
  final String lang = ref.watch(settingsProvider.select((SettingsModel s) => s.language));
  switch (lang) {
    case 'ur':
      return UrStrings();
    case 'ps':
      return PsStrings();
    default:
      return EnStrings();
  }
});

/// True when the active language is RTL (Urdu, Pashto).
final isRtlProvider = Provider<bool>((Ref ref) {
  final String lang = ref.watch(settingsProvider.select((SettingsModel s) => s.language));
  return lang == 'ur' || lang == 'ps';
});

abstract class AppStrings {
  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get close;
  String get retry;
  String get done;
  String get error;
  String get share;
  String get copy;
  String get delete;
  String get back;
  String get save;
  String get show;
  String get hide;

  // Scan screen
  String get scanTab;
  String get lookingForCode;
  String detectedIn(String seconds);
  String batchModeCount(int n);
  String get modeQr;
  String get modeBarcode;
  String get modeBatch;
  String get gallery;
  String get historyTab;
  String get flashOn;
  String get flashOff;
  String get settingsTitle;
  String get scanAgain;
  String get tapToSelectCode;
  String get batchSheetTitle;
  String get exportCsv;
  String get clear;

  // Permission / camera states
  String get allowCameraTitle;
  String get allowCameraBody;
  String get allowCameraButton;
  String get openSettingsButton;
  String get scanFromGallery;
  String get noCameraTitle;
  String get noCameraBody;
  String get cameraInUseTitle;
  String get cameraInUseBody;
  String get noCodeInImage;

  // Result screen + sheet
  String get resultTitle;
  String get favorite;
  String get unfavorite;
  String get saveToList;
  String get savedToList;
  String get copiedToClipboard;
  String get expandContent;
  String get detailsTitle;
  String get formatRow;
  String get gs1CountryRow;
  String get checkDigitRow;
  String get checkDigitValid;
  String get checkDigitInvalid;
  String get scannedAtRow;
  String get wifiNetworkRow;
  String get wifiSecurityRow;
  String get wifiPasswordRow;
  String get urlFullRow;
  String get safetyNoteTitle;
  String get suspiciousLinkTitle;
  String get suspiciousLinkBody;
  String get openAnyway;
  String get passwordCopiedWifi;
  String get actionNotSupported;
  String get actionFailed;

  // Primary action labels
  String get actionOpen;
  String get actionSearch;
  String get actionConnect;
  String get actionAddContact;
  String get actionCall;
  String get actionMessage;
  String get actionCompose;
  String get actionOpenInMaps;
  String get actionAddToCalendar;

  // Result type badges
  String get kindUrl;
  String get kindWifi;
  String get kindContact;
  String get kindEmail;
  String get kindPhone;
  String get kindSms;
  String get kindGeo;
  String get kindEvent;
  String get kindProduct;
  String get kindText;

  // History
  String get historyTitle;
  String historySubtitle(int n);
  String get searchHint;
  String get filterAll;
  String get filterFavorites;
  String get filterLinks;
  String get filterBarcodes;
  String get filterWifi;
  String get today;
  String get yesterday;
  String get undo;
  String get deletedSnack;
  String selectedCount(int n);
  String get exportJson;
  String get importBackup;
  String importedCount(int n);
  String get importFailed;
  String get clearAll;
  String get clearAllTitle;
  String get clearAllBody;
  String get noHistoryTitle;
  String get noHistoryBody;
  String get noResultsBody;
  String get createdTag;
  String get shareSelected;
  String get deleteSelected;

  // Create
  String get createTab;
  String get typeText;
  String get typeLink;
  String get typeWifi;
  String get typeContact;
  String get typeEmail;
  String get typePhone;
  String get typeSms;
  String get typeLocation;
  String get labelContent;
  String get labelUrl;
  String get labelSsid;
  String get labelPassword;
  String get labelSecurity;
  String get securityWpa;
  String get securityWep;
  String get securityNone;
  String get labelHiddenNetwork;
  String get labelName;
  String get labelPhone;
  String get labelEmail;
  String get labelOrg;
  String get labelSubject;
  String get labelMessage;
  String get labelLatitude;
  String get labelLongitude;
  String get qrPreviewTitle;
  String get colorInk;
  String get colorBlue;
  String get colorGreen;
  String get contrastWarning;
  String get saveImage;
  String get imageSaved;
  String get imageSaveFailed;
  String get fieldRequired;
  String get invalidUrl;
  String get invalidEmail;
  String get invalidCoords;

  // Settings
  String get sectionScanning;
  String get vibrateOnScan;
  String get beepOnScan;
  String get continuousScan;
  String get defaultMode;
  String get flashOnDefault;
  String get hapticStrength;
  String get hapticLight;
  String get hapticMedium;
  String get hapticHeavy;
  String get sectionSafety;
  String get autoOpenLinks;
  String get showFullUrl;
  String get warnSuspicious;
  String get autoCopy;
  String get sectionHistory;
  String get saveHistory;
  String get historyLimit;
  String get limitUnlimited;
  String get keepDuplicates;
  String get sectionAppearance;
  String get theme;
  String get themeSystem;
  String get themeLight;
  String get themeDark;
  String get language;
  String get langEnglish;
  String get langUrdu;
  String get langPashto;
  String get sectionCreate;
  String get defaultEcLevel;
  String get defaultQrColor;
  String get scanFormatsTitle;
  String get sectionAbout;
  String get versionLabel;
  String get privacyNote;
  String get licensesTitle;
}

class EnStrings extends AppStrings {
  @override String get appName => 'Bolt Scan';
  @override String get ok => 'OK';
  @override String get cancel => 'Cancel';
  @override String get close => 'Close';
  @override String get retry => 'Retry';
  @override String get done => 'Done';
  @override String get error => 'Something went wrong';
  @override String get share => 'Share';
  @override String get copy => 'Copy';
  @override String get delete => 'Delete';
  @override String get back => 'Back';
  @override String get save => 'Save';
  @override String get show => 'Show';
  @override String get hide => 'Hide';

  @override String get scanTab => 'Scan';
  @override String get lookingForCode => 'Looking for a code';
  @override String detectedIn(String seconds) => 'Detected in $seconds s';
  @override String batchModeCount(int n) => 'Batch mode: $n scanned';
  @override String get modeQr => 'QR';
  @override String get modeBarcode => 'Barcode';
  @override String get modeBatch => 'Batch';
  @override String get gallery => 'Gallery';
  @override String get historyTab => 'History';
  @override String get flashOn => 'Flash on';
  @override String get flashOff => 'Flash off';
  @override String get settingsTitle => 'Settings';
  @override String get scanAgain => 'Scan again';
  @override String get tapToSelectCode => 'Tap a code to select it';
  @override String get batchSheetTitle => 'Batch scan';
  @override String get exportCsv => 'Export CSV';
  @override String get clear => 'Clear';

  @override String get allowCameraTitle => 'Camera access needed';
  @override String get allowCameraBody =>
      'Bolt Scan needs the camera to scan codes. Nothing is recorded or sent anywhere.';
  @override String get allowCameraButton => 'Allow camera';
  @override String get openSettingsButton => 'Open settings';
  @override String get scanFromGallery => 'Scan from gallery';
  @override String get noCameraTitle => 'No camera found';
  @override String get noCameraBody =>
      'This device has no usable camera. You can still scan codes from gallery images.';
  @override String get cameraInUseTitle => 'Camera is busy';
  @override String get cameraInUseBody =>
      'Another app is using the camera. Close it and try again.';
  @override String get noCodeInImage => 'No code found in this image';

  @override String get resultTitle => 'Result';
  @override String get favorite => 'Favorite';
  @override String get unfavorite => 'Unfavorite';
  @override String get saveToList => 'Save to list';
  @override String get savedToList => 'Saved to list';
  @override String get copiedToClipboard => 'Copied to clipboard';
  @override String get expandContent => 'Show full content';
  @override String get detailsTitle => 'Details';
  @override String get formatRow => 'Format';
  @override String get gs1CountryRow => 'Country';
  @override String get checkDigitRow => 'Check digit';
  @override String get checkDigitValid => 'valid';
  @override String get checkDigitInvalid => 'invalid';
  @override String get scannedAtRow => 'Scanned';
  @override String get wifiNetworkRow => 'Network';
  @override String get wifiSecurityRow => 'Security';
  @override String get wifiPasswordRow => 'Password';
  @override String get urlFullRow => 'Full URL';
  @override String get safetyNoteTitle => 'Safety';
  @override String get suspiciousLinkTitle => 'Suspicious link';
  @override String get suspiciousLinkBody =>
      'This link looks suspicious. Open it only if you trust the source.';
  @override String get openAnyway => 'Open anyway';
  @override String get passwordCopiedWifi =>
      'Password copied. Paste it in Wi-Fi settings.';
  @override String get actionNotSupported => 'No app on this device can do that';
  @override String get actionFailed => 'Could not complete that action';

  @override String get actionOpen => 'Open';
  @override String get actionSearch => 'Search';
  @override String get actionConnect => 'Connect';
  @override String get actionAddContact => 'Add contact';
  @override String get actionCall => 'Call';
  @override String get actionMessage => 'Message';
  @override String get actionCompose => 'Compose';
  @override String get actionOpenInMaps => 'Open in Maps';
  @override String get actionAddToCalendar => 'Add to calendar';

  @override String get kindUrl => 'URL';
  @override String get kindWifi => 'WIFI';
  @override String get kindContact => 'CONTACT';
  @override String get kindEmail => 'EMAIL';
  @override String get kindPhone => 'PHONE';
  @override String get kindSms => 'SMS';
  @override String get kindGeo => 'LOCATION';
  @override String get kindEvent => 'EVENT';
  @override String get kindProduct => 'PRODUCT';
  @override String get kindText => 'TEXT';

  @override String get historyTitle => 'History';
  @override String historySubtitle(int n) =>
      '$n scans, stored only on this phone';
  @override String get searchHint => 'Search scans';
  @override String get filterAll => 'All';
  @override String get filterFavorites => 'Favorites';
  @override String get filterLinks => 'Links';
  @override String get filterBarcodes => 'Barcodes';
  @override String get filterWifi => 'Wi-Fi';
  @override String get today => 'Today';
  @override String get yesterday => 'Yesterday';
  @override String get undo => 'Undo';
  @override String get deletedSnack => 'Deleted';
  @override String selectedCount(int n) => '$n selected';
  @override String get exportJson => 'Export JSON';
  @override String get importBackup => 'Import backup';
  @override String importedCount(int n) => 'Imported $n scans';
  @override String get importFailed => 'Could not read that backup file';
  @override String get clearAll => 'Clear all';
  @override String get clearAllTitle => 'Clear all history?';
  @override String get clearAllBody =>
      'This permanently deletes every scan on this phone.';
  @override String get noHistoryTitle => 'No scans yet';
  @override String get noHistoryBody =>
      'Point the camera at any QR code or barcode and it scans by itself.';
  @override String get noResultsBody => 'Nothing matches your search.';
  @override String get createdTag => 'Created';
  @override String get shareSelected => 'Share selected';
  @override String get deleteSelected => 'Delete selected';

  @override String get createTab => 'Create';
  @override String get typeText => 'Text';
  @override String get typeLink => 'Link';
  @override String get typeWifi => 'Wi-Fi';
  @override String get typeContact => 'Contact';
  @override String get typeEmail => 'Email';
  @override String get typePhone => 'Phone';
  @override String get typeSms => 'SMS';
  @override String get typeLocation => 'Location';
  @override String get labelContent => 'Content';
  @override String get labelUrl => 'Link (https://…)';
  @override String get labelSsid => 'Network name';
  @override String get labelPassword => 'Password';
  @override String get labelSecurity => 'Security';
  @override String get securityWpa => 'WPA/WPA2';
  @override String get securityWep => 'WEP';
  @override String get securityNone => 'None (open)';
  @override String get labelHiddenNetwork => 'Hidden network';
  @override String get labelName => 'Name';
  @override String get labelPhone => 'Phone';
  @override String get labelEmail => 'Email';
  @override String get labelOrg => 'Organization';
  @override String get labelSubject => 'Subject';
  @override String get labelMessage => 'Message';
  @override String get labelLatitude => 'Latitude';
  @override String get labelLongitude => 'Longitude';
  @override String get qrPreviewTitle => 'Preview';
  @override String get colorInk => 'Ink';
  @override String get colorBlue => 'Blue';
  @override String get colorGreen => 'Green';
  @override String get contrastWarning =>
      'This color is very light and may be hard to scan. Prefer ink or blue.';
  @override String get saveImage => 'Save image';
  @override String get imageSaved => 'QR image saved to gallery';
  @override String get imageSaveFailed => 'Could not save the image';
  @override String get fieldRequired => 'This field is required';
  @override String get invalidUrl => 'Enter a valid link, e.g. https://example.com';
  @override String get invalidEmail => 'Enter a valid email address';
  @override String get invalidCoords => 'Enter valid latitude/longitude numbers';

  @override String get sectionScanning => 'Scanning';
  @override String get vibrateOnScan => 'Vibrate on scan';
  @override String get beepOnScan => 'Beep on scan';
  @override String get continuousScan => 'Keep scanning after result';
  @override String get defaultMode => 'Default mode';
  @override String get flashOnDefault => 'Flash on by default';
  @override String get hapticStrength => 'Haptic strength';
  @override String get hapticLight => 'Light';
  @override String get hapticMedium => 'Medium';
  @override String get hapticHeavy => 'Heavy';
  @override String get sectionSafety => 'Safety';
  @override String get autoOpenLinks => 'Open links automatically';
  @override String get showFullUrl => 'Always show the full URL before opening';
  @override String get warnSuspicious => 'Warn about suspicious links';
  @override String get autoCopy => 'Copy result to clipboard automatically';
  @override String get sectionHistory => 'History';
  @override String get saveHistory => 'Save scan history';
  @override String get historyLimit => 'History limit';
  @override String get limitUnlimited => 'Unlimited';
  @override String get keepDuplicates => 'Keep duplicate scans';
  @override String get sectionAppearance => 'Appearance';
  @override String get theme => 'Theme';
  @override String get themeSystem => 'System';
  @override String get themeLight => 'Light';
  @override String get themeDark => 'Dark';
  @override String get language => 'Language';
  @override String get langEnglish => 'English';
  @override String get langUrdu => 'Urdu';
  @override String get langPashto => 'Pashto';
  @override String get sectionCreate => 'Create';
  @override String get defaultEcLevel => 'Default error correction';
  @override String get defaultQrColor => 'Default QR color';
  @override String get scanFormatsTitle => 'Scan formats';
  @override String get sectionAbout => 'About';
  @override String get versionLabel => 'Version';
  @override String get privacyNote => 'Everything stays on your phone.';
  @override String get licensesTitle => 'Open-source licenses';
}

class UrStrings extends AppStrings {
  @override String get appName => 'بولٹ اسکین';
  @override String get ok => 'ٹھیک ہے';
  @override String get cancel => 'منسوخ کریں';
  @override String get close => 'بند کریں';
  @override String get retry => 'دوبارہ کوشش کریں';
  @override String get done => 'ہو گیا';
  @override String get error => 'کچھ غلط ہو گیا';
  @override String get share => 'شیئر کریں';
  @override String get copy => 'کاپی کریں';
  @override String get delete => 'حذف کریں';
  @override String get back => 'واپس';
  @override String get save => 'محفوظ کریں';
  @override String get show => 'دکھائیں';
  @override String get hide => 'چھپائیں';

  @override String get scanTab => 'اسکین';
  @override String get lookingForCode => 'کوڈ تلاش کیا جا رہا ہے';
  @override String detectedIn(String seconds) => '$seconds سیکنڈ میں ملا';
  @override String batchModeCount(int n) => 'بیچ موڈ: $n اسکین ہوئے';
  @override String get modeQr => 'QR';
  @override String get modeBarcode => 'بارکوڈ';
  @override String get modeBatch => 'بیچ';
  @override String get gallery => 'گیلری';
  @override String get historyTab => 'ہسٹری';
  @override String get flashOn => 'فلیش آن';
  @override String get flashOff => 'فلیش آف';
  @override String get settingsTitle => 'ترتیبات';
  @override String get scanAgain => 'دوبارہ اسکین کریں';
  @override String get tapToSelectCode => 'منتخب کرنے کے لیے کوڈ پر ٹیپ کریں';
  @override String get batchSheetTitle => 'بیچ اسکین';
  @override String get exportCsv => 'CSV ایکسپورٹ کریں';
  @override String get clear => 'صاف کریں';

  @override String get allowCameraTitle => 'کیمرے کی اجازت درکار ہے';
  @override String get allowCameraBody =>
      'بولٹ اسکین کو کوڈ اسکین کرنے کے لیے کیمرہ چاہیے۔ کچھ بھی ریکارڈ یا بھیجا نہیں جاتا۔';
  @override String get allowCameraButton => 'کیمرے کی اجازت دیں';
  @override String get openSettingsButton => 'ترتیبات کھولیں';
  @override String get scanFromGallery => 'گیلری سے اسکین کریں';
  @override String get noCameraTitle => 'کوئی کیمرہ نہیں ملا';
  @override String get noCameraBody =>
      'اس ڈیوائس میں کوئی قابلِ استعمال کیمرہ نہیں ہے۔ آپ گیلری کی تصاویر سے اسکین کر سکتے ہیں۔';
  @override String get cameraInUseTitle => 'کیمرہ مصروف ہے';
  @override String get cameraInUseBody =>
      'کوئی اور ایپ کیمرہ استعمال کر رہی ہے۔ اسے بند کر کے دوبارہ کوشش کریں۔';
  @override String get noCodeInImage => 'اس تصویر میں کوئی کوڈ نہیں ملا';

  @override String get resultTitle => 'نتیجہ';
  @override String get favorite => 'پسندیدہ';
  @override String get unfavorite => 'پسندیدہ سے ہٹائیں';
  @override String get saveToList => 'فہرست میں محفوظ کریں';
  @override String get savedToList => 'فہرست میں محفوظ ہو گیا';
  @override String get copiedToClipboard => 'کلپ بورڈ میں کاپی ہو گیا';
  @override String get expandContent => 'مکمل مواد دکھائیں';
  @override String get detailsTitle => 'تفصیلات';
  @override String get formatRow => 'فارمیٹ';
  @override String get gs1CountryRow => 'ملک';
  @override String get checkDigitRow => 'چیک ڈیجٹ';
  @override String get checkDigitValid => 'درست';
  @override String get checkDigitInvalid => 'غلط';
  @override String get scannedAtRow => 'اسکین کا وقت';
  @override String get wifiNetworkRow => 'نیٹ ورک';
  @override String get wifiSecurityRow => 'سیکیورٹی';
  @override String get wifiPasswordRow => 'پاس ورڈ';
  @override String get urlFullRow => 'مکمل لنک';
  @override String get safetyNoteTitle => 'حفاظت';
  @override String get suspiciousLinkTitle => 'مشکوک لنک';
  @override String get suspiciousLinkBody =>
      'یہ لنک مشکوک لگ رہا ہے۔ صرف اس صورت میں کھولیں جب آپ ذریعے پر بھروسہ کرتے ہوں۔';
  @override String get openAnyway => 'بہرحال کھولیں';
  @override String get passwordCopiedWifi =>
      'پاس ورڈ کاپی ہو گیا۔ وائی فائی ترتیبات میں پیسٹ کریں۔';
  @override String get actionNotSupported => 'اس ڈیوائس میں کوئی ایپ یہ نہیں کر سکتی';
  @override String get actionFailed => 'یہ عمل مکمل نہ ہو سکا';

  @override String get actionOpen => 'کھولیں';
  @override String get actionSearch => 'تلاش کریں';
  @override String get actionConnect => 'کنیکٹ کریں';
  @override String get actionAddContact => 'رابطہ شامل کریں';
  @override String get actionCall => 'کال کریں';
  @override String get actionMessage => 'پیغام بھیجیں';
  @override String get actionCompose => 'لکھیں';
  @override String get actionOpenInMaps => 'نقشے میں کھولیں';
  @override String get actionAddToCalendar => 'کیلنڈر میں شامل کریں';

  @override String get kindUrl => 'لنک';
  @override String get kindWifi => 'وائی فائی';
  @override String get kindContact => 'رابطہ';
  @override String get kindEmail => 'ای میل';
  @override String get kindPhone => 'فون';
  @override String get kindSms => 'ایس ایم ایس';
  @override String get kindGeo => 'مقام';
  @override String get kindEvent => 'ایونٹ';
  @override String get kindProduct => 'پروڈکٹ';
  @override String get kindText => 'متن';

  @override String get historyTitle => 'ہسٹری';
  @override String historySubtitle(int n) => '$n اسکین، صرف اس فون میں محفوظ';
  @override String get searchHint => 'اسکین تلاش کریں';
  @override String get filterAll => 'تمام';
  @override String get filterFavorites => 'پسندیدہ';
  @override String get filterLinks => 'لنکس';
  @override String get filterBarcodes => 'بارکوڈز';
  @override String get filterWifi => 'وائی فائی';
  @override String get today => 'آج';
  @override String get yesterday => 'کل';
  @override String get undo => 'واپس لیں';
  @override String get deletedSnack => 'حذف ہو گیا';
  @override String selectedCount(int n) => '$n منتخب';
  @override String get exportJson => 'JSON ایکسپورٹ کریں';
  @override String get importBackup => 'بیک اپ درآمد کریں';
  @override String importedCount(int n) => '$n اسکین درآمد ہوئے';
  @override String get importFailed => 'بیک اپ فائل پڑھی نہ جا سکی';
  @override String get clearAll => 'سب صاف کریں';
  @override String get clearAllTitle => 'کیا تمام ہسٹری صاف کر دی جائے؟';
  @override String get clearAllBody =>
      'اس سے اس فون کے تمام اسکین مستقل طور پر حذف ہو جائیں گے۔';
  @override String get noHistoryTitle => 'ابھی کوئی اسکین نہیں';
  @override String get noHistoryBody =>
      'کیمرہ کسی QR کوڈ یا بارکوڈ کی طرف کریں، یہ خود بخود اسکین کر لے گا۔';
  @override String get noResultsBody => 'آپ کی تلاش سے کچھ نہیں ملا۔';
  @override String get createdTag => 'بنایا گیا';
  @override String get shareSelected => 'منتخب شیئر کریں';
  @override String get deleteSelected => 'منتخب حذف کریں';

  @override String get createTab => 'بنائیں';
  @override String get typeText => 'متن';
  @override String get typeLink => 'لنک';
  @override String get typeWifi => 'وائی فائی';
  @override String get typeContact => 'رابطہ';
  @override String get typeEmail => 'ای میل';
  @override String get typePhone => 'فون';
  @override String get typeSms => 'ایس ایم ایس';
  @override String get typeLocation => 'مقام';
  @override String get labelContent => 'مواد';
  @override String get labelUrl => 'لنک (https://…)';
  @override String get labelSsid => 'نیٹ ورک کا نام';
  @override String get labelPassword => 'پاس ورڈ';
  @override String get labelSecurity => 'سیکیورٹی';
  @override String get securityWpa => 'WPA/WPA2';
  @override String get securityWep => 'WEP';
  @override String get securityNone => 'کوئی نہیں (اوپن)';
  @override String get labelHiddenNetwork => 'چھپا ہوا نیٹ ورک';
  @override String get labelName => 'نام';
  @override String get labelPhone => 'فون';
  @override String get labelEmail => 'ای میل';
  @override String get labelOrg => 'ادارہ';
  @override String get labelSubject => 'موضوع';
  @override String get labelMessage => 'پیغام';
  @override String get labelLatitude => 'عرض بلد';
  @override String get labelLongitude => 'طول بلد';
  @override String get qrPreviewTitle => 'پیش نظارہ';
  @override String get colorInk => 'سیاہی';
  @override String get colorBlue => 'نیلا';
  @override String get colorGreen => 'سبز';
  @override String get contrastWarning =>
      'یہ رنگ بہت ہلکا ہے اور اسکین کرنا مشکل ہو سکتا ہے۔ سیاہی یا نیلا بہتر ہے۔';
  @override String get saveImage => 'تصویر محفوظ کریں';
  @override String get imageSaved => 'QR تصویر گیلری میں محفوظ ہو گئی';
  @override String get imageSaveFailed => 'تصویر محفوظ نہ ہو سکی';
  @override String get fieldRequired => 'یہ خانہ ضروری ہے';
  @override String get invalidUrl => 'درست لنک لکھیں، مثلاً https://example.com';
  @override String get invalidEmail => 'درست ای میل ایڈریس لکھیں';
  @override String get invalidCoords => 'درست عرض بلد/طول بلد نمبر لکھیں';

  @override String get sectionScanning => 'اسکیننگ';
  @override String get vibrateOnScan => 'اسکین پر وائبریشن';
  @override String get beepOnScan => 'اسکین پر بیپ';
  @override String get continuousScan => 'نتیجے کے بعد اسکین جاری رکھیں';
  @override String get defaultMode => 'ڈیفالٹ موڈ';
  @override String get flashOnDefault => 'فلیش بطور ڈیفالٹ آن';
  @override String get hapticStrength => 'وائبریشن کی شدت';
  @override String get hapticLight => 'ہلکی';
  @override String get hapticMedium => 'درمیانی';
  @override String get hapticHeavy => 'تیز';
  @override String get sectionSafety => 'حفاظت';
  @override String get autoOpenLinks => 'لنکس خودکار طور پر کھولیں';
  @override String get showFullUrl => 'کھولنے سے پہلے ہمیشہ مکمل لنک دکھائیں';
  @override String get warnSuspicious => 'مشکوک لنکس کے بارے میں خبردار کریں';
  @override String get autoCopy => 'نتیجہ خودکار طور پر کاپی کریں';
  @override String get sectionHistory => 'ہسٹری';
  @override String get saveHistory => 'اسکین ہسٹری محفوظ کریں';
  @override String get historyLimit => 'ہسٹری کی حد';
  @override String get limitUnlimited => 'لامحدود';
  @override String get keepDuplicates => 'دہرے اسکین رکھیں';
  @override String get sectionAppearance => 'ظاہری شکل';
  @override String get theme => 'تھیم';
  @override String get themeSystem => 'سسٹم';
  @override String get themeLight => 'روشن';
  @override String get themeDark => 'تاریک';
  @override String get language => 'زبان';
  @override String get langEnglish => 'انگریزی';
  @override String get langUrdu => 'اردو';
  @override String get langPashto => 'پشتو';
  @override String get sectionCreate => 'بنائیں';
  @override String get defaultEcLevel => 'ڈیفالٹ ایرر کریکشن';
  @override String get defaultQrColor => 'ڈیفالٹ QR رنگ';
  @override String get scanFormatsTitle => 'اسکین فارمیٹس';
  @override String get sectionAbout => 'متعلق';
  @override String get versionLabel => 'ورژن';
  @override String get privacyNote => 'سب کچھ آپ کے فون میں رہتا ہے۔';
  @override String get licensesTitle => 'اوپن سورس لائسنسز';
}

class PsStrings extends AppStrings {
  @override String get appName => 'بولټ سکین';
  @override String get ok => 'سمه ده';
  @override String get cancel => 'لغوه کړئ';
  @override String get close => 'بند کړئ';
  @override String get retry => 'بیا هڅه وکړئ';
  @override String get done => 'ترسره شو';
  @override String get error => 'یو څه غلط شول';
  @override String get share => 'شریک کړئ';
  @override String get copy => 'کاپي کړئ';
  @override String get delete => 'ړنګ کړئ';
  @override String get back => 'شاته';
  @override String get save => 'خوندي کړئ';
  @override String get show => 'وښایاست';
  @override String get hide => 'پټ کړئ';

  @override String get scanTab => 'سکین';
  @override String get lookingForCode => 'د کوډ لټون روان دی';
  @override String detectedIn(String seconds) => 'په $seconds ثانیو کې وموندل شو';
  @override String batchModeCount(int n) => 'بېچ حالت: $n سکین شوي';
  @override String get modeQr => 'QR';
  @override String get modeBarcode => 'بارکوډ';
  @override String get modeBatch => 'بېچ';
  @override String get gallery => 'ګالري';
  @override String get historyTab => 'تاریخچه';
  @override String get flashOn => 'فلش روښانه';
  @override String get flashOff => 'فلش مړ';
  @override String get settingsTitle => 'ترتیبات';
  @override String get scanAgain => 'بیا سکین کړئ';
  @override String get tapToSelectCode => 'د ټاکلو لپاره په کوډ ټېپ کړئ';
  @override String get batchSheetTitle => 'بېچ سکین';
  @override String get exportCsv => 'CSV صادر کړئ';
  @override String get clear => 'پاک کړئ';

  @override String get allowCameraTitle => 'کیمرې ته لاسرسی پکار دی';
  @override String get allowCameraBody =>
      'بولټ سکین د کوډونو سکین لپاره کیمرې ته اړتیا لري. هیڅ شی نه ثبتېږي او نه لېږل کېږي.';
  @override String get allowCameraButton => 'کیمرې ته اجازه ورکړئ';
  @override String get openSettingsButton => 'ترتیبات خلاص کړئ';
  @override String get scanFromGallery => 'له ګالرۍ څخه سکین کړئ';
  @override String get noCameraTitle => 'کیمره ونه موندل شوه';
  @override String get noCameraBody =>
      'په دې وسیله کې د کار وړ کیمره نشته. تاسو کولای شئ له ګالرۍ انځورونو څخه سکین وکړئ.';
  @override String get cameraInUseTitle => 'کیمره بوخته ده';
  @override String get cameraInUseBody =>
      'بل اپ کیمره کاروي. هغه وتړئ او بیا هڅه وکړئ.';
  @override String get noCodeInImage => 'په دې انځور کې کوډ ونه موندل شو';

  @override String get resultTitle => 'پایله';
  @override String get favorite => 'خوښ';
  @override String get unfavorite => 'له خوښو لرې کړئ';
  @override String get saveToList => 'په لېست کې خوندي کړئ';
  @override String get savedToList => 'په لېست کې خوندي شو';
  @override String get copiedToClipboard => 'کلپ بورډ ته کاپي شو';
  @override String get expandContent => 'بشپړ متن وښایاست';
  @override String get detailsTitle => 'جزئیات';
  @override String get formatRow => 'بڼه';
  @override String get gs1CountryRow => 'هېواد';
  @override String get checkDigitRow => 'کتنه شمېره';
  @override String get checkDigitValid => 'سمه ده';
  @override String get checkDigitInvalid => 'غلطه ده';
  @override String get scannedAtRow => 'د سکین وخت';
  @override String get wifiNetworkRow => 'شبکه';
  @override String get wifiSecurityRow => 'امنیت';
  @override String get wifiPasswordRow => 'پټنوم';
  @override String get urlFullRow => 'بشپړ تړونی';
  @override String get safetyNoteTitle => 'خوندیتوب';
  @override String get suspiciousLinkTitle => 'مشکوک تړونی';
  @override String get suspiciousLinkBody =>
      'دا تړونی مشکوک ښکاري. یوازې هغه مهال یې خلاص کړئ چې سرچینې باور لرئ.';
  @override String get openAnyway => 'بیا هم خلاص کړئ';
  @override String get passwordCopiedWifi =>
      'پټنوم کاپي شو. د وای فای په ترتیباتو کې یې ولګوئ.';
  @override String get actionNotSupported => 'په دې وسیله کې هیڅ اپ دا نشي کولای';
  @override String get actionFailed => 'دا کړنه ترسره نه شوه';

  @override String get actionOpen => 'خلاص کړئ';
  @override String get actionSearch => 'لټون وکړئ';
  @override String get actionConnect => 'وصل کړئ';
  @override String get actionAddContact => 'اړیکه ورزیاته کړئ';
  @override String get actionCall => 'اړیکه ونیسئ';
  @override String get actionMessage => 'پیغام ولېږئ';
  @override String get actionCompose => 'ولیقئ';
  @override String get actionOpenInMaps => 'په نقشه کې خلاص کړئ';
  @override String get actionAddToCalendar => 'کلیزې ته ورزیاته کړئ';

  @override String get kindUrl => 'تړونی';
  @override String get kindWifi => 'وای فای';
  @override String get kindContact => 'اړیکه';
  @override String get kindEmail => 'بریښنالیک';
  @override String get kindPhone => 'ټېلېفون';
  @override String get kindSms => 'SMS';
  @override String get kindGeo => 'ځای';
  @override String get kindEvent => 'پېښه';
  @override String get kindProduct => 'تولید';
  @override String get kindText => 'متن';

  @override String get historyTitle => 'تاریخچه';
  @override String historySubtitle(int n) => '$n سکین، یوازې په دې ټېلېفون کې خوندي';
  @override String get searchHint => 'سکینونه ولټوئ';
  @override String get filterAll => 'ټول';
  @override String get filterFavorites => 'خوښ';
  @override String get filterLinks => 'تړوني';
  @override String get filterBarcodes => 'بارکوډونه';
  @override String get filterWifi => 'وای فای';
  @override String get today => 'نن';
  @override String get yesterday => 'پرون';
  @override String get undo => 'بېرته واخلئ';
  @override String get deletedSnack => 'ړنګ شو';
  @override String selectedCount(int n) => '$n ټاکل شوي';
  @override String get exportJson => 'JSON صادر کړئ';
  @override String get importBackup => 'بېک اپ راوارد کړئ';
  @override String importedCount(int n) => '$n سکینونه راوارد شول';
  @override String get importFailed => 'د بېک اپ فایل ونه لوستل شو';
  @override String get clearAll => 'ټول پاک کړئ';
  @override String get clearAllTitle => 'ټوله تاریخچه پاکه شي؟';
  @override String get clearAllBody =>
      'دا به په دې ټېلېفون کې ټول سکینونه تل لپاره ړنګ کړي.';
  @override String get noHistoryTitle => 'تر اوسه هیڅ سکین نشته';
  @override String get noHistoryBody =>
      'کیمره هر QR کوډ یا بارکوډ ته ونیسئ، دا به یې په خپله سکین کړي.';
  @override String get noResultsBody => 'ستاسو له لټون سره هیڅ شی برابر نه شو.';
  @override String get createdTag => 'جوړ شوی';
  @override String get shareSelected => 'ټاکل شوي شریک کړئ';
  @override String get deleteSelected => 'ټاکل شوي ړنګ کړئ';

  @override String get createTab => 'جوړ کړئ';
  @override String get typeText => 'متن';
  @override String get typeLink => 'تړونی';
  @override String get typeWifi => 'وای فای';
  @override String get typeContact => 'اړیکه';
  @override String get typeEmail => 'بریښنالیک';
  @override String get typePhone => 'ټېلېفون';
  @override String get typeSms => 'SMS';
  @override String get typeLocation => 'ځای';
  @override String get labelContent => 'منځپانګه';
  @override String get labelUrl => 'تړونی (https://…)';
  @override String get labelSsid => 'د شبکې نوم';
  @override String get labelPassword => 'پټنوم';
  @override String get labelSecurity => 'امنیت';
  @override String get securityWpa => 'WPA/WPA2';
  @override String get securityWep => 'WEP';
  @override String get securityNone => 'هیڅ (خلاص)';
  @override String get labelHiddenNetwork => 'پټه شبکه';
  @override String get labelName => 'نوم';
  @override String get labelPhone => 'ټېلېفون';
  @override String get labelEmail => 'بریښنالیک';
  @override String get labelOrg => 'اداره';
  @override String get labelSubject => 'موضوع';
  @override String get labelMessage => 'پیغام';
  @override String get labelLatitude => 'عرض البلد';
  @override String get labelLongitude => 'طول البلد';
  @override String get qrPreviewTitle => 'مخکتنه';
  @override String get colorInk => 'رنګ';
  @override String get colorBlue => 'آبي';
  @override String get colorGreen => 'شنه';
  @override String get contrastWarning =>
      'دا رنګ ډېر روښانه دی او سکین کېدل یې ستونزمن کېدای شي. رنګ یا آبي غوره کړئ.';
  @override String get saveImage => 'انځور خوندي کړئ';
  @override String get imageSaved => 'د QR انځور په ګالرۍ کې خوندي شو';
  @override String get imageSaveFailed => 'انځور خوندي نه شو';
  @override String get fieldRequired => 'دا برخه اړینه ده';
  @override String get invalidUrl => 'سم تړونی ولیقئ، لکه https://example.com';
  @override String get invalidEmail => 'سم بریښنالیک ولیقئ';
  @override String get invalidCoords => 'سمې عرض البلد/طول البلد شمېرې ولیقئ';

  @override String get sectionScanning => 'سکین کول';
  @override String get vibrateOnScan => 'په سکین کې خوځېدل';
  @override String get beepOnScan => 'په سکین کې غږ';
  @override String get continuousScan => 'له پایلې وروسته سکین ته دوام ورکړئ';
  @override String get defaultMode => 'ټاکلی حالت';
  @override String get flashOnDefault => 'فلش په ډیفالټ روښانه';
  @override String get hapticStrength => 'د خوځېدو ځواک';
  @override String get hapticLight => 'سپک';
  @override String get hapticMedium => 'منځنی';
  @override String get hapticHeavy => 'درېدلی';
  @override String get sectionSafety => 'خوندیتوب';
  @override String get autoOpenLinks => 'تړوني په اتومات ډول خلاص کړئ';
  @override String get showFullUrl => 'تر خلاصولو مخکې تل بشپړ تړونی وښایاست';
  @override String get warnSuspicious => 'له مشکوکو تړونیو څخه خبرداری ورکړئ';
  @override String get autoCopy => 'پایله په اتومات ډول کاپي کړئ';
  @override String get sectionHistory => 'تاریخچه';
  @override String get saveHistory => 'د سکین تاریخچه خوندي کړئ';
  @override String get historyLimit => 'د تاریخچې محدودیت';
  @override String get limitUnlimited => 'لامحدود';
  @override String get keepDuplicates => 'نقل سکینونه وساتئ';
  @override String get sectionAppearance => 'بڼه';
  @override String get theme => 'بڼه';
  @override String get themeSystem => 'سیسټم';
  @override String get themeLight => 'روښانه';
  @override String get themeDark => 'تور';
  @override String get language => 'ژبه';
  @override String get langEnglish => 'انګلیسي';
  @override String get langUrdu => 'اردو';
  @override String get langPashto => 'پښتو';
  @override String get sectionCreate => 'جوړول';
  @override String get defaultEcLevel => 'ټاکلی تېروتنه سمون';
  @override String get defaultQrColor => 'ټاکلی QR رنګ';
  @override String get scanFormatsTitle => 'د سکین بڼې';
  @override String get sectionAbout => 'په اړه';
  @override String get versionLabel => 'بڼه';
  @override String get privacyNote => 'هر څه ستاسو په ټېلېفون کې پاتې کېږي.';
  @override String get licensesTitle => 'د خلاص سرچینې جوازونه';
}
