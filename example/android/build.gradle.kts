buildscript {
    extra.apply {
        set("kotlin_version", "2.1.0")
        set("compose_version", "1.6.7")
        set("compose_compiler_version", "1.5.14")
    }
    
    repositories {
        google()
        mavenCentral()
         maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")
    }
    
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("org.jetbrains.kotlin:compose-compiler-gradle-plugin:2.1.0")
    }
}


allprojects {
    repositories {
        google()
        mavenCentral()
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

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
