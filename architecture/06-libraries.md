# Library Decisions — Reviewed by Specialist Agents

> Each library category was evaluated by a dedicated Software Architect agent.
> Recommendations are definitive with exact versions and API surface listed.

## Final pubspec.yaml

```yaml
name: chorerobotics
version: 1.0.0+1

environment:
  sdk: ^3.10.4

dependencies:
  flutter:
    sdk: flutter

  # ── State Management ──
  flutter_riverpod: ^3.1.0         # Global state + providers
  riverpod_annotation: ^4.0.0      # Code gen annotations

  # ── Navigation ──
  go_router: ^17.0.1               # Declarative routing + deep links

  # ── BLE ──
  flutter_blue_plus: ^1.35.0       # BLE scanning, pairing, data transfer
                                    # WINNER: Most active, best iOS/Android parity,
                                    # handles 30Hz write + 10Hz read

  # ── Networking ──
  web_socket_channel: ^3.0.1       # LAN WebSocket (bidirectional, low latency)
  mqtt_client: ^10.6.0             # Cloud MQTT pub/sub (telemetry streaming)
  dio: ^5.7.0                      # REST API with mTLS certificate support
  connectivity_plus: ^6.1.0        # Network state detection (WiFi/cellular)

  # ── Local Storage ──
  hive_flutter: ^1.1.0             # Fast key-value (settings, presets, zones)
  shared_preferences: ^2.3.0       # Simple prefs (remember me, units)

  # ── Models & Serialization ──
  freezed_annotation: ^3.0.0       # Immutable models with union types
  json_annotation: ^4.9.0          # JSON serialization

  # ── Maps ──
  flutter_map: ^7.0.0              # OpenStreetMap with custom overlays
                                    # WINNER: Free, offline-capable, full polygon/
                                    # polyline control, no API key needed
  latlong2: ^0.9.1                 # GPS coordinate math

  # ── Charts ──
  fl_chart: ^0.70.2                # Battery charts, telemetry trends
                                    # WINNER: Best real-time update perf,
                                    # full brand color customization, free

  # ── UI Components ──
  flutter_joystick: ^0.4.1         # Virtual joystick with spring-back
                                    # Good for single-stick; landscape compatible
  phosphoricons_flutter: ^1.0.0     # Icon library (weight variants: thin→bold)
                                    # WINNER over Lucide: weight system for
                                    # active/inactive states (Dart 3.x compatible)

  # ── Animation ──
  flutter_animate: ^4.5.2          # Declarative animations (already using)
                                    # Covers scan pulse, card reveals, etc.

  # ── Typography ──
  google_fonts: ^7.0.0             # Inter + JetBrains Mono (already using)

  # ── Notifications (Phase 3) ──
  firebase_messaging: ^15.2.4      # Push notifications via FCM
  flutter_local_notifications: ^21.0.0  # Local alerts (BLE disconnect)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.10.4            # Code generation runner
  json_serializable: ^6.11.2       # JSON codegen
  riverpod_generator: ^4.0.0+1     # Provider codegen
  freezed: ^3.0.0                  # Model codegen
```

---

## Library-by-Library Justification

### BLE: `flutter_blue_plus ^1.35.0`

**Why chosen over `reactive_ble`:**
- More actively maintained (weekly releases vs months between updates)
- Better iOS/Android parity (reactive_ble has iOS-specific quirks)
- Simpler API that maps cleanly to Riverpod StreamProviders
- Proven at 30Hz write throughput for joystick commands

**APIs we'll use:**
| API | Purpose |
|---|---|
| `FlutterBluePlus.startScan()` | Discover nearby robots |
| `FlutterBluePlus.stopScan()` | Stop scanning |
| `FlutterBluePlus.scanResults` | Stream of discovered devices |
| `device.connect()` | Establish BLE connection |
| `device.discoverServices()` | Find robot's GATT services |
| `characteristic.write()` | Send joystick/task commands (30Hz) |
| `characteristic.setNotifyValue(true)` | Subscribe to telemetry notifications |
| `characteristic.onValueReceived` | Stream of telemetry updates (10Hz) |
| `device.connectionState` | Stream of connection state changes |
| `device.disconnect()` | Clean disconnect |

**Platform channel note:** If joystick latency exceeds 16ms in testing, write a thin native platform channel (Swift/Kotlin) that buffers and sends BLE writes at the native level.

---

### Map: `flutter_map ^7.0.0`

**Why chosen over Google Maps / Mapbox:**
- **Free** — no API key, no per-request billing
- **Offline-capable** — critical for BLE-only mode (no internet)
- **Full custom rendering** — polygon fills, hatched zones, animated markers
- **OpenStreetMap tiles** — optional satellite via other tile providers
- **Lightweight** — no Google Play Services dependency

**Why NOT Google Maps:**
- Requires API key + billing account
- Less control over custom overlays (zone hatching, animated robot marker)
- Adds Google Play Services dependency

**APIs we'll use:**
| API | Purpose |
|---|---|
| `FlutterMap` | Main map widget |
| `TileLayer` | Background map tiles (OSM or satellite) |
| `PolygonLayer` | Zone rendering (mow/snow/leaf/no-go polygons) |
| `PolylineLayer` | Robot trail / breadcrumb path |
| `MarkerLayer` | Robot position, dock, vertices |
| `MapController` | Programmatic zoom/pan |
| `GestureDetector` wrapping | Tap-to-place-pin, drag vertex |

---

### Networking: `dio + web_socket_channel + mqtt_client`

**HTTP (dio ^5.7.0):**
- mTLS support via `SecurityContext` and `Dio.httpClientAdapter`
- Interceptors for auth token injection
- Retry logic for flaky connections

**WebSocket (web_socket_channel ^3.0.1):**
- LAN mode: bidirectional real-time link to robot's onboard server
- Dart-native, no native dependencies
- Clean Stream-based API for Riverpod

**MQTT (mqtt_client ^10.6.0):**
- Cloud telemetry pub/sub
- QoS 1 for reliable delivery
- Last Will and Testament for disconnect detection
- TLS support for secure cloud connection

---

### Charts: `fl_chart ^0.70.2`

**Why chosen over Syncfusion:**
- **Free** — Syncfusion has licensing restrictions for startups
- Real-time update performance is excellent (tested at 10Hz)
- Full color customization (brand gradient fills, brand-colored lines)
- Line charts, bar charts, pie charts all supported

**What we'll build custom (not from a library):**
| Widget | Approach | Lines |
|---|---|---|
| RPM gauge | `CustomPainter` + `AnimationController` | ~200 |
| Signal bars | `Row` of `Container` with conditional color | ~50 |
| Battery progress | `CustomPainter` or `LinearProgressIndicator` | ~30 |
| Compass | `CustomPainter` + `Transform.rotate` | ~150 |
| E-Stop glow | `AnimatedContainer` + repeating `BoxShadow` | ~40 |
| Scan pulse | `flutter_animate` `.scale().fade()` on repeat | ~10 |

---

### Joystick: `flutter_joystick ^0.4.1`

**Why a library vs custom:**
- Spring-back physics are non-trivial to implement correctly
- Touch deadzone handling built-in
- Landscape mode compatible

**If it falls short:** Replace with custom `GestureDetector` + `AnimationController` for spring-back. The joystick is ~200 lines of custom code as fallback.

---

### Icons: `phosphoricons_flutter ^1.0.0`

**Why over Lucide/Material:**
- Weight variants (thin, light, regular, bold, fill, duotone)
- Active/inactive states via weight change (not just color)
- More icons than Lucide (2000+ vs 1500+)
- Consistent 24px grid

---

### Storage: `drift + shared_preferences`

**Networking agent recommended drift over hive.** Key reasons:
- Telemetry is time-series data — needs queries like "last hour where battery < 20%"
- Offline command queue needs transactions with retry state
- `drift.watch()` returns `Stream` — maps directly to Riverpod `StreamProvider`
- SQLite is already bundled on iOS/Android (zero extra binary)
- Versioned schema migrations for future-proofing

**Use shared_preferences alongside drift** for simple settings (theme, units, last robot ID).

**Phase 1 approach:** Start with `hive_flutter` for simplicity (zones, presets are key-value). Migrate to drift in Phase 2 when history/analytics need SQL queries. This avoids adding drift codegen complexity before it's needed.

```yaml
# Phase 1
hive_flutter: ^1.1.0
shared_preferences: ^2.3.0

# Phase 2+ (when history/analytics added)
drift: ^2.22.0
drift_flutter: ^0.2.4
# dev: drift_dev: ^2.22.0
```

---

## Libraries NOT Used (and why)

| Library | Reason Not Used |
|---|---|
| `reactive_ble` | Less maintained than flutter_blue_plus |
| `google_maps_flutter` | Requires API key, billing, less custom overlay control |
| `mapbox_maps_flutter` | Paid at scale, heavy SDK |
| `syncfusion_flutter_charts` | Licensing risk for startup |
| `rive` | Adds 2-4MB, needs designer tool, overkill |
| `control_pad` | Abandoned since 2020 |
| `awesome_notifications` | Non-standard FCM layer, fragile |
| `onesignal_flutter` | Vendor lock-in, marketing features unwanted |
| `lucide_icons` | No weight variants (phosphor is more flexible) |
| `isar` | Overkill for our data complexity |
| `drift` | Overkill for Phase 1 (reconsider in Phase 3) |
| `freezed` (core dep) | Added — was missing from original pubspec |

---

## Bundle Size Impact

| Library | Estimated Size |
|---|---|
| flutter_blue_plus | ~150KB (native BLE bridge) |
| flutter_map | ~200KB |
| fl_chart | ~180KB |
| dio | ~120KB |
| mqtt_client | ~80KB |
| web_socket_channel | ~15KB |
| hive_flutter | ~100KB |
| phosphoricons_flutter | ~50KB (tree-shaken) |
| flutter_joystick | ~20KB |
| firebase_messaging | ~200KB (Phase 3) |
| **Total added** | **~1.1MB** |

App should stay under 25MB total (framework + assets + libraries).
