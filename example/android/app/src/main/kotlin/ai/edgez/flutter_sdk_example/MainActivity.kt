package ai.edgez.flutter_sdk_example

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager
import ai.moonshine.voice.TextToSpeech as MoonshineTextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "ai.edgez.flutter_sdk_example/downloads"
    private val textToSpeechChannel = "ai.edgez.flutter_sdk_example/text_to_speech"
    private lateinit var speechChannel: MethodChannel
    private val speechExecutor = Executors.newSingleThreadExecutor()
    private val speechRequest = AtomicInteger()
    private var moonshineSpeech: MoonshineTextToSpeech? = null
    private var moonshineLanguage: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sourcePath = call.argument<String>("sourcePath")
            val fileName = call.argument<String>("fileName")
            if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                result.error("invalid_arguments", "Missing sourcePath or fileName", null)
                return@setMethodCallHandler
            }

            runCatching { saveToDownloads(File(sourcePath), fileName) }
                .onSuccess(result::success)
                .onFailure { error ->
                    Log.e("EdgezDownloads", "Unable to publish log file", error)
                    result.error("download_failed", error.message, null)
                }
        }

        speechChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            textToSpeechChannel,
        )
        speechChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text")
                    val languageTag = call.argument<String>("languageTag")
                    if (text.isNullOrBlank() || languageTag.isNullOrBlank()) {
                        result.error("invalid_arguments", "Missing text or languageTag", null)
                    } else {
                        speakTranslation(text, languageTag, result)
                    }
                }
                "stop" -> {
                    speechRequest.incrementAndGet()
                    speechExecutor.execute { moonshineSpeech?.stop() }
                    result.success(null)
                }
                "release" -> releaseSpeechEngine(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        speechRequest.incrementAndGet()
        speechExecutor.shutdownNow()
        moonshineSpeech?.close()
        moonshineSpeech = null
        moonshineLanguage = null
        super.onDestroy()
    }

    private fun speakTranslation(
        text: String,
        languageTag: String,
        result: MethodChannel.Result,
    ) {
        val request = speechRequest.incrementAndGet()
        speechExecutor.execute {
            try {
                var engine = moonshineSpeech
                if (engine == null || moonshineLanguage != languageTag) {
                    engine?.close()
                    notifySpeechProgress(0, "Preparing Moonshine voice")
                    engine = MoonshineTextToSpeech(applicationContext)
                        .language(languageTag)
                        .onProgress { fraction, file ->
                            notifySpeechProgress(
                                (fraction * 100).toInt().coerceIn(0, 100),
                                file,
                            )
                        }
                    if (languageTag == "zh-hans") {
                        engine.voice("kokoro_zf_xiaoxiao")
                    }
                    engine.load()
                    if (speechRequest.get() != request) {
                        engine.close()
                        completeSpeechError(
                            result,
                            "tts_request_replaced",
                            "A newer speech request replaced this one",
                        )
                        return@execute
                    }
                    moonshineSpeech = engine
                    moonshineLanguage = languageTag
                    notifySpeechProgress(100, "Moonshine voice ready")
                }
                engine.stop()
                engine.sayInBackground(text)
                runOnUiThread { result.success(null) }
            } catch (error: Throwable) {
                Log.e("EdgezMoonshineTts", "Moonshine speech failed", error)
                completeSpeechError(
                    result,
                    "moonshine_tts_failed",
                    error.message ?: error.javaClass.simpleName,
                )
            }
        }
    }

    private fun releaseSpeechEngine(result: MethodChannel.Result) {
        speechRequest.incrementAndGet()
        speechExecutor.execute {
            try {
                moonshineSpeech?.close()
                moonshineSpeech = null
                moonshineLanguage = null
                runOnUiThread { result.success(null) }
            } catch (error: Throwable) {
                Log.e("EdgezMoonshineTts", "Unable to release Moonshine speech", error)
                completeSpeechError(
                    result,
                    "moonshine_tts_release_failed",
                    error.message ?: error.javaClass.simpleName,
                )
            }
        }
    }

    private fun notifySpeechProgress(percent: Int, file: String?) {
        runOnUiThread {
            speechChannel.invokeMethod(
                "progress",
                mapOf("percent" to percent, "file" to (file ?: "")),
            )
        }
    }

    private fun completeSpeechError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        runOnUiThread { result.error(code, message, null) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureLockScreen(intent)
    }

    override fun onNewIntent(intent: Intent) {
        configureLockScreen(intent)
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun configureLockScreen(intent: Intent?) {
        val showForIncomingCall = intent?.data?.let { uri ->
            uri.scheme == "edgez" && uri.host == "call"
        } == true
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(showForIncomingCall)
            setTurnScreenOn(showForIncomingCall)
        } else if (showForIncomingCall) {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        } else {
            @Suppress("DEPRECATION")
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    private fun saveToDownloads(source: File, fileName: String): String {
        require(source.isFile) { "Staged log file does not exist" }
        require(!fileName.contains('/') && !fileName.contains('\\')) {
            "Invalid download file name"
        }
        check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "System Downloads requires Android 10 or newer"
        }

        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "text/plain")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val resolver = contentResolver
        val uri = checkNotNull(
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values),
        ) { "Unable to create the Downloads entry" }

        try {
            resolver.openOutputStream(uri, "w").use { output ->
                checkNotNull(output) { "Unable to open the Downloads entry" }
                source.inputStream().use { input -> input.copyTo(output) }
            }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (error: Throwable) {
            resolver.delete(uri, null, null)
            throw error
        }
        return fileName
    }
}
