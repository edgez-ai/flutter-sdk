# Roadmap

This roadmap describes planned directions. Items here are **not part of the
current public SDK contract** until they appear in the feature guide and a
released API.

## Offline maps

Add an offline-first map experience for visualizing the EdgeZ mesh without an
internet connection.

Planned scope:

- Download and manage map regions for offline use.
- Display discovered nodes, shared locations, geofences, and mesh topology.
- Show freshness and confidence for cached positions.
- Keep map storage, rendering, and provider-specific code outside the core mesh
  transport API.
- Define retention, deletion, and privacy controls for locally cached location
  history.

The current SDK already exposes the data needed by a map layer through
`EdgezMeshNode`, `EdgezSensorSample`, `EdgezTopologyLink`, and
`EdgezMeshSession.state`. The current example intentionally contains no map
provider or map UI.

## libp2p cross-boundary mixed mesh

Add a libp2p transport layer that can bridge EdgeZ HaLow mesh traffic across
network boundaries while preserving local offline operation.

The target architecture is a mixed mesh:

- HaLow/BLE remains the local device and radio transport.
- libp2p connects eligible gateway nodes over IP networks.
- A routing boundary decides whether traffic stays local or crosses a gateway.
- Messages retain stable identities and IDs across transports so they can be
  authenticated and deduplicated.
- Store-and-forward behavior handles intermittent gateway connectivity.

Key design work:

1. Define a transport-independent envelope for identity, addressing, message
   IDs, hop limits, timestamps, and payload type.
2. Map EdgeZ node identities to libp2p peer identities without exposing private
   keys or weakening the existing conversation encryption model.
3. Add gateway discovery, route selection, loop prevention, deduplication, and
   delivery acknowledgement semantics.
4. Specify authorization and policy for traffic crossing local mesh boundaries.
5. Add observability for the selected route, gateway transitions, latency, and
   delivery state.
6. Test partitions, reconnects, duplicate paths, incompatible protocol
   versions, and mixed online/offline peers.

## Proposed delivery phases

| Phase | Outcome |
| --- | --- |
| 1. Contracts | Transport-neutral envelopes, route metadata, and documented security boundaries. |
| 2. Gateway prototype | One EdgeZ mesh can exchange authenticated messages through a libp2p gateway. |
| 3. Mixed routing | Automatic local-versus-cross-boundary routing with loop prevention and deduplication. |
| 4. Offline maps | Downloadable regions with node, location, geofence, and topology overlays. |
| 5. Resilience | Store-and-forward queues, reconnect recovery, compatibility tests, and operational metrics. |
| 6. Public SDK | Stable APIs, migration notes, example UI, and production guidance. |

## Open decisions

- Supported offline map data format, provider, licensing, and update strategy.
- Whether libp2p runs in the Flutter process, a native service, or a dedicated
  gateway application.
- Peer identity derivation and rotation policy.
- Gateway trust, admission, relay, and abuse-prevention rules.
- Routing priorities when BLE/HaLow and libp2p paths are both available.
- Message expiry, queue limits, and conflict behavior after long partitions.

