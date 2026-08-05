plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "pl.bemowski.trekjot"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pl.bemowski.trekjot"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // S-06: Google Maps API key from local.properties (local dev) or GH Secrets (CI).
        val localFile = file("local.properties")
        val mapsKey = if (localFile.exists()) {
            localFile.readLines()
                .firstOrNull { it.startsWith("MAPS_API_KEY=") }
                ?.substringAfter("MAPS_API_KEY=")
                ?.trim()
        } else null
        manifestPlaceholders["MAPS_API_KEY"] = mapsKey
            ?: System.getenv("MAPS_API_KEY")
            ?: ""
        // firebase_app_distribution has production/staging flavors; pick production.
        missingDimensionStrategy("default", "production")
    }

    signingConfigs {
        create("release") {
            // CI decodes the keystore to a file and sets KEYSTORE_PATH env var.
            val ksPath = System.getenv("KEYSTORE_PATH")
            if (ksPath != null) {
                storeFile = file(ksPath)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Use real keystore if env vars are present (CI); fall back to debug (local dev).
            val hasKeystore = System.getenv("KEYSTORE_PATH") != null
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // ProGuard rules for flutter_places_sdk (R8 minification compatibility).
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
