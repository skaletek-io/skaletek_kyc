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

  @override
  String get continueButton => 'Continuar';

  @override
  String get goBack => 'Volver';

  @override
  String get startLivenessCheck => 'Iniciar verificación de vivacidad';

  @override
  String get creatingSession => 'Creando sesión...';

  @override
  String get clickToStartLivenessCheck =>
      'Haz clic para iniciar la verificación de vivacidad';

  @override
  String get frontView => 'Vista frontal';

  @override
  String get backView => 'Vista trasera';

  @override
  String get pleaseSelectFrontDocument =>
      'Por favor selecciona un documento frontal';

  @override
  String get pleaseSelectBackDocument =>
      'Por favor selecciona un documento trasero';

  @override
  String get imageSizeExceedsMaximum =>
      'El tamaño de la imagen excede el tamaño máximo permitido';

  @override
  String failedToPickImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get pleaseProvideValidDocumentType =>
      'Por favor proporciona un tipo de documento válido en el país';

  @override
  String get documentDetectionFailed =>
      'La detección del documento falló. Usando imagen original.';

  @override
  String get sessionRefreshed =>
      'Sesión actualizada. Por favor intenta subir de nuevo.';

  @override
  String get failedToRefreshSession =>
      'Error al actualizar sesión. Por favor intenta de nuevo.';
}
