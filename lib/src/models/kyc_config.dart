import 'kyc_user_info.dart';
import 'kyc_customization.dart';

class KYCConfig {
  final String token;
  final KYCUserInfo userInfo;
  final KYCCustomization customization;
  final SkaletekEnvironment environment;

  const KYCConfig({
    required this.token,
    required this.userInfo,
    required this.customization,
    this.environment = SkaletekEnvironment.dev, // Default to dev
  });

  Map<String, dynamic> toMap() {
    return {
      'token': token,
      'userInfo': userInfo.toMap(),
      'customization': customization.toMap(),
      'environment': environment.value,
    };
  }

  factory KYCConfig.fromMap(Map<String, dynamic> map) {
    return KYCConfig(
      token: map['token'] ?? '',
      userInfo: KYCUserInfo.fromMap(map['userInfo'] ?? {}),
      customization: KYCCustomization.fromMap(map['customization'] ?? {}),
      environment: SkaletekEnvironment.values.firstWhere(
        (e) => e.value == map['environment'],
        orElse: () => SkaletekEnvironment.dev,
      ),
    );
  }

  @override
  String toString() {
    return 'KYCConfig(token: $token, userInfo: $userInfo, customization: $customization, environment: ${environment.value})';
  }
}

enum SkaletekEnvironment {
  dev('dev'),
  prod('prod'),
  sandbox('sandbox');

  const SkaletekEnvironment(this.value);
  final String value;
}
