// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Skaletek KYC';

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
  String get ok => 'OK';

  @override
  String get continueButton => 'Continuer';

  @override
  String get goBack => 'Retour';

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
  String get frontView => 'Vue de face';

  @override
  String get backView => 'Vue de dos';

  @override
  String get pleaseSelectFrontDocument =>
      'Veuillez sélectionner un document recto';

  @override
  String get pleaseSelectBackDocument =>
      'Veuillez sélectionner un document verso';

  @override
  String get clickToStartLivenessCheck =>
      'Cliquez pour démarrer la vérification de vivacité';

  @override
  String get startLivenessCheck => 'Démarrer la vérification de vivacité';

  @override
  String get creatingSession => 'Création de session...';

  @override
  String errorInitializing(String error) {
    return 'Erreur d\'initialisation : $error';
  }

  @override
  String get imageSizeExceedsMaximum =>
      'La taille de l\'image dépasse la taille maximale autorisée';

  @override
  String failedToPickImage(String error) {
    return 'Échec de sélection d\'image : $error';
  }

  @override
  String get pleaseProvideValidDocumentType =>
      'Veuillez fournir un type de document valide dans le pays';

  @override
  String get documentDetectionFailed =>
      'La détection du document a échoué. Utilisation de l\'image originale.';

  @override
  String get sessionRefreshed =>
      'Session rafraîchie. Veuillez essayer de télécharger à nouveau.';

  @override
  String get failedToRefreshSession =>
      'Échec du rafraîchissement de session. Veuillez réessayer.';

  @override
  String get fitIdCardInBox => 'Placez la carte d\'identité dans le cadre';

  @override
  String get moveLeftSlightly => 'Bougez légèrement vers la gauche.';

  @override
  String get moveRightSlightly => 'Bougez légèrement vers la droite.';

  @override
  String get connecting => 'Connexion…';

  @override
  String get processingErrorOccurred =>
      'Une erreur de traitement s\'est produite';

  @override
  String get captured => 'Capturé !';

  @override
  String get languageSelector => 'Langue';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';
}
