package ai.edgez.flutter_sdk

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.BluetoothGattService
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.os.SystemClock
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.hoho.android.usbserial.driver.UsbSerialPort
import com.hoho.android.usbserial.driver.UsbSerialProber
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.SecureRandom
import java.util.ArrayDeque
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

private const val BLE_PERMISSION_REQUEST = 9007
private const val MICROPHONE_PERMISSION_REQUEST = 9008
private const val LOCATION_PERMISSION_REQUEST = 9009
private const val NOTIFICATION_PERMISSION_REQUEST = 9010
private const val USB_PERMISSION_ACTION = "ai.edgez.flutter_sdk.USB_PERMISSION"
private const val USB_IO_TIMEOUT_MS = 10_000
private const val USB_GAP_MIN_MS = 1L
private const val USB_GAP_INITIAL_MS = 3L
private const val USB_GAP_MAX_MS = 10L
private const val USB_HEARTBEAT_INTERVAL_MS = 60_000L
private const val LEGACY_USB_VERSION: Byte = 1
private const val LEGACY_USB_ECHO_REQUEST: Byte = 1
private const val LEGACY_USB_ECHO_RESPONSE: Byte = 2
private const val LEGACY_USB_TX_ACK: Byte = 3
private const val LEGACY_USB_FLOW_CONTROL: Byte = 4
private const val LEGACY_USB_HEADER_LEN = 8
private const val LEGACY_USB_MAX_PAYLOAD = 256
private const val EDGEZ_TINYUSB_VID = 0x303A
private const val EDGEZ_TINYUSB_CDC_PID = 0x4001
private const val EDGEZ_USB_SERIAL_JTAG_PID = 0x1001
private const val CP2102_VID = 0x10C4
private const val CP2102_PID = 0xEA60
private const val USB_CDC_BAUD = 921_600
private const val LOCATION_REFRESH_TIMEOUT_MS = 10_000L
private const val LOG_TAG = "EdgezFlutterSdk"
private const val VOICE_CODEC_AMR_NB = 1
private const val VOICE_CODEC_OPUS = 2
private const val EDGEZ_HEADER_LEN = 4
private const val SERIAL_STREAM_HEADER_LEN = 4
private const val SERIAL_STREAM_MAGIC_0: Byte = 0x94.toByte()
private const val SERIAL_STREAM_MAGIC_1: Byte = 0xC3.toByte()
private const val LOG_STREAM_VERSION: Byte = 2
private const val LOG_STREAM_RECORD: Byte = 1
private const val LOG_STREAM_SET_LEVEL: Byte = 2
private const val LOG_STREAM_LEVEL_RESPONSE: Byte = 3
private const val LOG_STREAM_HEADER_LEN = 5
private const val LOG_STREAM_LEVEL_ERROR = 0xff
private const val EDGEZ_MAX_PAYLOAD = 512
private const val EDGEZ_MAX_FRAME = EDGEZ_HEADER_LEN + EDGEZ_MAX_PAYLOAD
private const val EDGEZ_BLE_REQUESTED_MTU = 517
private const val OTA_BEGIN: Byte = 1
private const val OTA_DATA: Byte = 2
private const val OTA_END: Byte = 3
private const val OTA_ABORT: Byte = 4
private const val OTA_DATA_HEADER_SIZE = 5
private const val OTA_DATA_MAX_CHUNK_SIZE = 220
private const val OTA_WRITE_TIMEOUT_MS = 15_000L
private const val CONTROL_SERVICE_READY_FALLBACK_MS = 750L
private const val MTU_CALLBACK_FALLBACK_MS = 1_500L
private const val SERVICE_DISCOVERY_TIMEOUT_MS = 5_000L
private const val MAX_SERVICE_DISCOVERY_ATTEMPTS = 2
private val EDGEZ_VOICE_PROTOCOL_MAGIC = byteArrayOf('V'.code.toByte(), 'C'.code.toByte(), 2)
private val EDGEZ_SPEED_PROTOCOL_MAGIC = byteArrayOf('S'.code.toByte(), 'T'.code.toByte(), 2)
private const val EDGEZ_USB_NONCE_SIZE = 16
private const val EDGEZ_VOICE_NONCE_SIZE = 12
private const val EDGEZ_VOICE_ROUTE_SIZE = 6 + 1 + 4
private const val EDGEZ_VOICE_TX_QUEUE_DEPTH = 2
private const val EDGEZ_SPEED_TX_QUEUE_DEPTH = 8
private val EDGEZ_MAGIC_0 = 'E'.code.toByte()
private val EDGEZ_MAGIC_1 = 'Z'.code.toByte()
private val EDGEZ_SERVICE_UUID: UUID = UUID.fromString("0000fff0-0000-1000-8000-00805f9b34fb")
private val EDGEZ_RX_UUID: UUID = UUID.fromString("0000fff1-0000-1000-8000-00805f9b34fb")
private val EDGEZ_TX_UUID: UUID = UUID.fromString("0000fff2-0000-1000-8000-00805f9b34fb")
private val EDGEZ_FORWARD_RX_UUID: UUID = UUID.fromString("0000fff3-0000-1000-8000-00805f9b34fb")
private val EDGEZ_FORWARD_TX_UUID: UUID = UUID.fromString("0000fff4-0000-1000-8000-00805f9b34fb")
private val EDGEZ_OTA_UUID: UUID = UUID.fromString("0000fff5-0000-1000-8000-00805f9b34fb")
private val EDGEZ_OTA_STATUS_UUID: UUID = UUID.fromString("0000fff6-0000-1000-8000-00805f9b34fb")
private val EDGEZ_VOICE_RX_UUID: UUID = UUID.fromString("0000fff7-0000-1000-8000-00805f9b34fb")
private val EDGEZ_VOICE_TX_UUID: UUID = UUID.fromString("0000fff8-0000-1000-8000-00805f9b34fb")
private val CCCD_UUID: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

private data class EdgezBleWrite(
    val frame: ByteArray,
    val writeType: Int,
)

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
    private var pendingBondDevice: BluetoothDevice? = null
    private var bondReceiverRegistered = false
    private var rxCharacteristic: BluetoothGattCharacteristic? = null
    private var txCharacteristic: BluetoothGattCharacteristic? = null
    private var forwardRxCharacteristic: BluetoothGattCharacteristic? = null
    private var forwardTxCharacteristic: BluetoothGattCharacteristic? = null
    private var otaCharacteristic: BluetoothGattCharacteristic? = null
    private var otaStatusCharacteristic: BluetoothGattCharacteristic? = null
    private var voiceRxCharacteristic: BluetoothGattCharacteristic? = null
    private var voiceTxCharacteristic: BluetoothGattCharacteristic? = null
    private val notificationDescriptors = ArrayDeque<BluetoothGattDescriptor>()
    private var notificationDescriptorWriteInFlight = false
    private var serviceReadyPending = false
    @Volatile private var serviceDiscoveryStarted = false
    @Volatile private var serviceDiscoveryComplete = false
    @Volatile private var serviceDiscoveryAttempts = 0
    @Volatile private var controlNotificationWriteStarted = false
    @Volatile private var controlNotificationFailed = false
    private var negotiatedMtu = 23
    private val otaWriteLock = Object()
    private var otaWriteStatus: Int? = null
    private val otaAbortRequested = AtomicBoolean(false)
    private val otaInProgress = AtomicBoolean(false)
    private var pendingScanResult: MethodChannel.Result? = null
    private var pendingMicrophoneResult: MethodChannel.Result? = null
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingNotificationResult: MethodChannel.Result? = null
    private var voicePlayer: MediaPlayer? = null
    private var voiceRecorder: MediaRecorder? = null
    private var voiceRecordingFile: File? = null
    private var voiceRecordingCodec: Int = VOICE_CODEC_AMR_NB
    private var voiceRecordingStartedAtMs: Long = 0
    private var liveVoiceAudio: EdgezLiveVoiceAudio? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val devices = mutableMapOf<String, BluetoothDevice>()
    private val rxBuffer = ByteArray(EDGEZ_MAX_FRAME * 2)
    private var rxLen = 0
    private val forwardRxBuffer = ByteArray(EDGEZ_MAX_FRAME * 2)
    private var forwardRxLen = 0
    private val usbRxBuffer = ByteArray(EDGEZ_MAX_FRAME * 64)
    private var usbRxLen = 0
    private val txQueue = ArrayDeque<EdgezBleWrite>()
    private val voiceTxQueue = ArrayDeque<EdgezBleWrite>()
    private var txWriteInFlight = false
    private var voiceTxWriteInFlight = false
    private var dataWriteInFlight = false
    private var capturedVoiceFrames = 0
    private var transmittedVoiceFrames = 0
    private var receivedVoiceFrames = 0
    private var scanGeneration = 0
    private var usbConnection: UsbDeviceConnection? = null
    private var usbSerialPort: UsbSerialPort? = null
    private var usbConsolePort: UsbSerialPort? = null
    private val usbConsoleLineBuffer = StringBuilder()
    private val usbDebugLineBuffer = StringBuilder()
    private var usbInterface: UsbInterface? = null
    private var usbInEndpoint: UsbEndpoint? = null
    private var usbOutEndpoint: UsbEndpoint? = null
    private var usbVendorEchoTransport = false
    private var usbVendorConsoleInterface: UsbInterface? = null
    private var usbVendorConsoleInEndpoint: UsbEndpoint? = null
    private val usbRunning = AtomicBoolean(false)
    private val usbWriteLock = Object()
    private val usbRealtimeLock = Object()
    private val usbStatsLock = Object()
    private val usbRealtimeTxQueue = ArrayDeque<ByteArray>()
    private var usbRealtimeWriteInFlight = false
    private var usbRealtimeWriteFailure: Throwable? = null
    private var pendingUsbResult: MethodChannel.Result? = null
    private var pendingUsbDevice: UsbDevice? = null
    private var usbReceiverRegistered = false
    private var usbHeartbeatSequence = 0
    private var usbHeartbeatSent = 0
    private var usbHeartbeatPingsReceived = 0
    private var usbHeartbeatPongsReceived = 0
    private var usbHeartbeatTimeouts = 0
    private var usbAwaitingPongSequence = 0
    private var usbAwaitingPongNonce: ByteArray? = null
    @Volatile private var preferredDeviceLogLevel: Int = 2
    private var usbPingSentAtMs = 0L
    private var usbLastRttMs = 0L
    private var usbProtocolReady = false
    private val usbNonceRandom = SecureRandom()
    @Volatile private var usbInterFrameGapMs = USB_GAP_INITIAL_MS
    // The firmware acknowledges every application frame after accepting it
    // from the serial stream. Track control and realtime traffic together so
    // a caller cannot report a text/voice frame as sent while it is still
    // queued (or already dropped) on the device.
    private var usbApplicationFramesSent = 0L
    private var usbApplicationFramesAcked = 0L

    private val bluetoothAdapter: BluetoothAdapter?
        get() = context.getSystemService(BluetoothManager::class.java)?.adapter

    private val usbManager: UsbManager
        get() = context.getSystemService(Context.USB_SERVICE) as UsbManager

    private fun activeTransportName(): String = when {
        gatt != null -> "ble"
        usbConnection != null -> "usb"
        else -> "none"
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                USB_PERMISSION_ACTION -> {
                    val result = pendingUsbResult ?: return
                    val device = intent.usbDeviceExtra() ?: pendingUsbDevice
                    val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                    pendingUsbResult = null
                    pendingUsbDevice = null
                    if (!granted || device == null) {
                        result.error("usb_permission_denied", "USB permission was denied", null)
                    } else {
                        connectUsbDevice(device).fold(
                            onSuccess = { result.success(null) },
                            onFailure = { result.error("usb_connect_failed", it.message, null) },
                        )
                    }
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    val device = intent.usbDeviceExtra()
                    if (device != null && usbConnection != null) closeUsb(true)
                }
            }
        }
    }

    private val bondStateReceiver = object : BroadcastReceiver() {
        @SuppressLint("MissingPermission")
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != BluetoothDevice.ACTION_BOND_STATE_CHANGED) return
            @Suppress("DEPRECATION")
            val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
                ?: return
            val pending = pendingBondDevice ?: return
            if (device.address != pending.address) return

            when (intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.BOND_NONE)) {
                BluetoothDevice.BOND_BONDED -> {
                    pendingBondDevice = null
                    emit(mapOf("type" to "log", "log" to "BLE pairing complete ${device.address}"))
                    connectGatt(device)
                }
                BluetoothDevice.BOND_BONDING -> emit(
                    mapOf("type" to "log", "log" to "BLE awaiting pairing PIN ${device.address}"),
                )
                BluetoothDevice.BOND_NONE -> {
                    pendingBondDevice = null
                    EdgezBleForegroundService.stop(context)
                    emit(mapOf("type" to "log", "log" to "BLE pairing failed or canceled ${device.address}"))
                    emit(mapOf("type" to "connection", "connection" to "none"))
                }
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "edgez_flutter_sdk/methods")
        events = EventChannel(binding.binaryMessenger, "edgez_flutter_sdk/events")
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
        liveVoiceAudio = EdgezLiveVoiceAudio(
            context,
            onEncodedFrame = { audio ->
                capturedVoiceFrames++
                if (capturedVoiceFrames == 1 || capturedVoiceFrames % 25 == 0) {
                    emit(
                        mapOf(
                            "type" to "log",
                            "log" to "Live voice captured frames=$capturedVoiceFrames bytes=${audio.size}",
                        ),
                    )
                }
                emit(mapOf("type" to "voiceAudio", "packet" to audio))
            },
            onError = { error ->
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "Live voice capture failed: ${error.message}",
                    ),
                )
            },
        )
        val bondFilter = IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(bondStateReceiver, bondFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(bondStateReceiver, bondFilter)
        }
        bondReceiverRegistered = true
        val usbFilter = IntentFilter().apply {
            addAction(USB_PERMISSION_ACTION)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(usbReceiver, usbFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(usbReceiver, usbFilter)
        }
        usbReceiverRegistered = true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopBleScan()
        closeGatt()
        closeUsb(false)
        discardVoiceRecording()
        liveVoiceAudio?.stop()
        liveVoiceAudio = null
        voicePlayer?.release()
        voicePlayer = null
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        eventSink = null
        if (bondReceiverRegistered) {
            context.unregisterReceiver(bondStateReceiver)
            bondReceiverRegistered = false
        }
        if (usbReceiverRegistered) {
            context.unregisterReceiver(usbReceiver)
            usbReceiverRegistered = false
        }
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

    @Suppress("DEPRECATION")
    private fun Intent.usbDeviceExtra(): UsbDevice? =
        if (Build.VERSION.SDK_INT >= 33) {
            getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
        } else {
            getParcelableExtra(UsbManager.EXTRA_DEVICE)
        }

    private fun usbTransportName(device: UsbDevice): String = when {
        device.vendorId == EDGEZ_TINYUSB_VID &&
            device.productId == EDGEZ_USB_SERIAL_JTAG_PID ->
            "esp32s3-usb-serial-jtag"
        device.vendorId == EDGEZ_TINYUSB_VID &&
            (device.productId == EDGEZ_TINYUSB_CDC_PID ||
                (0 until device.interfaceCount).any {
                    device.getInterface(it).interfaceClass == UsbConstants.USB_CLASS_CDC_DATA
                }) -> "tinyusb-cdc-uart"
        device.vendorId == CP2102_VID && device.productId == CP2102_PID ->
            "cp2102-uart"
        else -> "generic-usb"
    }

    private fun enumerateUsbInterfaces(device: UsbDevice): List<Map<String, Any>> =
        (0 until device.interfaceCount).map { interfaceIndex ->
            val intf = device.getInterface(interfaceIndex)
            val endpoints = (0 until intf.endpointCount).map { endpointIndex ->
                val endpoint = intf.getEndpoint(endpointIndex)
                mapOf<String, Any>(
                    "address" to endpoint.address,
                    "direction" to if (endpoint.direction == UsbConstants.USB_DIR_IN) "in" else "out",
                    "type" to endpoint.type,
                    "maxPacketSize" to endpoint.maxPacketSize,
                    "interval" to endpoint.interval,
                )
            }
            mapOf<String, Any>(
                "id" to intf.id,
                "alternateSetting" to intf.alternateSetting,
                "name" to (intf.name ?: ""),
                "class" to intf.interfaceClass,
                "subclass" to intf.interfaceSubclass,
                "protocol" to intf.interfaceProtocol,
                "endpoints" to endpoints,
            )
        }

    private fun logUsbEnumeration(device: UsbDevice) {
        Log.i(
            LOG_TAG,
            "USB enumerate name=${device.deviceName} vid=${device.vendorId.toString(16).padStart(4, '0')} " +
                "pid=${device.productId.toString(16).padStart(4, '0')} transport=${usbTransportName(device)} " +
                "class=${device.deviceClass}/${device.deviceSubclass}/${device.deviceProtocol} " +
                "interfaces=${device.interfaceCount} permission=${usbManager.hasPermission(device)}",
        )
        for (interfaceIndex in 0 until device.interfaceCount) {
            val intf = device.getInterface(interfaceIndex)
            Log.i(
                LOG_TAG,
                "USB interface index=$interfaceIndex id=${intf.id} alt=${intf.alternateSetting} " +
                    "class=${intf.interfaceClass}/${intf.interfaceSubclass}/${intf.interfaceProtocol} " +
                    "name=${intf.name ?: ""} endpoints=${intf.endpointCount}",
            )
            for (endpointIndex in 0 until intf.endpointCount) {
                val endpoint = intf.getEndpoint(endpointIndex)
                Log.i(
                    LOG_TAG,
                    "USB endpoint interface=$interfaceIndex index=$endpointIndex " +
                        "address=0x${endpoint.address.toString(16).padStart(2, '0')} " +
                        "direction=${if (endpoint.direction == UsbConstants.USB_DIR_IN) "in" else "out"} " +
                        "type=${endpoint.type} maxPacket=${endpoint.maxPacketSize} interval=${endpoint.interval}",
                )
            }
        }
    }

    private fun listUsbDevices(): List<Map<String, Any>> =
        usbManager.deviceList.values.map { device ->
            logUsbEnumeration(device)
            mapOf(
                "id" to device.deviceId,
                "name" to (runCatching { device.productName }.getOrNull()
                    ?: device.deviceName.substringAfterLast('/').ifEmpty { "USB device" }),
                "vendorId" to device.vendorId,
                "productId" to device.productId,
                "transport" to usbTransportName(device),
                "deviceClass" to device.deviceClass,
                "deviceSubclass" to device.deviceSubclass,
                "deviceProtocol" to device.deviceProtocol,
                "hasPermission" to usbManager.hasPermission(device),
                "interfaces" to enumerateUsbInterfaces(device),
            )
        }

    private fun findUsbInterface(device: UsbDevice): Triple<UsbInterface, UsbEndpoint, UsbEndpoint>? {
        val candidates = mutableListOf<Triple<UsbInterface, UsbEndpoint, UsbEndpoint>>()
        for (index in 0 until device.interfaceCount) {
            val intf = device.getInterface(index)
            var input: UsbEndpoint? = null
            var output: UsbEndpoint? = null
            for (endpointIndex in 0 until intf.endpointCount) {
                val endpoint = intf.getEndpoint(endpointIndex)
                if (endpoint.type != UsbConstants.USB_ENDPOINT_XFER_BULK) continue
                if (endpoint.direction == UsbConstants.USB_DIR_IN) input = endpoint
                if (endpoint.direction == UsbConstants.USB_DIR_OUT) output = endpoint
            }
            if (input != null && output != null) candidates += Triple(intf, input, output)
        }
        return candidates.minByOrNull { candidate ->
            when (candidate.first.interfaceClass) {
                UsbConstants.USB_CLASS_CDC_DATA -> 0
                UsbConstants.USB_CLASS_VENDOR_SPEC -> 1
                else -> 2
            }
        }
    }

    private fun connectUsb(deviceId: Int?, result: MethodChannel.Result) {
        val device = usbManager.deviceList.values.firstOrNull {
            it.deviceId == deviceId
        }
        if (device == null || findUsbInterface(device) == null) {
            result.error("usb_device_missing", "Compatible ESP32-S3 USB device not found", null)
            return
        }
        if (!usbManager.hasPermission(device)) {
            if (pendingUsbResult != null) {
                result.error("usb_permission_pending", "Another USB permission request is active", null)
                return
            }
            pendingUsbResult = result
            pendingUsbDevice = device
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            val permissionIntent = PendingIntent.getBroadcast(
                context, 0, Intent(USB_PERMISSION_ACTION).setPackage(context.packageName), flags,
            )
            usbManager.requestPermission(device, permissionIntent)
            return
        }
        connectUsbDevice(device).fold(
            onSuccess = { result.success(null) },
            onFailure = { result.error("usb_connect_failed", it.message, null) },
        )
    }

    private fun cancelPendingUsbConnection() {
        val result = pendingUsbResult
        pendingUsbResult = null
        pendingUsbDevice = null
        result?.error(
            "usb_connection_cancelled",
            "USB connection cancelled because another transport was selected",
            null,
        )
    }

    private fun connectUsbDevice(device: UsbDevice): Result<Unit> = runCatching {
        logUsbEnumeration(device)
        val endpoints = findUsbInterface(device)
            ?: throw IllegalStateException("USB bulk endpoints are unavailable")
        if (device.vendorId == EDGEZ_TINYUSB_VID &&
            endpoints.first.interfaceClass == UsbConstants.USB_CLASS_VENDOR_SPEC
        ) {
            connectUsbVendorEcho(device, endpoints)
            return@runCatching
        }
        val driver = UsbSerialProber.getDefaultProber().probeDevice(device)
            ?: throw IllegalStateException("No supported USB serial driver for this device")
        // The root TinyUSB console test exposes two CDC interfaces. CDC0 is
        // the framed mobile data channel; CDC1 is an independent log console.
        // Always bind the app to port zero so console text cannot enter the
        // mobile protocol stream.
        val port = driver.ports.getOrNull(0)
            ?: throw IllegalStateException("USB serial device has no CDC data port")
        val consolePort = if (usbTransportName(device) == "tinyusb-cdc-uart") {
            driver.ports.getOrNull(1)
        } else {
            null
        }
        closeUsb(false)
        closeGatt()
        val connection = usbManager.openDevice(device)
            ?: throw IllegalStateException("Unable to open USB device")
        try {
            port.open(connection)
            port.setParameters(
                USB_CDC_BAUD,
                8,
                UsbSerialPort.STOPBITS_1,
                UsbSerialPort.PARITY_NONE,
            )
            port.dtr = true
            port.rts = true
            consolePort?.open(connection)
            consolePort?.setParameters(
                USB_CDC_BAUD,
                8,
                UsbSerialPort.STOPBITS_1,
                UsbSerialPort.PARITY_NONE,
            )
            consolePort?.dtr = true
            consolePort?.rts = true
        } catch (error: Throwable) {
            runCatching { consolePort?.close() }
            runCatching { port.close() }
            connection.close()
            throw error
        }
        usbConnection = connection
        usbSerialPort = port
        usbConsolePort = consolePort
        usbInterface = endpoints.first
        usbInEndpoint = endpoints.second
        usbOutEndpoint = endpoints.third
        Log.i(
            LOG_TAG,
            "USB selected transport=${usbTransportName(device)} dataInterface=${endpoints.first.id} " +
                "driver=${driver.javaClass.simpleName} baud=$USB_CDC_BAUD " +
                "in=0x${endpoints.second.address.toString(16).padStart(2, '0')} " +
                "out=0x${endpoints.third.address.toString(16).padStart(2, '0')}",
        )
        rxLen = 0
        usbRunning.set(true)
        startUsbReader()
        startUsbConsoleReader()
        startUsbHeartbeat()
        emit(mapOf("type" to "connection", "connection" to "usb"))
        emit(
            mapOf(
                "type" to "log",
                "log" to "USB CDC data port connected; sending mobile-initiated ping",
            ),
        )
        if (consolePort != null) {
            emit(mapOf("type" to "log", "log" to "TinyUSB CDC console port connected"))
        }
    }

    /** Raw TinyUSB vendor echo, matching 48acba6: EZ/version/type/seq/len. */
    private fun connectUsbVendorEcho(
        device: UsbDevice,
        endpoints: Triple<UsbInterface, UsbEndpoint, UsbEndpoint>,
    ) {
        closeUsb(false)
        closeGatt()
        val connection = usbManager.openDevice(device)
            ?: throw IllegalStateException("Unable to open USB vendor device")
        if (!connection.claimInterface(endpoints.first, true)) {
            connection.close()
            throw IllegalStateException("Unable to claim USB vendor interface")
        }
        usbConnection = connection
        usbInterface = endpoints.first
        usbInEndpoint = endpoints.second
        usbOutEndpoint = endpoints.third
        usbVendorEchoTransport = true
        val console = findUsbCdcConsoleInterface(device, endpoints.first)
        if (console != null && !connection.claimInterface(console.first, true)) {
            connection.releaseInterface(endpoints.first)
            connection.close()
            throw IllegalStateException("Unable to claim TinyUSB console interface")
        }
        usbVendorConsoleInterface = console?.first
        usbVendorConsoleInEndpoint = console?.second
        usbRxLen = 0
        usbRunning.set(true)
        startUsbVendorReader()
        startUsbVendorConsoleReader()
        startUsbHeartbeat()
        emit(mapOf("type" to "connection", "connection" to "usb"))
        emit(mapOf("type" to "log", "log" to "USB vendor echo connected; sending mobile ping"))
        if (console != null) {
            emit(mapOf("type" to "log", "log" to "TinyUSB CDC console connected"))
        } else {
            emit(mapOf("type" to "log", "log" to "TinyUSB CDC console interface not found"))
        }
    }

    private fun startUsbVendorReader() {
        thread(name = "edgez-usb-vendor-rx") {
            val buffer = ByteArray(16 * 1024)
            while (usbRunning.get() && usbVendorEchoTransport) {
                val connection = usbConnection ?: break
                val endpoint = usbInEndpoint ?: break
                val read = runCatching { connection.bulkTransfer(endpoint, buffer, buffer.size, 1000) }
                if (read.isFailure) break
                val count = read.getOrThrow()
                if (count > 0) handleUsbVendorBytes(buffer.copyOf(count))
            }
        }
    }

    private fun startUsbVendorConsoleReader() {
        if (usbVendorConsoleInEndpoint == null) return
        thread(name = "edgez-usb-vendor-console") {
            val buffer = ByteArray(4096)
            while (usbRunning.get() && usbVendorEchoTransport) {
                val connection = usbConnection ?: break
                val endpoint = usbVendorConsoleInEndpoint ?: break
                val read = runCatching { connection.bulkTransfer(endpoint, buffer, buffer.size, 1000) }
                if (read.isFailure) break
                val count = read.getOrThrow()
                if (count > 0) appendUsbConsoleBytes(buffer, count)
            }
        }
    }

    private fun handleUsbVendorBytes(bytes: ByteArray) {
        if (usbRxLen + bytes.size > usbRxBuffer.size) usbRxLen = 0
        System.arraycopy(bytes, 0, usbRxBuffer, usbRxLen, bytes.size)
        usbRxLen += bytes.size
        while (usbRxLen >= LEGACY_USB_HEADER_LEN) {
            if (usbRxBuffer[0] != EDGEZ_MAGIC_0 || usbRxBuffer[1] != EDGEZ_MAGIC_1 ||
                usbRxBuffer[2] != LEGACY_USB_VERSION) {
                consumeUsbBytes(1)
                continue
            }
            val payloadLength = (usbRxBuffer[6].toInt() and 0xff) or
                ((usbRxBuffer[7].toInt() and 0xff) shl 8)
            if (payloadLength > LEGACY_USB_MAX_PAYLOAD) {
                consumeUsbBytes(1)
                continue
            }
            val frameLength = LEGACY_USB_HEADER_LEN + payloadLength
            if (usbRxLen < frameLength) return
            val type = usbRxBuffer[3]
            val sequence = (usbRxBuffer[4].toInt() and 0xff) or
                ((usbRxBuffer[5].toInt() and 0xff) shl 8)
            handleLegacyUsbEcho(type, sequence,
                usbRxBuffer.copyOfRange(LEGACY_USB_HEADER_LEN, frameLength))
            consumeUsbBytes(frameLength)
        }
    }

    private fun findUsbCdcConsoleInterface(
        device: UsbDevice,
        vendorInterface: UsbInterface,
    ): Pair<UsbInterface, UsbEndpoint>? {
        for (index in 0 until device.interfaceCount) {
            val intf = device.getInterface(index)
            if (intf.id == vendorInterface.id ||
                intf.interfaceClass != UsbConstants.USB_CLASS_CDC_DATA
            ) continue
            for (endpointIndex in 0 until intf.endpointCount) {
                val endpoint = intf.getEndpoint(endpointIndex)
                if (endpoint.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                    endpoint.direction == UsbConstants.USB_DIR_IN
                ) return intf to endpoint
            }
        }
        return null
    }

    private fun startUsbReader() {
        thread(name = "edgez-usb-rx") {
            val buffer = ByteArray(16 * 1024)
            while (usbRunning.get()) {
                val port = usbSerialPort ?: break
                val read = runCatching { port.read(buffer, 1000) }
                if (read.isFailure) {
                    val error = read.exceptionOrNull() ?: break
                    // A detach broadcast can race this blocking read. Never let
                    // the background reader terminate the entire Flutter app.
                    if (usbRunning.get()) {
                        Log.w(LOG_TAG, "USB data reader stopped", error)
                        emit(mapOf("type" to "log", "log" to "USB data reader stopped: ${error.message}"))
                    }
                    break
                }
                val count = read.getOrThrow()
                if (count > 0) handleUsbBytes(buffer.copyOf(count))
            }
        }
    }

    private fun startUsbConsoleReader() {
        if (usbConsolePort == null) return
        thread(name = "edgez-usb-console") {
            val buffer = ByteArray(4096)
            while (usbRunning.get()) {
                val port = usbConsolePort ?: break
                val read = runCatching { port.read(buffer, 1000) }
                if (read.isFailure) {
                    val error = read.exceptionOrNull() ?: break
                    if (usbRunning.get()) {
                        Log.w(LOG_TAG, "USB console reader stopped", error)
                        emit(mapOf("type" to "log", "log" to "USB console reader stopped: ${error.message}"))
                    }
                    break
                }
                val count = read.getOrThrow()
                if (count > 0) appendUsbConsoleBytes(buffer, count)
            }
        }
    }

    private fun appendUsbConsoleBytes(bytes: ByteArray, count: Int) {
        val lines = mutableListOf<String>()
        synchronized(usbConsoleLineBuffer) {
            usbConsoleLineBuffer.append(String(bytes, 0, count, Charsets.UTF_8))
            while (true) {
                val newline = usbConsoleLineBuffer.indexOf("\n")
                if (newline < 0) break
                val line = usbConsoleLineBuffer.substring(0, newline).trimEnd('\r')
                usbConsoleLineBuffer.delete(0, newline + 1)
                if (line.isNotBlank()) lines += line
            }
            if (usbConsoleLineBuffer.length > 4096) usbConsoleLineBuffer.clear()
        }
        for (line in lines) emit(mapOf("type" to "log", "log" to "FW: $line"))
    }

    /**
     * USB Serial/JTAG exposes one USB serial stream, so ESP_LOG output and
     * framed protocol responses share it. Protocol parsing resynchronizes on
     * the frame magic; every discarded printable byte is reconstructed here
     * as an ESP32 log line for the Debug page.
     */
    private fun appendUsbDebugByte(value: Byte) {
        val unsigned = value.toInt() and 0xff
        var line: String? = null
        synchronized(usbDebugLineBuffer) {
            when (unsigned) {
                '\n'.code -> {
                    line = usbDebugLineBuffer.toString().trimEnd('\r')
                    usbDebugLineBuffer.clear()
                }
                '\r'.code -> Unit
                '\t'.code -> usbDebugLineBuffer.append('\t')
                in 0x20..0x7e -> usbDebugLineBuffer.append(unsigned.toChar())
                else -> usbDebugLineBuffer.clear()
            }
            if (usbDebugLineBuffer.length > 4096) usbDebugLineBuffer.clear()
        }
        line?.takeIf { it.isNotBlank() }?.let {
            Log.i(LOG_TAG, "FW: $it")
            emit(mapOf("type" to "log", "log" to "FW: $it"))
        }
    }

    private fun startUsbHeartbeat() {
        thread(name = "edgez-usb-heartbeat") {
            while (usbRunning.get()) {
                val (heartbeat, sequence) = synchronized(usbStatsLock) {
                    if (usbAwaitingPongSequence != 0) usbHeartbeatTimeouts++
                    usbHeartbeatSequence++
                    usbHeartbeatSent++
                    usbAwaitingPongSequence = usbHeartbeatSequence
                    val nonce = ByteArray(EDGEZ_USB_NONCE_SIZE).also(usbNonceRandom::nextBytes)
                    val handshakePayload = nonce + byteArrayOf(preferredDeviceLogLevel.toByte())
                    usbAwaitingPongNonce = handshakePayload
                    usbPingSentAtMs = System.currentTimeMillis()
                    Pair(
                        buildLegacyUsbEcho(
                            LEGACY_USB_ECHO_REQUEST,
                            usbHeartbeatSequence,
                            handshakePayload,
                        ),
                        usbHeartbeatSequence,
                    )
                }
                emit(mapOf("type" to "log", "log" to "USB PING seq=$sequence"))
                writeUsbRaw(heartbeat).onFailure {
                    if (usbRunning.get()) {
                        emit(mapOf("type" to "log", "log" to "USB heartbeat write failed: ${it.message}"))
                    }
                }
                emitUsbLinkStats()
                try {
                    Thread.sleep(USB_HEARTBEAT_INTERVAL_MS)
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    break
                }
            }
        }
    }

    private fun buildLegacyUsbEcho(type: Byte, sequence: Int, payload: ByteArray): ByteArray =
        ByteBuffer.allocate(LEGACY_USB_HEADER_LEN + payload.size)
            .order(ByteOrder.LITTLE_ENDIAN)
            .put(EDGEZ_MAGIC_0)
            .put(EDGEZ_MAGIC_1)
            .put(LEGACY_USB_VERSION)
            .put(type)
            .putShort(sequence.toShort())
            .putShort(payload.size.toShort())
            .put(payload)
            .array()

    private fun buildLogStreamCommand(level: Int, tag: ByteArray): ByteArray =
        byteArrayOf(
            'L'.code.toByte(),
            'G'.code.toByte(),
            LOG_STREAM_VERSION,
            LOG_STREAM_SET_LEVEL,
            level.toByte(),
        ) + tag

    private fun handleLegacyUsbEcho(type: Byte, sequence: Int, payload: ByteArray) {
        if (type == LEGACY_USB_ECHO_REQUEST) {
            synchronized(usbStatsLock) { usbHeartbeatPingsReceived++ }
            writeUsbRaw(buildLegacyUsbEcho(LEGACY_USB_ECHO_RESPONSE, sequence, payload))
            markUsbProtocolReady()
        } else if (type == LEGACY_USB_ECHO_RESPONSE) {
            var rttMs: Long? = null
            val validPong = synchronized(usbStatsLock) {
                val expectedNonce = usbAwaitingPongNonce
                val matches = sequence == (usbAwaitingPongSequence and 0xffff) &&
                    expectedNonce != null && payload.contentEquals(expectedNonce)
                if (matches) {
                    usbHeartbeatPongsReceived++
                    usbLastRttMs = (System.currentTimeMillis() - usbPingSentAtMs).coerceAtLeast(0)
                    rttMs = usbLastRttMs
                    usbAwaitingPongSequence = 0
                    usbAwaitingPongNonce = null
                }
                matches
            }
            if (!validPong) return
            markUsbProtocolReady()
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "USB PONG seq=$sequence${rttMs?.let { " rtt=${it}ms" } ?: ""}",
                ),
            )
        } else if (type == LEGACY_USB_TX_ACK) {
            synchronized(usbStatsLock) {
                usbApplicationFramesAcked++
                usbStatsLock.notifyAll()
            }
            // ACKs can arrive for every application frame. Do not turn them into
            // high-frequency UI heartbeat-stat events.
            return
        } else if (type == LEGACY_USB_FLOW_CONTROL) {
            usbInterFrameGapMs = sequence.toLong().coerceIn(USB_GAP_MIN_MS, USB_GAP_MAX_MS)
            return
        }
        emitUsbLinkStats()
    }

    private fun markUsbProtocolReady() {
        if (usbVendorEchoTransport) return
        synchronized(usbStatsLock) {
            if (usbProtocolReady || !usbRunning.get()) return
            usbProtocolReady = true
        }
        mainHandler.post {
            if (!usbRunning.get()) return@post
            emit(mapOf("type" to "ready", "mtu" to EDGEZ_MAX_PAYLOAD))
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "USB firmware handshake complete; EdgeZ protocol ready",
                ),
            )
        }
    }

    private fun emitUsbLinkStats() {
        val event = synchronized(usbStatsLock) {
            mapOf(
                "type" to "usbLinkStats",
                "sentPings" to usbHeartbeatSent,
                "receivedPings" to usbHeartbeatPingsReceived,
                "receivedPongs" to usbHeartbeatPongsReceived,
                "timeouts" to usbHeartbeatTimeouts,
                "rttMs" to usbLastRttMs,
            )
        }
        emit(event)
    }

    private fun closeUsb(emitDisconnected: Boolean) {
        val wasConnected = usbConnection != null
        usbRunning.set(false)
        val connection = usbConnection
        val port = usbSerialPort
        val consolePort = usbConsolePort
        if (usbVendorEchoTransport) {
            runCatching { usbVendorConsoleInterface?.let { connection?.releaseInterface(it) } }
            runCatching { usbInterface?.let { connection?.releaseInterface(it) } }
        }
        runCatching { consolePort?.dtr = false }
        runCatching { consolePort?.rts = false }
        runCatching { consolePort?.close() }
        runCatching { port?.dtr = false }
        runCatching { port?.rts = false }
        runCatching { port?.close() }
        connection?.close()
        usbConnection = null
        usbSerialPort = null
        usbConsolePort = null
        synchronized(usbConsoleLineBuffer) { usbConsoleLineBuffer.clear() }
        synchronized(usbDebugLineBuffer) { usbDebugLineBuffer.clear() }
        usbInterface = null
        usbInEndpoint = null
        usbOutEndpoint = null
        usbVendorEchoTransport = false
        usbVendorConsoleInterface = null
        usbVendorConsoleInEndpoint = null
        rxLen = 0
        usbRxLen = 0
        synchronized(usbRealtimeLock) {
            usbRealtimeTxQueue.clear()
            usbRealtimeWriteInFlight = false
            usbRealtimeWriteFailure = null
            usbRealtimeLock.notifyAll()
        }
        synchronized(usbStatsLock) {
            usbHeartbeatSequence = 0
            usbHeartbeatSent = 0
            usbHeartbeatPingsReceived = 0
            usbHeartbeatPongsReceived = 0
            usbHeartbeatTimeouts = 0
            usbAwaitingPongSequence = 0
            usbAwaitingPongNonce = null
            usbPingSentAtMs = 0
            usbLastRttMs = 0
            usbProtocolReady = false
            usbInterFrameGapMs = USB_GAP_INITIAL_MS
            usbApplicationFramesSent = 0
            usbApplicationFramesAcked = 0
            usbStatsLock.notifyAll()
        }
        if (wasConnected && emitDisconnected) {
            emit(mapOf("type" to "connection", "connection" to "none"))
            emit(mapOf("type" to "log", "log" to "USB device disconnected"))
        }
    }

    private fun writeUsbFrame(
        payload: ByteArray,
        trackAcceptance: Boolean = true,
    ): Result<String> = runCatching {
        if (payload.size > EDGEZ_MAX_PAYLOAD) {
            throw IllegalArgumentException("Payload too large: ${payload.size}/$EDGEZ_MAX_PAYLOAD")
        }
        val frame = buildSerialStreamFrame(payload)
        synchronized(usbWriteLock) {
            val port = usbSerialPort ?: throw IllegalStateException("USB UART is not connected")
            port.write(frame, USB_IO_TIMEOUT_MS)
            Thread.sleep(usbInterFrameGapMs)
        }
        if (trackAcceptance) {
            synchronized(usbStatsLock) { usbApplicationFramesSent++ }
        }
        "USB UART frame sent"
    }

    private fun enqueueUsbRealtimeFrame(
        frame: ByteArray,
        dropStale: Boolean,
    ): Result<String> {
        var startWriter = false
        synchronized(usbRealtimeLock) {
            val queueDepth =
                if (dropStale) EDGEZ_VOICE_TX_QUEUE_DEPTH else EDGEZ_SPEED_TX_QUEUE_DEPTH
            if (usbRealtimeTxQueue.size >= queueDepth) {
                if (!dropStale) {
                    return Result.failure(IllegalStateException("USB realtime queue is full"))
                }
                usbRealtimeTxQueue.pollFirst()
            }
            usbRealtimeTxQueue.addLast(frame)
            usbRealtimeWriteFailure = null
            if (!usbRealtimeWriteInFlight) {
                usbRealtimeWriteInFlight = true
                startWriter = true
            }
        }
        if (startWriter) startUsbRealtimeWriter()
        return Result.success("USB realtime queued")
    }

    private fun startUsbRealtimeWriter() {
        thread(name = "edgez-usb-realtime-tx") {
            while (usbRunning.get()) {
                val frame = synchronized(usbRealtimeLock) {
                    val next = usbRealtimeTxQueue.pollFirst()
                    if (next == null) {
                        usbRealtimeWriteInFlight = false
                        usbRealtimeLock.notifyAll()
                    }
                    next
                }
                if (frame == null) return@thread
                val write = writeUsbFrame(frame, trackAcceptance = false)
                if (write.isFailure) {
                    synchronized(usbRealtimeLock) {
                        usbRealtimeTxQueue.clear()
                        usbRealtimeWriteFailure = write.exceptionOrNull()
                        usbRealtimeWriteInFlight = false
                        usbRealtimeLock.notifyAll()
                    }
                    emit(
                        mapOf(
                            "type" to "log",
                            "log" to "USB realtime write failed: ${write.exceptionOrNull()?.message}",
                        ),
                    )
                    return@thread
                }
            }
            synchronized(usbRealtimeLock) {
                usbRealtimeTxQueue.clear()
                usbRealtimeWriteInFlight = false
                usbRealtimeLock.notifyAll()
            }
        }
    }

    private fun waitForUsbRealtimeTxDrain(timeoutMs: Int): Result<String> {
        val deadline = System.currentTimeMillis() + timeoutMs
        synchronized(usbRealtimeLock) {
            while ((usbRealtimeWriteInFlight || usbRealtimeTxQueue.isNotEmpty()) &&
                usbRunning.get()
            ) {
                val remaining = deadline - System.currentTimeMillis()
                if (remaining <= 0) break
                usbRealtimeLock.wait(remaining)
            }
            usbRealtimeWriteFailure?.let { return Result.failure(it) }
            if (usbRealtimeWriteInFlight || usbRealtimeTxQueue.isNotEmpty()) {
                return Result.failure(
                    IllegalStateException("USB realtime TX did not drain after ${timeoutMs}ms"),
                )
            }
        }
        return Result.success("USB realtime TX complete")
    }

    private fun writeUsbRaw(bytes: ByteArray): Result<String> = runCatching {
        if (usbVendorEchoTransport) {
            val connection = usbConnection ?: throw IllegalStateException("USB vendor device is not connected")
            val endpoint = usbOutEndpoint ?: throw IllegalStateException("USB vendor write endpoint is not connected")
            synchronized(usbWriteLock) {
                val written = connection.bulkTransfer(endpoint, bytes, bytes.size, USB_IO_TIMEOUT_MS)
                if (written != bytes.size) {
                    throw IllegalStateException("USB vendor short write: $written/${bytes.size}")
                }
            }
            return@runCatching "USB vendor frame sent"
        }
        val frame = buildSerialStreamFrame(bytes)
        synchronized(usbWriteLock) {
            val port = usbSerialPort ?: throw IllegalStateException("USB UART is not connected")
            port.write(frame, USB_IO_TIMEOUT_MS)
            Thread.sleep(usbInterFrameGapMs)
        }
        "UART stream frame sent"
    }

    private fun buildSerialStreamFrame(payload: ByteArray): ByteArray =
        ByteBuffer.allocate(SERIAL_STREAM_HEADER_LEN + payload.size)
            .order(ByteOrder.BIG_ENDIAN)
            .put(SERIAL_STREAM_MAGIC_0)
            .put(SERIAL_STREAM_MAGIC_1)
            .putShort(payload.size.toShort())
            .put(payload)
            .array()

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
        emit(mapOf("type" to "log", "log" to "EdgeZ Flutter SDK attached"))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listUsbDevices" -> result.success(listUsbDevices())
            "connectUsb" -> connectUsb(call.argument<Int>("deviceId"), result)
            "setDeviceLogLevel" -> {
                val level = call.argument<Int>("level") ?: 2
                val tag = call.argument<String>("tag").orEmpty()
                val tagBytes = tag.toByteArray(Charsets.UTF_8)
                if (level !in 0..5) {
                    result.error("invalid_log_level", "Log level must be between 0 and 5", null)
                } else if (tagBytes.size > LEGACY_USB_MAX_PAYLOAD) {
                    result.error("invalid_log_tag", "Log tag is too long", null)
                } else if (gatt == null && (!usbProtocolReady || usbConnection == null)) {
                    result.error("transport_not_ready", "BLE/USB stream is not ready", null)
                } else {
                    preferredDeviceLogLevel = level
                    sendRealtimePacket(
                        protocolMagic = byteArrayOf(),
                        packet = buildLogStreamCommand(level, tagBytes),
                        dropStale = false,
                    ).fold(
                        onSuccess = { result.success(null) },
                        onFailure = { result.error("transport_write_failed", it.message, null) },
                    )
                }
            }
            "configureDeviceLogLevel" -> {
                val level = call.argument<Int>("level") ?: 2
                if (level !in 0..5) {
                    result.error("invalid_log_level", "Log level must be between 0 and 5", null)
                } else {
                    preferredDeviceLogLevel = level
                    result.success(null)
                }
            }
            "reportUsbPacketLoss" -> {
                val loss = call.argument<Number>("lossPercent")?.toDouble() ?: 0.0
                usbInterFrameGapMs = when {
                    loss >= 5.0 -> (usbInterFrameGapMs + 2).coerceAtMost(USB_GAP_MAX_MS)
                    loss >= 1.0 -> (usbInterFrameGapMs + 1).coerceAtMost(USB_GAP_MAX_MS)
                    loss <= 0.25 -> (usbInterFrameGapMs - 1).coerceAtLeast(USB_GAP_MIN_MS)
                    else -> usbInterFrameGapMs
                }
                if (usbConnection != null) {
                    writeUsbRaw(
                        buildLegacyUsbEcho(
                            LEGACY_USB_FLOW_CONTROL,
                            usbInterFrameGapMs.toInt(),
                            byteArrayOf(),
                        ),
                    )
                }
                result.success(usbInterFrameGapMs.toInt())
            }
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
            "getBestKnownLocation" -> getBestKnownLocation(result)
            "requestMicrophonePermission" -> requestMicrophonePermission(result)
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "notificationsAllowed" -> result.success(
                EdgezBleForegroundService.notificationsAllowed(context),
            )
            "canUseFullScreenIntent" -> {
                val allowed = if (Build.VERSION.SDK_INT >= 34) {
                    context.getSystemService(android.app.NotificationManager::class.java)
                        .canUseFullScreenIntent()
                } else {
                    true
                }
                result.success(allowed)
            }
            "showIncomingMessageNotification" -> {
                result.success(
                    EdgezBleForegroundService.showMessage(
                        context = context,
                        sender = call.argument<String>("sender").orEmpty(),
                        body = call.argument<String>("body").orEmpty(),
                        nodeNum = call.argument<Number>("nodeNum")?.toLong() ?: 0L,
                        messageId = call.argument<String>("messageId").orEmpty(),
                    ),
                )
            }
            "showIncomingCallNotification" -> {
                result.success(
                    EdgezBleForegroundService.showIncomingCall(
                        context = context,
                        caller = call.argument<String>("caller").orEmpty(),
                        nodeNum = call.argument<Number>("nodeNum")?.toLong() ?: 0L,
                        callId = call.argument<Number>("callId")?.toLong() ?: 0L,
                    ),
                )
            }
            "cancelIncomingCallNotification" -> {
                EdgezBleForegroundService.cancelIncomingCall(context)
                result.success(null)
            }
            "clearCallLockScreenPresentation" -> {
                clearLockScreenPresentation()
                result.success(null)
            }
            "startVoiceRecording" -> startVoiceRecording(result)
            "stopVoiceRecording" -> {
                val send = call.argument<Boolean>("send") ?: true
                stopVoiceRecording(send, result)
            }
            "playVoiceMessage" -> playVoiceMessage(call, result)
            "isOtaReady" -> result.success(gatt != null && otaCharacteristic != null)
            "performOta" -> performOta(call, result)
            "abortOta" -> {
                otaAbortRequested.set(true)
                result.success(null)
            }
            "sendVoiceCallFrame" -> {
                val nonce = call.argument<ByteArray>("nonce")
                val ciphertext = call.argument<ByteArray>("ciphertext")
                if (nonce == null || ciphertext == null) {
                    result.error("voice_frame_invalid", "Voice crypto envelope is missing", null)
                    return
                }
                val waitForDrainMs = call.argument<Int>("waitForDrainMs") ?: 0
                sendVoiceCallFrame(
                    to = call.argument<Long>("to") ?: 0L,
                    maxHop = call.argument<Int>("maxHop") ?: 0,
                    sequence = call.argument<Int>("sequence") ?: 1,
                    nonce = nonce,
                    ciphertext = ciphertext,
                ).fold(
                    onSuccess = {
                        if (waitForDrainMs <= 0) {
                            result.success(it)
                        } else {
                            thread(name = "edgez-voice-call-tx-drain") {
                                waitForApplicationTxDrain(waitForDrainMs).fold(
                                    onSuccess = { mainHandler.post { result.success(null) } },
                                    onFailure = {
                                        mainHandler.post {
                                            result.error(
                                                "voice_write_timeout",
                                                it.message ?: "Voice write did not complete",
                                                null,
                                            )
                                        }
                                    },
                                )
                            }
                        }
                    },
                    onFailure = {
                        result.error("voice_write_failed", it.message ?: "Voice write failed", null)
                    },
                )
            }
            "sendSpeedTestFrame" -> {
                val payload = call.argument<ByteArray>("payload")
                if (payload == null) {
                    result.error("speed_frame_invalid", "Speed-test payload is missing", null)
                    return
                }
                val waitForDrainMs = call.argument<Int>("waitForDrainMs") ?: 0
                val sequence = call.argument<Int>("sequence") ?: 1
                sendSpeedTestFrame(
                    to = call.argument<Long>("to") ?: 0L,
                    maxHop = call.argument<Int>("maxHop") ?: 0,
                    sequence = sequence,
                    payload = payload,
                ).fold(
                    onSuccess = {
                        if (waitForDrainMs <= 0) {
                            result.success(null)
                        } else {
                            thread(name = "edgez-speed-tx-drain") {
                                waitForApplicationTxDrain(waitForDrainMs).fold(
                                    onSuccess = { mainHandler.post { result.success(null) } },
                                    onFailure = {
                                        mainHandler.post {
                                            result.error(
                                                "ble_write_timeout",
                                                it.message ?: "Speed-test write did not complete",
                                                null,
                                            )
                                        }
                                    },
                                )
                            }
                        }
                    },
                    onFailure = {
                        result.error("speed_write_failed", it.message ?: "Speed-test write failed", null)
                    },
                )
            }
            "startLiveVoiceAudio" -> {
                if (ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.RECORD_AUDIO,
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    result.error("microphone_permission_denied", "Microphone permission denied", null)
                    return
                }
                capturedVoiceFrames = 0
                transmittedVoiceFrames = 0
                receivedVoiceFrames = 0
                runCatching { liveVoiceAudio?.start() }
                    .fold(
                        onSuccess = { result.success(null) },
                        onFailure = {
                            result.error("voice_audio_failed", it.message ?: "Live voice failed", null)
                        },
                    )
            }
            "stopLiveVoiceAudio" -> {
                liveVoiceAudio?.stop()
                result.success(null)
            }
            "playLiveVoiceAudio" -> {
                val audio = call.argument<ByteArray>("audio")
                if (audio == null || audio.isEmpty()) {
                    result.error("voice_audio_invalid", "Live voice audio is empty", null)
                    return
                }
                liveVoiceAudio?.play(audio)
                result.success(null)
            }
            "disconnect" -> {
                stopBleScan()
                cancelPendingUsbConnection()
                closeGatt()
                closeUsb(false)
                emit(mapOf("type" to "connection", "connection" to "none"))
                result.success(null)
            }
            "initializeMesh" -> {
                val packet = call.argument<ByteArray>("packet")
                if (packet == null) {
                    result.error("missing_packet", "Missing HaLow init packet", null)
                    return
                }
                Log.i(
                    LOG_TAG,
                    "EdgeZ TX mesh-init route=${activeTransportName()} " +
                        "bytes=${packet.size} compatibility=${call.argument<String>("sdkCompatibility") ?: ""} " +
                        "release=${call.argument<String>("sdkReleaseId") ?: ""} " +
                        "signatureBytes=${call.argument<Int>("sdkReleaseSignatureBytes") ?: 0}",
                )
                sendFrame(packet).fold(
                    onSuccess = {
                        emit(mapOf("type" to "log", "log" to "HaLow mesh init queued"))
                        result.success(null)
                    },
                    onFailure = {
                        result.error("ble_write_failed", it.message ?: "BLE write failed", null)
                    },
                )
            }
            "sendPacket" -> {
                val packet = call.argument<ByteArray>("packet")
                val label = call.argument<String>("label") ?: "Packet"
                val waitForDrainMs = call.argument<Int>("waitForDrainMs") ?: 0
                val writeWithoutResponse =
                    call.argument<Boolean>("writeWithoutResponse") ?: false
                if (packet == null) {
                    result.error("missing_packet", "Missing packet", null)
                    return
                }
                if (label.contains("SDK license", ignoreCase = true) ||
                    label.contains("settings", ignoreCase = true)
                ) {
                    Log.i(
                        LOG_TAG,
                        "EdgeZ TX label=$label route=${activeTransportName()} " +
                            "bytes=${packet.size} compatibility=${call.argument<String>("sdkCompatibility") ?: ""} " +
                            "release=${call.argument<String>("sdkReleaseId") ?: ""} " +
                            "signatureBytes=${call.argument<Int>("sdkReleaseSignatureBytes") ?: 0}",
                    )
                }
                if (label.contains("location", ignoreCase = true)) {
                    Log.i(LOG_TAG, "GPS TX label=$label bytes=${packet.size}")
                    logGpsPacket(packet, "tx")
                }
                if (label.contains("conversation", ignoreCase = true)) {
                    Log.i(
                        LOG_TAG,
                        "EdgeZ TX label=$label route=${activeTransportName()} bytes=${packet.size}",
                    )
                }
                sendFrame(packet, writeWithoutResponse).fold(
                    onSuccess = {
                        emit(mapOf("type" to "log", "log" to "$label queued"))
                        if (waitForDrainMs <= 0) {
                            result.success(null)
                        } else {
                            thread(name = "edgez-control-tx-drain") {
                                waitForControlTxDrain(waitForDrainMs).fold(
                                    onSuccess = {
                                        mainHandler.post {
                                            emit(mapOf("type" to "log", "log" to "$label sent"))
                                            result.success(null)
                                        }
                                    },
                                    onFailure = {
                                        mainHandler.post {
                                            result.error(
                                                "ble_write_timeout",
                                                it.message ?: "BLE write did not complete",
                                                null,
                                            )
                                        }
                                    },
                                )
                            }
                        }
                    },
                    onFailure = {
                        result.error("ble_write_failed", it.message ?: "BLE write failed", null)
                    },
                )
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
        when (requestCode) {
            BLE_PERMISSION_REQUEST -> {
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
            MICROPHONE_PERMISSION_REQUEST -> {
                val result = pendingMicrophoneResult ?: return true
                pendingMicrophoneResult = null
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                emit(mapOf("type" to "log", "log" to if (granted) "Microphone permission granted" else "Microphone permission denied"))
                result.success(granted)
                return true
            }
            LOCATION_PERMISSION_REQUEST -> {
                val result = pendingLocationResult ?: return true
                pendingLocationResult = null
                if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                    returnBestKnownLocation(result)
                } else {
                    result.error("location_permission_denied", "Location permission denied", null)
                }
                return true
            }
            NOTIFICATION_PERMISSION_REQUEST -> {
                val result = pendingNotificationResult ?: return true
                pendingNotificationResult = null
                val granted = grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to if (granted) {
                            "Notification permission granted"
                        } else {
                            "Notification permission denied; background messages and calls cannot be shown"
                        },
                    ),
                )
                result.success(granted)
                return true
            }
            else -> return false
        }
    }

    private fun getBestKnownLocation(result: MethodChannel.Result) {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        )
        if (permissions.none {
                ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
            }
        ) {
            val currentActivity = activity
            if (currentActivity == null) {
                result.error("location_permission_required", "Location permission requires an activity", null)
                return
            }
            pendingLocationResult = result
            currentActivity.requestPermissions(permissions, LOCATION_PERMISSION_REQUEST)
            return
        }
        returnBestKnownLocation(result)
    }

    @SuppressLint("MissingPermission")
    @Suppress("DEPRECATION")
    private fun returnBestKnownLocation(result: MethodChannel.Result) {
        val hasFine = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val manager = context.getSystemService(LocationManager::class.java)
        if (manager == null || (!hasFine && !hasCoarse)) {
            result.success(null)
            return
        }
        val cachedProviders = if (hasFine) {
            listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER,
            )
        } else {
            listOf(LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)
        }
        val cachedLocation = cachedProviders.mapNotNull { provider ->
            runCatching {
                if (manager.isProviderEnabled(provider)) {
                    manager.getLastKnownLocation(provider)
                } else {
                    null
                }
            }.getOrNull()
        }.maxByOrNull { it.time }

        val refreshProviders = buildList {
            if (hasFine && runCatching {
                    manager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                }.getOrDefault(false)
            ) {
                add(LocationManager.GPS_PROVIDER)
            }
            if (runCatching {
                    manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                }.getOrDefault(false)
            ) {
                add(LocationManager.NETWORK_PROVIDER)
            }
        }
        if (refreshProviders.isEmpty()) {
            returnLocation(result, cachedLocation)
            return
        }

        var completed = false
        var timeout: Runnable? = null
        lateinit var listener: LocationListener
        val complete: (Location?) -> Unit = { freshLocation ->
            if (!completed) {
                completed = true
                timeout?.let(mainHandler::removeCallbacks)
                runCatching { manager.removeUpdates(listener) }
                returnLocation(result, freshLocation ?: cachedLocation)
            }
        }
        listener = LocationListener { location -> complete(location) }
        timeout = Runnable { complete(null) }
        mainHandler.postDelayed(timeout, LOCATION_REFRESH_TIMEOUT_MS)

        var refreshRequested = false
        for (provider in refreshProviders) {
            val requested = runCatching {
                manager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
            }.isSuccess
            refreshRequested = refreshRequested || requested
        }
        if (!refreshRequested) complete(null)
    }

    private fun returnLocation(result: MethodChannel.Result, location: Location?) {
        if (location == null) {
            Log.w(LOG_TAG, "GPS local refresh result=none")
        } else {
            Log.i(
                LOG_TAG,
                "GPS local refresh provider=${location.provider} " +
                    "lat=${location.latitude} lon=${location.longitude} " +
                    "accuracy=${location.accuracy}m timestamp=${location.time} " +
                    "zero=${location.latitude == 0.0 && location.longitude == 0.0}",
            )
        }
        result.success(
            location?.let {
                mapOf(
                    "latitude" to it.latitude,
                    "longitude" to it.longitude,
                    "timestampMs" to it.time,
                )
            },
        )
    }

    private fun requestMicrophonePermission(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.success(false)
            emit(mapOf("type" to "log", "log" to "Microphone permission requires an activity"))
            return
        }
        pendingMicrophoneResult = result
        currentActivity.requestPermissions(
            arrayOf(Manifest.permission.RECORD_AUDIO),
            MICROPHONE_PERMISSION_REQUEST,
        )
        emit(mapOf("type" to "log", "log" to "Requesting microphone permission"))
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(EdgezBleForegroundService.notificationsAllowed(context))
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "activity_missing",
                "Notification permission requires a foreground activity",
                null,
            )
            return
        }
        pendingNotificationResult = result
        currentActivity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST,
        )
    }

    private fun clearLockScreenPresentation() {
        val currentActivity = activity ?: return
        if (Build.VERSION.SDK_INT >= 27) {
            currentActivity.setShowWhenLocked(false)
            currentActivity.setTurnScreenOn(false)
        } else {
            @Suppress("DEPRECATION")
            currentActivity.window.clearFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun newMediaRecorder(): MediaRecorder {
        return if (Build.VERSION.SDK_INT >= 31) MediaRecorder(context) else MediaRecorder()
    }

    private fun startVoiceRecording(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            result.error("microphone_permission_denied", "Microphone permission denied", null)
            return
        }
        runCatching {
            discardVoiceRecording()
            val dir = File(context.cacheDir, "edgez_voice")
            if (!dir.exists()) dir.mkdirs()
            val supportsOpus = Build.VERSION.SDK_INT >= 29
            val codec = if (supportsOpus) VOICE_CODEC_OPUS else VOICE_CODEC_AMR_NB
            val extension = if (supportsOpus) "ogg" else "3gp"
            val file = File(dir, "recording_${System.currentTimeMillis()}.$extension")
            val recorder = newMediaRecorder()
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            if (supportsOpus) {
                recorder.setOutputFormat(MediaRecorder.OutputFormat.OGG)
                recorder.setAudioEncoder(MediaRecorder.AudioEncoder.OPUS)
                recorder.setAudioSamplingRate(16000)
                recorder.setAudioEncodingBitRate(12000)
            } else {
                recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                recorder.setAudioSamplingRate(8000)
                recorder.setAudioEncodingBitRate(4750)
            }
            recorder.setOutputFile(file.absolutePath)
            recorder.prepare()
            recorder.start()
            voiceRecorder = recorder
            voiceRecordingFile = file
            voiceRecordingCodec = codec
            voiceRecordingStartedAtMs = System.currentTimeMillis()
        }.fold(
            onSuccess = {
                emit(mapOf("type" to "log", "log" to "Voice recording started"))
                result.success(null)
            },
            onFailure = {
                discardVoiceRecording()
                result.error("voice_record_failed", it.message ?: "Voice recording failed", null)
            },
        )
    }

    private fun stopVoiceRecording(send: Boolean, result: MethodChannel.Result) {
        val recorder = voiceRecorder
        val file = voiceRecordingFile
        val codec = voiceRecordingCodec
        val durationMs = (System.currentTimeMillis() - voiceRecordingStartedAtMs).coerceAtLeast(0)
        if (recorder == null || file == null) {
            result.success(null)
            return
        }

        voiceRecorder = null
        voiceRecordingFile = null
        voiceRecordingStartedAtMs = 0

        runCatching {
            try {
                recorder.stop()
            } finally {
                recorder.release()
            }
            if (!send || durationMs < 250 || !file.exists() || file.length() <= 0) {
                file.delete()
                null
            } else {
                val bytes = file.readBytes()
                file.delete()
                mapOf(
                    "bytes" to bytes,
                    "durationMs" to durationMs.toInt(),
                    "codec" to codec,
                )
            }
        }.fold(
            onSuccess = {
                emit(mapOf("type" to "log", "log" to if (it == null) "Voice recording cancelled" else "Voice recording stopped"))
                result.success(it)
            },
            onFailure = {
                file.delete()
                result.error("voice_record_failed", it.message ?: "Voice recording failed", null)
            },
        )
    }

    private fun discardVoiceRecording() {
        val recorder = voiceRecorder
        voiceRecorder = null
        runCatching {
            recorder?.stop()
        }
        recorder?.release()
        voiceRecordingFile?.delete()
        voiceRecordingFile = null
        voiceRecordingStartedAtMs = 0
    }

    private fun playVoiceMessage(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val codec = call.argument<Int>("codec") ?: 0
        if (bytes == null || bytes.isEmpty()) {
            result.error("voice_missing", "Voice message has no audio bytes", null)
            return
        }
        runCatching {
            voicePlayer?.release()
            voicePlayer = null
            val dir = File(context.cacheDir, "edgez_voice")
            if (!dir.exists()) dir.mkdirs()
            val extension = if (codec == VOICE_CODEC_OPUS) "ogg" else "3gp"
            val file = File(dir, "voice_${System.currentTimeMillis()}.$extension")
            file.writeBytes(bytes)
            val player = MediaPlayer()
            player.setDataSource(file.absolutePath)
            player.setOnCompletionListener {
                it.release()
                if (voicePlayer === it) {
                    voicePlayer = null
                }
                file.delete()
            }
            player.prepare()
            player.start()
            voicePlayer = player
        }.fold(
            onSuccess = {
                emit(mapOf("type" to "log", "log" to "Voice replay started"))
                result.success(null)
            },
            onFailure = {
                result.error("voice_play_failed", it.message ?: "Voice replay failed", null)
            },
        )
    }

    private fun performOta(call: MethodCall, result: MethodChannel.Result) {
        val image = call.argument<ByteArray>("image")
        if (image == null || image.isEmpty()) {
            result.error("ota_image_invalid", "OTA image is empty", null)
            return
        }
        if (gatt == null || otaCharacteristic == null) {
            result.error("ota_unavailable", "BLE OTA characteristic FFF5 is unavailable", null)
            return
        }
        if (!otaInProgress.compareAndSet(false, true)) {
            result.error("ota_in_progress", "An OTA update is already running", null)
            return
        }
        otaAbortRequested.set(false)
        thread(name = "edgez-ble-ota") {
            runCatching {
                writeOtaPacket(otaPacket(OTA_BEGIN, image.size))
                val chunkSize = (negotiatedMtu - 3 - OTA_DATA_HEADER_SIZE)
                    .coerceIn(20, OTA_DATA_MAX_CHUNK_SIZE)
                var sent = 0
                while (sent < image.size) {
                    check(!otaAbortRequested.get()) { "Firmware update cancelled" }
                    val length = minOf(chunkSize, image.size - sent)
                    writeOtaPacket(otaDataPacket(sent, image, length))
                    sent += length
                    emit(
                        mapOf(
                            "type" to "otaProgress",
                            "sentBytes" to sent,
                            "totalBytes" to image.size,
                        ),
                    )
                }
                writeOtaPacket(byteArrayOf(OTA_END))
                "Firmware uploaded; the device is restarting"
            }.onFailure {
                runCatching { writeOtaPacket(byteArrayOf(OTA_ABORT)) }
            }.fold(
                onSuccess = { message -> mainHandler.post { result.success(message) } },
                onFailure = { error ->
                    mainHandler.post {
                        result.error("ota_failed", error.message ?: "Firmware update failed", null)
                    }
                },
            )
            otaInProgress.set(false)
            otaAbortRequested.set(false)
        }
    }

    private fun otaPacket(command: Byte, value: Int): ByteArray =
        ByteBuffer.allocate(OTA_DATA_HEADER_SIZE)
            .order(ByteOrder.LITTLE_ENDIAN)
            .put(command)
            .putInt(value)
            .array()

    private fun otaDataPacket(offset: Int, image: ByteArray, length: Int): ByteArray =
        ByteBuffer.allocate(OTA_DATA_HEADER_SIZE + length)
            .order(ByteOrder.LITTLE_ENDIAN)
            .put(OTA_DATA)
            .putInt(offset)
            .put(image, offset, length)
            .array()

    @SuppressLint("MissingPermission")
    private fun writeOtaPacket(packet: ByteArray) {
        val activeGatt = gatt ?: throw IllegalStateException("BLE is not connected")
        val characteristic = otaCharacteristic
            ?: throw IllegalStateException("BLE OTA characteristic FFF5 is unavailable")
        synchronized(otaWriteLock) {
            otaWriteStatus = null
            val started = if (Build.VERSION.SDK_INT >= 33) {
                activeGatt.writeCharacteristic(
                    characteristic,
                    packet,
                    BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT,
                ) == BluetoothGatt.GATT_SUCCESS
            } else {
                characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                characteristic.value = packet
                activeGatt.writeCharacteristic(characteristic)
            }
            if (!started) throw IllegalStateException("BLE OTA write could not start")
            val deadline = System.currentTimeMillis() + OTA_WRITE_TIMEOUT_MS
            while (otaWriteStatus == null && System.currentTimeMillis() < deadline) {
                otaWriteLock.wait((deadline - System.currentTimeMillis()).coerceAtLeast(1))
            }
            val status = otaWriteStatus ?: throw IllegalStateException("BLE OTA write timed out")
            if (status != BluetoothGatt.GATT_SUCCESS) {
                throw IllegalStateException("BLE OTA write failed: $status")
            }
        }
    }

    private fun sendVoiceCallFrame(
        to: Long,
        maxHop: Int,
        sequence: Int,
        nonce: ByteArray,
        ciphertext: ByteArray,
    ): Result<String> {
        if (nonce.size != EDGEZ_VOICE_NONCE_SIZE || ciphertext.isEmpty()) {
            return Result.failure(IllegalArgumentException("Invalid voice-call crypto envelope"))
        }
        val packet = ByteBuffer.allocate(
            EDGEZ_VOICE_ROUTE_SIZE + nonce.size + ciphertext.size,
        ).order(ByteOrder.BIG_ENDIAN)
        for (shift in 40 downTo 0 step 8) packet.put((to ushr shift).toByte())
        packet.put(maxHop.coerceIn(0, 255).toByte())
        packet.putInt(sequence)
        packet.put(nonce)
        packet.put(ciphertext)
        return sendVoicePacket(packet.array())
    }

    private fun sendSpeedTestFrame(
        to: Long,
        maxHop: Int,
        sequence: Int,
        payload: ByteArray,
    ): Result<String> {
        if (to == 0L || sequence <= 0 || payload.isEmpty()) {
            return Result.failure(IllegalArgumentException("Invalid speed-test route or payload"))
        }
        val packet = ByteBuffer.allocate(EDGEZ_VOICE_ROUTE_SIZE + payload.size)
            .order(ByteOrder.BIG_ENDIAN)
        for (shift in 40 downTo 0 step 8) packet.put((to ushr shift).toByte())
        packet.put(maxHop.coerceIn(0, 255).toByte())
        packet.putInt(sequence)
        packet.put(payload)
        return sendRealtimePacket(
            protocolMagic = EDGEZ_SPEED_PROTOCOL_MAGIC,
            packet = packet.array(),
            dropStale = false,
        )
    }

    @SuppressLint("MissingPermission")
    private fun sendVoicePacket(packet: ByteArray): Result<String> {
        return sendRealtimePacket(
            protocolMagic = EDGEZ_VOICE_PROTOCOL_MAGIC,
            packet = packet,
            dropStale = true,
        )
    }

    @SuppressLint("MissingPermission")
    private fun sendRealtimePacket(
        protocolMagic: ByteArray,
        packet: ByteArray,
        dropStale: Boolean,
    ): Result<String> {
        val frame = protocolMagic + packet
        val activeGatt = gatt
        if (activeGatt == null) {
            return if (usbConnection != null) {
                enqueueUsbRealtimeFrame(frame, dropStale)
            } else {
                Result.failure(IllegalStateException("BLE and USB are not connected"))
            }
        }
        val voice = voiceRxCharacteristic ?: return Result.failure(
            IllegalStateException("BLE voice characteristics FFF7/FFF8 are unavailable"),
        )
        val maxVoiceFrame = minOf(negotiatedMtu - 3, EDGEZ_MAX_PAYLOAD)
        if (frame.size > maxVoiceFrame) {
            return Result.failure(
                IllegalArgumentException("Voice packet too large: ${frame.size}/$maxVoiceFrame"),
            )
        }
        synchronized(this) {
            val queueDepth =
                if (dropStale) EDGEZ_VOICE_TX_QUEUE_DEPTH else EDGEZ_SPEED_TX_QUEUE_DEPTH
            if (voiceTxQueue.size >= queueDepth) {
                if (!dropStale) {
                    return Result.failure(IllegalStateException("BLE realtime queue is full"))
                }
                if (voiceTxWriteInFlight) voiceTxQueue.pollLast() else voiceTxQueue.pollFirst()
            }
            voiceTxQueue.addLast(
                EdgezBleWrite(frame, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT),
            )
            if (dropStale) transmittedVoiceFrames++
        }
        if (dropStale &&
            (transmittedVoiceFrames == 1 || transmittedVoiceFrames % 25 == 0)
        ) {
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "Live voice queued frames=$transmittedVoiceFrames bytes=${frame.size}",
                ),
            )
        }
        return if (writeNextVoiceFrame(activeGatt, voice)) {
            Result.success("BLE voice queued")
        } else {
            synchronized(this) {
                voiceTxQueue.removeIf { queued -> queued.frame === frame }
            }
            Result.failure(IllegalStateException("BLE voice write failed"))
        }
    }

    private fun waitForApplicationTxDrain(timeoutMs: Int): Result<String> {
        if (gatt == null && usbConnection != null) {
            return waitForUsbRealtimeTxDrain(timeoutMs)
        }
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            synchronized(this) {
                if (!voiceTxWriteInFlight && voiceTxQueue.isEmpty()) {
                    return Result.success("BLE realtime TX complete")
                }
            }
            try {
                Thread.sleep(5)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
                return Result.failure(IllegalStateException("BLE realtime TX interrupted"))
            }
        }
        return Result.failure(IllegalStateException("BLE realtime TX not complete after ${timeoutMs}ms"))
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
        val filter = ScanFilter.Builder()
            .setServiceUuid(ParcelUuid(EDGEZ_SERVICE_UUID))
            .build()
        scanCallback = callback
        scanner.startScan(listOf(filter), settings, callback)
        emit(mapOf("type" to "log", "log" to "BLE scan started for EdgeZ service $EDGEZ_SERVICE_UUID"))
        mainHandler.postDelayed({
            if (scanCallback == callback && scanGeneration == generation && devices.isEmpty()) {
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE scan is running but no EdgeZ advertisements were received. Check permissions, Location services, and that the device advertises $EDGEZ_SERVICE_UUID.",
                    ),
                )
            }
        }, 6000)
        result.success(null)
    }

    @SuppressLint("MissingPermission")
    private fun publishScanResult(result: ScanResult) {
        val serviceUuids = result.scanRecord?.serviceUuids.orEmpty()
        if (serviceUuids.none { it.uuid == EDGEZ_SERVICE_UUID }) return
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
        cancelPendingUsbConnection()
        stopBleScan()
        closeUsb(false)
        closeGatt()
        runCatching {
            EdgezBleForegroundService.start(context, "")
        }.onFailure { error ->
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "BLE background service could not start: ${error.message}",
                ),
            )
        }
        if (device.bondState != BluetoothDevice.BOND_BONDED) {
            pendingBondDevice = device
            emit(mapOf("type" to "log", "log" to "Starting BLE pairing ${device.address}"))
            if (!device.createBond()) {
                pendingBondDevice = null
                EdgezBleForegroundService.stop(context)
                result.error("ble_pairing_failed", "BLE pairing could not start", null)
                return
            }
            result.success(null)
            return
        }
        connectGatt(device)
        result.success(null)
    }

    @SuppressLint("MissingPermission")
    private fun connectGatt(device: BluetoothDevice) {
        gatt = if (Build.VERSION.SDK_INT >= 23) {
            device.connectGatt(context, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
        } else {
            device.connectGatt(context, false, gattCallback)
        }
        emit(mapOf("type" to "log", "log" to "Connecting BLE ${device.address}"))
    }

    @SuppressLint("MissingPermission")
    private fun discoverServicesOnce(activeGatt: BluetoothGatt, reason: String) {
        val attempt = synchronized(this) {
            if (gatt !== activeGatt || serviceDiscoveryComplete || serviceDiscoveryStarted) {
                return
            }
            serviceDiscoveryStarted = true
            serviceDiscoveryAttempts += 1
            serviceDiscoveryAttempts
        }
        emit(
            mapOf(
                "type" to "log",
                "log" to "Discovering BLE services ($reason, attempt $attempt/$MAX_SERVICE_DISCOVERY_ATTEMPTS)",
            ),
        )
        if (!activeGatt.discoverServices()) {
            synchronized(this) { serviceDiscoveryStarted = false }
            retryServiceDiscovery(activeGatt, "Android rejected service discovery")
            return
        }
        mainHandler.postDelayed({
            if (gatt === activeGatt && !serviceDiscoveryComplete && serviceDiscoveryStarted) {
                synchronized(this) { serviceDiscoveryStarted = false }
                retryServiceDiscovery(activeGatt, "BLE service discovery callback timed out")
            }
        }, SERVICE_DISCOVERY_TIMEOUT_MS)
    }

    private fun retryServiceDiscovery(activeGatt: BluetoothGatt, failure: String) {
        if (serviceDiscoveryAttempts >= MAX_SERVICE_DISCOVERY_ATTEMPTS) {
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "$failure. BLE setup failed; disconnect, remove the pairing, and try again.",
                ),
            )
            return
        }
        emit(mapOf("type" to "log", "log" to "$failure; retrying"))
        mainHandler.postDelayed({
            discoverServicesOnce(activeGatt, "retry after timeout")
        }, CONTROL_SERVICE_READY_FALLBACK_MS)
    }

    @SuppressLint("MissingPermission")
    private fun closeGatt() {
        otaAbortRequested.set(true)
        EdgezBleForegroundService.stop(context)
        liveVoiceAudio?.stop()
        pendingBondDevice = null
        rxCharacteristic = null
        txCharacteristic = null
        forwardRxCharacteristic = null
        forwardTxCharacteristic = null
        otaCharacteristic = null
        otaStatusCharacteristic = null
        voiceRxCharacteristic = null
        voiceTxCharacteristic = null
        notificationDescriptors.clear()
        notificationDescriptorWriteInFlight = false
        serviceReadyPending = false
        serviceDiscoveryStarted = false
        serviceDiscoveryComplete = false
        serviceDiscoveryAttempts = 0
        controlNotificationWriteStarted = false
        controlNotificationFailed = false
        negotiatedMtu = 23
        rxLen = 0
        forwardRxLen = 0
        clearTxQueue()
        gatt?.close()
        gatt = null
    }

    private fun sendFrame(
        payload: ByteArray,
        writeWithoutResponse: Boolean = false,
    ): Result<String> {
        val activeGatt = gatt
        if (activeGatt == null) {
            return if (usbConnection != null) {
                writeUsbFrame(payload)
            } else {
                Result.failure(IllegalStateException("BLE and USB are not connected"))
            }
        }
        val rx = rxCharacteristic ?: return Result.failure(IllegalStateException("BLE control service is not ready"))
        if (payload.size > EDGEZ_MAX_PAYLOAD) {
            return Result.failure(IllegalArgumentException("Payload too large: ${payload.size}/$EDGEZ_MAX_PAYLOAD"))
        }

        val tx = ByteBuffer.allocate(EDGEZ_HEADER_LEN + payload.size).order(ByteOrder.LITTLE_ENDIAN)
        tx.put(EDGEZ_MAGIC_0)
        tx.put(EDGEZ_MAGIC_1)
        tx.putShort(payload.size.toShort())
        tx.put(payload)

        val frame = tx.array()
        val supportsWriteWithoutResponse =
            rx.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0
        val writeType =
            if (writeWithoutResponse && supportsWriteWithoutResponse) {
                BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
            } else {
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            }
        val write = EdgezBleWrite(frame, writeType)
        synchronized(this) {
            txQueue.add(write)
        }
        return if (writeNextFrame(activeGatt, rx)) {
            Result.success("BLE queued protobuf")
        } else {
            synchronized(this) {
                txQueue.remove(write)
            }
            Result.failure(IllegalStateException("BLE write failed"))
        }
    }

    private fun waitForControlTxDrain(timeoutMs: Int): Result<String> {
        if (gatt == null && usbConnection != null) {
            return waitForApplicationTxDrain(timeoutMs)
        }
        val deadline = System.currentTimeMillis() + timeoutMs
        while (System.currentTimeMillis() < deadline) {
            synchronized(this) {
                if (!txWriteInFlight && txQueue.isEmpty()) {
                    return Result.success("BLE control TX complete")
                }
            }
            try {
                Thread.sleep(10)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
                return Result.failure(IllegalStateException("BLE control TX interrupted"))
            }
        }
        return Result.failure(
            IllegalStateException("BLE control TX not complete after ${timeoutMs}ms"),
        )
    }

    @SuppressLint("MissingPermission")
    private fun writeNextFrame(
        activeGatt: BluetoothGatt? = gatt,
        writeCharacteristic: BluetoothGattCharacteristic? = rxCharacteristic,
    ): Boolean {
        val currentGatt = activeGatt ?: return false
        val rx = writeCharacteristic ?: return false
        val frame = synchronized(this) {
            if (dataWriteInFlight || txWriteInFlight) return true
            val nextFrame = txQueue.peekFirst() ?: return true
            txWriteInFlight = true
            dataWriteInFlight = true
            nextFrame
        }

        val ok = if (Build.VERSION.SDK_INT >= 33) {
            currentGatt.writeCharacteristic(rx, frame.frame, frame.writeType) == BluetoothGatt.GATT_SUCCESS
        } else {
            rx.writeType = frame.writeType
            rx.value = frame.frame
            currentGatt.writeCharacteristic(rx)
        }
        if (!ok) {
            synchronized(this) {
                txWriteInFlight = false
                dataWriteInFlight = false
            }
        }
        return ok
    }

    @SuppressLint("MissingPermission")
    private fun writeNextVoiceFrame(
        activeGatt: BluetoothGatt? = gatt,
        writeCharacteristic: BluetoothGattCharacteristic? = voiceRxCharacteristic,
    ): Boolean {
        val currentGatt = activeGatt ?: return false
        val voice = writeCharacteristic ?: return false
        val frame = synchronized(this) {
            if (dataWriteInFlight || voiceTxWriteInFlight) return true
            val nextFrame = voiceTxQueue.peekFirst() ?: return true
            voiceTxWriteInFlight = true
            dataWriteInFlight = true
            nextFrame
        }
        val ok = if (Build.VERSION.SDK_INT >= 33) {
            currentGatt.writeCharacteristic(
                voice,
                frame.frame,
                frame.writeType,
            ) == BluetoothGatt.GATT_SUCCESS
        } else {
            voice.writeType = frame.writeType
            voice.value = frame.frame
            currentGatt.writeCharacteristic(voice)
        }
        if (!ok) {
            synchronized(this) {
                voiceTxWriteInFlight = false
                dataWriteInFlight = false
            }
        }
        return ok
    }

    private fun writeNextDataFrame(activeGatt: BluetoothGatt) {
        if (synchronized(this) { dataWriteInFlight }) return
        if (txQueue.isNotEmpty()) {
            writeNextFrame(activeGatt, rxCharacteristic)
        } else if (voiceTxQueue.isNotEmpty()) {
            writeNextVoiceFrame(activeGatt, voiceRxCharacteristic)
        }
    }

    @Synchronized
    private fun clearTxQueue() {
        txQueue.clear()
        voiceTxQueue.clear()
        txWriteInFlight = false
        voiceTxWriteInFlight = false
        dataWriteInFlight = false
    }

    private val gattCallback = object : BluetoothGattCallback() {
        @SuppressLint("MissingPermission")
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            emit(mapOf("type" to "log", "log" to "BLE connection status=$status state=$newState"))
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                serviceDiscoveryStarted = false
                serviceDiscoveryComplete = false
                serviceDiscoveryAttempts = 0
                controlNotificationWriteStarted = false
                controlNotificationFailed = false
                val highPriorityRequested = gatt.requestConnectionPriority(
                    BluetoothGatt.CONNECTION_PRIORITY_HIGH,
                )
                emit(mapOf("type" to "log", "log" to "BLE high priority requested=$highPriorityRequested"))
                if (Build.VERSION.SDK_INT >= 26) {
                    gatt.setPreferredPhy(
                        BluetoothDevice.PHY_LE_2M_MASK,
                        BluetoothDevice.PHY_LE_2M_MASK,
                        BluetoothDevice.PHY_OPTION_NO_PREFERRED,
                    )
                    emit(mapOf("type" to "log", "log" to "BLE 2M PHY requested"))
                }
                emit(mapOf("type" to "connection", "connection" to "ble"))
                runCatching {
                    EdgezBleForegroundService.start(
                        context,
                        gatt.device.name ?: gatt.device.address,
                    )
                }.onFailure { error ->
                    emit(
                        mapOf(
                            "type" to "log",
                            "log" to "BLE background service could not start: ${error.message}",
                        ),
                    )
                }
                val mtuRequestStarted = gatt.requestMtu(EDGEZ_BLE_REQUESTED_MTU)
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to if (mtuRequestStarted) {
                            "BLE link connected; negotiating MTU"
                        } else {
                            "BLE MTU request was rejected; continuing with service discovery"
                        },
                    ),
                )
                if (!mtuRequestStarted) {
                    discoverServicesOnce(gatt, "MTU request rejected")
                } else {
                    mainHandler.postDelayed({
                        if (this@EdgezFlutterSdkPlugin.gatt === gatt &&
                            !serviceDiscoveryStarted &&
                            !serviceDiscoveryComplete
                        ) {
                            emit(
                                mapOf(
                                    "type" to "log",
                                    "log" to "BLE MTU callback timed out; continuing with default MTU",
                                ),
                            )
                            discoverServicesOnce(gatt, "MTU callback timeout")
                        }
                    }, MTU_CALLBACK_FALLBACK_MS)
                }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                otaAbortRequested.set(true)
                EdgezBleForegroundService.stop(context)
                rxCharacteristic = null
                txCharacteristic = null
                forwardRxCharacteristic = null
                forwardTxCharacteristic = null
                otaCharacteristic = null
                otaStatusCharacteristic = null
                voiceRxCharacteristic = null
                voiceTxCharacteristic = null
                notificationDescriptors.clear()
                notificationDescriptorWriteInFlight = false
                serviceReadyPending = false
                serviceDiscoveryStarted = false
                serviceDiscoveryComplete = false
                serviceDiscoveryAttempts = 0
                controlNotificationWriteStarted = false
                controlNotificationFailed = false
                negotiatedMtu = 23
                rxLen = 0
                forwardRxLen = 0
                clearTxQueue()
                emit(mapOf("type" to "connection", "connection" to "none"))
            }
        }

        @SuppressLint("MissingPermission")
        override fun onMtuChanged(gatt: BluetoothGatt, mtu: Int, status: Int) {
            emit(mapOf("type" to "log", "log" to "BLE MTU mtu=$mtu status=$status"))
            if (status == BluetoothGatt.GATT_SUCCESS) negotiatedMtu = mtu
            discoverServicesOnce(gatt, "MTU callback")
        }

        override fun onPhyUpdate(
            gatt: BluetoothGatt,
            txPhy: Int,
            rxPhy: Int,
            status: Int,
        ) {
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "BLE PHY tx=$txPhy rx=$rxPhy status=$status",
                ),
            )
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            emit(mapOf("type" to "log", "log" to "BLE services status=$status"))
            synchronized(this@EdgezFlutterSdkPlugin) {
                serviceDiscoveryStarted = false
            }
            if (status != BluetoothGatt.GATT_SUCCESS) {
                retryServiceDiscovery(gatt, "BLE service discovery failed with status $status")
                return
            }
            serviceDiscoveryComplete = true
            val service: BluetoothGattService? = gatt.getService(EDGEZ_SERVICE_UUID)
            val rx = service?.getCharacteristic(EDGEZ_RX_UUID)
            val tx = service?.getCharacteristic(EDGEZ_TX_UUID)
            if (rx == null || tx == null) {
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE setup failed: EdgeZ control service is missing rx=${rx != null} tx=${tx != null}. Check device firmware and clear the phone's Bluetooth cache.",
                    ),
                )
                return
            }

            rxCharacteristic = rx
            txCharacteristic = tx
            forwardRxCharacteristic = service.getCharacteristic(EDGEZ_FORWARD_RX_UUID)
            forwardTxCharacteristic = service.getCharacteristic(EDGEZ_FORWARD_TX_UUID)
            otaCharacteristic = service.getCharacteristic(EDGEZ_OTA_UUID)
            otaStatusCharacteristic = service.getCharacteristic(EDGEZ_OTA_STATUS_UUID)
            voiceRxCharacteristic = service.getCharacteristic(EDGEZ_VOICE_RX_UUID)
            voiceTxCharacteristic = service.getCharacteristic(EDGEZ_VOICE_TX_UUID)
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "BLE characteristics control=true " +
                        "rxWriteNoResponse=${rx.properties and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0} " +
                        "forwardRx=${forwardRxCharacteristic != null} forwardTx=${forwardTxCharacteristic != null} " +
                        "ota=${otaCharacteristic != null} otaStatus=${otaStatusCharacteristic != null} " +
                        "voiceRx=${voiceRxCharacteristic != null} voiceTx=${voiceTxCharacteristic != null}",
                ),
            )
            notificationDescriptors.clear()
            notificationDescriptorWriteInFlight = false
            controlNotificationWriteStarted = false
            controlNotificationFailed = false
            queueNotification(gatt, tx, requiredForControl = true)
            forwardTxCharacteristic?.let {
                queueNotification(gatt, it)
                emit(mapOf("type" to "log", "log" to "BLE forwarded-mesh channel available"))
            }
            otaStatusCharacteristic?.let { queueNotification(gatt, it) }
            voiceTxCharacteristic?.let { queueNotification(gatt, it) }
            serviceReadyPending = true
            writeNextNotificationDescriptor(gatt)
            maybeMarkControlServiceReady(gatt)
            // Some Android stacks accept the CCCD write at the peripheral but
            // omit onDescriptorWrite while PHY/data-length negotiation is in
            // flight. Do not leave HaLow initialization blocked forever. The
            // delay lets the GATT operation finish before Flutter writes INIT.
            mainHandler.postDelayed({
                if (this@EdgezFlutterSdkPlugin.gatt === gatt && serviceReadyPending) {
                    emit(
                        mapOf(
                            "type" to "log",
                            "log" to "BLE notification callback timeout; continuing with control service",
                        ),
                    )
                    maybeMarkControlServiceReady(gatt, allowPendingNotifications = true)
                }
            }, CONTROL_SERVICE_READY_FALLBACK_MS)
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            if (descriptor.uuid != CCCD_UUID) return
            notificationDescriptorWriteInFlight = false
            val isControlNotification = descriptor.characteristic.uuid == txCharacteristic?.uuid
            if (status != BluetoothGatt.GATT_SUCCESS) {
                emit(mapOf("type" to "log", "log" to "BLE notification subscription failed status=$status uuid=${descriptor.characteristic.uuid}"))
                if (isControlNotification) controlNotificationFailed = true
            }
            writeNextNotificationDescriptor(gatt)
            maybeMarkControlServiceReady(gatt)
        }

        @SuppressLint("MissingPermission")
        private fun queueNotification(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            requiredForControl: Boolean = false,
        ) {
            if (!gatt.setCharacteristicNotification(characteristic, true)) {
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE notification setup rejected uuid=${characteristic.uuid}",
                    ),
                )
                if (requiredForControl) controlNotificationFailed = true
                return
            }
            val descriptor = characteristic.getDescriptor(CCCD_UUID)
            if (descriptor == null) {
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE notification descriptor missing uuid=${characteristic.uuid}",
                    ),
                )
                if (requiredForControl) controlNotificationFailed = true
                return
            }
            notificationDescriptors.addLast(descriptor)
        }

        @SuppressLint("MissingPermission")
        private fun writeNextNotificationDescriptor(gatt: BluetoothGatt) {
            if (notificationDescriptorWriteInFlight || notificationDescriptors.isEmpty()) return
            val descriptor = notificationDescriptors.removeFirst()
            notificationDescriptorWriteInFlight = true
            val isControlNotification = descriptor.characteristic.uuid == txCharacteristic?.uuid
            val started = if (Build.VERSION.SDK_INT >= 33) {
                gatt.writeDescriptor(
                    descriptor,
                    BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE,
                ) == BluetoothGatt.GATT_SUCCESS
            } else {
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                gatt.writeDescriptor(descriptor)
            }
            if (!started) {
                notificationDescriptorWriteInFlight = false
                emit(mapOf("type" to "log", "log" to "BLE notification subscription failed to start uuid=${descriptor.characteristic.uuid}"))
                if (isControlNotification) controlNotificationFailed = true
                writeNextNotificationDescriptor(gatt)
            } else if (isControlNotification) {
                controlNotificationWriteStarted = true
            }
        }

        private fun maybeMarkControlServiceReady(
            gatt: BluetoothGatt,
            allowPendingNotifications: Boolean = false,
        ) {
            if (!serviceReadyPending) return
            if (controlNotificationFailed) {
                serviceReadyPending = false
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE setup failed: the phone could not enable device-status notifications. Disconnect, remove the pairing, and try again.",
                    ),
                )
                return
            }
            if (!allowPendingNotifications &&
                (notificationDescriptorWriteInFlight || notificationDescriptors.isNotEmpty())
            ) {
                return
            }
            if (!controlNotificationWriteStarted) {
                serviceReadyPending = false
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "BLE setup failed: device-status notifications were not started.",
                    ),
                )
                return
            }
            serviceReadyPending = false
            emit(
                mapOf(
                    "type" to "log",
                    "log" to if (allowPendingNotifications && notificationDescriptorWriteInFlight) {
                        "BLE notification confirmation timed out; requesting device status anyway"
                    } else {
                        "BLE control channel ready; requesting device status"
                    },
                ),
            )
            emit(mapOf("type" to "ready"))
            writeNextFrame(gatt, rxCharacteristic)
        }

        override fun onCharacteristicWrite(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            status: Int,
        ) {
            if (characteristic.uuid == otaCharacteristic?.uuid) {
                synchronized(otaWriteLock) {
                    otaWriteStatus = status
                    otaWriteLock.notifyAll()
                }
                return
            }
            val isVoiceWrite = characteristic.uuid == voiceRxCharacteristic?.uuid
            synchronized(this@EdgezFlutterSdkPlugin) {
                dataWriteInFlight = false
                if (isVoiceWrite) {
                    voiceTxWriteInFlight = false
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        voiceTxQueue.pollFirst()
                    } else {
                        voiceTxQueue.clear()
                    }
                } else {
                    txWriteInFlight = false
                    if (status == BluetoothGatt.GATT_SUCCESS) {
                        txQueue.pollFirst()
                    } else {
                        txQueue.clear()
                    }
                }
            }
            val remaining = synchronized(this@EdgezFlutterSdkPlugin) {
                if (isVoiceWrite) voiceTxQueue.size else txQueue.size
            }
            emit(mapOf("type" to "log", "log" to "BLE TX complete status=$status queued=$remaining voice=$isVoiceWrite"))
            writeNextDataFrame(gatt)
        }

        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
            value: ByteArray,
        ) {
            when (characteristic.uuid) {
                txCharacteristic?.uuid -> handleBytes(value)
                forwardTxCharacteristic?.uuid -> handleForwardBytes(value)
                otaStatusCharacteristic?.uuid -> emit(
                    mapOf("type" to "log", "log" to "BLE OTA status=${value.toHexString()}"),
                )
                voiceTxCharacteristic?.uuid -> handleVoiceBytes(value)
                else -> emit(
                    mapOf("type" to "log", "log" to "BLE notification from unknown characteristic ${characteristic.uuid}"),
                )
            }
        }

        @Deprecated("Deprecated in Java")
        override fun onCharacteristicChanged(
            gatt: BluetoothGatt,
            characteristic: BluetoothGattCharacteristic,
        ) {
            val value = characteristic.value ?: return
            when (characteristic.uuid) {
                txCharacteristic?.uuid -> handleBytes(value)
                forwardTxCharacteristic?.uuid -> handleForwardBytes(value)
                otaStatusCharacteristic?.uuid -> emit(
                    mapOf("type" to "log", "log" to "BLE OTA status=${value.toHexString()}"),
                )
                voiceTxCharacteristic?.uuid -> handleVoiceBytes(value)
                else -> emit(
                    mapOf("type" to "log", "log" to "BLE notification from unknown characteristic ${characteristic.uuid}"),
                )
            }
        }
    }

    private fun handleBytes(bytes: ByteArray) {
        if (rxLen + bytes.size > rxBuffer.size) {
            rxLen = 0
        }
        System.arraycopy(bytes, 0, rxBuffer, rxLen, bytes.size)
        rxLen += bytes.size

        while (rxLen >= EDGEZ_HEADER_LEN) {
            val magicOffset = findMagicOffset(rxBuffer, rxLen)
            if (magicOffset < 0) {
                rxLen = 0
                return
            }
            if (magicOffset > 0) {
                System.arraycopy(rxBuffer, magicOffset, rxBuffer, 0, rxLen - magicOffset)
                rxLen -= magicOffset
            }
            if (rxLen < EDGEZ_HEADER_LEN) return
            val payloadLen = (rxBuffer[2].toInt() and 0xff) or ((rxBuffer[3].toInt() and 0xff) shl 8)
            if (payloadLen <= 0 || payloadLen > EDGEZ_MAX_PAYLOAD) {
                rxLen = 0
                return
            }
            val frameLen = EDGEZ_HEADER_LEN + payloadLen
            if (rxLen < frameLen) return
            val payload = rxBuffer.copyOfRange(EDGEZ_HEADER_LEN, frameLen)
            if (isRealtimePayload(payload)) {
                handleVoiceBytes(payload)
            } else {
                logGpsPacket(payload, "ble")
                emit(
                    mapOf(
                        "type" to "packet",
                        "packet" to payload,
                        "receivedAtUs" to SystemClock.elapsedRealtimeNanos() / 1_000L,
                    ),
                )
            }
            val remaining = rxLen - frameLen
            if (remaining > 0) {
                System.arraycopy(rxBuffer, frameLen, rxBuffer, 0, remaining)
            }
            rxLen = remaining
        }
    }

    private fun handleUsbBytes(bytes: ByteArray) {
        var sourceOffset = 0
        while (sourceOffset < bytes.size) {
            if (usbRxLen == usbRxBuffer.size) usbRxLen = 0
            val count = minOf(bytes.size - sourceOffset, usbRxBuffer.size - usbRxLen)
            System.arraycopy(bytes, sourceOffset, usbRxBuffer, usbRxLen, count)
            usbRxLen += count
            sourceOffset += count
            parseUsbBytes()
        }
    }

    private fun parseUsbBytes() {
        while (usbRxLen >= 2) {
            if (usbRxBuffer[0] != SERIAL_STREAM_MAGIC_0 ||
                usbRxBuffer[1] != SERIAL_STREAM_MAGIC_1
            ) {
                appendUsbDebugByte(usbRxBuffer[0])
                consumeUsbBytes(1)
                continue
            }
            if (usbRxLen < SERIAL_STREAM_HEADER_LEN) return
            val payloadLen = ((usbRxBuffer[2].toInt() and 0xff) shl 8) or
                (usbRxBuffer[3].toInt() and 0xff)
            if (payloadLen <= 0 || payloadLen > EDGEZ_MAX_PAYLOAD) {
                consumeUsbBytes(1)
                continue
            }
            val frameLen = SERIAL_STREAM_HEADER_LEN + payloadLen
            if (usbRxLen < frameLen) return
            val payload = usbRxBuffer.copyOfRange(SERIAL_STREAM_HEADER_LEN, frameLen)
            if (payload.size >= LEGACY_USB_HEADER_LEN &&
                payload[0] == EDGEZ_MAGIC_0 && payload[1] == EDGEZ_MAGIC_1 &&
                payload[2] == LEGACY_USB_VERSION &&
                (payload[3] == LEGACY_USB_ECHO_REQUEST ||
                    payload[3] == LEGACY_USB_ECHO_RESPONSE ||
                    payload[3] == LEGACY_USB_TX_ACK ||
                    payload[3] == LEGACY_USB_FLOW_CONTROL)
            ) {
                val echoPayloadLen = (payload[6].toInt() and 0xff) or
                    ((payload[7].toInt() and 0xff) shl 8)
                if (echoPayloadLen <= LEGACY_USB_MAX_PAYLOAD &&
                    payload.size == LEGACY_USB_HEADER_LEN + echoPayloadLen
                ) {
                    val sequence = (payload[4].toInt() and 0xff) or
                        ((payload[5].toInt() and 0xff) shl 8)
                    handleLegacyUsbEcho(
                        payload[3],
                        sequence,
                        payload.copyOfRange(LEGACY_USB_HEADER_LEN, payload.size),
                    )
                }
            } else {
                dispatchUsbPayload(payload)
            }
            consumeUsbBytes(frameLen)
        }
    }

    private fun consumeUsbBytes(count: Int) {
        usbRxLen -= count
        if (usbRxLen > 0) {
            System.arraycopy(usbRxBuffer, count, usbRxBuffer, 0, usbRxLen)
        }
    }

    private fun dispatchUsbPayload(payload: ByteArray) {
        if (handleLogStreamFrame(payload)) return
        // A valid framed payload is also proof that the firmware UART parser is
        // running, even when heartbeat diagnostics are disabled in the future.
        markUsbProtocolReady()
        Log.i(LOG_TAG, "EdgeZ RX route=usb bytes=${payload.size}")
        if (isRealtimePayload(payload)) {
            handleVoiceBytes(payload)
            return
        }
        logGpsPacket(payload, "usb")
        emit(
            mapOf(
                "type" to "packet",
                "packet" to payload,
                "receivedAtUs" to SystemClock.elapsedRealtimeNanos() / 1_000L,
            ),
        )
    }

    private fun handleForwardBytes(bytes: ByteArray) {
        if (forwardRxLen + bytes.size > forwardRxBuffer.size) {
            forwardRxLen = 0
        }
        System.arraycopy(bytes, 0, forwardRxBuffer, forwardRxLen, bytes.size)
        forwardRxLen += bytes.size

        while (forwardRxLen >= EDGEZ_HEADER_LEN) {
            val magicOffset = findMagicOffset(forwardRxBuffer, forwardRxLen)
            if (magicOffset < 0) {
                forwardRxLen = 0
                return
            }
            if (magicOffset > 0) {
                System.arraycopy(forwardRxBuffer, magicOffset, forwardRxBuffer, 0, forwardRxLen - magicOffset)
                forwardRxLen -= magicOffset
            }
            if (forwardRxLen < EDGEZ_HEADER_LEN) return
            val payloadLen = (forwardRxBuffer[2].toInt() and 0xff) or
                ((forwardRxBuffer[3].toInt() and 0xff) shl 8)
            if (payloadLen <= 0 || payloadLen > EDGEZ_MAX_PAYLOAD) {
                forwardRxLen = 0
                return
            }
            val frameLen = EDGEZ_HEADER_LEN + payloadLen
            if (forwardRxLen < frameLen) return
            val payload = forwardRxBuffer.copyOfRange(EDGEZ_HEADER_LEN, frameLen)
            logGpsPacket(payload, "forward")
            emit(
                mapOf(
                    "type" to "packet",
                    "packet" to payload,
                    "route" to "ble_forward",
                    "receivedAtUs" to SystemClock.elapsedRealtimeNanos() / 1_000L,
                ),
            )
            val remaining = forwardRxLen - frameLen
            if (remaining > 0) {
                System.arraycopy(forwardRxBuffer, frameLen, forwardRxBuffer, 0, remaining)
            }
            forwardRxLen = remaining
        }
    }

    private fun logGpsPacket(payload: ByteArray, route: String) {
        runCatching {
            var fromNode = 0L
            var beaconBytes: ByteArray? = null
            var reportBytes: ByteArray? = null
            var locationUpdateBytes: ByteArray? = null
            ProtoReader(payload).forEachField { field ->
                when (field.number) {
                    1 -> field.varint?.let { fromNode = it }
                    106 -> beaconBytes = field.bytes
                    107 -> reportBytes = field.bytes
                    108 -> locationUpdateBytes = field.bytes
                }
            }

            locationUpdateBytes?.let { update ->
                var latitude: Float? = null
                var longitude: Float? = null
                var timestampMs = 0L
                ProtoReader(update).forEachField { field ->
                    when (field.number) {
                        1 -> latitude = field.float
                        2 -> longitude = field.float
                        3 -> field.varint?.let { timestampMs = it }
                    }
                }
                Log.i(
                    LOG_TAG,
                    "GPS ${if (route == "tx") "TX" else "RX"} route=$route " +
                        "body=location_update location=${formatLocation(latitude, longitude)} " +
                        "timestamp=$timestampMs zero=${isZeroLocation(latitude, longitude)}",
                )
            }

            beaconBytes?.let { beacon ->
                var topLatitude: Float? = null
                var topLongitude: Float? = null
                var sensorLatitude: Float? = null
                var sensorLongitude: Float? = null
                ProtoReader(beacon).forEachField { field ->
                    when (field.number) {
                        5 -> topLatitude = field.float
                        6 -> topLongitude = field.float
                        101 -> field.bytes?.let { sensor ->
                            val reading = decodeGpsSensor(sensor)
                            when (reading?.first) {
                                3 -> sensorLatitude = reading.second
                                4 -> sensorLongitude = reading.second
                            }
                        }
                    }
                }
                Log.i(
                    LOG_TAG,
                    "GPS RX route=$route body=beacon from=${formatNode(fromNode)} " +
                        "top=${formatLocation(topLatitude, topLongitude)} " +
                        "sensor=${formatLocation(sensorLatitude, sensorLongitude)} " +
                        "zero=${isZeroLocation(sensorLatitude, sensorLongitude)}",
                )
            }

            reportBytes?.let { report ->
                var peerCount = 0
                var gpsPeerCount = 0
                val gpsDetails = mutableListOf<String>()
                ProtoReader(report).forEachField { field ->
                    if (field.number != 1 || field.bytes == null) return@forEachField
                    peerCount++
                    var peerNode = 0L
                    var latitude: Float? = null
                    var longitude: Float? = null
                    ProtoReader(field.bytes).forEachField { peerField ->
                        when (peerField.number) {
                            1 -> peerField.varint?.let { peerNode = it }
                            3 -> peerField.bytes?.let { sensor ->
                                val reading = decodeGpsSensor(sensor)
                                when (reading?.first) {
                                    3 -> latitude = reading.second
                                    4 -> longitude = reading.second
                                }
                            }
                        }
                    }
                    if (latitude != null || longitude != null) {
                        gpsPeerCount++
                        gpsDetails += "${formatNode(peerNode)}=${formatLocation(latitude, longitude)}" +
                            " zero=${isZeroLocation(latitude, longitude)}"
                    }
                }
                Log.i(
                    LOG_TAG,
                    "GPS RX route=$route body=report from=${formatNode(fromNode)} " +
                        "peers=$peerCount gpsPeers=$gpsPeerCount" +
                        if (gpsDetails.isEmpty()) "" else " gps=${gpsDetails.joinToString()}",
                )
            }
        }.onFailure { error ->
            Log.w(LOG_TAG, "GPS packet inspection failed route=$route len=${payload.size}", error)
        }
    }

    private fun decodeGpsSensor(sensor: ByteArray): Pair<Int, Float>? {
        var type: Int? = null
        var value: Float? = null
        ProtoReader(sensor).forEachField { field ->
            when (field.number) {
                1 -> type = field.varint?.toInt()
                4 -> value = field.float
            }
        }
        val resolvedType = type
        val resolvedValue = value
        return if ((resolvedType == 3 || resolvedType == 4) && resolvedValue != null) {
            resolvedType to resolvedValue
        } else {
            null
        }
    }

    private fun formatNode(node: Long): String =
        "0x${java.lang.Long.toHexString(node and 0xffffffffffffL).padStart(12, '0')}"

    private fun formatLocation(latitude: Float?, longitude: Float?): String =
        "(${latitude?.toString() ?: "missing"},${longitude?.toString() ?: "missing"})"

    private fun isZeroLocation(latitude: Float?, longitude: Float?): Boolean =
        latitude == 0.0f && longitude == 0.0f

    private fun isRealtimePayload(bytes: ByteArray): Boolean {
        if (bytes.size > EDGEZ_VOICE_PROTOCOL_MAGIC.size &&
            (bytes.copyOfRange(0, EDGEZ_VOICE_PROTOCOL_MAGIC.size)
                .contentEquals(EDGEZ_VOICE_PROTOCOL_MAGIC) ||
                bytes.copyOfRange(0, EDGEZ_SPEED_PROTOCOL_MAGIC.size)
                    .contentEquals(EDGEZ_SPEED_PROTOCOL_MAGIC))
        ) {
            return true
        }
        // Accept the raw routed speed frame too. This keeps USB compatible
        // with firmware builds that omit the three-byte realtime envelope.
        return bytes.size > 9 &&
            bytes[6] == 'E'.code.toByte() &&
            bytes[7] == 'Z'.code.toByte() &&
            bytes[8] == 'S'.code.toByte() &&
            bytes[9] == 'T'.code.toByte()
    }

    private fun handleVoiceBytes(
        bytes: ByteArray,
        receivedAtUs: Long = SystemClock.elapsedRealtimeNanos() / 1_000L,
    ) {
        if (handleLogStreamFrame(bytes)) return
        val hasVoiceEnvelope = bytes.size > EDGEZ_VOICE_PROTOCOL_MAGIC.size &&
            bytes.copyOfRange(0, EDGEZ_VOICE_PROTOCOL_MAGIC.size)
                .contentEquals(EDGEZ_VOICE_PROTOCOL_MAGIC)
        val hasSpeedEnvelope = bytes.size > EDGEZ_SPEED_PROTOCOL_MAGIC.size &&
            bytes.copyOfRange(0, EDGEZ_SPEED_PROTOCOL_MAGIC.size)
                .contentEquals(EDGEZ_SPEED_PROTOCOL_MAGIC)
        val payload = when {
            hasVoiceEnvelope -> bytes.copyOfRange(EDGEZ_VOICE_PROTOCOL_MAGIC.size, bytes.size)
            hasSpeedEnvelope -> bytes.copyOfRange(EDGEZ_SPEED_PROTOCOL_MAGIC.size, bytes.size)
            else -> bytes
        }
        if (payload.size > 9 &&
            payload[6] == 'E'.code.toByte() &&
            payload[7] == 'Z'.code.toByte() &&
            payload[8] == 'S'.code.toByte() &&
            payload[9] == 'T'.code.toByte()
        ) {
            emit(
                mapOf(
                    "type" to "speedTestFrame",
                    "packet" to payload,
                    // Capture this before posting to Flutter's main thread.
                    // Large USB reads can otherwise batch many callbacks and
                    // make Dart processing time look like link throughput.
                    "receivedAtUs" to receivedAtUs,
                ),
            )
            return
        }
        if (!hasVoiceEnvelope) {
            emit(mapOf("type" to "log", "log" to "Realtime frame invalid len=${bytes.size}"))
            return
        }
        if (payload.size < 6 + 4 + EDGEZ_VOICE_NONCE_SIZE + 1 ||
            payload.size > EDGEZ_MAX_PAYLOAD
        ) {
            emit(mapOf("type" to "log", "log" to "BLE voice payload invalid len=${payload.size}"))
            return
        }
        emit(mapOf("type" to "voiceFrame", "packet" to payload))
        receivedVoiceFrames++
        if (receivedVoiceFrames == 1 || receivedVoiceFrames % 25 == 0) {
            emit(
                mapOf(
                    "type" to "log",
                    "log" to "Live voice received frames=$receivedVoiceFrames bytes=${payload.size}",
                ),
            )
        }
    }

    private fun handleLogStreamFrame(bytes: ByteArray): Boolean {
        if (bytes.size < LOG_STREAM_HEADER_LEN ||
            bytes[0] != 'L'.code.toByte() ||
            bytes[1] != 'G'.code.toByte() ||
            bytes[2] != LOG_STREAM_VERSION
        ) return false

        val payload = bytes.copyOfRange(LOG_STREAM_HEADER_LEN, bytes.size)
        when (bytes[3]) {
            LOG_STREAM_RECORD -> {
                val text = payload.toString(Charsets.UTF_8).trimEnd('\r', '\n')
                if (text.isNotBlank()) emit(mapOf("type" to "log", "log" to "FW: $text"))
            }
            LOG_STREAM_LEVEL_RESPONSE -> {
                val tag = payload.toString(Charsets.UTF_8).ifBlank { "*" }
                val level = bytes[4].toInt() and 0xff
                emit(
                    mapOf(
                        "type" to "log",
                        "log" to "Device log level=${if (level == LOG_STREAM_LEVEL_ERROR) "error" else level} tag=$tag",
                    ),
                )
            }
        }
        return true
    }

    private fun findMagicOffset(buffer: ByteArray, length: Int): Int {
        for (index in 0 until length - 1) {
            if (buffer[index] == EDGEZ_MAGIC_0 && buffer[index + 1] == EDGEZ_MAGIC_1) {
                return index
            }
        }
        return -1
    }

    private fun ByteArray.toHexString(): String = joinToString("") { "%02x".format(it) }

    private fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }
}

private data class ProtoField(
    val number: Int,
    val varint: Long? = null,
    val fixed32: Int? = null,
    val bytes: ByteArray? = null,
) {
    val float: Float?
        get() = fixed32?.let(Float::fromBits)
}

private class ProtoReader(private val data: ByteArray) {
    private var offset = 0

    fun forEachField(block: (ProtoField) -> Unit) {
        while (offset < data.size) {
            val key = readVarint()
            val number = (key ushr 3).toInt()
            require(number > 0) { "Invalid protobuf field number" }
            when ((key and 0x07).toInt()) {
                0 -> block(ProtoField(number = number, varint = readVarint()))
                1 -> skip(8)
                2 -> {
                    val length = readVarint().toInt()
                    require(length >= 0 && offset + length <= data.size) {
                        "Invalid protobuf field length"
                    }
                    block(
                        ProtoField(
                            number = number,
                            bytes = data.copyOfRange(offset, offset + length),
                        ),
                    )
                    offset += length
                }
                5 -> block(ProtoField(number = number, fixed32 = readFixed32()))
                else -> throw IllegalArgumentException("Unsupported protobuf wire type")
            }
        }
    }

    private fun readVarint(): Long {
        var result = 0L
        var shift = 0
        while (offset < data.size && shift < 64) {
            val byte = data[offset++].toInt() and 0xff
            result = result or ((byte and 0x7f).toLong() shl shift)
            if ((byte and 0x80) == 0) return result
            shift += 7
        }
        throw IllegalArgumentException("Invalid protobuf varint")
    }

    private fun readFixed32(): Int {
        require(offset + 4 <= data.size) { "Invalid protobuf fixed32" }
        val value = (data[offset].toInt() and 0xff) or
            ((data[offset + 1].toInt() and 0xff) shl 8) or
            ((data[offset + 2].toInt() and 0xff) shl 16) or
            ((data[offset + 3].toInt() and 0xff) shl 24)
        offset += 4
        return value
    }

    private fun skip(length: Int) {
        require(offset + length <= data.size) { "Invalid protobuf field" }
        offset += length
    }
}
