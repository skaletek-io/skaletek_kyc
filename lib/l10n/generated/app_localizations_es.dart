// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get exitVerificationTitle => '¿Salir de la verificación?';

  @override
  String get exitVerificationMessage =>
      '¿Estás seguro de que quieres salir del proceso de verificación? Se perderá tu progreso.';

  @override
  String get exit => 'Salir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get greetingGeneric => '¡Hola!';

  @override
  String greetingPersonalized(String firstName, String lastName) {
    return '¡Hola $firstName $lastName!';
  }

  @override
  String get getReadyToUploadId => 'Prepárate para subir tu identificación';

  @override
  String get photosensitivityWarning => 'Advertencia de fotosensibilidad';

  @override
  String get cameraRequiredMessage =>
      'Necesitaremos que tengas una cámara funcionando.';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get spanish => 'Español';
}
