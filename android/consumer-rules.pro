# Organic Maps' native library resolves Java classes, enum fields, constructors,
# and callback methods by their literal JNI names. R8 cannot infer those native
# references, so obfuscating the SDK classes causes fatal JNI lookup failures
# such as BookmarkManager.INSTANCE returning a null field ID.
-keep,includedescriptorclasses class app.organicmaps.sdk.** { *; }

# HttpClient.cpp receives an okhttp3.Call from Java and resolves cancel() on
# the concrete runtime class with GetObjectClass/GetMethodID. Keep that
# interface implementation method name even when OkHttp itself is optimized.
-keepclassmembers class * implements okhttp3.Call {
    void cancel();
}

# Preserve native entry-point names in this plugin and any future dependencies.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
