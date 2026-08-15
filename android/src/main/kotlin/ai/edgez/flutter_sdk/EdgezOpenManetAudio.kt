package ai.edgez.flutter_sdk

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaRecorder
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

private const val OMC_SAMPLE_RATE = 48_000
private const val OMC_FRAME_SAMPLES = 960
private const val OMC_FRAME_BYTES = OMC_FRAME_SAMPLES * 2
private const val OMC_BIT_RATE = 24_000
private const val OMC_FRAME_US = 20_000L

/** Raw Opus capture/playback matching OpenMANET Comms RTP (PT 111, 48 kHz,
 * mono, one 20 ms frame per packet). */
internal class EdgezOpenManetAudio(
    private val context: Context,
    private val onOpusFrame: (ByteArray) -> Unit,
    private val onError: (Throwable) -> Unit,
) {
    private val captureExecutor = Executors.newSingleThreadExecutor()
    private val playbackExecutor = Executors.newSingleThreadExecutor()
    private val capturing = AtomicBoolean(false)
    @Volatile private var captureGeneration = 0
    private var decoder: MediaCodec? = null
    private var track: AudioTrack? = null
    private var decoderTimestampUs = 0L

    @SuppressLint("MissingPermission")
    fun start() {
        if (!capturing.compareAndSet(false, true)) return
        val generation = ++captureGeneration
        captureExecutor.execute {
            var recorder: AudioRecord? = null
            var encoder: MediaCodec? = null
            try {
                val minimum = AudioRecord.getMinBufferSize(
                    OMC_SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                )
                recorder = AudioRecord(
                    MediaRecorder.AudioSource.VOICE_COMMUNICATION,
                    OMC_SAMPLE_RATE,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    maxOf(minimum, OMC_FRAME_BYTES * 4),
                )
                check(recorder.state == AudioRecord.STATE_INITIALIZED) {
                    "OpenMANET AudioRecord initialization failed"
                }
                val format = MediaFormat.createAudioFormat(
                    MediaFormat.MIMETYPE_AUDIO_OPUS,
                    OMC_SAMPLE_RATE,
                    1,
                ).apply {
                    setInteger(MediaFormat.KEY_BIT_RATE, OMC_BIT_RATE)
                    setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, OMC_FRAME_BYTES)
                }
                encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS)
                encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                encoder.start()
                recorder.startRecording()
                val pcm = ByteArray(OMC_FRAME_BYTES)
                val info = MediaCodec.BufferInfo()
                var timestampUs = 0L
                while (capturing.get() && generation == captureGeneration) {
                    var offset = 0
                    while (offset < pcm.size && capturing.get() && generation == captureGeneration) {
                        val count = recorder.read(
                            pcm,
                            offset,
                            pcm.size - offset,
                            AudioRecord.READ_BLOCKING,
                        )
                        if (count <= 0) break
                        offset += count
                    }
                    if (offset != pcm.size) continue
                    val inputIndex = encoder.dequeueInputBuffer(OMC_FRAME_US)
                    if (inputIndex >= 0) {
                        encoder.getInputBuffer(inputIndex)?.apply {
                            clear()
                            put(pcm)
                        }
                        encoder.queueInputBuffer(inputIndex, 0, pcm.size, timestampUs, 0)
                        timestampUs += OMC_FRAME_US
                    }
                    drainEncoder(encoder, info)
                }
            } catch (error: Throwable) {
                capturing.set(false)
                onError(error)
            } finally {
                runCatching { if (recorder?.recordingState == AudioRecord.RECORDSTATE_RECORDING) recorder.stop() }
                recorder?.release()
                runCatching { encoder?.stop() }
                encoder?.release()
            }
        }
    }

    private fun drainEncoder(codec: MediaCodec, info: MediaCodec.BufferInfo) {
        while (true) {
            val outputIndex = codec.dequeueOutputBuffer(info, 0)
            if (outputIndex < 0) return
            if (info.size > 0 && info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                codec.getOutputBuffer(outputIndex)?.let { buffer ->
                    buffer.position(info.offset)
                    buffer.limit(info.offset + info.size)
                    ByteArray(info.size).also {
                        buffer.get(it)
                        onOpusFrame(it)
                    }
                }
            }
            codec.releaseOutputBuffer(outputIndex, false)
        }
    }

    fun play(opus: ByteArray) {
        if (opus.isEmpty()) return
        val copy = opus.copyOf()
        playbackExecutor.execute {
            try {
                val codec = decoder ?: buildDecoder().also { decoder = it }
                val inputIndex = codec.dequeueInputBuffer(OMC_FRAME_US)
                if (inputIndex < 0) return@execute
                codec.getInputBuffer(inputIndex)?.apply {
                    clear()
                    put(copy)
                }
                codec.queueInputBuffer(inputIndex, 0, copy.size, decoderTimestampUs, 0)
                decoderTimestampUs += OMC_FRAME_US
                val info = MediaCodec.BufferInfo()
                while (true) {
                    val outputIndex = codec.dequeueOutputBuffer(info, 0)
                    if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        ensureTrack(codec.outputFormat)
                        continue
                    }
                    if (outputIndex < 0) break
                    if (info.size > 0) {
                        val output = codec.getOutputBuffer(outputIndex)
                        val player = ensureTrack(codec.outputFormat)
                        if (output != null) {
                            output.position(info.offset)
                            output.limit(info.offset + info.size)
                            val pcm = ByteArray(info.size)
                            output.get(pcm)
                            player.write(pcm, 0, pcm.size, AudioTrack.WRITE_BLOCKING)
                            if (player.playState != AudioTrack.PLAYSTATE_PLAYING) player.play()
                        }
                    }
                    codec.releaseOutputBuffer(outputIndex, false)
                }
            } catch (error: Throwable) {
                onError(error)
            }
        }
    }

    private fun buildDecoder(): MediaCodec {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_OPUS,
            OMC_SAMPLE_RATE,
            1,
        )
        format.setByteBuffer("csd-0", opusHead())
        format.setByteBuffer("csd-1", nativeLong(6_500_000L))
        format.setByteBuffer("csd-2", nativeLong(80_000_000L))
        return MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS).also {
            it.configure(format, null, null, 0)
            it.start()
        }
    }

    private fun opusHead(): ByteBuffer = ByteBuffer.allocate(19)
        .order(ByteOrder.LITTLE_ENDIAN)
        .apply {
            put("OpusHead".toByteArray(Charsets.US_ASCII))
            put(1)
            put(1)
            putShort(312)
            putInt(OMC_SAMPLE_RATE)
            putShort(0)
            put(0)
            flip()
        }

    private fun nativeLong(value: Long): ByteBuffer = ByteBuffer.allocate(8)
        .order(ByteOrder.nativeOrder())
        .apply { putLong(value); flip() }

    private fun ensureTrack(format: MediaFormat): AudioTrack {
        track?.let { return it }
        val rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val minimum = AudioTrack.getMinBufferSize(
            rate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        return AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build(),
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(rate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .build(),
            )
            .setBufferSizeInBytes(maxOf(minimum, OMC_FRAME_BYTES * 6))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
            .also { track = it }
    }

    fun stop() {
        stopCapture()
        playbackExecutor.execute {
            runCatching { decoder?.stop() }
            decoder?.release()
            decoder = null
            track?.run {
                if (playState == AudioTrack.PLAYSTATE_PLAYING) pause()
                flush()
                release()
            }
            track = null
            decoderTimestampUs = 0L
        }
    }

    fun stopCapture() {
        captureGeneration++
        capturing.set(false)
    }
}
