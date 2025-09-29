plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // Step 3: Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.my_app"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.my_app"

        // Firebase plugins require minSdk 23
        minSdk = 23
        targetSdk = 34

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.firebase:firebase-analytics:21.6.2")
    // 👇 yaha aur Firebase dependencies add kar sakti ho apne use-case k hisaab se
    // For example:
    // implementation("com.google.firebase:firebase-auth:23.0.0")
    // implementation("com.google.firebase:firebase-firestore:25.1.1")
}
