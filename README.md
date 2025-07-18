# Skaletek KYC Flutter Plugin

A Flutter plugin for integrating Skaletek's Know Your Customer (KYC) verification services


## 🚀 Quick Start

### 1. Add Dependency

```yaml
dependencies:
  skaletek_kyc: ^0.0.1
```

### 2. Android Setup

For Android face liveness detection, several configurations are required:

#### 2.1. Update `android/build.gradle` (Project Level)

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
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.3.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.0.0")
        classpath("org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.0.0")
    }
}

allprojects {
    repositories {
        maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")
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

#### 2.2. Update `android/app/build.gradle` (App Level)

```gradle
android {
    compileSdk = 35
    ndkVersion = "27.0.12077973" 

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // AWS Amplify Face Liveness SDK
    implementation("com.amplifyframework.ui:liveness:1.4.0")
    implementation("com.amplifyframework:core:2.27.0")
    implementation("com.amplifyframework:aws-auth-cognito:2.27.0")
}

// Auto-copy amplifyconfiguration.json for face liveness detection
tasks.register("copyAmplifyConfig") {
    doLast {
        val sourceFile = file("../../../assets/amplifyconfiguration.json")
        val targetDir = file("src/main/res/raw")
        
        if (sourceFile.exists()) {
            targetDir.mkdirs()
            sourceFile.copyTo(file("${targetDir.path}/amplifyconfiguration.json"), overwrite = true)
            println("✅ amplifyconfiguration.json for face liveness setup")
        } else {
            println("⚠️ amplifyconfiguration.json not found at ${sourceFile.path}")
        }
    }
}

tasks.named("preBuild") {
    dependsOn("copyAmplifyConfig")
}
```

#### 2.3. Add Camera Permission to `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    
    <application
        android:label="your_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of your manifest -->
    </application>
</manifest>
```

#### 2.4. Update MainActivity

Ensure your `MainActivity` extends `FlutterFragmentActivity`:

```kotlin
// android/app/src/main/kotlin/com/yourpackage/yourapp/MainActivity.kt
package com.yourpackage.yourapp

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**What this setup does:**
- ✅ Configures Kotlin and Compose for face liveness UI
- ✅ Adds required AWS Amplify dependencies
- ✅ Automatically copies `amplifyconfiguration.json` to correct location
- ✅ Enables camera permissions for face verification
- ✅ Uses FlutterFragmentActivity for better native integration

### 3. Initialize in main()

```dart
import 'package:flutter/material.dart';
import 'package:skaletek_kyc/skaletek_kyc.dart';

void main()  {
  
  runApp(MyApp());
}
```

### 4. Start Verification

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
- `DocumentType.nationalId`
- `DocumentType.residencePermit`
- `DocumentType.healthCard`
- `DocumentType.driverLicense`

### Document Sources
- `DocumentSource.camera` - Live camera capture
- `DocumentSource.file` - File upload from gallery


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

For support and questions:
- Email: support@skaletek.io
- Documentation: [https://docs.skaletek.io](https://docs.skaletek.io)
- Issues: [GitHub Issues](https://github.com/skaletek-io/skaletek_kyc/issues) 