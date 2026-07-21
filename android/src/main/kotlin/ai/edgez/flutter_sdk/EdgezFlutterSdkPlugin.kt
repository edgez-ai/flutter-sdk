package ai.edgez.flutter_sdk

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
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
import android.location.LocationManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
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
import java.util.ArrayDeque
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

private const val BLE_PERMISSION_REQUEST = 9007
private const val MICROPHONE_PERMISSION_REQUEST = 9008
private const val VOICE_CODEC_AMR_NB = 1
private const val VOICE_CODEC_OPUS = 2
private const val EDGEZ_HEADER_LEN = 4
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
private val EDGEZ_VOICE_PROTOCOL_MAGIC = byteArrayOf('V'.code.toByte(), 'C'.code.toByte(), 2)
private const val EDGEZ_VOICE_NONCE_SIZE = 12
private const val EDGEZ_VOICE_ROUTE_SIZE = 6 + 1 + 4
private const val EDGEZ_VOICE_TX_QUEUE_DEPTH = 2
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
    private var negotiatedMtu = 23
    private val otaWriteLock = Object()
    private var otaWriteStatus: Int? = null
    private val otaAbortRequested = AtomicBoolean(false)
    private val otaInProgress = AtomicBoolean(false)
    private var pendingScanResult: MethodChannel.Result? = null
    private var pendingMicrophoneResult: MethodChannel.Result? = null
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
    private val txQueue = ArrayDeque<ByteArray>()
    private val voiceTxQueue = ArrayDeque<ByteArray>()
    private var txWriteInFlight = false
    private var voiceTxWriteInFlight = false
    private var dataWriteInFlight = false
    private var scanGeneration = 0

    private val bluetoothAdapter: BluetoothAdapter?
        get() = context.getSystemService(BluetoothManager::class.java)?.adapter

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
        liveVoiceAudio = EdgezLiveVoiceAudio(context) { audio ->
            emit(mapOf("type" to "voiceAudio", "packet" to audio))
        }
        val bondFilter = IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(bondStateReceiver, bondFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(bondStateReceiver, bondFilter)
        }
        bondReceiverRegistered = true
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopBleScan()
        closeGatt()
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
            "requestMicrophonePermission" -> requestMicrophonePermission(result)
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
                sendVoiceCallFrame(
                    to = call.argument<Long>("to") ?: 0L,
                    maxHop = call.argument<Int>("maxHop") ?: 0,
                    sequence = call.argument<Int>("sequence") ?: 1,
                    nonce = nonce,
                    ciphertext = ciphertext,
                ).fold(
                    onSuccess = { result.success(it) },
                    onFailure = {
                        result.error("voice_write_failed", it.message ?: "Voice write failed", null)
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
                closeGatt()
                emit(mapOf("type" to "connection", "connection" to "none"))
                result.success(null)
            }
            "initializeMesh" -> {
                val packet = call.argument<ByteArray>("packet")
                if (packet == null) {
                    result.error("missing_packet", "Missing HaLow init packet", null)
                    return
                }
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
                if (packet == null) {
                    result.error("missing_packet", "Missing packet", null)
                    return
                }
                sendFrame(packet).fold(
                    onSuccess = {
                        emit(mapOf("type" to "log", "log" to "$label queued"))
                        result.success(null)
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
            else -> return false
        }
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

    @SuppressLint("MissingPermission")
    private fun sendVoicePacket(packet: ByteArray): Result<String> {
        val activeGatt = gatt
            ?: return Result.failure(IllegalStateException("BLE is not connected"))
        val voice = voiceRxCharacteristic ?: return Result.failure(
            IllegalStateException("BLE voice characteristics FFF7/FFF8 are unavailable"),
        )
        val frame = EDGEZ_VOICE_PROTOCOL_MAGIC + packet
        val maxVoiceFrame = minOf(negotiatedMtu - 3, EDGEZ_MAX_PAYLOAD)
        if (frame.size > maxVoiceFrame) {
            return Result.failure(
                IllegalArgumentException("Voice packet too large: ${frame.size}/$maxVoiceFrame"),
            )
        }
        synchronized(this) {
            if (voiceTxQueue.size >= EDGEZ_VOICE_TX_QUEUE_DEPTH) {
                if (voiceTxWriteInFlight) voiceTxQueue.pollLast() else voiceTxQueue.pollFirst()
            }
            voiceTxQueue.addLast(frame)
        }
        return if (writeNextVoiceFrame(activeGatt, voice)) {
            Result.success("BLE voice queued")
        } else {
            synchronized(this) { voiceTxQueue.remove(frame) }
            Result.failure(IllegalStateException("BLE voice write failed"))
        }
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
        stopBleScan()
        closeGatt()
        if (device.bondState != BluetoothDevice.BOND_BONDED) {
            pendingBondDevice = device
            emit(mapOf("type" to "log", "log" to "Starting BLE pairing ${device.address}"))
            if (!device.createBond()) {
                pendingBondDevice = null
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
    private fun closeGatt() {
        otaAbortRequested.set(true)
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
        negotiatedMtu = 23
        rxLen = 0
        forwardRxLen = 0
        clearTxQueue()
        gatt?.close()
        gatt = null
    }

    private fun sendFrame(payload: ByteArray): Result<String> {
        val activeGatt = gatt ?: return Result.failure(IllegalStateException("BLE is not connected"))
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
        synchronized(this) {
            txQueue.add(frame)
        }
        return if (writeNextFrame(activeGatt, rx)) {
            Result.success("BLE queued protobuf")
        } else {
            synchronized(this) {
                txQueue.remove(frame)
            }
            Result.failure(IllegalStateException("BLE write failed"))
        }
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
            currentGatt.writeCharacteristic(rx, frame, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) == BluetoothGatt.GATT_SUCCESS
        } else {
            rx.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            rx.value = frame
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
                frame,
                BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT,
            ) == BluetoothGatt.GATT_SUCCESS
        } else {
            voice.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            voice.value = frame
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
                val highPriorityRequested = gatt.requestConnectionPriority(
                    BluetoothGatt.CONNECTION_PRIORITY_HIGH,
                )
                emit(mapOf("type" to "log", "log" to "BLE high priority requested=$highPriorityRequested"))
                emit(mapOf("type" to "connection", "connection" to "ble"))
                gatt.requestMtu(EDGEZ_BLE_REQUESTED_MTU)
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                otaAbortRequested.set(true)
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
            gatt.discoverServices()
        }

        @SuppressLint("MissingPermission")
        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            emit(mapOf("type" to "log", "log" to "BLE services status=$status"))
            val service: BluetoothGattService? = gatt.getService(EDGEZ_SERVICE_UUID)
            val rx = service?.getCharacteristic(EDGEZ_RX_UUID)
            val tx = service?.getCharacteristic(EDGEZ_TX_UUID)
            if (rx == null || tx == null) {
                emit(mapOf("type" to "log", "log" to "BLE service missing rx=${rx != null} tx=${tx != null}"))
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
                        "forwardRx=${forwardRxCharacteristic != null} forwardTx=${forwardTxCharacteristic != null} " +
                        "ota=${otaCharacteristic != null} otaStatus=${otaStatusCharacteristic != null} " +
                        "voiceRx=${voiceRxCharacteristic != null} voiceTx=${voiceTxCharacteristic != null}",
                ),
            )
            notificationDescriptors.clear()
            notificationDescriptorWriteInFlight = false
            queueNotification(gatt, tx)
            forwardTxCharacteristic?.let {
                queueNotification(gatt, it)
                emit(mapOf("type" to "log", "log" to "BLE forwarded-mesh channel available"))
            }
            otaStatusCharacteristic?.let { queueNotification(gatt, it) }
            voiceTxCharacteristic?.let { queueNotification(gatt, it) }
            serviceReadyPending = true
            writeNextNotificationDescriptor(gatt)
            maybeMarkControlServiceReady(gatt)
        }

        override fun onDescriptorWrite(
            gatt: BluetoothGatt,
            descriptor: BluetoothGattDescriptor,
            status: Int,
        ) {
            if (descriptor.uuid != CCCD_UUID) return
            notificationDescriptorWriteInFlight = false
            if (status != BluetoothGatt.GATT_SUCCESS) {
                emit(mapOf("type" to "log", "log" to "BLE notification subscription failed status=$status uuid=${descriptor.characteristic.uuid}"))
            }
            writeNextNotificationDescriptor(gatt)
            maybeMarkControlServiceReady(gatt)
        }

        @SuppressLint("MissingPermission")
        private fun queueNotification(gatt: BluetoothGatt, characteristic: BluetoothGattCharacteristic) {
            gatt.setCharacteristicNotification(characteristic, true)
            characteristic.getDescriptor(CCCD_UUID)?.let { notificationDescriptors.addLast(it) }
        }

        @SuppressLint("MissingPermission")
        private fun writeNextNotificationDescriptor(gatt: BluetoothGatt) {
            if (notificationDescriptorWriteInFlight || notificationDescriptors.isEmpty()) return
            val descriptor = notificationDescriptors.removeFirst()
            notificationDescriptorWriteInFlight = true
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
                writeNextNotificationDescriptor(gatt)
            }
        }

        private fun maybeMarkControlServiceReady(gatt: BluetoothGatt) {
            if (!serviceReadyPending || notificationDescriptorWriteInFlight || notificationDescriptors.isNotEmpty()) return
            serviceReadyPending = false
            emit(mapOf("type" to "log", "log" to "BLE control service ready"))
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
            emit(mapOf("type" to "packet", "packet" to payload))
            val remaining = rxLen - frameLen
            if (remaining > 0) {
                System.arraycopy(rxBuffer, frameLen, rxBuffer, 0, remaining)
            }
            rxLen = remaining
        }
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
            emit(mapOf("type" to "packet", "packet" to payload, "route" to "ble_forward"))
            val remaining = forwardRxLen - frameLen
            if (remaining > 0) {
                System.arraycopy(forwardRxBuffer, frameLen, forwardRxBuffer, 0, remaining)
            }
            forwardRxLen = remaining
        }
    }

    private fun handleVoiceBytes(bytes: ByteArray) {
        if (bytes.size <= EDGEZ_VOICE_PROTOCOL_MAGIC.size ||
            !bytes.copyOfRange(0, EDGEZ_VOICE_PROTOCOL_MAGIC.size)
                .contentEquals(EDGEZ_VOICE_PROTOCOL_MAGIC)
        ) {
            emit(mapOf("type" to "log", "log" to "BLE voice frame invalid len=${bytes.size}"))
            return
        }
        val payload = bytes.copyOfRange(EDGEZ_VOICE_PROTOCOL_MAGIC.size, bytes.size)
        if (payload.size < 6 + 4 + EDGEZ_VOICE_NONCE_SIZE + 1 ||
            payload.size > EDGEZ_MAX_PAYLOAD
        ) {
            emit(mapOf("type" to "log", "log" to "BLE voice payload invalid len=${payload.size}"))
            return
        }
        emit(mapOf("type" to "voiceFrame", "packet" to payload))
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
