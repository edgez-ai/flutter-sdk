package ai.edgez.flutter_sdk

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.SystemClock
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.sqrt

private const val CALL_SAMPLE_RATE = 8_000
private const val CALL_FRAME_MS = 40
private const val CALL_SAMPLES_PER_FRAME = CALL_SAMPLE_RATE * CALL_FRAME_MS / 1_000
private const val PLAYBACK_PREFILL_FRAMES = 2
private const val PLAYBACK_REPRIME_GAP_MS = CALL_FRAME_MS * 4L

internal class EdgezLiveVoiceAudio(
    context: Context,
    private val onEncodedFrame: (ByteArray) -> Unit,
    private val onError: (Throwable) -> Unit,
) {
    private val audioManager = context.getSystemService(AudioManager::class.java)
    private val executor = Executors.newSingleThreadExecutor()
    private val capturing = AtomicBoolean(false)
    private var player: AudioTrack? = null
    private var playbackFramesBuffered = 0
    private var lastPlaybackFrameAtMs = 0L
    private var callAudioConfigured = false
    private var previousAudioMode = AudioManager.MODE_NORMAL
    private var previousSpeakerphoneOn = false
    private var previousCommunicationDevice: AudioDeviceInfo? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    @SuppressLint("MissingPermission")
    fun start() {
        configureCallAudio()
        if (!capturing.compareAndSet(false, true)) return
        executor.execute {
            val minimum = AudioRecord.getMinBufferSize(
                CALL_SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
            val recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                CALL_SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minimum, CALL_SAMPLES_PER_FRAME * 4),
            )
            val echo = if (AcousticEchoCanceler.isAvailable()) {
                AcousticEchoCanceler.create(recorder.audioSessionId)?.also { it.enabled = true }
            } else null
            val gain = if (AutomaticGainControl.isAvailable()) {
                AutomaticGainControl.create(recorder.audioSessionId)?.also { it.enabled = true }
            } else null
            val noise = if (NoiseSuppressor.isAvailable()) {
                NoiseSuppressor.create(recorder.audioSessionId)?.also { it.enabled = true }
            } else null
            val pcm = ShortArray(CALL_SAMPLES_PER_FRAME)
            val voiceDetector = VoiceActivityDetector()
            var preRollFrame: ShortArray? = null
            try {
                check(recorder.state == AudioRecord.STATE_INITIALIZED) {
                    "Live voice AudioRecord initialization failed"
                }
                recorder.startRecording()
                while (capturing.get()) {
                    var offset = 0
                    while (offset < pcm.size && capturing.get()) {
                        val read = recorder.read(
                            pcm,
                            offset,
                            pcm.size - offset,
                            AudioRecord.READ_BLOCKING,
                        )
                        if (read <= 0) break
                        offset += read
                    }
                    if (offset == pcm.size && capturing.get()) {
                        val decision = voiceDetector.analyze(pcm)
                        if (decision.speechStarted) {
                            preRollFrame?.let { frame -> onEncodedFrame(encodeImaAdpcm(frame)) }
                            preRollFrame = null
                        }
                        if (decision.shouldSend) {
                            onEncodedFrame(encodeImaAdpcm(pcm))
                        } else {
                            preRollFrame = pcm.copyOf()
                        }
                    }
                }
            } catch (error: Throwable) {
                capturing.set(false)
                onError(error)
            } finally {
                if (recorder.recordingState == AudioRecord.RECORDSTATE_RECORDING) recorder.stop()
                echo?.release()
                gain?.release()
                noise?.release()
                recorder.release()
            }
        }
    }

    fun stop() {
        capturing.set(false)
        releasePlayback()
        restoreCallAudio()
    }

    @Synchronized
    fun play(encoded: ByteArray) {
        val pcm = decodeImaAdpcm(encoded, CALL_SAMPLES_PER_FRAME) ?: return
        configureCallAudio()
        val track = player ?: buildPlaybackTrack().also { player = it }
        val now = SystemClock.elapsedRealtime()
        if (lastPlaybackFrameAtMs > 0L && now - lastPlaybackFrameAtMs > PLAYBACK_REPRIME_GAP_MS) {
            if (track.playState == AudioTrack.PLAYSTATE_PLAYING) track.pause()
            track.flush()
            playbackFramesBuffered = 0
        }
        lastPlaybackFrameAtMs = now
        var offset = 0
        while (offset < pcm.size) {
            val written = track.write(pcm, offset, pcm.size - offset, AudioTrack.WRITE_BLOCKING)
            if (written <= 0) return
            offset += written
        }
        if (track.playState != AudioTrack.PLAYSTATE_PLAYING) {
            playbackFramesBuffered++
            if (playbackFramesBuffered >= PLAYBACK_PREFILL_FRAMES) track.play()
        }
    }

    @Suppress("DEPRECATION")
    private fun buildPlaybackTrack(): AudioTrack {
        val legacy = Build.VERSION.SDK_INT < Build.VERSION_CODES.S
        val attributes = AudioAttributes.Builder()
            .setUsage(if (legacy) AudioAttributes.USAGE_MEDIA else AudioAttributes.USAGE_VOICE_COMMUNICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .apply { if (legacy) setLegacyStreamType(AudioManager.STREAM_MUSIC) }
            .build()
        val format = AudioFormat.Builder()
            .setSampleRate(CALL_SAMPLE_RATE)
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
        val minimum = AudioTrack.getMinBufferSize(
            CALL_SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        return AudioTrack.Builder()
            .setAudioAttributes(attributes)
            .setAudioFormat(format)
            .setBufferSizeInBytes(maxOf(minimum, CALL_SAMPLES_PER_FRAME * 8))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
            .also { track ->
                audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                    .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                    ?.let(track::setPreferredDevice)
                track.setVolume(AudioTrack.getMaxVolume())
            }
    }

    @Suppress("DEPRECATION")
    private fun configureCallAudio() {
        if (callAudioConfigured) return
        previousAudioMode = audioManager.mode
        previousSpeakerphoneOn = audioManager.isSpeakerphoneOn
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            previousCommunicationDevice = audioManager.communicationDevice
        }
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        val attributes = AudioAttributes.Builder()
            .setUsage(
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                    AudioAttributes.USAGE_MEDIA
                } else {
                    AudioAttributes.USAGE_VOICE_COMMUNICATION
                },
            )
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
            .build()
        audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
            .setAudioAttributes(attributes)
            .setOnAudioFocusChangeListener { }
            .build()
            .also(audioManager::requestAudioFocus)
        val routed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.availableCommunicationDevices
                .firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                ?.let(audioManager::setCommunicationDevice) == true
        } else false
        if (!routed) audioManager.isSpeakerphoneOn = true
        callAudioConfigured = true
    }

    @Suppress("DEPRECATION")
    private fun restoreCallAudio() {
        if (!callAudioConfigured) return
        audioFocusRequest?.let(audioManager::abandonAudioFocusRequest)
        audioFocusRequest = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val previous = previousCommunicationDevice
            if (previous != null && audioManager.availableCommunicationDevices.any { it.id == previous.id }) {
                audioManager.setCommunicationDevice(previous)
            } else {
                audioManager.clearCommunicationDevice()
            }
            previousCommunicationDevice = null
        } else {
            audioManager.isSpeakerphoneOn = previousSpeakerphoneOn
        }
        audioManager.mode = previousAudioMode
        callAudioConfigured = false
    }

    @Synchronized
    private fun releasePlayback() {
        player?.run {
            if (playState == AudioTrack.PLAYSTATE_PLAYING) pause()
            flush()
            release()
        }
        player = null
        playbackFramesBuffered = 0
        lastPlaybackFrameAtMs = 0L
    }
}

private data class VoiceActivityDecision(
    val shouldSend: Boolean,
    val speechStarted: Boolean,
)

private class VoiceActivityDetector(
    private val minimumSpeechRms: Double = 40.0,
    private val noiseMultiplier: Double = 1.6,
    private val hangoverFrames: Int = 8,
    private val calibrationFrames: Int = 10,
) {
    private var noiseRms = minimumSpeechRms / noiseMultiplier
    private var remainingHangoverFrames = 0
    private var framesObserved = 0
    private val calibrationRms = DoubleArray(calibrationFrames.coerceAtLeast(0))
    private val calibrationSeedFrames = minOf(3, calibrationFrames)

    fun analyze(samples: ShortArray): VoiceActivityDecision {
        if (samples.isEmpty()) return VoiceActivityDecision(false, false)
        val rms = calculateRms(samples)
        if (framesObserved < calibrationFrames) {
            if (framesObserved >= calibrationSeedFrames) {
                val threshold = max(minimumSpeechRms, noiseRms * noiseMultiplier)
                if (rms >= threshold) {
                    val started = remainingHangoverFrames == 0
                    remainingHangoverFrames = hangoverFrames
                    return VoiceActivityDecision(true, started)
                }
                if (remainingHangoverFrames > 0) {
                    remainingHangoverFrames--
                    return VoiceActivityDecision(true, false)
                }
            }
            calibrationRms[framesObserved++] = rms
            val observed = calibrationRms.copyOf(framesObserved).sortedArray()
            noiseRms = observed[framesObserved / 2].coerceAtLeast(1.0)
            return VoiceActivityDecision(false, false)
        }
        val threshold = max(minimumSpeechRms, noiseRms * noiseMultiplier)
        if (rms >= threshold) {
            val started = remainingHangoverFrames == 0
            remainingHangoverFrames = hangoverFrames
            return VoiceActivityDecision(true, started)
        }
        if (remainingHangoverFrames > 0) {
            remainingHangoverFrames--
            return VoiceActivityDecision(true, false)
        }
        noiseRms = noiseRms * 0.95 + rms * 0.05
        return VoiceActivityDecision(false, false)
    }

    private fun calculateRms(samples: ShortArray): Double {
        var sum = 0.0
        for (sample in samples) sum += sample
        val mean = sum / samples.size
        var sumSquares = 0.0
        for (sample in samples) {
            val value = sample - mean
            sumSquares += value * value
        }
        return sqrt(sumSquares / samples.size)
    }
}

private val IMA_INDEX_TABLE = intArrayOf(
    -1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8,
)
private val IMA_STEP_TABLE = intArrayOf(
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
    157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
    724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499,
    2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630,
    9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623,
    27086, 29794, 32767,
)

private fun encodeImaAdpcm(samples: ShortArray): ByteArray {
    if (samples.isEmpty()) return ByteArray(0)
    var predictor = samples[0].toInt()
    val probes = minOf(samples.size - 1, 16)
    val averageDelta = if (probes > 0) {
        (1..probes).sumOf { kotlin.math.abs(samples[it].toInt() - samples[it - 1].toInt()) } / probes
    } else 0
    var stepIndex = IMA_STEP_TABLE.indexOfFirst { it >= averageDelta }
        .let { if (it < 0) IMA_STEP_TABLE.lastIndex else it }
    val output = ByteArray(4 + samples.size / 2)
    output[0] = predictor.toByte()
    output[1] = (predictor shr 8).toByte()
    output[2] = stepIndex.toByte()
    for (sampleIndex in 1 until samples.size) {
        val step = IMA_STEP_TABLE[stepIndex]
        var difference = samples[sampleIndex].toInt() - predictor
        var code = 0
        if (difference < 0) { code = 8; difference = -difference }
        var delta = step shr 3
        if (difference >= step) { code = code or 4; difference -= step; delta += step }
        if (difference >= step shr 1) { code = code or 2; difference -= step shr 1; delta += step shr 1 }
        if (difference >= step shr 2) { code = code or 1; delta += step shr 2 }
        predictor = (predictor + if (code and 8 != 0) -delta else delta)
            .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
        stepIndex = (stepIndex + IMA_INDEX_TABLE[code]).coerceIn(0, IMA_STEP_TABLE.lastIndex)
        val nibble = sampleIndex - 1
        val index = 4 + nibble / 2
        output[index] = if (nibble and 1 == 0) code.toByte()
        else (output[index].toInt() or (code shl 4)).toByte()
    }
    return output
}

private fun decodeImaAdpcm(bytes: ByteArray, sampleCount: Int): ShortArray? {
    if (sampleCount <= 0 || bytes.size < 4 + sampleCount / 2) return null
    var predictor = ((bytes[0].toInt() and 0xff) or (bytes[1].toInt() shl 8)).toShort().toInt()
    var stepIndex = bytes[2].toInt() and 0xff
    if (stepIndex > IMA_STEP_TABLE.lastIndex) return null
    val output = ShortArray(sampleCount)
    output[0] = predictor.toShort()
    for (sampleIndex in 1 until sampleCount) {
        val nibble = sampleIndex - 1
        val packed = bytes[4 + nibble / 2].toInt() and 0xff
        val code = if (nibble and 1 == 0) packed and 0x0f else packed shr 4
        val step = IMA_STEP_TABLE[stepIndex]
        var delta = step shr 3
        if (code and 4 != 0) delta += step
        if (code and 2 != 0) delta += step shr 1
        if (code and 1 != 0) delta += step shr 2
        predictor = (predictor + if (code and 8 != 0) -delta else delta)
            .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
        stepIndex = (stepIndex + IMA_INDEX_TABLE[code]).coerceIn(0, IMA_STEP_TABLE.lastIndex)
        output[sampleIndex] = predictor.toShort()
    }
    return output
}
