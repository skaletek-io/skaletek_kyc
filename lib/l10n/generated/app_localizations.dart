import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('es'),
    Locale('fr'),
  ];

  /// Title for exit verification dialog
  ///
  /// In en, this message translates to:
  /// **'Exit Verification?'**
  String get exitVerificationTitle;

  /// Message for exit verification dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the verification process? Your progress will be lost.'**
  String get exitVerificationMessage;

  /// Exit button text
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Generic greeting when no user name is available
  ///
  /// In en, this message translates to:
  /// **'Hey there!'**
  String get greetingGeneric;

  /// Personalized greeting with user's name
  ///
  /// In en, this message translates to:
  /// **'Hey {firstName} {lastName}!'**
  String greetingPersonalized(String firstName, String lastName);

  /// Main instruction for document upload
  ///
  /// In en, this message translates to:
  /// **'Get ready to upload your ID'**
  String get getReadyToUploadId;

  /// Warning title for photosensitive users
  ///
  /// In en, this message translates to:
  /// **'Photosensitivity Warning'**
  String get photosensitivityWarning;

  /// Message about camera requirement
  ///
  /// In en, this message translates to:
  /// **'We will require you have a working camera.'**
  String get cameraRequiredMessage;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// French language name
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// Spanish language name
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Go back button text
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// Button text to start liveness check
  ///
  /// In en, this message translates to:
  /// **'Start liveness check'**
  String get startLivenessCheck;

  /// Loading message when creating session
  ///
  /// In en, this message translates to:
  /// **'Creating session...'**
  String get creatingSession;

  /// Instruction for starting liveness check
  ///
  /// In en, this message translates to:
  /// **'Click to Start liveness check'**
  String get clickToStartLivenessCheck;

  /// Label for front side of document
  ///
  /// In en, this message translates to:
  /// **'Front view'**
  String get frontView;

  /// Label for back side of document
  ///
  /// In en, this message translates to:
  /// **'Back view'**
  String get backView;

  /// Error message when front document is missing
  ///
  /// In en, this message translates to:
  /// **'Please select a front document'**
  String get pleaseSelectFrontDocument;

  /// Error message when back document is missing
  ///
  /// In en, this message translates to:
  /// **'Please select a back document'**
  String get pleaseSelectBackDocument;

  /// Error when image file is too large
  ///
  /// In en, this message translates to:
  /// **'Image size exceeds the maximum allowed size'**
  String get imageSizeExceedsMaximum;

  /// Error when image selection fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(String error);

  /// Error when document type is invalid
  ///
  /// In en, this message translates to:
  /// **'Please provide a valid Document type in the country'**
  String get pleaseProvideValidDocumentType;

  /// Warning when document detection fails
  ///
  /// In en, this message translates to:
  /// **'Document detection failed. Using original image.'**
  String get documentDetectionFailed;

  /// Message when session is successfully refreshed
  ///
  /// In en, this message translates to:
  /// **'Session refreshed. Please try uploading again.'**
  String get sessionRefreshed;

  /// Error when session refresh fails
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh session. Please try again.'**
  String get failedToRefreshSession;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
