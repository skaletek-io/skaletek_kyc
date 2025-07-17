# Android Setup for Face Liveness Detection

This guide shows how to automatically configure your Android app to work with the Face Liveness Detector.

## Problem
The Face Liveness Detector requires `amplifyconfiguration.json` to be located in `android/app/src/main/res/raw/` directory. Without this setup, you'll get this error:
```
E/FaceLivenessView: FaceLivenessDetector error: CameraPermissionDeniedException: Camera permissions have not been granted.
```

## Solution: Automatic Setup

Add this task to your `android/app/build.gradle` (or `build.gradle.kts`) file:

### For build.gradle (Groovy)
```gradle
// Add at the bottom of android/app/build.gradle

task copyAmplifyConfig {
    doLast {
        def homeDir = System.getProperty('user.home')
        def pubCacheDir = file("${homeDir}/.pub-cache/hosted/pub.dev")
        def sourceFile = null
        
        // Find the plugin in pub cache
        if (pubCacheDir.exists()) {
            pubCacheDir.listFiles().each { dir ->
                if (dir.name.startsWith('skaletek_kyc-')) {
                    def configFile = file("${dir.absolutePath}/assets/amplifyconfiguration.json")
                    if (configFile.exists()) {
                        sourceFile = configFile
                        return true
                    }
                }
            }
        }
        
        def targetDir = file("src/main/res/raw")
        if (sourceFile && sourceFile.exists()) {
            targetDir.mkdirs()
            copy {
                from sourceFile
                into targetDir
            }
            println "✅ Copied amplifyconfiguration.json for face liveness"
        } else {
            println "⚠️ Could not find amplifyconfiguration.json in plugin cache"
        }
    }
}

preBuild.dependsOn copyAmplifyConfig
```

### For build.gradle.kts (Kotlin)
```kotlin
// Add at the bottom of android/app/build.gradle.kts

tasks.register("copyAmplifyConfig") {
    doLast {
        val homeDir = System.getProperty("user.home")
        val pubCacheDir = file("${homeDir}/.pub-cache/hosted/pub.dev")
        var sourceFile: File? = null
        
        // Find the plugin in pub cache
        if (pubCacheDir.exists()) {
            pubCacheDir.listFiles()?.forEach { dir ->
                if (dir.name.startsWith("skaletek_kyc-")) {
                    val configFile = file("${dir.absolutePath}/assets/amplifyconfiguration.json")
                    if (configFile.exists()) {
                        sourceFile = configFile
                        return@forEach
                    }
                }
            }
        }
        
        val targetDir = file("src/main/res/raw")
        sourceFile?.let { source ->
            if (source.exists()) {
                targetDir.mkdirs()
                source.copyTo(file("${targetDir.path}/amplifyconfiguration.json"), overwrite = true)
                println("✅ Copied amplifyconfiguration.json for face liveness")
            }
        } ?: println("⚠️ Could not find amplifyconfiguration.json in plugin cache")
    }
}

tasks.named("preBuild") {
    dependsOn("copyAmplifyConfig")
}
```

## What This Does

1. **Automatic Detection**: Finds the skaletek_kyc plugin in your pub cache
2. **File Copying**: Copies `amplifyconfiguration.json` to the correct Android location
3. **Build Integration**: Runs automatically before each build
4. **No Manual Steps**: No need to manually copy files

## Verification

After adding the task and running your first build, you should see:
```
✅ Copied amplifyconfiguration.json for face liveness
```

The file will be created at: `android/app/src/main/res/raw/amplifyconfiguration.json`

## Troubleshooting

If you see the warning message:
```
⚠️ Could not find amplifyconfiguration.json in plugin cache
```

Try these steps:
1. Run `flutter pub get` to ensure the plugin is properly installed
2. Check that `skaletek_kyc` is listed in your `pubspec.yaml`
3. Verify the plugin version is correctly specified

## Alternative: Manual Setup

If automatic setup doesn't work, you can manually copy the file:
1. Find the plugin in your pub cache: `~/.pub-cache/hosted/pub.dev/skaletek_kyc-*/`
2. Copy `assets/amplifyconfiguration.json` to `android/app/src/main/res/raw/`

## Result

With this setup, the Face Liveness Detector will work correctly and you won't see camera permission errors during face verification. 