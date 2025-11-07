# Skaletek KYC Flutter Plugin

A comprehensive Flutter plugin for **Know Your Customer (KYC) verification** services, featuring document scanning, face liveness detection, and identity verification powered by AWS Amplify.

## ✨ Features

- 🆔 **Document Verification**: Passport, National ID, Driver's License, and more
- 👤 **Face Liveness Detection**: Real-time biometric verification using AWS Amplify
- 📸 **Camera Integration**: Live document capture with auto-detection
- 🎨 **Customizable UI**: Branded verification experience
- 🔒 **Secure**: Enterprise-grade security with AWS infrastructure
- 📱 **Cross-platform**: iOS and Android support

## 🚀 Quick Start


### 1. Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  skaletek_kyc: ^0.0.10
```

Run:
```bash
flutter pub get
```

### 2. Platform Setup

## 📱 Android Setup

### Overview
Android setup includes automated AWS Amplify configuration and ProGuard rules management. The plugin automatically copies necessary configuration files and provides helpful setup guidance.

### Step 1: Update Project Build Configuration

#### 1.1. Update `android/build.gradle` (Project Level)

```gradle
buildscript {
    extra.apply {
        set("kotlin_version", "2.0.0")
        set("compose_version", "1.6.7")
        set("compose_compiler_version", "1.5.14")
    }
    
    repositories {
        google()
        mavenCentral()
         maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.3.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.0")
        classpath("org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.0.0")
    }
}


// Apply Compose plugin only to the face_liveness_detector project
subprojects {
    afterEvaluate {
        if (project.name == "app" || project.name == "face_liveness_detector") {
            apply(plugin = "org.jetbrains.kotlin.plugin.compose")
        }
    }
}
```

#### 1.2. Update `android/app/build.gradle` (App Level)

```gradle

plugins {
   //...
  id("org.jetbrains.kotlin.plugin.compose") 
}

android {
    compileSdk = 35
    ndkVersion = "27.0.12077973" //this is required by our sdk

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        //...
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
      //...
        minSdk = 24
    }

    buildTypes {
        release {
            //...
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "skaletek-proguard-rules.pro"
            )
        }
    }
}

dependencies {
     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

     // Add these Compose dependencies
    implementation("androidx.compose.ui:ui:1.6.7")
    implementation("androidx.compose.material:material:1.6.7")
    implementation("androidx.compose.runtime:runtime:1.6.7")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    // AWS Amplify Face Liveness SDK
    implementation("com.amplifyframework.ui:liveness:1.4.0")
    implementation("com.amplifyframework:core:2.27.0")
    implementation("com.amplifyframework:aws-auth-cognito:2.27.0")
}


apply {
    val userHome = System.getProperty("user.home")
    val localAppData = System.getenv("LOCALAPPDATA") ?: "$userHome/AppData/Local"
    val pubCacheDirs = listOf("$userHome/.pub-cache/hosted/pub.dev", "$localAppData/Pub/Cache/hosted/pub.dev")
    
    pubCacheDirs.map { file(it) }.find { it.exists() }?.listFiles()
        ?.find { it.name.startsWith("skaletek_kyc-") }
        ?.let { file("${it.absolutePath}/android/skaletek_kyc.gradle") }
        ?.takeIf { it.exists() }?.let { from(it) }
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

####  `ios/Runner.xcodeproj/project.pbxproj` 
```
IPHONEOS_DEPLOYMENT_TARGET = 14.0
```

### Step 2: Automated iOS Setup (One-time Podfile Update)

Add this **automation block** to your `ios/Podfile` in the `post_install` hook:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
  
  # Skaletek KYC Auto Setup
  setup_script_paths = []
  setup_script_paths << 'Pods/skaletek_kyc/skaletek_kyc_setup.rb' if File.exist?('Pods/skaletek_kyc/skaletek_kyc_setup.rb')
  Dir.glob(File.expand_path('~/.pub-cache/hosted/pub.dev/skaletek_kyc-*/ios/skaletek_kyc_setup.rb')).each { |path| setup_script_paths << path }
  
  if setup_script_path = setup_script_paths.first
    puts "✅ Skaletek KYC: Running iOS setup..."
    load setup_script_path
    SkaletekKYC.setup_ios_project
  else
    puts "⚠️ Skaletek KYC: Setup script not found. Run 'flutter pub get' first."
  end
end
```


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


### Step 3: Camera Permissions (Automated)

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

### 🌐 Environment Configuration

You can now specify the environment for the KYC verification process. This controls which backend endpoints are used for the session.

#### Supported Environments

- `SkaletekEnvironment.dev`
- `SkaletekEnvironment.prod`
- `SkaletekEnvironment.sandbox`

#### Usage

```dart
SkaletekKYC.instance.startVerification(
  context: context,
  token: "your-token-here",
  userInfo: userInfo,
  customization: customization,
  environment: SkaletekEnvironment.prod, // or .dev, .sandbox
  onComplete: (result) {
    // Handle result
  },
);
```

- If you do not specify the `environment` parameter, it defaults to `SkaletekEnvironment.dev`.

**Note:**  
- The environment parameter is available in the `KYCConfig` and is passed through the SDK automatically.
- The correct API endpoints are selected internally based on the environment you choose.

---

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:skaletek_kyc/skaletek_kyc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skaletek KYC Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DemoApp(),
    );
  }
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  bool _isVerifying = false;
  String _status = '';
  bool _hasVerificationResult = false;

  void _startVerification() async {
    setState(() {
      _isVerifying = true;
      _status = 'Starting verification...';
      _hasVerificationResult = false;
    });

    final userInfo = KYCUserInfo(
      firstName: "Whyte",
      lastName: "Peter",
      documentType: DocumentType.passport.value,
      issuingCountry: "USA",
    );
    final customization = KYCCustomization(
      docSrc: DocumentSource.file.value,
      logoUrl: null,
      partnerName: "My Company",
      primaryColor: null,
    );

    SkaletekKYC.instance.startVerification(
      context: context,
      token: "your-token-here",
      userInfo: userInfo,
      customization: customization,
      environment: SkaletekEnvironment.prod, // or .dev, .sandbox
      onComplete: (result) {
        setState(() {
          _isVerifying = false;
          _hasVerificationResult = true;
          if (result['success'] == true) {
            _status = 'Verification completed successfully!';
          } else {
            _status =
                'Verification failed:  ${result['status'] ?? 'Unknown error'}';
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skaletek KYC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Color(0xFF1261C1)),
            const SizedBox(height: 24),
            const Text(
              'Skaletek KYC SDK Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This demo shows how to integrate the Skaletek KYC Flutter SDK for identity verification.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_isVerifying)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verification in progress...'),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1261C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Start Identity Verification'),
                ),
              ),

            const SizedBox(height: 20),
            if (_hasVerificationResult && _status.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('success')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.contains('success')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _status.contains('success')
                        ? Colors.green[700]
                        : Colors.red[700],
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
- Check that `compileSdk` is set to 35 or higher
- Check that `ndkVersion` is set "27.0.12077973"

**iOS Build Errors:**
- Confirm Swift Package Manager dependencies are added
- Verify configuration files are added to Xcode project
- Check iOS deployment target is 14.0+

**Face Liveness Issues:**
- Verify camera permissions are granted
- Check network connectivity for AWS services

