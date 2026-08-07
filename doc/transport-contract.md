# EdgeZ host transport contract

This contract is shared by the mobile SDK and device firmware. BLE and USB are
different byte transports, but they expose the same logical application
interface.

## Logical interface

A host transport implements these operations:

```text
connect() -> ready(maxApplicationFrameBytes)
send(channel, payload, waitForAcceptance)
frames -> (channel, payload)
disconnect()
```

`channel` is one of:

| Channel | Payload | Users |
| --- | --- | --- |
| `control` | Serialized `NetworkPacket` protobuf | setup, status, beacons, text messages, recorded voice-message chunks, conversation ACKs |
| `realtimeVoice` | Compact encrypted voice-call route and payload | live voice calls |
| `realtimeSpeed` | Compact routed speed-test frame | link measurement |

The maximum encoded application frame is 512 bytes. For realtime channels the
three-byte channel marker is part of that limit.

`send(..., waitForAcceptance: true)` completes when the device transport has
accepted the complete application frame. It does **not** mean that a peer
received the message. Peer delivery continues to use a protobuf
`NetworkPacket` with `Operation.ACKNOWLEDGE` and the original message ID.

Application frames are ordered within a connection. A reconnect resets parser,
acceptance-counter, and deduplication state.

## Logical channel encoding

After removing the physical transport framing, both transports carry the same
bytes:

| Channel | Encoded bytes |
| --- | --- |
| `control` | raw `NetworkPacket` protobuf |
| `realtimeVoice` | ASCII `VC`, version byte `0x02`, compact voice payload |
| `realtimeSpeed` | ASCII `ST`, version byte `0x02`, compact speed payload |

Unknown channel markers or versions must be rejected, not dispatched as a
different channel.

## BLE binding

- Control host-to-device: write an `EZ` frame to characteristic `FFF1`. The
  two-byte payload length is little-endian.
- Control device-to-host: receive an `EZ` frame from characteristic `FFF2`.
- Realtime host-to-device: write the logical realtime frame to `FFF7`.
- Realtime device-to-host: receive the logical realtime frame from `FFF8`.
- A successful GATT write completion is transport acceptance.

The BLE `EZ` frame is:

```text
45 5a | payload_length:u16_le | payload
```

## USB binding

Every USB CDC application or link frame uses this stream envelope:

```text
94 c3 | payload_length:u16_be | payload
```

Control and realtime payloads use the logical channel encoding above. USB CDC
runs at 921600 baud, 8 data bits, no parity, and 1 stop bit.

Because a UART write only proves that Android handed bytes to the serial
driver, firmware returns a link frame after accepting every host-to-device
application frame:

```text
45 5a | version=01 | type=03 | sequence:u16_le | length=0:u16_le
```

Type `03` is `TX_ACCEPTED`. It is consumed by the transport and never forwarded
to the application. Acceptance frames are cumulative and ordered for the
connection, so the mobile side may use sent/accepted counters for back-pressure.

USB realtime traffic uses the same queue-and-drain mechanism as BLE. Frames are
placed in a bounded native queue and written serially. Speed sends pause after
each short batch until that queue drains; live voice may discard a stale queued
frame rather than increasing latency. No firmware status packet or per-speed-
frame `TX_ACCEPTED` is required.

Firmware decouples UART and HaLow work with separate PSRAM queues in each
direction. Protobuf/control has a dedicated 64-frame high-priority FIFO;
voice/speed shares a 256-frame realtime FIFO. Each slot holds one complete
application frame up to 512 bytes. Workers always select pending control work
before realtime work. Producers wait for their queue's space so pressure
propagates through the UART driver instead of dropping frames locally.

The firmware UART driver uses a 64 KiB RX ring and 32 KiB TX ring. Its 32 KiB
stream-parser staging buffer is allocated in PSRAM. Android reads up to 16 KiB
per serial operation and retains up to 64 complete framed packets while
assembling burst traffic.

USB pacing starts with a 3 ms inter-frame gap and automatically adjusts within
1–10 ms. Firmware queue pressure feeds a recommended mobile TX gap through the
high-priority link-control path. Final receiver sequence loss adjusts the local
gap and reports it to firmware for subsequent device-to-mobile traffic.
Realtime speed/voice traffic does not use a firmware-acceptance window.

The same link-frame layout reserves type `01` for `PING` and type `02` for
`PONG`. Link frames are diagnostics/control traffic and are not included in the
application acceptance counters. Mobile alone initiates one heartbeat per
minute; firmware only returns the matching `PONG`.

## Message mapping

- Text send/receive: `control`.
- Recorded voice message send/receive: protobuf chunks on `control`; wait for
  transport acceptance between chunks to avoid overrunning the firmware queue.
- Live voice-call signaling and audio: `realtimeVoice`; use transport
  acceptance as back-pressure for host-to-device frames.
- Speed test: `realtimeSpeed`; BLE and USB use the same bounded realtime queue
  and periodic queue-drain checkpoints.

Encryption, message IDs, routing, and peer delivery acknowledgements are above
the transport layer and must behave identically on BLE and USB.
