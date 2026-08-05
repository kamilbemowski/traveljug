# Keep j2objc annotations — required by flutter_places_sdk via Guava
-dontwarn com.google.j2objc.annotations.**
-keep class com.google.j2objc.annotations.** { *; }

# Keep Google Places SDK
-keep class com.google.android.libraries.places.** { *; }
-dontwarn com.google.android.libraries.places.**

# Keep Flutter Places SDK
-keep class com.msh.flutter_google_places_sdk.** { *; }
