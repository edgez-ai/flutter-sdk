package ai.edgez.flutter_sdk

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class EdgezBleControlChunksTest {
    @Test
    fun maximumPayloadReassemblesAtEverySupportedMtu() {
        val payload = ByteArray(512) { it.toByte() }
        val frame = byteArrayOf(0x45, 0x5a, 0, 2) + payload
        for (mtu in listOf(23, 64, 185, 247, 512, 517)) {
            val chunks = edgezBleControlChunks(frame, mtu)
            assertTrue(chunks.all { it.isNotEmpty() && it.size <= minOf(mtu - 3, 512) })
            assertArrayEquals(frame, chunks.fold(byteArrayOf()) { buffer, chunk -> buffer + chunk })
            assertEquals(26, edgezBleControlChunks(frame, 23).size)
        }
    }

    @Test
    fun smallStatusFrameRemainsOneWrite() {
        val frame = byteArrayOf(0x45, 0x5a, 1, 0, 8)
        val chunks = edgezBleControlChunks(frame, 23)
        assertEquals(1, chunks.size)
        assertArrayEquals(frame, chunks.single())
    }

    @Test
    fun maximumMtuStillRespectsAttributeLimit() {
        assertEquals(listOf(512, 4), edgezBleControlChunks(ByteArray(516), 517).map { it.size })
        assertEquals(listOf(20, 1), edgezBleControlChunks(ByteArray(21), 23).map { it.size })
    }
}
