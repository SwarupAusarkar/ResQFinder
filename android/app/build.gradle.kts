//plugins {
//    id("com.android.application")
//    id("kotlin-android")
//    // The Flutter Gradle Plugin must be applied after Android + Kotlin
//    id("dev.flutter.flutter-gradle-plugin")
//    id("com.google.gms.google-services") // Add this line for Firebase
//}
//
//kotlin {
//    jvmToolchain(17)
//}
//
//android {
//    namespace = "com.example.emergency_res_loc_new"
//    compileSdk = 36
//    ndkVersion = "27.0.12077973"
//
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_17
//        targetCompatibility = JavaVersion.VERSION_17
//    }
//
//    kotlinOptions {
//        jvmTarget = "17"
//    }
//
//    defaultConfig {
//        applicationId = "com.example.emergency_resource_locator"
//        minSdk = flutter.minSdkVersion
//        targetSdk = 36
//        versionCode = flutter.versionCode
//        versionName = flutter.versionName
//    }
//
//    buildTypes {
//        release {
//            signingConfig = signingConfigs.getByName("debug")
//        }
//    }
//}
//
//// Let Flutter Firebase plugins handle their own Android dependencies
//dependencies {
//    // Remove manual Firebase dependencies - let Flutter plugins manage them
//}
//
//flutter {
//    source = "../.." }
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after Android + Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase
}

kotlin {
    jvmToolchain(17)
}

android {
    namespace = "com.example.emergency_res_loc_new"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Enable Java 17 + desugaring
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.emergency_resource_locator"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ✅ Updated to required version
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Let Flutter Firebase plugins handle their own Android dependencies
}

flutter {
    source = "../.."
}
