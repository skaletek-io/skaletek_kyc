# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# AWS Amplify and Smithy Kotlin rules
-dontwarn aws.smithy.kotlin.runtime.http.engine.okhttp4.OkHttp4Engine
-keep class aws.smithy.kotlin.runtime.** { *; }
-keep class com.amplifyframework.** { *; }
-dontwarn com.amplifyframework.**

# AWS SDK keep rules
-keep class software.amazon.awssdk.** { *; }
-dontwarn software.amazon.awssdk.**

# OkHttp rules for AWS SDK
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Gson rules (often used with AWS)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.example.test_ekyc.**$$serializer { *; }
-keepclassmembers class com.example.test_ekyc.** {
    *** Companion;
}
-keepclasseswithmembers class com.example.test_ekyc.** {
    kotlinx.serialization.KSerializer serializer(...);
}