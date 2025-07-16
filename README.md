# Skaletek KYC

A Flutter SDK for integrating Skaletek's Know Your Customer (KYC) verification services with automatic AWS Amplify setup for face liveness detection.

## Features

- **Automatic AWS Configuration**: No need for manual AWS Amplify setup
- **Face Liveness Detection**: Built-in support using AWS Face Liveness
- **Document Verification**: Supports ID card scanning and verification
- **Seamless Integration**: Simple API for quick integration
- **Cross-platform**: Works on both iOS and Android

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  skaletek_kyc: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Usage

The Skaletek KYC SDK automatically handles all AWS Amplify configuration for you. Simply use it in your Flutter app:

```dart
import 'package:skaletek_kyc/skaletek_kyc.dart';
import 'package:flutter/material.dart';

class MyKYCScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KYC Verification')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startKYC(context),
          child: Text('Start KYC Verification'),
        ),
      ),
    );
  }

  void _startKYC(BuildContext context) async {
    // Configure user information
    final userInfo = KYCUserInfo(
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      phoneNumber: '+1234567890',
    );

    // Configure UI customization
    final customization = KYCCustomization(
      primaryColor: Colors.blue,
      secondaryColor: Colors.grey,
      logoUrl: 'https://your-company.com/logo.png',
    );

    // Start KYC verification
    await SkaletekKYC.instance.startVerification(
      context: context,
      token: 'your-kyc-session-token',
      userInfo: userInfo,
      customization: customization,
      onComplete: (result) {
        print('KYC Result: $result');
        // Handle the KYC result
        if (result['status'] == 'success') {
          // KYC verification successful
        } else {
          // KYC verification failed
        }
      },
    );
  }
}
```

### Configuration

#### No Manual Setup Required!

Unlike other KYC solutions, Skaletek KYC automatically handles all AWS configuration. The SDK includes:

- Pre-configured AWS Amplify settings
- Automatic Face Liveness detector setup
- Built-in Cognito authentication
- All required dependencies

#### Getting Your API Token

Contact Skaletek support to get your API token and configuration:

1. Visit [Skaletek Dashboard](https://dashboard.skaletek.com)
2. Create an account or sign in
3. Generate your KYC API token
4. Use the token in your app

### Advanced Usage

#### Check Amplify Status

You can check if Amplify is properly configured:

```dart
import 'package:skaletek_kyc/skaletek_kyc.dart';

// Check if Amplify is configured
bool isConfigured = await SkaletekKycPlugin.isAmplifyConfigured();
print('Amplify configured: $isConfigured');

// Get detailed configuration status
Map<String, dynamic> status = await SkaletekKycPlugin.getAmplifyConfigStatus();
print('Configuration status: $status');
```

#### Manual Amplify Initialization

If needed, you can manually trigger Amplify initialization:

```dart
Map<String, dynamic> result = await SkaletekKycPlugin.initializeAmplify();
if (result['success']) {
  print('Amplify initialized successfully');
} else {
  print('Failed to initialize Amplify: ${result['message']}');
}
```

### KYC Flow

The KYC verification process includes:

1. **Document Capture**: Users scan their ID document
2. **Face Liveness**: Real-time face liveness detection
3. **Verification**: Server-side verification and comparison
4. **Results**: Instant verification results

### Customization

You can customize the UI to match your app's branding:

```dart
final customization = KYCCustomization(
  primaryColor: Color(0xFF1976D2),
  secondaryColor: Color(0xFF424242),
  backgroundColor: Color(0xFFF5F5F5),
  logoUrl: 'https://yourcompany.com/logo.png',
  companyName: 'Your Company',
  // Custom text and labels
  welcomeTitle: 'Welcome to Verification',
  welcomeSubtitle: 'Please follow the steps to verify your identity',
);
```

### Error Handling

The SDK provides comprehensive error handling:

```dart
await SkaletekKYC.instance.startVerification(
  // ... other parameters
  onComplete: (result) {
    switch (result['status']) {
      case 'success':
        // Verification successful
        String sessionId = result['sessionId'];
        break;
      case 'failure':
        // Verification failed
        String error = result['error'];
        break;
      case 'cancelled':
        // User cancelled the process
        break;
    }
  },
);
```

## Platform Support

- **iOS**: 13.0 and above
- **Android**: API level 21 (Android 5.0) and above

## Dependencies

The SDK automatically includes and configures:

- AWS Amplify for authentication
- Face Liveness Detector for biometric verification
- Camera and image processing capabilities
- HTTP client for API communication

## Support

For support and questions:

- Email: support@skaletek.com
- Documentation: [docs.skaletek.com](https://docs.skaletek.com)
- GitHub Issues: [github.com/skaletek-io/skaletek_kyc/issues](https://github.com/skaletek-io/skaletek_kyc/issues)

## License

This SDK is proprietary software owned by Skaletek. See the [LICENSE](LICENSE) file for details.
