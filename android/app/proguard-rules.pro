# --- PROTECCIÓN PARA NOTIFICACIONES Y GSON ---
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-dontwarn sun.misc.**

# Proteger el plugin de notificaciones
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Proteger componentes visuales de Android
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class android.support.v4.app.NotificationCompat** { *; }

# Proteger los iconos (R8 a veces los borra)
-keep class **.R$drawable { *; }
-keep class **.R$mipmap { *; }