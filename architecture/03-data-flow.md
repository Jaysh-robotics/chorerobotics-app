# Data Flow & State Management

## Provider Architecture (Riverpod)

```
┌─────────────────────────────────────────────────────────────┐
│                    PROVIDER HIERARCHY                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  GLOBAL PROVIDERS (never disposed)                           │
│  ├── authProvider          → AuthState (token, user)         │
│  ├── connectionProvider    → ConnectionState (mode, status)  │
│  ├── robotProvider         → Robot (id, model, attachment)   │
│  ├── estopProvider         → bool (safety-critical)          │
│  └── settingsProvider      → AppSettings (units, notifs)     │
│                                                              │
│  STREAM PROVIDERS (auto-dispose when no listeners)           │
│  ├── telemetryStreamProvider → Stream<Telemetry>             │
│  │   Source: BLE characteristic / WebSocket / MQTT topic     │
│  │   Rate: ~10Hz (100ms updates)                             │
│  │   Contains: battery, speed, heading, gps, motors, temp    │
│  │                                                           │
│  ├── connectionStateStreamProvider → Stream<ConnectionMode>  │
│  │   Emits: ble_connected, wifi_connected, cloud_connected,  │
│  │          disconnected, reconnecting                       │
│  │                                                           │
│  └── diagnosticStreamProvider → Stream<DiagnosticReport>     │
│      Rate: ~1Hz (1s updates, only on diagnostics screen)     │
│                                                              │
│  COMPUTED PROVIDERS (derived from streams)                    │
│  ├── batteryProvider       → Battery (%, runtime, health)    │
│  ├── speedProvider         → double (m/s)                    │
│  ├── headingProvider       → double (degrees)                │
│  ├── gpsProvider           → LatLng (lat, lng)               │
│  ├── motorSpeedsProvider   → MotorSpeeds (fl, fr, rl, rr)   │
│  ├── signalStrengthProvider→ int (0-4 bars)                  │
│  ├── rtkStatusProvider     → RtkStatus (fix/float/single)    │
│  └── attachmentProvider    → Attachment (type, status)        │
│                                                              │
│  FEATURE PROVIDERS (scoped to feature)                       │
│  ├── zonesProvider         → List<Zone> (from local cache)   │
│  ├── scheduleProvider      → List<ScheduledTask>             │
│  ├── historyProvider       → List<TaskRecord>                │
│  ├── mowingConfigProvider  → MowingConfig (pattern, angle)   │
│  ├── snowConfigProvider    → SnowConfig (start, depth, dir)  │
│  └── leafConfigProvider    → LeafConfig (mode, dump point)   │
│                                                              │
│  COMMAND PROVIDERS (fire-and-forget notifiers)               │
│  ├── joystickCommandProvider → sends drive commands at 30Hz  │
│  ├── taskCommandProvider     → start/stop/pause task         │
│  ├── estopCommandProvider    → EMERGENCY STOP (priority)     │
│  └── dockCommandProvider     → return to dock                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### 1. Telemetry Flow (Read Path)

```
┌──────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Robot    │────→│ Connection       │────→│ Telemetry       │
│ Hardware  │ BLE │ Manager          │ Dart│ StreamProvider   │
│           │/WS  │                  │Stream│                │
└──────────┘/MQTT └──────────────────┘     └────────┬────────┘
                                                     │
                              ┌───────────────────────┼───────────────┐
                              │                       │               │
                    ┌─────────▼──────┐  ┌────────────▼───┐  ┌───────▼────────┐
                    │ batteryProvider │  │ speedProvider  │  │ gpsProvider    │
                    │ (computed)      │  │ (computed)     │  │ (computed)     │
                    └─────────┬──────┘  └────────────┬───┘  └───────┬────────┘
                              │                      │              │
                    ┌─────────▼──────┐  ┌────────────▼───┐  ┌───────▼────────┐
                    │ Battery Widget │  │ Speed HUD     │  │ Map Marker     │
                    │ (dashboard)    │  │ (control)      │  │ (map screen)   │
                    └────────────────┘  └────────────────┘  └────────────────┘
```

### 2. Command Flow (Write Path)

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ UI Action     │────→│ Command          │────→│ Connection       │
│ (button tap,  │     │ Encoder          │     │ Manager          │
│  joystick)    │     │ (JSON/protobuf)  │     │ (route to active)│
└──────────────┘     └──────────────────┘     └────────┬─────────┘
                                                        │
                                          ┌─────────────┼──────────────┐
                                          │             │              │
                                    ┌─────▼───┐  ┌─────▼───┐  ┌──────▼────┐
                                    │   BLE   │  │WebSocket│  │   MQTT   │
                                    │  Write  │  │  Send   │  │  Publish │
                                    └─────────┘  └─────────┘  └──────────┘
```

### 3. Connection Auto-Switch Flow

```
┌─────────────────────────────────────────────────────────────┐
│                CONNECTION STATE MACHINE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  [App Launch]                                                │
│       │                                                      │
│       ▼                                                      │
│  ┌─────────────┐  found   ┌──────────────┐                  │
│  │ BLE Scan    │─────────→│ BLE Connected │◄─── PREFERRED    │
│  └──────┬──────┘          └──────┬───────┘     (lowest       │
│         │ not found              │ lost         latency)     │
│         ▼                        ▼                           │
│  ┌─────────────┐  found   ┌──────────────┐                  │
│  │ WiFi Scan   │─────────→│WiFi Connected│◄─── FALLBACK 1   │
│  └──────┬──────┘          └──────┬───────┘     (medium       │
│         │ not found              │ lost         latency)     │
│         ▼                        ▼                           │
│  ┌─────────────┐  auth    ┌──────────────┐                  │
│  │ Cloud Auth  │─────────→│Cloud Connected│◄── FALLBACK 2   │
│  └──────┬──────┘          └──────┬───────┘    (highest       │
│         │ failed                 │ lost        latency)      │
│         ▼                        ▼                           │
│  ┌─────────────────────────────────┐                         │
│  │         DISCONNECTED            │                         │
│  │  (show reconnect overlay)       │                         │
│  │  (retry every 5s)               │                         │
│  └─────────────────────────────────┘                         │
│                                                              │
│  SAFETY RULE: If connection lost during active task:         │
│  0-10s  → Continue task (buffer commands)                    │
│  10-20s → Pause task, hold position                          │
│  20-30s → Return to dock                                     │
│  30s+   → Emergency stop                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4. E-Stop Data Flow (Safety Critical)

```
┌──────────────┐
│ E-Stop       │
│ Button Press │
│ (long-press) │
└──────┬───────┘
       │
       ▼  BYPASSES ALL STATE MANAGEMENT
┌──────────────────────────────────────────┐
│ estopCommandProvider                      │
│                                           │
│ 1. Set estopProvider = true (global)      │
│ 2. Send ESTOP command on ALL connections  │
│    simultaneously (BLE + WiFi + MQTT)     │
│ 3. Cancel all pending commands            │
│ 4. Log event with timestamp              │
│ 5. Vibrate device (haptic feedback)       │
│ 6. Block all navigation except E-Stop    │
│    recovery screen                        │
└──────────────────────────────────────────┘
```

### 5. Offline Data Sync

```
┌─────────────────────────────────────────────────────────────┐
│                    OFFLINE-FIRST CACHE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  LOCAL (Hive boxes):                                         │
│  ├── robot_box        → Robot config, name, serial           │
│  ├── zones_box        → Zone polygons, types, names          │
│  ├── schedules_box    → Scheduled tasks                      │
│  ├── presets_box      → Saved job configurations             │
│  ├── history_box      → Recent task records                  │
│  └── settings_box     → User preferences                    │
│                                                              │
│  SYNC STRATEGY:                                              │
│  ├── Zones: Write locally → sync to cloud when connected     │
│  ├── Schedules: Write locally → sync to robot when connected │
│  ├── History: Robot pushes → app stores locally + cloud      │
│  ├── Settings: Local only (no cloud sync needed)             │
│  └── Telemetry: Stream only, not persisted (except history)  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Model Definitions

### Core Models (Freezed)

```dart
// robot.dart
@freezed
class Robot with _$Robot {
  const factory Robot({
    required String id,
    required String model,
    required String name,
    required String serialNumber,
    required String firmwareVersion,
    required Attachment? attachment,
    required ConnectionMode connectionMode,
  }) = _Robot;
}

// telemetry.dart
@freezed
class Telemetry with _$Telemetry {
  const factory Telemetry({
    required double batteryPercent,
    required double batteryVoltage,
    required double batteryCurrentAmps,
    required double batteryTempC,
    required int batteryCycles,
    required double batteryHealth,
    required double speedMs,
    required double headingDeg,
    required double latitude,
    required double longitude,
    required RtkStatus rtkStatus,
    required int satelliteCount,
    required MotorSpeeds motors,
    required double systemTempC,
    required RobotState state,
    required String? activeTaskId,
    required int signalStrength,  // 0-4
    required DateTime timestamp,
  }) = _Telemetry;
}

// zone.dart
@freezed
class Zone with _$Zone {
  const factory Zone({
    required String id,
    required String name,
    required ZoneType type,        // mow, snow, leaf, noGo
    required List<LatLng> vertices,
    required double areaSqM,
  }) = _Zone;
}

// task.dart
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required TaskType type,        // mow, plow, collect
    required String zoneId,
    required TaskStatus status,    // pending, active, paused, complete, failed
    required DateTime? startTime,
    required DateTime? endTime,
    required double progressPercent,
    required double areaCompletedSqM,
    required Map<String, dynamic> parameters,
  }) = _Task;
}

// enums
enum ConnectionMode { ble, wifi, cloud, disconnected }
enum RobotState { idle, working, charging, paused, error, estop }
enum RtkStatus { fix, float, single, none }
enum ZoneType { mow, snow, leaf, noGo }
enum TaskType { mow, plow, collect }
enum TaskStatus { pending, active, paused, complete, failed }
enum AttachmentType { mowerBlade, snowPlow, leafCollector, none }
```

## State Management Rules

1. **Global state** (auth, connection, robot, e-stop) → `@Riverpod(keepAlive: true)`
2. **Screen state** (forms, selections) → `@riverpod` (auto-dispose)
3. **Streams** (telemetry) → `StreamProvider` with auto-dispose
4. **Commands** → `AsyncNotifierProvider` for fire-and-forget actions
5. **Cache** → Hive boxes accessed through providers, never directly
6. **Never** put UI state (scroll position, tab index) in Riverpod — use Flutter built-in state
