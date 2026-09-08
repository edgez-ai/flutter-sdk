package ai.edgez.flutter_sdk

// FFF1 is a byte stream: firmware buffers the EZ header and payload across
// writes. Keep each ATT value within both the negotiated MTU and the 512-byte
// attribute limit, including when an EZ envelope holds a 512-byte payload.
internal fun edgezBleControlChunks(frame: ByteArray, mtu: Int): List<ByteArray> {
    val chunkSize = minOf((mtu - 3).coerceAtLeast(20), 512)
    return frame.asList().chunked(chunkSize).map { it.toByteArray() }
}
