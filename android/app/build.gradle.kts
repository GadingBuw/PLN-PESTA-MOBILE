import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Membaca versi dari local.properties agar tidak error "Unresolved reference"
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.example.pesta_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Perbaikan warning jvmTarget deprecated
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.pesta_mobile"
        
        // Supabase butuh minimal SDK 21
        minSdk = flutter.minSdkVersion 
        
        // Perbaikan Unresolved reference: targetSdk
        targetSdk = flutter.targetSdkVersion
        
        // Perbaikan Unresolved reference: flutterVersionCode & flutterVersionName
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            // Di Kotlin DSL, gunakan awalan 'is'
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
