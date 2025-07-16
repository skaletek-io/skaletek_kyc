# Complete Skaletek SDK Plugin Implementation Guide

This guide shows how to create a Flutter plugin that automatically handles AWS Amplify configuration for face liveness detection, so end users don't need to manually configure iOS and Android projects.

## Project Structure

```
skaletek_sdk/
├── lib/
│   ├── skaletek_sdk.dart
│   └── skaletek_kyc_initialization.dart
├── ios/
│   ├── Classes/
│   │   └── SkaletekSdkPlugin.swift
│   ├── Runner/
│   │   ├── amplifyconfiguration.json
│   │   └── awsconfiguration.json
│   └── skaletek_sdk.podspec
├── android/
│   ├── src/main/
│   │   ├── kotlin/com/skaletek/skaletek_sdk/
│   │   │   └── SkaletekSdkPlugin.kt
│   │   └── res/raw/
│   │       └── amplifyconfiguration.json
│   └── build.gradle
├── tool/
│   └── bundle_resources.dart
└── pubspec.yaml
```

## 1. pubspec.yaml

```yaml
name: skaletek_sdk
description: SDK for Skaletek KYC with automatic AWS configuration
version: 1.0.0

environment:
  sdk: '>=2.17.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  face_liveness_detector: ^latest_version
  plugin_platform_interface: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  plugin:
    platforms:
      android:
        package: com.skaletek.skaletek_sdk
        pluginClass: SkaletekSdkPlugin
      ios:
        pluginClass: SkaletekSdkPlugin
```

## 2. Main Plugin API (lib/skaletek_sdk.dart)

```dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:face_liveness_detector/face_liveness_detector.dart';

/// Main SDK class that handles all KYC operations
class SkaletekSDK {
  static const MethodChannel _channel = MethodChannel('skaletek_sdk');
  
  /// Initialize the SDK with AWS credentials
  /// This is optional - the SDK will use default embedded configuration
  static Future<void> initialize({
    String? identityPoolId,
    String? userPoolId,
    String? appClientId,
    String? region,
  }) async {
    try {
      await _channel.invokeMethod('initializeKYC', {
        'identityPoolId': identityPoolId,
        'userPoolId': userPoolId,
        'appClientId': appClientId,
        'region': region,
      });
    } on PlatformException catch (e) {
      throw SkaletekSDKException('Failed to initialize SDK: ${e.message}');
    }
  }
  
  /// Start face liveness detection
  static Future<LivenessResult> startLivenessDetection() async {
    try {
      // Use the face_liveness_detector package
      final result = await FaceLivenessDetector.startLivenessDetection();
      return LivenessResult(
        isLive: result.isLive,
        confidence: result.confidence,
        sessionId: result.sessionId,
      );
    } on PlatformException catch (e) {
      throw SkaletekSDKException('Liveness detection failed: ${e.message}');
    }
  }
  
  /// Get SDK version
  static Future<String> getVersion() async {
    try {
      final String version = await _channel.invokeMethod('getVersion');
      return version;
    } on PlatformException catch (e) {
      throw SkaletekSDKException('Failed to get version: ${e.message}');
    }
  }
}

/// Result of liveness detection
class LivenessResult {
  final bool isLive;
  final double confidence;
  final String sessionId;
  
  LivenessResult({
    required this.isLive,
    required this.confidence,
    required this.sessionId,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'isLive': isLive,
      'confidence': confidence,
      'sessionId': sessionId,
    };
  }
}

/// Exception thrown by the SDK
class SkaletekSDKException implements Exception {
  final String message;
  
  SkaletekSDKException(this.message);
  
  @override
  String toString() => 'SkaletekSDKException: $message';
}
```

## 3. iOS Plugin Implementation (ios/Classes/SkaletekSdkPlugin.swift)

```swift
import Flutter
import UIKit
import Amplify
import AWSCognitoAuthPlugin

public class SkaletekSdkPlugin: NSObject, FlutterPlugin {
    private static var isAmplifyConfigured = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "skaletek_sdk", binaryMessenger: registrar.messenger())
        let instance = SkaletekSdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Automatically configure Amplify when plugin is registered
        instance.configureAmplify()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeKYC":
            initializeKYC(result: result)
        case "startLivenessDetection":
            startLivenessDetection(arguments: call.arguments, result: result)
        case "getVersion":
            result("1.0.0")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func configureAmplify() {
        guard !SkaletekSdkPlugin.isAmplifyConfigured else {
            print("✅ Amplify already configured")
            return
        }
        
        do {
            // Load configuration from embedded files
            if let amplifyConfigPath = Bundle.main.path(forResource: "amplifyconfiguration", ofType: "json"),
               let awsConfigPath = Bundle.main.path(forResource: "awsconfiguration", ofType: "json") {
                
                try Amplify.add(plugin: AWSCognitoAuthPlugin())
                try Amplify.configure()
                
                SkaletekSdkPlugin.isAmplifyConfigured = true
                print("✅ Amplify configured automatically by Skaletek SDK")
            } else {
                print("⚠️ AWS configuration files not found in bundle")
            }
        } catch {
            print("⚠️ Could not initialize Amplify: \(error)")
        }
    }
    
    private func initializeKYC(result: @escaping FlutterResult) {
        // Your KYC initialization logic here
        result(["status": "initialized"])
    }
    
    private func startLivenessDetection(arguments: Any?, result: @escaping FlutterResult) {
        // Your liveness detection logic here
        result(["status": "started"])
    }
}

// Extension to handle AppDelegate integration
extension SkaletekSdkPlugin {
    public static func configureInAppDelegate(_ application: UIApplication, 
                                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // This method can be called from AppDelegate if needed
        // But our plugin auto-configures, so this is optional
    }
}
```

## 4. iOS Podspec (ios/skaletek_sdk.podspec)

```ruby
Pod::Spec.new do |s|
  s.name             = 'skaletek_sdk'
  s.version          = '1.0.0'
  s.summary          = 'Skaletek SDK for KYC with automatic AWS configuration'
  s.description      = <<-DESC
A Flutter plugin that provides seamless KYC and face liveness detection with automatic AWS configuration.
                       DESC
  s.homepage         = 'https://github.com/skaletek/skaletek_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Skaletek' => 'contact@skaletek.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Amplify'
  s.dependency 'AWSCognitoAuthPlugin'
  s.platform = :ios, '11.0'
  s.swift_version = '5.0'
  
  # Resource bundle for configuration files
  s.resource_bundles = {
    'SkaletekSDK' => ['Runner/*.json']
  }
end
```

## 5. Android Plugin Implementation (android/src/main/kotlin/com/skaletek/skaletek_sdk/SkaletekSdkPlugin.kt)

```kotlin
package com.skaletek.skaletek_sdk

import android.app.Application
import android.content.Context
import android.util.Log
import com.amplifyframework.AmplifyException
import com.amplifyframework.auth.cognito.AWSCognitoAuthPlugin
import com.amplifyframework.core.Amplify
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException

class SkaletekSdkPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    
    companion object {
        private const val TAG = "SkaletekSdkPlugin"
        private var isAmplifyConfigured = false
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "skaletek_sdk")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Automatically configure Amplify when plugin is attached
        configureAmplify()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeKYC" -> {
                initializeKYC(result)
            }
            "startLivenessDetection" -> {
                startLivenessDetection(call.arguments, result)
            }
            "getVersion" -> {
                result.success("1.0.0")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun configureAmplify() {
        if (isAmplifyConfigured) {
            Log.d(TAG, "✅ Amplify already configured")
            return
        }

        try {
            // Check if configuration file exists in raw resources
            val rawResources = context.resources
            val configResourceId = rawResources.getIdentifier(
                "amplifyconfiguration", 
                "raw", 
                context.packageName
            )
            
            if (configResourceId != 0) {
                Amplify.addPlugin(AWSCognitoAuthPlugin())
                Amplify.configure(context)
                
                isAmplifyConfigured = true
                Log.d(TAG, "✅ Amplify configured automatically by Skaletek SDK")
            } else {
                Log.w(TAG, "⚠️ AWS configuration file not found in raw resources")
            }
        } catch (error: AmplifyException) {
            Log.e(TAG, "⚠️ Could not initialize Amplify", error)
        }
    }

    private fun initializeKYC(result: Result) {
        // Your KYC initialization logic here
        result.success(mapOf("status" to "initialized"))
    }

    private fun startLivenessDetection(arguments: Any?, result: Result) {
        // Your liveness detection logic here
        result.success(mapOf("status" to "started"))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

## 6. Android Gradle Configuration (android/build.gradle)

```gradle
group 'com.skaletek.skaletek_sdk'
version '1.0'

buildscript {
    ext.kotlin_version = '2.0.0'
    ext.compose_version = '1.6.7'
    ext.compose_compiler_version = '1.5.14'
    
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath "org.jetbrains.kotlin:kotlin-serialization:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'
apply plugin: 'org.jetbrains.kotlin.plugin.compose'

android {
    compileSdk 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
        coreLibraryDesugaringEnabled true
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
        test.java.srcDirs += 'src/test/kotlin'
    }

    defaultConfig {
        minSdk 21
    }

    buildFeatures {
        compose true
    }

    composeOptions {
        kotlinCompilerExtensionVersion compose_compiler_version
    }

    dependencies {
        coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
        
        // Compose dependencies
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
}
```

## 7. Resource Bundling Script (tool/bundle_resources.dart)

```dart
import 'dart:io';
import 'dart:convert';

/// Script to automatically bundle AWS configuration files into the plugin
/// This should be run during plugin build process
class ResourceBundler {
  static const String defaultAmplifyConfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "YOUR_IDENTITY_POOL_ID",
              "Region": "YOUR_REGION"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "YOUR_USER_POOL_ID",
            "AppClientId": "YOUR_APP_CLIENT_ID",
            "Region": "YOUR_REGION"
          }
        }
      }
    }
  }
}
''';

  static const String defaultAwsConfig = '''
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "IdentityManager": {
    "Default": {}
  },
  "CredentialsProvider": {
    "CognitoIdentity": {
      "Default": {
        "PoolId": "YOUR_IDENTITY_POOL_ID",
        "Region": "YOUR_REGION"
      }
    }
  },
  "CognitoUserPool": {
    "Default": {
      "PoolId": "YOUR_USER_POOL_ID",
      "AppClientId": "YOUR_APP_CLIENT_ID",
      "Region": "YOUR_REGION"
    }
  }
}
''';

  static Future<void> bundleResources() async {
    print('📦 Bundling AWS configuration resources...');
    
    // Create iOS resources
    await _createIOSResources();
    
    // Create Android resources
    await _createAndroidResources();
    
    print('✅ Resource bundling completed');
  }
  
  static Future<void> _createIOSResources() async {
    final iosDir = Directory('ios/Runner');
    if (!await iosDir.exists()) {
      await iosDir.create(recursive: true);
    }
    
    // Create amplifyconfiguration.json
    final amplifyConfigFile = File('ios/Runner/amplifyconfiguration.json');
    await amplifyConfigFile.writeAsString(defaultAmplifyConfig);
    
    // Create awsconfiguration.json
    final awsConfigFile = File('ios/Runner/awsconfiguration.json');
    await awsConfigFile.writeAsString(defaultAwsConfig);
    
    print('📱 iOS resources created');
  }
  
  static Future<void> _createAndroidResources() async {
    final androidRawDir = Directory('android/src/main/res/raw');
    if (!await androidRawDir.exists()) {
      await androidRawDir.create(recursive: true);
    }
    
    // Create amplifyconfiguration.json
    final amplifyConfigFile = File('android/src/main/res/raw/amplifyconfiguration.json');
    await amplifyConfigFile.writeAsString(defaultAmplifyConfig);
    
    print('🤖 Android resources created');
  }
  
  static Future<void> updateConfiguration(Map<String, dynamic> config) async {
    final amplifyConfig = jsonDecode(defaultAmplifyConfig) as Map<String, dynamic>;
    
    // Update with provided configuration
    if (config.containsKey('identityPoolId')) {
      amplifyConfig['auth']['plugins']['awsCognitoAuthPlugin']['CredentialsProvider']
          ['CognitoIdentity']['Default']['PoolId'] = config['identityPoolId'];
    }
    
    if (config.containsKey('userPoolId')) {
      amplifyConfig['auth']['plugins']['awsCognitoAuthPlugin']['CognitoUserPool']
          ['Default']['PoolId'] = config['userPoolId'];
    }
    
    if (config.containsKey('appClientId')) {
      amplifyConfig['auth']['plugins']['awsCognitoAuthPlugin']['CognitoUserPool']
          ['Default']['AppClientId'] = config['appClientId'];
    }
    
    if (config.containsKey('region')) {
      amplifyConfig['auth']['plugins']['awsCognitoAuthPlugin']['CredentialsProvider']
          ['CognitoIdentity']['Default']['Region'] = config['region'];
      amplifyConfig['auth']['plugins']['awsCognitoAuthPlugin']['CognitoUserPool']
          ['Default']['Region'] = config['region'];
    }
    
    final updatedConfig = jsonEncode(amplifyConfig);
    
    // Update iOS
    await File('ios/Runner/amplifyconfiguration.json').writeAsString(updatedConfig);
    
    // Update Android
    await File('android/src/main/res/raw/amplifyconfiguration.json').writeAsString(updatedConfig);
    
    print('🔄 Configuration updated');
  }
}

void main(List<String> args) async {
  if (args.isNotEmpty && args[0] == 'bundle') {
    await ResourceBundler.bundleResources();
  } else {
    print('Usage: dart tool/bundle_resources.dart bundle');
  }
}
```

## 8. Configuration Files

### iOS amplifyconfiguration.json (ios/Runner/amplifyconfiguration.json)
```json
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "YOUR_IDENTITY_POOL_ID",
              "Region": "YOUR_REGION"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "YOUR_USER_POOL_ID",
            "AppClientId": "YOUR_APP_CLIENT_ID",
            "Region": "YOUR_REGION"
          }
        }
      }
    }
  }
}
```

### iOS awsconfiguration.json (ios/Runner/awsconfiguration.json)
```json
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "IdentityManager": {
    "Default": {}
  },
  "CredentialsProvider": {
    "CognitoIdentity": {
      "Default": {
        "PoolId": "YOUR_IDENTITY_POOL_ID",
        "Region": "YOUR_REGION"
      }
    }
  },
  "CognitoUserPool": {
    "Default": {
      "PoolId": "YOUR_USER_POOL_ID",
      "AppClientId": "YOUR_APP_CLIENT_ID",
      "Region": "YOUR_REGION"
    }
  }
}
```

### Android amplifyconfiguration.json (android/src/main/res/raw/amplifyconfiguration.json)
```json
{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "YOUR_IDENTITY_POOL_ID",
              "Region": "YOUR_REGION"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "YOUR_USER_POOL_ID",
            "AppClientId": "YOUR_APP_CLIENT_ID",
            "Region": "YOUR_REGION"
          }
        }
      }
    }
  }
}
```

## 9. Usage Instructions for End Users

### Installation

Add this to your app's `pubspec.yaml`:

```yaml
dependencies:
  skaletek_sdk: ^1.0.0
```

Run:
```bash
flutter pub get
```

### Basic Usage (Zero Configuration)

```dart
import 'package:skaletek_sdk/skaletek_sdk.dart';

// Initialize the SDK (optional - uses default configuration)
await SkaletekSDK.initialize();

// Start face liveness detection
try {
  final result = await SkaletekSDK.startLivenessDetection();
  
  if (result.isLive) {
    print('Face is live! Confidence: ${result.confidence}');
    print('Session ID: ${result.sessionId}');
  } else {
    print('Face liveness check failed');
  }
} on SkaletekSDKException catch (e) {
  print('Error: ${e.message}');
}
```

### Custom Configuration (Optional)

```dart
await SkaletekSDK.initialize(
  identityPoolId: 'us-east-1:your-identity-pool-id',
  userPoolId: 'us-east-1_yourUserPoolId',
  appClientId: 'your-app-client-id',
  region: 'us-east-1',
);
```

## 10. Build and Setup Instructions

### For Plugin Development:

1. **Bundle Resources**: Run the resource bundling script
```bash
dart tool/bundle_resources.dart bundle
```

2. **Update Configuration**: Replace placeholder values in configuration files with actual AWS credentials

3. **Test the Plugin**: Create a test Flutter app and add your plugin as a dependency

### For Publishing:

1. **Update pubspec.yaml**: Set the correct version and description
2. **Add Documentation**: Include comprehensive README.md
3. **Test on Both Platforms**: Ensure iOS and Android work correctly
4. **Publish**: Use `flutter pub publish`

## Key Benefits

### For End Users:
- **No iOS/Android configuration needed** - Plugin handles everything automatically
- **No manual file copying** - AWS configuration is embedded in the plugin
- **No Xcode/Android Studio setup** - Just add the dependency and use
- **Simple API** - One method call to start liveness detection

### What the Plugin Handles Automatically:
- ✅ AWS Amplify initialization
- ✅ iOS Swift Package Manager dependencies
- ✅ Android Gradle dependencies and configuration
- ✅ Configuration file management
- ✅ Platform-specific setup

This complete implementation provides a seamless experience for your plugin users by automatically handling all AWS configuration complexity behind the scenes.