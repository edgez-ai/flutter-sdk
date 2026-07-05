package ai.edgez.flutter_sdk

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

private const val BLE_PERMISSION_REQUEST = 9007

class EdgezFlutterSdkPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var events: EventChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null
    private var scanCallback: ScanCallback? = null
    private var gatt: BluetoothGatt? = null
    private var pendingScanResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val devices = mutableMapOf<String, BluetoothDevice>()
    private var scanGeneration = 0

    private val bluetoothAdapter: BluetoothAdapter?
        get() = context.getSystemService(BluetoothManager::class.java)?.adapter

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "edgez_flutter_sdk/methods")
        events = EventChannel(binding.binaryMessenger, "edgez_flutter_sdk/events")
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopBleScan()
        closeGatt()
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        eventSink = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
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
            "startBleScan" -> startBleScan(result)
            "stopBleScan" -> {
                stopBleScan()
                emit(mapOf("type" to "log", "log" to "BLE scan stopped"))
                result.success(null)
            }
            "connectBle" -> {
                val deviceId = call.argument<String>("deviceId").orEmpty()
                connectBle(deviceId, result)
            }
            "disconnect" -> {
                stopBleScan()
                closeGatt()
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != BLE_PERMISSION_REQUEST) return false
        val result = pendingScanResult ?: return true
        pendingScanResult = null
        if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            startBleScan(result)
        } else {
            result.error("ble_permission_denied", "BLE permission denied", null)
            emit(mapOf("type" to "log", "log" to "BLE permission denied"))
        }
        return true
    }

    private fun requiredBlePermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= 31) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    private fun hasBlePermissions(): Boolean {
        return requiredBlePermissions().all {
            ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestBlePermissions(result: MethodChannel.Result): Boolean {
        if (hasBlePermissions()) return false
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("ble_permission_required", "BLE permission required", null)
            return true
        }
        pendingScanResult = result
        currentActivity.requestPermissions(requiredBlePermissions(), BLE_PERMISSION_REQUEST)
        emit(mapOf("type" to "log", "log" to "Requesting BLE permission: ${requiredBlePermissions().joinToString()}"))
        return true
    }

    private fun isLocationEnabled(): Boolean {
        val manager = context.getSystemService(LocationManager::class.java) ?: return true
        return if (Build.VERSION.SDK_INT >= 28) {
            manager.isLocationEnabled
        } else {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startBleScan(result: MethodChannel.Result) {
        if (requestBlePermissions(result)) return
        val adapter = bluetoothAdapter
        if (adapter == null) {
            result.error("ble_unavailable", "Bluetooth unavailable", null)
            return
        }
        if (!adapter.isEnabled) {
            result.error("ble_disabled", "Bluetooth is disabled", null)
            return
        }
        val scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            result.error("ble_scanner_unavailable", "BLE scanner unavailable", null)
            return
        }
        if (!isLocationEnabled()) {
            emit(mapOf("type" to "log", "log" to "Location services are off; Android may hide BLE scan results"))
        }

        stopBleScan()
        devices.clear()
        val generation = ++scanGeneration
        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                publishScanResult(scanResult)
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                results.forEach(::publishScanResult)
            }

            override fun onScanFailed(errorCode: Int) {
                emit(mapOf("type" to "log", "log" to "BLE scan failed=$errorCode"))
            }
        }
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        scanCallback = callback
        scanner.startScan(null, settings, callback)
        emit(mapOf("type" to "log", "log" to "BLE scan started"))
        mainHandler.postDelayed({
            if (scanCallback == callback && scanGeneration == generation && devices.isEmpty()) {
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE scan is running but no advertisements were received. Check Nearby devices permission, Location permission, and Location services.",
                    ),
                )
            }
        }, 6000)
        result.success(null)
    }

    @SuppressLint("MissingPermission")
    private fun publishScanResult(result: ScanResult) {
        val device = result.device ?: return
        val id = device.address ?: return
        val name = result.scanRecord?.deviceName ?: device.name ?: ""
        devices[id] = device
        emit(
            mapOf(
                "type" to "bleDevice",
                "bleDevice" to mapOf(
                    "id" to id,
                    "name" to name,
                    "rssi" to result.rssi,
                    "lastSeenMs" to System.currentTimeMillis(),
                ),
            ),
        )
    }

    @SuppressLint("MissingPermission")
    private fun stopBleScan() {
        val callback = scanCallback ?: return
        if (hasBlePermissions()) {
            bluetoothAdapter?.bluetoothLeScanner?.stopScan(callback)
        }
        scanCallback = null
        scanGeneration += 1
    }

    @SuppressLint("MissingPermission")
    private fun connectBle(deviceId: String, result: MethodChannel.Result) {
        if (!hasBlePermissions()) {
            result.error("ble_permission_required", "BLE permission required", null)
            return
        }
        val device = devices[deviceId] ?: bluetoothAdapter?.getRemoteDevice(deviceId)
        if (device == null) {
            result.error("ble_device_missing", "BLE device not found", null)
            return
        }
        stopBleScan()
        closeGatt()
        gatt = if (Build.VERSION.SDK_INT >= 23) {
            device.connectGatt(context, false, object : BluetoothGattCallback() {}, BluetoothDevice.TRANSPORT_LE)
        } else {
            device.connectGatt(context, false, object : BluetoothGattCallback() {})
        }
        emit(mapOf("type" to "connection", "connection" to "ble"))
        emit(mapOf("type" to "log", "log" to "Connecting BLE ${device.address}"))
        result.success(null)
    }

    @SuppressLint("MissingPermission")
    private fun closeGatt() {
        gatt?.close()
        gatt = null
    }

    private fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}
