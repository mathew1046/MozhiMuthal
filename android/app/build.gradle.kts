import java.security.MessageDigest

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mozhimuthal.mozhimuthal"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mozhimuthal.mozhimuthal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.18.0")
    implementation("com.cloudflare.realtimekit.android-vad:webrtc:2.0.10-cf.4")
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar", "*.aar"))))
}

// The model is intentionally checked at build time. It must be supplied by
// the release process; the app never downloads a model or uses a token.
tasks.register("verifyPyannoteModel") {
    val model = file("src/main/assets/models/pyannote-segmentation-3.0.onnx")
    val manifest = file("src/main/assets/models/SHA256SUMS")
    doLast {
        check(model.exists()) { "Missing pinned Pyannote ONNX model: $model" }
        check(manifest.exists()) { "Missing model checksum manifest: $manifest" }
        val expected = manifest.readLines().firstOrNull { it.endsWith("  pyannote-segmentation-3.0.onnx") }
            ?.substringBefore("  ")?.trim()
        check(!expected.isNullOrBlank()) { "Checksum manifest has no model entry" }
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(model.readBytes()).joinToString("") { byte -> "%02x".format(byte) }
        check(digest.equals(expected, ignoreCase = true)) { "Pyannote model SHA-256 mismatch" }
    }
}
