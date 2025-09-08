// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Skaletek KYC';

  @override
  String get exitVerificationTitle => 'Exit Verification?';

  @override
  String get exitVerificationMessage =>
      'Are you sure you want to exit the verification process? Your progress will be lost.';

  @override
  String get exit => 'Exit';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get continueButton => 'Continue';

  @override
  String get goBack => 'Go Back';

  @override
  String get greetingGeneric => 'Hey there!';

  @override
  String greetingPersonalized(String firstName, String lastName) {
    return 'Hey $firstName $lastName!';
  }

  @override
  String get getReadyToUploadId => 'Get ready to upload your ID';

  @override
  String get photosensitivityWarning => 'Photosensitivity Warning';

  @override
  String get cameraRequiredMessage =>
      'We will require you have a working camera.';

  @override
  String get frontView => 'Front view';

  @override
  String get backView => 'Back view';

  @override
  String get pleaseSelectFrontDocument => 'Please select a front document';

  @override
  String get pleaseSelectBackDocument => 'Please select a back document';

  @override
  String get clickToStartLivenessCheck => 'Click to Start liveness check';

  @override
  String get startLivenessCheck => 'Start liveness check';

  @override
  String get creatingSession => 'Creating session...';

  @override
  String errorInitializing(String error) {
    return 'Error initializing: $error';
  }

  @override
  String get imageSizeExceedsMaximum =>
      'Image size exceeds the maximum allowed size';

  @override
  String failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get pleaseProvideValidDocumentType =>
      'Please provide a valid Document type in the country';

  @override
  String get documentDetectionFailed =>
      'Document detection failed. Using original image.';

  @override
  String get sessionRefreshed =>
      'Session refreshed. Please try uploading again.';

  @override
  String get failedToRefreshSession =>
      'Failed to refresh session. Please try again.';

  @override
  String get fitIdCardInBox => 'Fit ID card in the box';

  @override
  String get moveLeftSlightly => 'Move left slightly.';

  @override
  String get moveRightSlightly => 'Move right slightly.';

  @override
  String get connecting => 'Connecting…';

  @override
  String get processingErrorOccurred => 'Processing error occurred';

  @override
  String get captured => 'Captured!';

  @override
  String get languageSelector => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';
}
