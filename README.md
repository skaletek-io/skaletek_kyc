# Skaletek KYC Flutter Plugin

A Flutter plugin for integrating Skaletek's Know Your Customer (KYC) verification services with **automatic AWS Amplify configuration**. No manual native setup required!

## ✨ Features

- 🚀 **Zero Native Configuration** - AWS Amplify configured automatically
- 📱 **Cross-Platform** - iOS and Android support
- 🔐 **Secure** - Built-in AWS Cognito authentication
- 🎨 **Customizable** - Flexible UI customization options
- 📸 **Advanced Verification** - Document scanning and face liveness detection

## 🚀 Quick Start

### 1. Add Dependency

```yaml
dependencies:
  skaletek_kyc: ^0.0.1
```

### 2. Initialize in main()

```dart
import 'package:flutter/material.dart';
import 'package:skaletek_kyc/skaletek_kyc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // REQUIRED: Initialize Skaletek KYC SDK
  await SkaletekKYC.initialize();
  
  runApp(MyApp());
}
```

### 3. Start Verification

```dart
import 'package:skaletek_kyc/skaletek_kyc.dart';

class MyVerificationScreen extends StatelessWidget {
  void _startKYCVerification(BuildContext context) {
    final userInfo = KYCUserInfo(
      firstName: "John",
      lastName: "Doe", 
      documentType: DocumentType.passport.value,
      issuingCountry: "USA",
    );

    final customization = KYCCustomization(
      docSrc: DocumentSource.camera.value,
      partnerName: "Your App Name",
      primaryColor: Colors.blue,
      logoUrl: "https://yourapp.com/logo.png",
    );

    SkaletekKYC.instance.startVerification(
      context: context,
      token: "your-session-token",
      userInfo: userInfo,
      customization: customization,
      onComplete: (result) {
        if (result['success'] == true) {
          print('KYC Verification successful!');
        } else {
          print('KYC Verification failed: ${result['status']}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KYC Verification')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startKYCVerification(context),
          child: Text('Start Identity Verification'),
        ),
      ),
    );
  }
}
```

## 🔧 Configuration Models

### KYCUserInfo
```dart
final userInfo = KYCUserInfo(
  firstName: "John",
  lastName: "Doe",
  documentType: DocumentType.passport.value, // or .drivingLicense, .nationalId
  issuingCountry: "USA",
);
```

### KYCCustomization
```dart
final customization = KYCCustomization(
  docSrc: DocumentSource.camera.value, // or .file for file upload
  partnerName: "Your Company",
  logoUrl: "https://example.com/logo.png", // optional
  primaryColor: Colors.blue, // optional
);
```

### Document Types
- `DocumentType.passport`
- `DocumentType.drivingLicense` 
- `DocumentType.nationalId`

### Document Sources
- `DocumentSource.camera` - Live camera capture
- `DocumentSource.file` - File upload from gallery

## 📋 SDK Status Checking

```dart
// Check if SDK is initialized
bool isInitialized = SkaletekKYC.isInitialized;

// Get detailed SDK information
Map<String, dynamic> info = await SkaletekKYC.instance.sdkInfo;
print('Platform: ${info['platform_version']}');
print('AWS Amplify: ${info['amplify_configured']}');
print('SDK Initialized: ${info['sdk_initialized']}');
```

## 🎯 What Happens Automatically

When you call `SkaletekKYC.initialize()`, the plugin automatically:

1. **iOS**: Loads AWS configuration from bundled assets and configures Amplify
2. **Android**: Copies configuration files to raw resources and initializes Amplify
3. **Sets up**: AWS Cognito authentication for face liveness detection
4. **Prepares**: All necessary services for KYC verification

## 🛠️ No Manual Configuration Required

Unlike other AWS-based plugins, **you don't need to**:
- ❌ Manually add AWS configuration files to iOS/Android projects
- ❌ Open Xcode to add files to the Runner target
- ❌ Modify native build scripts
- ❌ Configure AWS Amplify in AppDelegate or MainActivity
- ❌ Set up AWS dependencies manually

Everything is handled automatically by the plugin!

## 📱 Platform Support

- **iOS**: 14.0+
- **Android**: API Level 24+
- **Flutter**: 2.5.0+

## 🔐 Security

This plugin uses AWS Amplify with Cognito for secure authentication and communication. All AWS configurations are bundled securely with the plugin.

## 🐛 Troubleshooting

### Initialization Failed
```dart
bool success = await SkaletekKYC.initialize();
if (!success) {
  print('SDK initialization failed. Check logs for details.');
}
```

### Check SDK Status
```dart
final info = await SkaletekKYC.instance.sdkInfo;
if (info['amplify_configured'] != true) {
  print('AWS Amplify not configured properly');
}
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

For support and questions:
- Email: support@skaletek.io
- Documentation: [https://docs.skaletek.io](https://docs.skaletek.io)
- Issues: [GitHub Issues](https://github.com/skaletek-io/skaletek_kyc/issues) 