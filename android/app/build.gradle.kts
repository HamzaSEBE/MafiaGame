import java.security.KeyStore
import java.security.MessageDigest
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingPropertiesFile = rootProject.file("key.properties")
if (signingPropertiesFile.exists()) signingProperties.load(FileInputStream(signingPropertiesFile))
val useExistingTestSigning = providers.gradleProperty("useExistingTestSigning").orNull == "true"
val existingTestKey = file(System.getProperty("user.home") + "/.android/debug.keystore")
if (useExistingTestSigning) {
    if (!existingTestKey.exists()) throw GradleException("Existing test keystore is missing; refusing to create a replacement.")
    val keyStore = KeyStore.getInstance(existingTestKey, "android".toCharArray())
    val fingerprint = MessageDigest.getInstance("SHA-256")
        .digest(keyStore.getCertificate("androiddebugkey").encoded)
        .joinToString("") { "%02x".format(it) }
    if (fingerprint != "8cf88a21502fd3314a9469fdaa56333712a81f1e7cd853418ca7e5461355f544") {
        throw GradleException("Test signature does not match the existing Mafia APK.")
    }
}
val wantsRelease = gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (wantsRelease && !signingPropertiesFile.exists() && !useExistingTestSigning) {
    throw GradleException("Release signing requires android/key.properties. See android/key.properties.example.")
}

android {
    namespace = "com.example.mafia_nightfall"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mafia_nightfall"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (useExistingTestSigning) getByName("debug") {
            storeFile = existingTestKey
        }
        if (signingPropertiesFile.exists()) create("release") {
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
            storeFile = file(signingProperties.getProperty("storeFile"))
            storePassword = signingProperties.getProperty("storePassword")
        }
    }
    buildTypes {
        release {
            if (signingPropertiesFile.exists()) signingConfig = signingConfigs.getByName("release")
            else if (useExistingTestSigning) signingConfig = signingConfigs.getByName("debug")
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
