# Organic Maps' native library resolves Java classes, enum fields, constructors,
# and callback methods by their literal JNI names. R8 cannot infer those native
# references, so obfuscating the SDK classes causes fatal JNI lookup failures
# such as BookmarkManager.INSTANCE returning a null field ID.
-keep class app.organicmaps.sdk.** { *; }

# Preserve native entry-point names in this plugin and any future dependencies.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
