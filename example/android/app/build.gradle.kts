plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose") 
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.example"
    compileSdk = 35
     ndkVersion = "27.0.12077973"

      buildFeatures {
        compose = true
    }

      composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
         isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
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

// Skaletek KYC Android Setup
apply {
    val pubCacheDir = file("${System.getProperty("user.home")}/.pub-cache/hosted/pub.dev")
    val setupScript = pubCacheDir.listFiles()?.find { it.name.startsWith("skaletek_kyc-") }
        ?.let { file("${it.absolutePath}/android/skaletek_kyc.gradle") }
    
    if (setupScript?.exists() == true) {
        from(setupScript)
    }
}
