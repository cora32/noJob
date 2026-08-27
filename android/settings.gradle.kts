pluginManagement {
    // Load local.properties to handle machine-specific environment fixes
    val localProperties = java.util.Properties()
    val localPropertiesFile = file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
    }

    // Fix for ANDROID_PREFS_ROOT conflict if defined in local.properties
    localProperties.getProperty("android.prefsRoot")?.let {
        System.setProperty("android.prefsRoot", it)
    }

    val flutterSdkPath =
        run {
            val sdkPath = localProperties.getProperty("flutter.sdk")
            require(sdkPath != null) { "flutter.sdk not set in local.properties" }
            sdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
