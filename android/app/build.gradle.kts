plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gastos_personales"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Habilitar desugaring para usar características nuevas de Java en Androids viejos
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        // TODO: Especifica tu ID único de aplicación aquí si lo cambias
        applicationId = "com.example.gastos_personales"
        
        // Valores tomados de la configuración de Flutter
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Habilitar MultiDex para apps grandes (necesario por las librerías que usas)
        multiDexEnabled = true 
    }

    buildTypes {
        getByName("release") {
            // 1. FIRMA: Usamos la clave de debug para que puedas probar el APK release
            // (Para subir a la tienda, esto se cambia después)
            signingConfig = signingConfigs.getByName("debug")

            // 2. OPTIMIZACIÓN Y SEGURIDAD (Kotlin DSL Correcto):
            // isMinifyEnabled = false -> Intenta reducir el código (necesita ProGuard bien configurado)
            isMinifyEnabled = false
            
            // isShrinkResources = false -> NO borra imágenes/recursos para evitar errores
            isShrinkResources = false 
            
            // 3. REGLAS PROGUARD (Sintaxis con paréntesis y comillas dobles):
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Librería necesaria para que funcionen las fechas y zonas horarias en Androids viejos
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}