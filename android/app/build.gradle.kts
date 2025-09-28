plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after Android + Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add this line for Firebase
}

kotlin {
    jvmToolchain(17)
}

android {
    namespace = "com.example.emergency_res_loc_new"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    defaultConfig {
        applicationId = "com.example.emergency_resource_locator"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Let Flutter Firebase plugins handle their own Android dependencies
dependencies {
    // Remove manual Firebase dependencies - let Flutter plugins manage them
}

flutter {
    source = "../.."
}