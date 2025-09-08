// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get exitVerificationTitle => 'Quitter la vérification ?';

  @override
  String get exitVerificationMessage =>
      'Êtes-vous sûr de vouloir quitter le processus de vérification ? Votre progression sera perdue.';

  @override
  String get exit => 'Quitter';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get greetingGeneric => 'Salut !';

  @override
  String greetingPersonalized(String firstName, String lastName) {
    return 'Salut $firstName $lastName !';
  }

  @override
  String get getReadyToUploadId =>
      'Préparez-vous à télécharger votre pièce d\'identité';

  @override
  String get photosensitivityWarning => 'Avertissement de photosensibilité';

  @override
  String get cameraRequiredMessage =>
      'Nous aurons besoin que vous ayez une caméra fonctionnelle.';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';
}
