// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';
}
