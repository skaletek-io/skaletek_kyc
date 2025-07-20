# Skaletek KYC Flutter Plugin

[![pub package](https://img.shields.io/pub/v/skaletek_kyc.svg)](https://pub.dev/packages/skaletek_kyc)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Flutter plugin for **Know Your Customer (KYC) verification** services, featuring document scanning, face liveness detection, and identity verification powered by AWS Amplify.

## ✨ Features

- 🆔 **Document Verification**: Passport, National ID, Driver's License, and more
- 👤 **Face Liveness Detection**: Real-time biometric verification using AWS Amplify
- 📸 **Camera Integration**: Live document capture with auto-detection
- 📁 **File Upload**: Support for gallery/file-based document upload
- 🎨 **Customizable UI**: Branded verification experience
- 🔒 **Secure**: Enterprise-grade security with AWS infrastructure
- 📱 **Cross-platform**: iOS and Android support

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have:
- Flutter 3.8.1 or higher
- AWS Amplify configuration files (`amplifyconfiguration.json`, `awsconfiguration.json`)
- Valid Skaletek KYC session token

### 1. Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  skaletek_kyc: ^0.0.1
```

Run:
```bash
flutter pub get
```

### 2. Platform Setup

Choose your platform for detailed setup instructions:

- [📱 **Android Setup**](#android-setup) - Automated with manual configuration
- [🍎 **iOS Setup**](#ios-setup) - Semi-automated with manual steps

### 3. Basic Usage

```dart
import 'package:skaletek_kyc/skaletek_kyc.dart';

// Configure user information
final userInfo = KYCUserInfo(
  firstName: "John",
  lastName: "Doe",
  documentType: DocumentType.passport.value,
  issuingCountry: "USA",
);

// Customize the verification experience
final customization = KYCCustomization(
  docSrc: DocumentSource.camera.value,
  partnerName: "Your App Name",
  primaryColor: Colors.blue,
  logoUrl: "https://yourapp.com/logo.png",
);

// Start verification
SkaletekKYC.instance.startVerification(
  context: context,
  token: "your-session-token",
  userInfo: userInfo,
  customization: customization,
  onComplete: (result) {
    if (result['success'] == true) {
      print('✅ KYC Verification successful!');
      // Handle success
    } else {
      print('❌ KYC Verification failed: ${result['status']}');
      // Handle failure
    }
  },
);
```

---

## 📱 Android Setup

### Overview
Android setup includes automated AWS Amplify configuration with some manual build configuration required.

### Step 1: Update Project Build Configuration

#### 1.1. Update `android/build.gradle` (Project Level)

```gradle
buildscript {
    ext.kotlin_version = '2.0.0'
    ext.compose_version = '1.6.7'
    ext.compose_compiler_version = '1.5.14'
    
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath "org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.0.0"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://maven.pkg.jetbrains.space/public/p/compose/dev" }
    }
}

// Apply Compose plugin for face liveness detection
subprojects {
    afterEvaluate {
        if (project.name == "app" || project.name == "face_liveness_detector") {
            apply plugin: "org.jetbrains.kotlin.plugin.compose"
        }
    }
}
```

#### 1.2. Update `android/app/build.gradle` (App Level)

```gradle
android {
    compileSdk 35
    ndkVersion "27.0.12077973"

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true
    }

    kotlinOptions {
        jvmTarget = '11'
    }

    defaultConfig {
        minSdk 24
        // ... your other configurations
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
    
    // Jetpack Compose (required for face liveness UI)
    implementation "androidx.compose.ui:ui:$compose_version"
    implementation "androidx.compose.material:material:$compose_version"
    implementation "androidx.compose.runtime:runtime:$compose_version"
    implementation "androidx.activity:activity-compose:1.8.2"
    implementation "androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0"

    // AWS Amplify Face Liveness SDK
    implementation 'com.amplifyframework.ui:liveness:1.4.0'
    implementation 'com.amplifyframework:core:2.27.0'
    implementation 'com.amplifyframework:aws-auth-cognito:2.27.0'
}

// Automated configuration copying
tasks.register('copyAmplifyConfig') {
    doLast {
        def sourceFile = file('../../../assets/amplifyconfiguration.json')
        def targetDir = file('src/main/res/raw')
        
        if (sourceFile.exists()) {
            targetDir.mkdirs()
            sourceFile.copyTo(file("${targetDir.path}/amplifyconfiguration.json"), overwrite: true)
            println '✅ AWS Amplify configuration copied'
        } else {
            println '⚠️ amplifyconfiguration.json not found'
        }
    }
}

tasks.named('preBuild') {
    dependsOn 'copyAmplifyConfig'
}
```

### Step 2: Add Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature 
        android:name="android.hardware.camera" 
        android:required="true" />
    
    <application
        android:label="your_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of your manifest -->
    </application>
</manifest>
```

### Step 3: Update MainActivity

Ensure your `MainActivity` extends `FlutterFragmentActivity`:

```kotlin
// android/app/src/main/kotlin/com/yourpackage/yourapp/MainActivity.kt
package com.yourpackage.yourapp

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```


## 🍎 iOS Setup

### Overview
iOS setup includes automated configuration file copying with manual Swift Package Manager and Xcode configuration.

### Step 1: iOS Platform Configuration

First, ensure your `ios/Podfile` specifies the minimum iOS version:

```ruby
platform :ios, '14.0'
```

### Step 2: Automated iOS Setup (One-time Podfile Update)

Add this **automation block** to your `ios/Podfile` in the `post_install` hook:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
  
  # Skaletek KYC Auto Setup
  setup_script_paths = [
    'Pods/skaletek_kyc/skaletek_kyc_setup.rb',  # For published plugin
    File.expand_path('~/.pub-cache/hosted/pub.dev/skaletek_kyc-*/ios/skaletek_kyc_setup.rb')  # Alternative pub cache path
  ]
  
  setup_script_path = setup_script_paths.find { |path| File.exist?(path) }
  
  if setup_script_path
    load setup_script_path
    SkaletekKYC.setup_ios_project
  else
    puts "⚠️ Skaletek KYC setup script not found. Please ensure the plugin is installed."
  end
end
```

### Step 2.1: Run Pod Install

```bash
cd ios && pod install
```

**That's it!** The setup runs automatically and configures:
- ✅ **Copies AWS configuration files** to your iOS project  
- ✅ **Updates AppDelegate.swift** with Amplify initialization
- ✅ **Adds camera permissions** to Info.plist
- ✅ **No additional commands needed**

### Step 3: Add Swift Package Dependencies (Manual)

1. **Open your iOS project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add Package Dependencies:**
   - Go to **File > Add Package Dependencies...**

3. **Add AWS Amplify Swift:**
   - **URL:** `https://github.com/aws-amplify/amplify-swift`
   - **Version:** `2.46.1` or later
   - **Select:** `Amplify`, `AWSCognitoAuthPlugin`

4. **Add AWS Amplify UI Liveness:**
   - **URL:** `https://github.com/aws-amplify/amplify-ui-swift-liveness`
   - **Version:** `1.3.5` or later
   - **Select:** `FaceLiveness`

### Step 4: Camera Permissions (Automated)

Camera permissions are automatically added by the setup script. If you need to customize the message, edit this entry in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for document scanning and face verification.</string>
```

## 📖 API Reference

### KYCUserInfo

```dart
final userInfo = KYCUserInfo(
  firstName: "John",
  lastName: "Doe",
  documentType: DocumentType.passport.value,
  issuingCountry: "USA",
);
```

### KYCCustomization

```dart
final customization = KYCCustomization(
  docSrc: DocumentSource.camera.value,
  partnerName: "Your Company",
  logoUrl: "https://example.com/logo.png", // optional
  primaryColor: Colors.blue, // optional
);
```

### Document Types

| Type | Description |
|------|-------------|
| `DocumentType.passport` | International passport |
| `DocumentType.nationalId` | National ID card |
| `DocumentType.driverLicense` | Driver's license |
| `DocumentType.residencePermit` | Residence permit |
| `DocumentType.healthCard` | Health/medical card |

### Document Sources

| Source | Description |
|--------|-------------|
| `DocumentSource.camera` | Live camera capture with auto-detection |
| `DocumentSource.file` | File upload from device gallery |

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:skaletek_kyc/skaletek_kyc.dart';

class KYCVerificationScreen extends StatelessWidget {
  const KYCVerificationScreen({Key? key}) : super(key: key);

  void _startKYCVerification(BuildContext context) {
    final userInfo = KYCUserInfo(
      firstName: "John",
      lastName: "Doe", 
      documentType: DocumentType.passport.value,
      issuingCountry: "USA",
    );

    final customization = KYCCustomization(
      docSrc: DocumentSource.camera.value,
      partnerName: "My App",
      primaryColor: Theme.of(context).primaryColor,
      logoUrl: "https://myapp.com/logo.png",
    );

    SkaletekKYC.instance.startVerification(
      context: context,
      token: "your-session-token", // Get from your backend
      userInfo: userInfo,
      customization: customization,
      onComplete: (result) {
        final success = result['success'] as bool? ?? false;
        final status = result['status'] as String? ?? 'Unknown';
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Identity verification successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Verification failed: $status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verify Your Identity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'We need to verify your identity to ensure the security of your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _startKYCVerification(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Verification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔧 Troubleshooting

### Common Issues

**Android Build Errors:**
- Ensure Kotlin version is 2.0.0+
- Verify Compose dependencies are correctly added
- Check that `minSdk` is set to 24 or higher

**iOS Build Errors:**
- Confirm Swift Package Manager dependencies are added
- Verify configuration files are added to Xcode project
- Check iOS deployment target is 14.0+

**Face Liveness Issues:**
- Verify camera permissions are granted
- Check network connectivity for AWS services

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

For support and questions:

- **Email:** [support@skaletek.io](mailto:support@skaletek.io)
- **Documentation:** [docs.skaletek.io](https://docs.skaletek.io)
- **Issues:** [GitHub Issues](https://github.com/skaletek-io/skaletek_kyc/issues)
- **Website:** [skaletek.io](https://skaletek.io)

---

**Made with ❤️ by the Skaletek team** 