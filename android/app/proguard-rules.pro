# Zego SDK
-keep class com.zego.** { *; }
-dontwarn com.zego.**
-keep class com.itgsa.opensdk.** { *; }
-dontwarn com.itgsa.opensdk.**

# Jackson and DOM classes
-keep class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.**
-keep class java.beans.** { *; }
-dontwarn java.beans.**
-keep class org.w3c.dom.** { *; }
-dontwarn org.w3c.dom.**

# Flutter-specific
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Prevent R8 from removing resources
-keep class **.R$* { *; }