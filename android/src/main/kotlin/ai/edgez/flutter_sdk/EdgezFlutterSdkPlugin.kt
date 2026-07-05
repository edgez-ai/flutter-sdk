package ai.edgez.flutter_sdk

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class EdgezFlutterSdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "edgez_flutter_sdk/methods")
        events = EventChannel(binding.binaryMessenger, "edgez_flutter_sdk/events")
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        eventSink = null
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        emit(mapOf("type" to "log", "log" to "EdgeZ Flutter SDK attached"))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startBleScan" -> {
                // Native reference: EdgezBleClient.startScan { candidate -> ... }.
                emit(mapOf("type" to "log", "log" to "BLE scan requested"))
                result.success(null)
            }
            "stopBleScan" -> {
                // Native reference: EdgezBleClient.stopScan().
                result.success(null)
            }
            "connectBle" -> {
                // Native reference: EdgezBleClient.connect(candidate).
                emit(mapOf("type" to "connection", "connection" to "ble"))
                result.success(null)
            }
            "disconnect" -> {
                // Native reference: close the active EdgezBleClient.
                emit(mapOf("type" to "connection", "connection" to "none"))
                result.success(null)
            }
            "initializeMesh" -> {
                // Native reference: sendHaLowInit(country, meshId, passphrase, identity, maxHop).
                emit(mapOf("type" to "log", "log" to "HaLow mesh init requested"))
                result.success(null)
            }
            "sendTextMessage" -> {
                // Native reference: encryptConversationText + sendConversationMessage.
                result.success("")
            }
            "sendVoiceMessage" -> {
                // Native reference: encodeVoiceChunk + sendConversationMessage with PacketMime.VOICE.
                result.success("")
            }
            "sendDeviceSettings" -> {
                // Native reference: sendDeviceSettings from BLE client.
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun emit(event: Map<String, Any?>) {
        eventSink?.success(event)
    }
}
