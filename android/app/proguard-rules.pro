# Flutter Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.provider.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Keep Rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# RevenueCat / Purchases Keep Rules
-keep class com.revenuecat.purchases.** { *; }

# Google Mobile Ads Keep Rules
-keep class com.google.android.gms.ads.** { *; }

# Flutter Local Notifications & Audio Keep Rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.ryanheise.audioservice.** { *; }

# Prevent obfuscating model classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter Play Store Split Install / Deferred Components
-dontwarn com.google.android.play.core.**

# AndroidX WorkManager and Room database rules
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**
-dontwarn androidx.work.**


