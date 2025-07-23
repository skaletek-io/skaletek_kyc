import 'package:skaletek_kyc/src/models/kyc_customization.dart';
import 'package:skaletek_kyc/src/models/kyc_user_info.dart';

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

class AppConfig {
  // Region configuration
  static const String region = 'us-east-1'; // Default region

  /// Get KYC API URL based on environment
  static String getKycApiUrl(String environment) {
    switch (environment) {
      case 'prod':
        return 'https://kyc-api.skaletek.io';
      case 'sandbox':
        return 'https://kyc-api.sandbox.skaletek.io';
      case 'dev':
      default:
        return 'https://kyc-api.dev.skaletek.io';
    }
  }

  /// Get ML API URL based on environment
  /// Note: All environments currently use dev ML API
  static String getMlApiUrl(String environment) {
    switch (environment) {
      case 'prod':
        return 'https://ml.dev.skaletek.io';
      case 'sandbox':
        return 'https://ml.dev.skaletek.io';
      case 'dev':
      default:
        return 'https://ml.dev.skaletek.io';
    }
  }

  /// Get ML WebSocket URL based on environment
  /// Note: All environments currently use dev ML WebSocket
  static String getMlSocketUrl(String environment) {
    switch (environment) {
      case 'prod':
        return 'wss://ml.dev.skaletek.io/detection/ws';
      case 'sandbox':
        return 'wss://ml.dev.skaletek.io/detection/ws';
      case 'dev':
      default:
        return 'wss://ml.dev.skaletek.io/detection/ws';
    }
  }
}
