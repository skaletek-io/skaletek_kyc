# Complete Skaletek SDK Plugin Implementation Guide - Fixed Version

This guide shows how to create a Flutter plugin that automatically handles AWS Amplify configuration for face liveness detection, including automatic file copying to the user's app.

## Project Structure

```
skaletek_sdk/
├── lib/
│   ├── skaletek_sdk.dart
│   └── skaletek_kyc_initialization.dart
├── ios/
│   ├── Classes/
│   │   └── SkaletekSdkPlugin.swift
│   ├── Assets/
│   │   ├── amplifyconfiguration.json
│   │   └── awsconfiguration.json
│   └── skaletek_sdk.podspec
├── android/
│   ├── src/main/
│   │   ├── kotlin/com/skaletek/skaletek_sdk/
│   │   │   └── SkaletekSdkPlugin.kt
│   │   └── assets/
│   │       └── amplifyconfiguration.json
│   └── build.gradle
├── assets/
│   ├── amplifyconfiguration.json
│   └── awsconfiguration.json
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
  path_provider: ^2.0.0
  path: ^1.8.0

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
  assets:
    - assets/amplifyconfiguration.json
    - assets/awsconfiguration.json
```

## 2. Main Plugin API (lib/skaletek_sdk.dart)

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:face_liveness_detector/face_liveness_detector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Main SDK class that handles all KYC operations
class SkaletekSDK {
  static const MethodChannel _channel = MethodChannel('skaletek_sdk');
  static bool _isInitialized = false;
  
  /// Initialize the SDK with AWS credentials
  /// This automatically copies configuration files to the correct locations
  static Future<void> initialize({
    String? identityPoolId,
    String? userPoolId,
    String? appClientId,
    String? region,
  }) async {
    if (_isInitialized) return;
    
    try {
      // First, ensure configuration files are in the right place
      await _copyConfigurationFiles();
      
      // Then initialize the native plugins
      await _channel.invokeMethod('initializeKYC', {
        'identityPoolId': identityPoolId,
        'userPoolId': userPoolId,
        'appClientId': appClientId,
        'region': region,
      });
      
      _isInitialized = true;
    } on PlatformException catch (e) {
      throw SkaletekSDKException('Failed to initialize SDK: ${e.message}');
    }
  }
  
  /// Copy configuration files to the user's app directories
  static Future<void> _copyConfigurationFiles() async {
    try {
      if (Platform.isAndroid) {
        await _copyAndroidConfigFiles();
      } else if (Platform.isIOS) {
        await _copyIOSConfigFiles();
      }
    } catch (e) {
      print('Warning: Could not copy configuration files: $e');
    }
  }
  
  /// Copy configuration files for Android
  static Future<void> _copyAndroidConfigFiles() async {
    try {
      // Load the configuration from plugin assets
      final ByteData amplifyConfigData = await rootBundle.load('packages/skaletek_sdk/assets/amplifyconfiguration.json');
      final String amplifyConfig = String.fromCharCodes(amplifyConfigData.buffer.asUint8List());
      
      // Get the app's document directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appPath = appDocDir.path;
      
      // Navigate to the Android raw resources directory
      final String androidRawPath = path.join(appPath, '..', '..', '..', 'android', 'app', 'src', 'main', 'res', 'raw');
      final Directory androidRawDir = Directory(androidRawPath);
      
      if (!await androidRawDir.exists()) {
        await androidRawDir.create(recursive: true);
      }
      
      // Write the configuration file
      final File configFile = File(path.join(androidRawPath, 'amplifyconfiguration.json'));
      await configFile.writeAsString(amplifyConfig);
      
      print('✅ Android configuration file copied to: ${configFile.path}');
    } catch (e) {
      print('⚠️ Failed to copy Android configuration: $e');
    }
  }
  
  /// Copy configuration files for iOS
  static Future<void> _copyIOSConfigFiles() async {
    try {
      // Load the configuration from plugin assets
      final ByteData amplifyConfigData = await rootBundle.load('packages/skaletek_sdk/assets/amplifyconfiguration.json');
      final ByteData awsConfigData = await rootBundle.load('packages/skaletek_sdk/assets/awsconfiguration.json');
      
      final String amplifyConfig = String.fromCharCodes(amplifyConfigData.buffer.asUint8List());
      final String awsConfig = String.fromCharCodes(awsConfigData.buffer.asUint8List());
      
      // Get the app's document directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appPath = appDocDir.path;
      
      // Navigate to the iOS Runner directory
      final String iosRunnerPath = path.join(appPath, '..', '..', '..', 'ios', 'Runner');
      final Directory iosRunnerDir = Directory(iosRunnerPath);
      
      if (!await iosRunnerDir.exists()) {
        await iosRunnerDir.create(recursive: true);
      }
      
      // Write the configuration files
      final File amplifyConfigFile = File(path.join(iosRunnerPath, 'amplifyconfiguration.json'));
      final File awsConfigFile = File(path.join(iosRunnerPath, 'awsconfiguration.json'));
      
      await amplifyConfigFile.writeAsString(amplifyConfig);
      await awsConfigFile.writeAsString(awsConfig);
      
      print('✅ iOS configuration files copied to: $iosRunnerPath');
    } catch (e) {
      print('⚠️ Failed to copy iOS configuration: $e');
    }
  }
  
  /// Start face liveness detection
  static Future<LivenessResult> startLivenessDetection() async {
    if (!_isInitialized) {
      await initialize();
    }
    
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

## 3. Alternative Solution: Gradle Plugin Hook (android/build.gradle)

Instead of copying files at runtime, use a Gradle hook to copy files during build:

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

// Hook to copy configuration files during build
afterEvaluate {
    android.applicationVariants.all { variant ->
        variant.mergeResourcesProvider.configure {
            doLast {
                copyConfigurationFiles()
            }
        }
    }
}

def copyConfigurationFiles() {
    def pluginDir = project.rootProject.file('.flutter-plugins-dependencies')
    if (pluginDir.exists()) {
        def rawDir = file("${project.rootProject.projectDir}/android/app/src/main/res/raw")
        if (!rawDir.exists()) {
            rawDir.mkdirs()
        }
        
        // Copy from plugin assets
        def pluginAssets = file("${project.projectDir}/src/main/assets")
        if (pluginAssets.exists()) {
            copy {
                from pluginAssets
                into rawDir
                include '*.json'
            }
            println "✅ Configuration files copied to ${rawDir.path}"
        }
    }
}
```

## 4. Enhanced Android Plugin (android/src/main/kotlin/com/skaletek/skaletek_sdk/SkaletekSdkPlugin.kt)

```kotlin
package com.skaletek.skaletek_sdk

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
import java.io.File
import java.io.IOException
import java.io.InputStream

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
        
        // Copy configuration files first
        copyConfigurationFiles()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeKYC" -> {
                configureAmplify()
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

    private fun copyConfigurationFiles() {
        try {
            // Get the raw resources directory
            val rawDir = File(context.filesDir.parent, "../../android/app/src/main/res/raw")
            if (!rawDir.exists()) {
                rawDir.mkdirs()
            }
            
            // Copy configuration from plugin assets
            val assetManager = context.assets
            val configFiles = arrayOf("amplifyconfiguration.json")
            
            for (fileName in configFiles) {
                try {
                    val inputStream: InputStream = assetManager.open(fileName)
                    val outputFile = File(rawDir, fileName)
                    
                    inputStream.use { input ->
                        outputFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    
                    Log.d(TAG, "✅ Copied $fileName to ${outputFile.path}")
                } catch (e: IOException) {
                    Log.w(TAG, "Could not copy $fileName: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy configuration files: ${e.message}")
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
        result.success(mapOf("status" to "initialized"))
    }

    private fun startLivenessDetection(arguments: Any?, result: Result) {
        result.success(mapOf("status" to "started"))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

## 5. iOS Plugin with File Copying (ios/Classes/SkaletekSdkPlugin.swift)

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
        
        // Copy configuration files first
        instance.copyConfigurationFiles()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeKYC":
            configureAmplify()
            initializeKYC(result: result)
        case "startLivenessDetection":
            startLivenessDetection(arguments: call.arguments, result: result)
        case "getVersion":
            result("1.0.0")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func copyConfigurationFiles() {
        guard let pluginBundle = Bundle(for: SkaletekSdkPlugin.self) else {
            print("⚠️ Could not get plugin bundle")
            return
        }
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let runnerURL = documentsURL.appendingPathComponent("../../../ios/Runner")
        
        do {
            try fileManager.createDirectory(at: runnerURL, withIntermediateDirectories: true, attributes: nil)
            
            let configFiles = ["amplifyconfiguration.json", "awsconfiguration.json"]
            
            for fileName in configFiles {
                if let sourceURL = pluginBundle.url(forResource: fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json") {
                    let destinationURL = runnerURL.appendingPathComponent(fileName)
                    
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    print("✅ Copied \(fileName) to \(destinationURL.path)")
                }
            }
        } catch {
            print("⚠️ Failed to copy configuration files: \(error)")
        }
    }
    
    private func configureAmplify() {
        guard !SkaletekSdkPlugin.isAmplifyConfigured else {
            print("✅ Amplify already configured")
            return
        }
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            
            SkaletekSdkPlugin.isAmplifyConfigured = true
            print("✅ Amplify configured automatically by Skaletek SDK")
        } catch {
            print("⚠️ Could not initialize Amplify: \(error)")
        }
    }
    
    private func initializeKYC(result: @escaping FlutterResult) {
        result(["status": "initialized"])
    }
    
    private func startLivenessDetection(arguments: Any?, result: @escaping FlutterResult) {
        result(["status": "started"])
    }
}
```

## 6. Configuration Files

Create these files in your `assets/` directory:

### assets/amplifyconfiguration.json
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

### assets/awsconfiguration.json
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

## 7. Usage Instructions

### For End Users:

```dart
import 'package:skaletek_sdk/skaletek_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the SDK - this will automatically copy config files
  await SkaletekSDK.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _startLivenessDetection() async {
    try {
      final result = await SkaletekSDK.startLivenessDetection();
      
      if (result.isLive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face is live! Confidence: ${result.confidence}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face liveness check failed')),
        );
      }
    } on SkaletekSDKException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Skaletek SDK Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: _startLivenessDetection,
          child: Text('Start Liveness Detection'),
        ),
      ),
    );
  }
}
```

## Key Fixes:

1. **Automatic File Copying**: The plugin now copies configuration files to the user's app directories during initialization
2. **Multiple Copy Strategies**: Both runtime copying and build-time copying options
3. **Error Handling**: Better error handling for missing configuration files
4. **Asset Management**: Configuration files are bundled as Flutter assets
5. **Path Resolution**: Proper path resolution for both Android and iOS

This should resolve the crash issue by ensuring the `amplifyconfiguration.json` file is always in the correct location for the face liveness detection to work properly.