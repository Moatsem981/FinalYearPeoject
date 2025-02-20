plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Ensure Firebase plugin is applied
}

android {
    namespace = "com.example.myunicircle1"
    compileSdk = 34 // ✅ Ensure it's an actual number, not flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // ✅ Fix: Ensure required NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.myunicircle1"
        minSdk = 23 // ✅ Firebase requires at least 23
        targetSdk = 34 // ✅ Use an explicit number, not flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // ✅ Keep debug signing for now
        }
    }
}

dependencies {
    implementation("com.google.firebase:firebase-firestore-ktx")
}


// ✅ Apply Firebase Google Services Plugin (Ensures Firebase works properly)
apply(plugin = "com.google.gms.google-services")
