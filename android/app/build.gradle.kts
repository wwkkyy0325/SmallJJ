plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smalljj.health_app"
    compileSdk = flutter.compileSdkVersion
    // 不指定 ndkVersion：本项目没有 C/C++ 源码，sqlite3 用 sqlite3_flutter_libs
    // 的预编译产物；指定 NDK 只会在 NDK 副本损坏时把构建卡死。

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // 签名钥匙钉在项目里，不依赖 ANDROID_SDK_HOME / ANDROID_USER_HOME 指向哪儿。
    // 之前就是因为建包时那套环境变量指到了 ~/dev/android-avd，Gradle 在那里生成了
    // 另一把 debug 钥匙，debug/profile 包和 release 包签名不同，手机上一装就
    // INSTALL_FAILED_UPDATE_INCOMPATIBLE，只能卸载（数据一起没）。
    // 这是自用包、不上架，密码就写在这里；换钥匙必须卸载重装。
    signingConfigs {
        create("app") {
            storeFile = file("signing/smalljj.jks")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.smalljj.health_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            // 与 release 同一把钥匙：手机上装哪个包都能 -r 覆盖，不用卸载。
            signingConfig = signingConfigs.getByName("app")
        }
        release {
            // TODO: 真要上架时换成自己的正式 keystore。
            signingConfig = signingConfigs.getByName("app")
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
