# Firebase Database Design -- Complete Specification

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Date | 2026-03-23 |
| Status | Architecture Decision Record -- Firebase MVP Blueprint |
| Scope | Complete Firebase data layer for the ChoreRobotics mobile app (MVP through Phase 4) |
| Supersedes | 08-firebase-backend.md (high-level overview) |
| Production Path | 07-backend-architecture.md (Go + PostgreSQL + EMQX for 1000+ robots) |

---

## Table of Contents

1. [Architecture Recap: What Goes Where](#1-architecture-recap)
2. [Firebase Services Configuration](#2-firebase-services-configuration)
3. [Firestore Collections -- Complete Schema](#3-firestore-collections)
4. [Realtime Database -- Live Telemetry](#4-realtime-database)
5. [Firebase Storage -- Binary Assets](#5-firebase-storage)
6. [Security Rules -- Firestore](#6-security-rules-firestore)
7. [Security Rules -- Realtime Database](#7-security-rules-realtime-database)
8. [Security Rules -- Storage](#8-security-rules-storage)
9. [Cloud Functions](#9-cloud-functions)
10. [Indexes](#10-indexes)
11. [Data Sync Strategy](#11-data-sync-strategy)
12. [Offline Strategy](#12-offline-strategy)
13. [Cost Optimization](#13-cost-optimization)
14. [Migration Path to Production](#14-migration-path)
15. [Flutter Integration Patterns](#15-flutter-integration-patterns)
16. [Appendix: TypeScript Type Definitions](#16-appendix-typescript-types)

---

## 1. Architecture Recap

### The Three Entities

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATA FLOW OVERVIEW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐       ┌──────────────────┐       ┌──────────────────┐     │
│  │  MOBILE APP  │       │    FIREBASE      │       │    ROBOT         │     │
│  │  (Flutter)   │       │    (Cloud)       │       │   (Jetson/ROS2) │     │
│  └──────┬───────┘       └────────┬─────────┘       └────────┬────────┘     │
│         │                        │                           │               │
│         │   PATH A: LOCAL        │                           │               │
│         │◄══════════════════════════════════════════════════►│               │
│         │   BLE / WiFi WebSocket │                           │               │
│         │   Joystick 30Hz        │                           │               │
│         │   Telemetry 10Hz       │                           │               │
│         │   E-Stop               │                           │               │
│         │   Manual control       │                           │               │
│         │   Boundary recording   │                           │               │
│         │                        │                           │               │
│         │   PATH B: CLOUD        │                           │               │
│         │◄══════════════════════►│◄═════════════════════════►│               │
│         │   Auth (always)        │   Telemetry upload        │               │
│         │   Zone CRUD            │   Task history upload     │               │
│         │   Schedule CRUD        │   Zone/schedule download  │               │
│         │   Task history read    │   Firmware download       │               │
│         │   Settings sync        │   Command polling         │               │
│         │   Firmware metadata    │   Status heartbeat        │               │
│         │   Cloud commands       │                           │               │
│         │   (when no local conn) │                           │               │
│         │                        │                           │               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Ownership Matrix

| Data Type | Primary Writer | Secondary Writer | Readers | Firebase Service |
|---|---|---|---|---|
| User profile | App | -- | App | Firestore |
| User settings | App | -- | App | Firestore |
| Robot registration | App (pairing) | Robot (heartbeat) | App, Robot | Firestore |
| Live telemetry | Robot | -- | App | Realtime Database |
| Telemetry history | Robot (sampled) | -- | App | Firestore |
| Zones | App | -- | App, Robot | Firestore |
| Schedules | App | -- | App, Robot | Firestore |
| Cloud commands | App | Robot (ack) | App, Robot | Firestore |
| Task history | Robot | -- | App | Firestore |
| Firmware metadata | Admin | -- | App, Robot | Firestore |
| Firmware binaries | Admin | -- | Robot | Storage |
| Coverage maps | Robot | -- | App | Storage |
| Battery history | Robot | -- | App | Firestore |
| Diagnostic alerts | Robot | -- | App | Firestore |
| FCM tokens | App | -- | Cloud Functions | Firestore |
| Notification log | Cloud Functions | -- | App | Firestore |
| Weather cache | Cloud Functions | -- | App | Firestore |

---

## 2. Firebase Services Configuration

### Project Setup

```
Firebase Project: chorerobotics-app
Project ID:       chorerobotics-app
Region:           us-central1 (Firestore)
                  us-central1 (Realtime Database)
                  us-central1 (Cloud Functions)
Storage Bucket:   chorerobotics-app.firebasestorage.app
```

### Services Enabled

| Service | Purpose | Billing Impact |
|---|---|---|
| Firebase Auth | Email/password, Google, Apple sign-in | Free for 50K MAU |
| Cloud Firestore | Persistent structured data | Pay per read/write/storage |
| Realtime Database | Live telemetry streaming | Pay per bandwidth + storage |
| Firebase Storage | Firmware binaries, coverage maps | Pay per storage + bandwidth |
| Cloud Messaging (FCM) | Push notifications | Free (unlimited) |
| Cloud Functions | Triggers, notifications, cleanup | Pay per invocation + compute |

### Flutter Dependencies

```yaml
dependencies:
  firebase_core: ^3.12.0
  firebase_auth: ^5.5.0
  cloud_firestore: ^5.6.0
  firebase_database: ^11.3.0    # Realtime Database for live telemetry
  firebase_storage: ^12.4.0
  firebase_messaging: ^15.2.4
```

---

## 3. Firestore Collections -- Complete Schema

### Collection Hierarchy Overview

```
firestore-root/
│
├── users/{userId}                          # User profiles and settings
│   ├── fcm_tokens/{tokenId}               # Push notification device tokens
│   └── notification_log/{logId}           # Delivered notification records
│
├── robots/{robotId}                        # Robot registration and config
│   ├── zones/{zoneId}                      # Zone polygons per robot
│   ├── schedules/{scheduleId}              # Recurring task schedules
│   ├── commands/{commandId}                # Cloud command queue
│   ├── task_history/{taskId}               # Completed task records
│   ├── battery_history/{entryId}           # Daily battery snapshots
│   ├── alerts/{alertId}                    # Diagnostic alerts/faults
│   └── telemetry_snapshots/{snapshotId}    # Sampled telemetry (1/min)
│
├── firmware/{firmwareId}                   # Firmware release metadata
│
├── weather_cache/{locationId}              # Cached weather forecasts
│
└── app_config/global                       # Remote app configuration
```

---

### 3.1 `users/{userId}`

The user document is created on first sign-in. Firebase Auth UID is the document ID.

```typescript
// Collection: users
// Document ID: Firebase Auth UID (e.g., "aB1cD2eF3gH4")
// Writer: App (on sign-up, settings changes)
// Reader: App
// Estimated size: ~500 bytes

interface UserDocument {
  // Identity (set on creation)
  email: string;                    // "user@example.com"
  displayName: string;              // "Jay Smith"
  createdAt: Timestamp;             // Server timestamp
  updatedAt: Timestamp;             // Server timestamp

  // Settings (user-modifiable)
  settings: {
    units: "metric" | "imperial";   // Default: "imperial" for US users
    temperatureUnit: "celsius" | "fahrenheit";  // Default: "fahrenheit"
    theme: "system" | "light" | "dark";         // Default: "system"
  };

  // Notification preferences
  notifications: {
    taskComplete: boolean;          // Default: true
    taskError: boolean;             // Default: true
    batteryLow: boolean;            // Default: true
    connectionLost: boolean;        // Default: true
    weatherAlert: boolean;          // Default: false
    otaAvailable: boolean;          // Default: true
    estopTriggered: boolean;        // Default: true
  };

  // Robot associations (denormalized for fast reads)
  // This array allows one-query "list my robots" without a subcollection read.
  robotIds: string[];               // ["robot_abc123"] - max 10 for MVP

  // Account state
  accountStatus: "active" | "suspended" | "deleted";  // Default: "active"
}
```

**Design decisions:**
- Robot IDs are denormalized into the user document as an array. This avoids a subcollection query for the common "which robots do I own" check. The array is bounded (max 10 robots per user in MVP, max 50 in fleet mode).
- Notification preferences are embedded rather than in a subcollection because they are always read together and fit comfortably in one document.
- Settings are embedded for the same reason.

---

### 3.2 `users/{userId}/fcm_tokens/{tokenId}`

```typescript
// Subcollection: users/{userId}/fcm_tokens
// Document ID: auto-generated
// Writer: App (on app launch, token refresh)
// Reader: Cloud Functions (when sending notifications)
// Estimated size: ~300 bytes

interface FcmTokenDocument {
  token: string;                    // FCM registration token
  platform: "ios" | "android";     // Device platform
  deviceId: string;                // Unique device identifier
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Cleanup strategy:** Cloud Function triggers on token write to delete stale tokens (>90 days old, or if FCM returns "unregistered" on send attempt).

---

### 3.3 `users/{userId}/notification_log/{logId}`

```typescript
// Subcollection: users/{userId}/notification_log
// Document ID: auto-generated
// Writer: Cloud Functions
// Reader: App (notification history screen)
// Estimated size: ~400 bytes
// Retention: 90 days (Cloud Function cleanup)

interface NotificationLogDocument {
  type: "task_complete" | "task_error" | "battery_low" |
        "connection_lost" | "weather_alert" | "ota_available" |
        "estop_triggered";
  title: string;                    // "Mowing Complete"
  body: string;                     // "Front Yard mowing finished in 45 minutes"
  robotId: string;                  // Which robot triggered this
  data: Record<string, string>;     // Deep link data { "route": "/history/task123" }
  read: boolean;                    // Default: false
  createdAt: Timestamp;
}
```

---

### 3.4 `robots/{robotId}`

The robot document is the central entity. Created during pairing flow.

```typescript
// Collection: robots
// Document ID: Robot serial number (e.g., "CR-MK1-00001")
//   Using serial number as document ID because:
//   - Globally unique (assigned during manufacturing)
//   - Known at pairing time (printed on robot label)
//   - Stable across owner transfers
//   - Matches production PostgreSQL robots.serial_number
// Writer: App (pairing, rename), Robot (status updates, firmware version)
// Reader: App, Robot
// Estimated size: ~800 bytes

interface RobotDocument {
  // Identity (set during pairing, immutable after)
  serialNumber: string;             // "CR-MK1-00001"
  model: string;                    // "CHOREROBOT-MK1"

  // Ownership (set during pairing)
  ownerId: string;                  // Firebase Auth UID of the owner
  pairedAt: Timestamp;              // When the robot was first paired

  // User-editable
  name: string;                     // "Yard Bot" (default: "My ChoreBot")

  // Robot-reported state (written by robot via service account)
  firmwareVersion: string;          // "1.2.3"
  status: "online" | "offline" | "charging" | "working" |
          "paused" | "error" | "estop" | "docked";
  lastSeenAt: Timestamp;            // Last heartbeat from robot
  lastKnownPosition: {
    latitude: number;               // 33.684
    longitude: number;              // -73.047
  } | null;

  // Attachment state (robot-reported)
  attachment: {
    type: "mower_blade" | "snow_plow" | "leaf_collector" | "none";
    status: "connected" | "disconnected";
    detectedAt: Timestamp;
  };

  // Connection info (written by app during setup)
  wifiConfig: {
    ssid: string;                   // "HomeNetwork-5G"
    configuredAt: Timestamp;
  } | null;

  // Dock location (set by app during setup or zone editing)
  dockLocation: {
    latitude: number;
    longitude: number;
  } | null;

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

**Why serial number as document ID:** The serial number is printed on the physical robot and entered during pairing. It is globally unique and survives owner transfers. Using it as the document ID makes lookups O(1) and avoids needing a secondary index. This also maps directly to the `serial_number` column in the production PostgreSQL `robots` table.

---

### 3.5 `robots/{robotId}/zones/{zoneId}`

```typescript
// Subcollection: robots/{robotId}/zones
// Document ID: auto-generated (Firestore auto-ID)
// Writer: App (zone creation, editing, deletion)
// Reader: App, Robot (downloads zones on connect)
// Estimated size: 500 bytes (small yard) to 5KB (complex boundary, 100+ vertices)

interface ZoneDocument {
  // Zone definition
  name: string;                     // "Front Yard"
  type: "mow" | "snow" | "leaf" | "no_go";
  color: string;                    // Hex color override (optional, app has defaults)

  // Polygon geometry
  // Vertices stored as array of {lat, lng} pairs.
  // Minimum 3 vertices. Maximum 1000 vertices.
  // First and last vertex should be identical (closed polygon).
  vertices: Array<{
    lat: number;                    // Latitude (WGS84)
    lng: number;                    // Longitude (WGS84)
  }>;

  // Computed by app on save
  areaSqM: number;                  // Area in square meters
  perimeterM: number;              // Perimeter in meters

  // Metadata
  version: number;                  // Incremented on each edit (conflict resolution)
  isActive: boolean;                // Soft delete (false = hidden but recoverable)
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;                // Firebase Auth UID
}
```

**Document size estimate:**
- 3-vertex triangle: ~300 bytes
- 20-vertex property boundary: ~1.2 KB
- 100-vertex complex boundary (driven perimeter): ~5 KB
- Firestore limit is 1 MB per document. Even with 1000 vertices (~50 KB), we are well within limits.

**Sync to robot:** When the app creates or edits a zone, the robot needs the updated zone set. The app writes to Firestore; the robot either polls on reconnection or listens via Firestore snapshot listener (if connected to the internet).

---

### 3.6 `robots/{robotId}/schedules/{scheduleId}`

```typescript
// Subcollection: robots/{robotId}/schedules
// Document ID: auto-generated
// Writer: App
// Reader: App, Robot (downloads schedules on connect)
// Estimated size: ~600 bytes

interface ScheduleDocument {
  // Schedule identity
  name: string;                     // "Sunday Morning Mow"

  // Task configuration
  taskType: "mow" | "plow" | "collect";
  zoneId: string;                   // Reference to zones subcollection

  // Timing
  daysOfWeek: number[];             // [0, 3, 6] (0=Sunday, 6=Saturday)
  startTime: string;                // "08:00" (24-hour format, local time)
  timezone: string;                 // "America/New_York" (IANA timezone)

  // Task-specific parameters (polymorphic based on taskType)
  parameters: MowParameters | PlowParameters | CollectParameters;

  // State
  isEnabled: boolean;               // Toggle on/off without deleting
  weatherHold: boolean;             // Skip if weather is unfavorable
  lastExecutedAt: Timestamp | null; // Last time this schedule ran
  nextScheduledAt: Timestamp | null;// Next calculated run time

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;                // Firebase Auth UID
}

// Task-specific parameter types
interface MowParameters {
  pattern: "straight" | "diagonal" | "checker" | "spiral";
  angleDeg: number;                 // 0-180 stripe angle
  overlapPct: number;               // 0-30 pass overlap percentage
  cuttingHeightMm: number;          // 25-100 blade height in mm
}

interface PlowParameters {
  startPosition: "entrance" | "garage" | "center" | "custom";
  customStartPoint: { lat: number; lng: number } | null;
  snowDepth: "light" | "medium" | "heavy";
  disposalDirection: "left" | "right" | "pile_zone";
  pileZoneId: string | null;       // Zone ID for pile destination
}

interface CollectParameters {
  mode: "full_zone" | "spot_clean";
  spotCleanVertices: Array<{ lat: number; lng: number }> | null;
  collectionMode: "mulch" | "bag";
  dumpPoint: { lat: number; lng: number } | null;
}
```

---

### 3.7 `robots/{robotId}/commands/{commandId}`

Cloud commands are used when the app cannot reach the robot directly via BLE or WiFi. The robot polls this subcollection or listens with a Firestore snapshot listener.

```typescript
// Subcollection: robots/{robotId}/commands
// Document ID: auto-generated
// Writer: App (creates command), Robot (updates status)
// Reader: Robot (polls pending commands), App (watches status)
// Estimated size: ~400 bytes
// Retention: 7 days (Cloud Function cleanup of completed/failed commands)

interface CommandDocument {
  // Command definition
  type: "start_task" | "stop_task" | "pause_task" | "resume_task" |
        "dock" | "estop" | "clear_estop" |
        "update_firmware" | "sync_zones" | "sync_schedules";

  // Command payload (varies by type)
  payload: StartTaskPayload | StopTaskPayload | FirmwarePayload |
           Record<string, never>;   // Empty for dock, estop, clear_estop

  // Lifecycle state machine:
  //   pending -> acknowledged -> executing -> completed
  //   pending -> acknowledged -> executing -> failed
  //   pending -> expired (if not acknowledged within 5 minutes)
  status: "pending" | "acknowledged" | "executing" | "completed" |
          "failed" | "expired";

  // Error information (set by robot on failure)
  error: {
    code: string;                   // "BATTERY_TOO_LOW"
    message: string;                // "Battery at 12%, minimum 20% required"
  } | null;

  // Lifecycle timestamps
  createdAt: Timestamp;             // When app created the command
  acknowledgedAt: Timestamp | null; // When robot received it
  executingAt: Timestamp | null;    // When robot started executing
  completedAt: Timestamp | null;    // When execution finished
  expiresAt: Timestamp;            // createdAt + 5 minutes

  // Creator
  createdBy: string;                // Firebase Auth UID
}

// Payload types
interface StartTaskPayload {
  taskType: "mow" | "plow" | "collect";
  zoneId: string;
  parameters: MowParameters | PlowParameters | CollectParameters;
}

interface StopTaskPayload {
  reason: "user_requested" | "weather" | "schedule_end";
}

interface FirmwarePayload {
  firmwareId: string;               // Reference to firmware collection
  version: string;                  // "1.3.0"
  downloadUrl: string;              // Firebase Storage download URL
}
```

**Command lifecycle:**
```
App creates command         Robot polls/listens
       │                         │
       ▼                         ▼
  ┌─────────┐  snapshot     ┌─────────────┐
  │ pending  │─────────────>│acknowledged │
  └─────────┘  listener     └──────┬──────┘
       │                           │
       │ (5 min timeout)           ▼
       ▼                    ┌─────────────┐
  ┌─────────┐              │ executing   │
  │ expired │              └──────┬──────┘
  └─────────┘                     │
                          ┌───────┴───────┐
                          ▼               ▼
                   ┌───────────┐   ┌──────────┐
                   │ completed │   │  failed  │
                   └───────────┘   └──────────┘
```

**Important:** E-stop commands through Firebase are a LAST RESORT. The primary E-stop path is always BLE/WiFi direct to the robot. Firebase adds 200-2000ms latency which is unacceptable for safety-critical operations. The app sends E-stop on ALL channels simultaneously.

---

### 3.8 `robots/{robotId}/task_history/{taskId}`

```typescript
// Subcollection: robots/{robotId}/task_history
// Document ID: auto-generated
// Writer: Robot (after task completion)
// Reader: App (task history screen, analytics charts)
// Estimated size: ~800 bytes (without path), up to 50KB (with coverage path)
// Retention: 1 year

interface TaskHistoryDocument {
  // Task identity
  taskType: "mow" | "plow" | "collect";
  zoneId: string;
  zoneName: string;                 // Denormalized (zone might be renamed/deleted later)
  scheduleId: string | null;        // If triggered by schedule, null if manual

  // Execution metrics
  status: "completed" | "failed" | "cancelled" | "interrupted";
  startedAt: Timestamp;
  completedAt: Timestamp;
  durationMinutes: number;          // Total wall-clock minutes
  activeDurationMinutes: number;    // Minutes robot was actually moving (excludes pauses)

  // Coverage metrics
  areaCoveredSqM: number;           // Area actually covered
  areaTotalSqM: number;             // Total zone area
  coveragePct: number;              // areaCovered / areaTotal * 100
  distanceTraveledM: number;        // Total distance driven

  // Battery metrics
  batteryStartPct: number;          // Battery % at task start
  batteryEndPct: number;            // Battery % at task end
  batteryUsedPct: number;           // batteryStart - batteryEnd

  // Task-specific results
  taskResults: {
    // Mowing
    stripesCompleted?: number;
    cuttingHeightMm?: number;
    pattern?: string;

    // Snow
    passesCompleted?: number;
    estimatedSnowDepthMm?: number;

    // Leaf
    bagsCollected?: number;
    estimatedVolumeL?: number;
    dumpTrips?: number;
  };

  // Failure information
  failureReason: string | null;     // "obstacle_detected", "battery_critical", etc.

  // Coverage path (optional, can be large)
  // For tasks with many path points, the full path is stored in Firebase Storage
  // and only a summary is stored here.
  pathSummary: {
    pointCount: number;             // How many GPS points in the full path
    storageRef: string | null;      // "robots/{id}/coverage/{taskId}.json"
    boundingBox: {
      north: number;
      south: number;
      east: number;
      west: number;
    };
  };

  // Metadata
  createdAt: Timestamp;             // Same as completedAt (written post-completion)
}
```

**Coverage path storage:** Full GPS paths (potentially thousands of points at 1Hz over a 1-hour mow) are stored in Firebase Storage as JSON files, not in Firestore. The task history document contains only a summary with the Storage reference. This keeps the Firestore document under 1 KB while still enabling the app to download and display the full coverage map on demand.

---

### 3.9 `robots/{robotId}/battery_history/{entryId}`

```typescript
// Subcollection: robots/{robotId}/battery_history
// Document ID: date string (e.g., "2026-03-23") for deduplication
// Writer: Robot (once per day at midnight, and on charge complete)
// Reader: App (7-day battery history chart)
// Estimated size: ~300 bytes
// Retention: 90 days

interface BatteryHistoryDocument {
  date: string;                     // "2026-03-23" (ISO date)
  timestamp: Timestamp;             // Exact write time

  // End-of-day snapshot
  batteryPct: number;               // Battery % at time of write
  voltage: number;                  // Voltage (V)
  currentAmps: number;              // Current draw (A), negative = charging
  temperatureC: number;             // Battery temperature (Celsius)
  healthPct: number;                // Battery health / state of health
  cycleCount: number;               // Total charge cycles

  // Daily summary
  dailyStats: {
    minPct: number;                 // Lowest battery % during the day
    maxPct: number;                 // Highest battery % during the day
    chargeCount: number;            // Number of charge sessions
    totalRuntimeMinutes: number;    // Total active runtime
    totalChargeMinutes: number;     // Total time on charger
    energyUsedWh: number;           // Estimated energy consumed (watt-hours)
  };
}
```

**Document ID as date string:** Using the date as the document ID ensures exactly one record per day per robot, even if the robot writes multiple times. The last write wins, which is the desired behavior (most recent snapshot).

---

### 3.10 `robots/{robotId}/alerts/{alertId}`

```typescript
// Subcollection: robots/{robotId}/alerts
// Document ID: auto-generated
// Writer: Robot (on fault detection), Cloud Functions (on connection loss)
// Reader: App (diagnostics screen, dashboard recent activity)
// Estimated size: ~400 bytes
// Retention: 30 days

interface AlertDocument {
  // Alert classification
  severity: "critical" | "warning" | "info";
  category: "motor" | "blade" | "battery" | "connection" |
            "gps" | "sensor" | "system" | "safety";
  code: string;                     // "MOTOR_FL_OVERCURRENT"

  // Human-readable
  title: string;                    // "Front-Left Motor Overcurrent"
  message: string;                  // "FL motor drew 15A, threshold is 12A. Motor paused."

  // Context
  component: string;                // "motor_fl", "blade_assembly", "battery_pack"
  telemetrySnapshot: {
    batteryPct: number;
    speedMs: number;
    position: { lat: number; lng: number } | null;
    systemTempC: number;
  } | null;

  // State
  isActive: boolean;                // True until resolved
  acknowledgedAt: Timestamp | null; // When user saw it in app
  resolvedAt: Timestamp | null;     // When condition cleared

  // Metadata
  createdAt: Timestamp;
}
```

---

### 3.11 `robots/{robotId}/telemetry_snapshots/{snapshotId}`

Sampled telemetry stored in Firestore for historical queries. The full 1Hz stream goes to Realtime Database (section 4); this subcollection captures one snapshot per minute for trend analysis.

```typescript
// Subcollection: robots/{robotId}/telemetry_snapshots
// Document ID: auto-generated
// Writer: Robot (1 write per minute when active)
// Reader: App (analytics, trends, debugging)
// Estimated size: ~500 bytes
// Retention: 90 days (Cloud Function cleanup)

interface TelemetrySnapshotDocument {
  timestamp: Timestamp;

  // Battery
  batteryPct: number;
  batteryVoltage: number;
  batteryCurrentAmps: number;
  batteryTempC: number;

  // Position
  latitude: number;
  longitude: number;
  headingDeg: number;
  speedMs: number;

  // GPS quality
  rtkStatus: "fix" | "float" | "single" | "none";
  satelliteCount: number;
  positionAccuracyCm: number;

  // Motors
  motors: {
    fl: number;                     // RPM
    fr: number;
    rl: number;
    rr: number;
  };

  // System
  systemTempC: number;
  state: "idle" | "working" | "charging" | "paused" | "error" | "estop" | "docked";
  activeTaskId: string | null;
  signalStrength: number;           // 0-4 bars
}
```

**Write rate justification:** At 1 write per minute, an active robot generates 1,440 writes per day. An idle/docked robot writes once every 5 minutes (288 writes per day). This is well within Firestore free tier limits for small fleets.

---

### 3.12 `firmware/{firmwareId}`

```typescript
// Collection: firmware
// Document ID: version string (e.g., "1.3.0")
// Writer: Admin (Firebase Console or Admin SDK)
// Reader: App (firmware update screen), Robot (update check)
// Estimated size: ~1 KB

interface FirmwareDocument {
  // Version identity
  version: string;                  // "1.3.0" (semver)
  versionCode: number;              // 130 (monotonically increasing integer)
  artifactType: "robot_firmware" | "ros2_package" | "jetson_system";

  // Release information
  releaseNotes: string;             // Markdown-formatted release notes
  releaseChannel: "canary" | "beta" | "stable";
  releasedAt: Timestamp;

  // Compatibility
  minCompatibleVersion: string;     // "1.0.0" -- robots below this cannot upgrade
  targetModels: string[];           // ["CHOREROBOT-MK1", "CHOREROBOT-MK1-PRO"]

  // Artifact details
  artifact: {
    storagePath: string;            // "firmware/1.3.0/chorerobot-firmware-1.3.0.bin"
    sizeBytes: number;              // 15728640
    sha256: string;                 // Hex-encoded hash for integrity verification
  };

  // Install requirements
  preInstallChecks: {
    minBatteryPct: number;          // 50
    requiredState: string[];        // ["idle", "docked"]
    attachmentDetached: boolean;    // true
  };
  requiresReboot: boolean;
  estimatedInstallTimeSec: number;  // 120

  // Rollout state
  rolloutStage: "created" | "canary" | "partial_10" | "partial_50" |
                "full" | "halted" | "completed";
  rolloutStats: {
    totalEligible: number;
    deployed: number;
    succeeded: number;
    failed: number;
  };

  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;                // Admin UID
}
```

---

### 3.13 `weather_cache/{locationId}`

```typescript
// Collection: weather_cache
// Document ID: geohash of lat/lng at 5-character precision (~5km grid)
// Writer: Cloud Function (fetches from OpenWeatherMap)
// Reader: App, Cloud Function (schedule decision)
// Estimated size: ~2 KB
// TTL: 30 minutes (Firestore TTL policy or Cloud Function refresh)

interface WeatherCacheDocument {
  geohash: string;                  // "dr5ru"
  centerLat: number;
  centerLng: number;

  // Current conditions
  current: {
    tempC: number;
    humidity: number;               // 0-100
    windSpeedMs: number;
    condition: string;              // "clear", "rain", "snow", "thunderstorm"
    icon: string;                   // OpenWeatherMap icon code
  };

  // Hourly forecast (next 12 hours)
  hourly: Array<{
    dt: Timestamp;
    tempC: number;
    precipProbability: number;      // 0-1
    precipMm: number;
    windSpeedMs: number;
    condition: string;
  }>;

  // Schedule recommendation
  recommendation: {
    safeMow: boolean;               // True if conditions are mow-safe
    safeSnow: boolean;              // True if conditions require snow removal
    reason: string | null;          // "Rain expected at 2 PM" or null
  };

  fetchedAt: Timestamp;
  expiresAt: Timestamp;             // fetchedAt + 30 minutes
}
```

---

### 3.14 `app_config/global`

A single document for remote app configuration. Allows changing behavior without an app update.

```typescript
// Collection: app_config
// Document ID: "global" (singleton)
// Writer: Admin
// Reader: App (on launch, cached locally)
// Estimated size: ~500 bytes

interface AppConfigDocument {
  // Telemetry rates
  telemetryWriteIntervalSec: number;     // 5 (Realtime DB write interval)
  telemetrySnapshotIntervalSec: number;  // 60 (Firestore snapshot interval)

  // Command timeouts
  commandExpirationSec: number;          // 300 (5 minutes)
  estopTimeoutMs: number;                // 500

  // Feature flags
  features: {
    weatherIntegration: boolean;         // false in MVP
    multiRobot: boolean;                 // false in MVP
    spotClean: boolean;                  // true
    rtKDisplay: boolean;                 // true
  };

  // Maintenance
  maintenanceMode: boolean;              // false (show banner if true)
  maintenanceMessage: string | null;

  // Minimum app version
  minAppVersion: string;                 // "1.0.0"
  latestAppVersion: string;              // "1.2.0"
  forceUpdate: boolean;                  // false

  updatedAt: Timestamp;
}
```

---

## 4. Realtime Database -- Live Telemetry

### Why Realtime Database for Live Telemetry

| Factor | Firestore | Realtime Database |
|---|---|---|
| Billing model | Per read/write operation | Per bandwidth (GB transferred) |
| 1Hz telemetry cost | 86,400 writes/day = $0.15/day | ~10 MB/day bandwidth = free tier |
| Latency | 100-300ms | 10-50ms |
| Offline sync | Document-level | Path-level (more granular) |
| Listeners | Per-document snapshots | Per-path value events |

**Decision:** Realtime Database for the continuously-updating "latest telemetry" path. This is the data the app reads at 1-10Hz to update the dashboard, control screen, and battery screen. Firestore is too expensive per-operation for this access pattern.

### Path Structure

```
realtime-database-root/
│
├── robots/
│   └── {robotId}/
│       └── telemetry/
│           ├── battery_pct: 78                     # number
│           ├── battery_voltage: 25.4               # number
│           ├── battery_current_amps: -2.1           # number (negative = charging)
│           ├── battery_temp_c: 32.5                # number
│           ├── battery_health_pct: 94              # number
│           ├── battery_cycles: 142                 # number
│           ├── speed_ms: 0.8                       # number
│           ├── heading_deg: 127.3                  # number
│           ├── latitude: 33.6845                   # number
│           ├── longitude: -73.0472                 # number
│           ├── rtk_status: "fix"                   # string
│           ├── satellite_count: 14                 # number
│           ├── position_accuracy_cm: 2.5           # number
│           ├── motor_fl_rpm: 1200                  # number
│           ├── motor_fr_rpm: 1180                  # number
│           ├── motor_rl_rpm: 1150                  # number
│           ├── motor_rr_rpm: 1190                  # number
│           ├── system_temp_c: 45.2                 # number
│           ├── state: "working"                    # string
│           ├── active_task_id: "task_abc"           # string | null
│           ├── signal_strength: 3                  # number (0-4)
│           ├── attachment_type: "mower_blade"       # string
│           ├── timestamp: 1711200000000            # number (Unix ms)
│           └── _updated_at: 1711200000000          # number (server timestamp)
│
├── robot_status/
│   └── {robotId}/
│       ├── online: true                            # boolean
│       ├── last_heartbeat: 1711200000000           # number (Unix ms)
│       └── connection_type: "wifi"                 # "ble" | "wifi" | "cloud"
│
└── _metadata/
    └── schema_version: 1                           # number
```

### Design Decisions for Realtime Database

**Flat structure:** Each telemetry field is a top-level child under `robots/{robotId}/telemetry/`. This enables the app to listen to individual fields (e.g., only `battery_pct` on the battery screen) without downloading the entire telemetry payload. Realtime Database listeners are path-based, so `ref.child('battery_pct').onValue()` only downloads 8 bytes instead of the full ~500-byte telemetry object.

**Overwrite strategy:** The robot overwrites the entire `telemetry` node on each update. There is no history in Realtime Database -- it is a "current state" mirror only. History goes to Firestore `telemetry_snapshots` subcollection.

**Timestamp as Unix milliseconds:** Realtime Database does not have a native Timestamp type. Unix milliseconds as a number field is the standard approach.

### Write Rate and Data Size

```
Per telemetry update:
  Fields: ~25 fields
  Approximate JSON size: ~500 bytes
  Write frequency: Every 5 seconds (0.2 Hz) when robot is on cloud connection
                   (robot writes at 10Hz internally, app reads at 10Hz via BLE/WiFi,
                    only cloud-connected robots write to Realtime Database)

Per robot per day (assuming 8 hours active + 16 hours idle):
  Active:  8h * 720 writes/h = 5,760 writes * 500 bytes = 2.88 MB
  Idle:    16h * 720 writes/h = 11,520 writes * 200 bytes = 2.30 MB
  Total:   ~5.2 MB/day per robot

  (Idle telemetry is smaller because many fields are zero/unchanged)
```

### Cleanup Strategy

Realtime Database telemetry paths are ephemeral. There is no TTL built into Realtime Database, but since each write overwrites the previous value, there is only ever one document per robot. No cleanup needed. The `robot_status` node is similarly overwritten.

If a robot goes offline and never writes again, its stale data remains. A Cloud Function can run daily to scan `robot_status/` and delete entries where `last_heartbeat` is older than 30 days.

---

## 5. Firebase Storage -- Binary Assets

### Bucket Structure

```
gs://chorerobotics-app.firebasestorage.app/
│
├── firmware/
│   ├── robot_firmware/
│   │   ├── 1.0.0/
│   │   │   ├── chorerobot-firmware-1.0.0.bin       # Binary (10-50 MB)
│   │   │   └── manifest.json                       # Manifest metadata
│   │   ├── 1.1.0/
│   │   │   ├── chorerobot-firmware-1.1.0.bin
│   │   │   └── manifest.json
│   │   └── ...
│   ├── ros2_package/
│   │   └── {version}/
│   │       ├── chorerobot-ros2-{version}.deb       # Debian package (50-200 MB)
│   │       └── manifest.json
│   └── jetson_system/
│       └── {version}/
│           ├── l4t-update-{version}.tar.gz         # System update (200-500 MB)
│           └── manifest.json
│
├── robots/
│   └── {robotId}/
│       └── coverage/
│           └── {taskId}.json                       # GPS path data (10KB-5MB)
│               # Format: {"points": [{"lat":33.68,"lng":-73.04,"t":1711200000},...]}
│
└── users/
    └── {userId}/
        └── profile.jpg                             # Profile image (optional, <5MB)
```

### Storage Size Estimates

| Content | Size per Unit | Units per Robot per Month | Monthly per Robot |
|---|---|---|---|
| Firmware binaries | 50 MB | 0.5 (biweekly updates) | 25 MB |
| Coverage maps (tasks) | 500 KB avg | 30 tasks | 15 MB |
| Profile images | 500 KB | 1 per user | 0.5 MB |
| **Total** | | | **~40 MB/robot/month** |

Free tier allows 5 GB storage and 1 GB/day download. For 1-5 robots, this is sufficient. Firmware binaries are the largest items but are infrequently downloaded.

---

## 6. Security Rules -- Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // =========================================================
    // HELPER FUNCTIONS
    // =========================================================

    // Check if the request is from an authenticated user
    function isAuthenticated() {
      return request.auth != null;
    }

    // Check if the authenticated user matches the given userId
    function isUser(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Check if the authenticated user owns the robot
    // Requires reading the robot document to verify ownerId
    function isRobotOwner(robotId) {
      return isAuthenticated() &&
        get(/databases/$(database)/documents/robots/$(robotId)).data.ownerId
          == request.auth.uid;
    }

    // Check if the request is from a service account (robot)
    // Robot uses Firebase Admin SDK which sets custom claims
    function isRobotServiceAccount() {
      return isAuthenticated() &&
        request.auth.token.robot_service_account == true;
    }

    // Check if the request is from the specific robot for this data
    function isThisRobot(robotId) {
      return isRobotServiceAccount() &&
        request.auth.token.robot_serial == robotId;
    }

    // Check if the request is from an admin
    function isAdmin() {
      return isAuthenticated() &&
        request.auth.token.admin == true;
    }

    // Validate timestamp fields are server timestamps
    function isServerTimestamp(field) {
      return field == request.time;
    }

    // =========================================================
    // USERS COLLECTION
    // =========================================================

    match /users/{userId} {
      // Users can only read and write their own profile
      allow read: if isUser(userId);
      allow create: if isUser(userId) &&
        request.resource.data.keys().hasAll(['email', 'displayName', 'createdAt']) &&
        request.resource.data.email == request.auth.token.email;
      allow update: if isUser(userId) &&
        // Cannot change email or createdAt after creation
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['email', 'createdAt']);
      allow delete: if false;       // Soft delete via accountStatus field

      // FCM tokens subcollection
      match /fcm_tokens/{tokenId} {
        allow read: if isUser(userId);
        allow create, update: if isUser(userId) &&
          request.resource.data.keys().hasAll(['token', 'platform', 'deviceId']);
        allow delete: if isUser(userId);
      }

      // Notification log subcollection
      match /notification_log/{logId} {
        allow read: if isUser(userId);
        // Only Cloud Functions can write notification logs
        allow create: if isAdmin() || isRobotServiceAccount();
        allow update: if isUser(userId) &&
          // User can only update the 'read' field
          request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
        allow delete: if false;
      }
    }

    // =========================================================
    // ROBOTS COLLECTION
    // =========================================================

    match /robots/{robotId} {
      // Owner can read robot data
      allow read: if isRobotOwner(robotId) || isThisRobot(robotId) || isAdmin();

      // Owner can create robot during pairing
      allow create: if isAuthenticated() &&
        request.resource.data.ownerId == request.auth.uid &&
        request.resource.data.keys().hasAll([
          'serialNumber', 'model', 'ownerId', 'name', 'pairedAt', 'status'
        ]);

      // Owner can update certain fields (rename, dock location, wifi config)
      allow update: if isRobotOwner(robotId) &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'name', 'dockLocation', 'wifiConfig', 'updatedAt'
        ]);

      // Robot service account can update its own operational fields
      allow update: if isThisRobot(robotId) &&
        request.resource.data.diff(resource.data).affectedKeys().hasOnly([
          'status', 'firmwareVersion', 'lastSeenAt', 'lastKnownPosition',
          'attachment', 'updatedAt'
        ]);

      // Robots cannot be deleted from the app
      allow delete: if isAdmin();

      // ---------------------------------------------------------
      // ZONES SUBCOLLECTION
      // ---------------------------------------------------------
      match /zones/{zoneId} {
        allow read: if isRobotOwner(robotId) || isThisRobot(robotId);
        allow create: if isRobotOwner(robotId) &&
          request.resource.data.keys().hasAll([
            'name', 'type', 'vertices', 'areaSqM', 'version',
            'isActive', 'createdAt', 'updatedAt', 'createdBy'
          ]) &&
          request.resource.data.type in ['mow', 'snow', 'leaf', 'no_go'] &&
          request.resource.data.vertices.size() >= 3 &&
          request.resource.data.vertices.size() <= 1000;
        allow update: if isRobotOwner(robotId) &&
          // Version must increment
          request.resource.data.version == resource.data.version + 1;
        allow delete: if isRobotOwner(robotId);
      }

      // ---------------------------------------------------------
      // SCHEDULES SUBCOLLECTION
      // ---------------------------------------------------------
      match /schedules/{scheduleId} {
        allow read: if isRobotOwner(robotId) || isThisRobot(robotId);
        allow create, update: if isRobotOwner(robotId) &&
          request.resource.data.keys().hasAll([
            'name', 'taskType', 'zoneId', 'daysOfWeek', 'startTime',
            'timezone', 'isEnabled', 'createdAt', 'updatedAt'
          ]) &&
          request.resource.data.taskType in ['mow', 'plow', 'collect'] &&
          request.resource.data.daysOfWeek.size() >= 1 &&
          request.resource.data.daysOfWeek.size() <= 7;
        allow delete: if isRobotOwner(robotId);
      }

      // ---------------------------------------------------------
      // COMMANDS SUBCOLLECTION
      // ---------------------------------------------------------
      match /commands/{commandId} {
        // Owner and robot can read commands
        allow read: if isRobotOwner(robotId) || isThisRobot(robotId);

        // Only the owner (app) can create commands
        allow create: if isRobotOwner(robotId) &&
          request.resource.data.status == 'pending' &&
          request.resource.data.keys().hasAll([
            'type', 'status', 'createdAt', 'expiresAt', 'createdBy'
          ]);

        // Only the robot can update command status
        allow update: if isThisRobot(robotId) &&
          request.resource.data.diff(resource.data).affectedKeys().hasOnly([
            'status', 'acknowledgedAt', 'executingAt', 'completedAt', 'error'
          ]) &&
          // Valid status transitions only
          (
            (resource.data.status == 'pending' &&
              request.resource.data.status == 'acknowledged') ||
            (resource.data.status == 'acknowledged' &&
              request.resource.data.status == 'executing') ||
            (resource.data.status == 'executing' &&
              request.resource.data.status in ['completed', 'failed'])
          );

        allow delete: if false;     // Commands are never deleted by clients
      }

      // ---------------------------------------------------------
      // TASK HISTORY SUBCOLLECTION
      // ---------------------------------------------------------
      match /task_history/{taskId} {
        allow read: if isRobotOwner(robotId);

        // Only robot can write task history
        allow create: if isThisRobot(robotId) &&
          request.resource.data.keys().hasAll([
            'taskType', 'zoneId', 'status', 'startedAt', 'completedAt',
            'durationMinutes', 'areaCoveredSqM', 'batteryUsedPct', 'createdAt'
          ]);

        // Task history is immutable once written
        allow update: if false;
        allow delete: if false;
      }

      // ---------------------------------------------------------
      // BATTERY HISTORY SUBCOLLECTION
      // ---------------------------------------------------------
      match /battery_history/{entryId} {
        allow read: if isRobotOwner(robotId);
        allow create, update: if isThisRobot(robotId);
        allow delete: if false;
      }

      // ---------------------------------------------------------
      // ALERTS SUBCOLLECTION
      // ---------------------------------------------------------
      match /alerts/{alertId} {
        allow read: if isRobotOwner(robotId);

        // Robot can create alerts
        allow create: if isThisRobot(robotId) &&
          request.resource.data.severity in ['critical', 'warning', 'info'];

        // Owner can acknowledge alerts
        allow update: if isRobotOwner(robotId) &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['acknowledgedAt']);

        // Robot can resolve alerts
        allow update: if isThisRobot(robotId) &&
          request.resource.data.diff(resource.data).affectedKeys()
            .hasOnly(['isActive', 'resolvedAt']);

        allow delete: if false;
      }

      // ---------------------------------------------------------
      // TELEMETRY SNAPSHOTS SUBCOLLECTION
      // ---------------------------------------------------------
      match /telemetry_snapshots/{snapshotId} {
        allow read: if isRobotOwner(robotId);
        allow create: if isThisRobot(robotId);
        allow update, delete: if false;  // Immutable, append-only
      }
    }

    // =========================================================
    // FIRMWARE COLLECTION
    // =========================================================

    match /firmware/{firmwareId} {
      // Any authenticated user can read firmware metadata
      // (robot checks for updates, app shows available updates)
      allow read: if isAuthenticated() || isRobotServiceAccount();

      // Only admin can write firmware records
      allow create, update: if isAdmin();
      allow delete: if isAdmin();
    }

    // =========================================================
    // WEATHER CACHE COLLECTION
    // =========================================================

    match /weather_cache/{locationId} {
      // Any authenticated user can read cached weather
      allow read: if isAuthenticated();
      // Only Cloud Functions (admin) can write weather data
      allow write: if isAdmin();
    }

    // =========================================================
    // APP CONFIG COLLECTION
    // =========================================================

    match /app_config/{configId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // =========================================================
    // DEFAULT: DENY EVERYTHING ELSE
    // =========================================================

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 7. Security Rules -- Realtime Database

```json
{
  "rules": {
    "robots": {
      "$robotId": {
        "telemetry": {
          // Robot can write its own telemetry
          // App owner can read telemetry
          ".read": "auth != null && (
            root.child('_robot_owners').child($robotId).val() === auth.uid ||
            auth.token.robot_serial === $robotId ||
            auth.token.admin === true
          )",
          ".write": "auth != null && (
            auth.token.robot_serial === $robotId ||
            auth.token.admin === true
          )",
          // Validate telemetry structure
          ".validate": "newData.hasChildren(['battery_pct', 'timestamp'])",
          "battery_pct": {
            ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 100"
          },
          "speed_ms": {
            ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 10"
          },
          "heading_deg": {
            ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() < 360"
          },
          "state": {
            ".validate": "newData.isString() && newData.val().matches(/^(idle|working|charging|paused|error|estop|docked)$/)"
          },
          "signal_strength": {
            ".validate": "newData.isNumber() && newData.val() >= 0 && newData.val() <= 4"
          },
          "timestamp": {
            ".validate": "newData.isNumber()"
          }
        }
      }
    },
    "robot_status": {
      "$robotId": {
        ".read": "auth != null && (
          root.child('_robot_owners').child($robotId).val() === auth.uid ||
          auth.token.robot_serial === $robotId ||
          auth.token.admin === true
        )",
        ".write": "auth != null && (
          auth.token.robot_serial === $robotId ||
          auth.token.admin === true
        )"
      }
    },
    "_robot_owners": {
      // Lookup table mapping robotId -> ownerId for Realtime DB auth checks
      // Written by Cloud Function when robot is paired in Firestore
      ".read": "auth != null",
      ".write": "auth != null && auth.token.admin === true",
      "$robotId": {
        ".validate": "newData.isString()"
      }
    },
    "_metadata": {
      ".read": "auth != null",
      ".write": "auth != null && auth.token.admin === true"
    }
  }
}
```

**Implementation note:** The `_robot_owners` node is a denormalized lookup table. When a robot is paired in Firestore (`robots/{robotId}.ownerId` is set), a Cloud Function writes `_robot_owners/{robotId}: userId` in Realtime Database. This avoids Realtime Database rules needing to query Firestore (which is not possible in Realtime Database rules).

---

## 8. Security Rules -- Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // =========================================================
    // FIRMWARE BINARIES
    // =========================================================

    match /firmware/{artifactType}/{version}/{fileName} {
      // Any authenticated user or robot can download firmware
      allow read: if request.auth != null;
      // Only admin can upload firmware
      allow write: if request.auth != null && request.auth.token.admin == true;
    }

    // =========================================================
    // ROBOT COVERAGE MAPS
    // =========================================================

    match /robots/{robotId}/coverage/{fileName} {
      // Owner can read coverage maps
      allow read: if request.auth != null && (
        // Check is done via custom claims for performance
        // (cannot query Firestore from Storage rules)
        request.auth.token.admin == true ||
        request.auth.token.robot_serial == robotId
      );
      // Robot can write coverage maps
      allow write: if request.auth != null && (
        request.auth.token.robot_serial == robotId ||
        request.auth.token.admin == true
      ) && request.resource.size < 10 * 1024 * 1024;  // Max 10 MB per file
    }

    // For owner reads, we use signed URLs generated by Cloud Functions
    // rather than direct Storage rules, because Storage rules cannot
    // look up Firestore data.

    // =========================================================
    // USER PROFILE IMAGES
    // =========================================================

    match /users/{userId}/profile.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.uid == userId &&
        request.resource.size < 5 * 1024 * 1024 &&    // Max 5 MB
        request.resource.contentType.matches('image/.*');
    }

    // =========================================================
    // DEFAULT: DENY EVERYTHING ELSE
    // =========================================================

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 9. Cloud Functions

### Functions Overview

```
functions/
├── auth/
│   ├── onUserCreate.ts            # Initialize user document in Firestore
│   └── onUserDelete.ts            # Cleanup user data
│
├── robots/
│   ├── onRobotPair.ts             # Sync owner to Realtime DB _robot_owners
│   ├── onRobotOffline.ts          # Detect offline robots, send notifications
│   └── onCommandExpire.ts         # Expire stale pending commands
│
├── notifications/
│   ├── sendPushNotification.ts    # Callable: send push to user's devices
│   ├── onAlertCreate.ts           # Trigger: send push on critical/warning alert
│   └── onTaskComplete.ts          # Trigger: send push on task completion
│
├── telemetry/
│   └── cleanupOldSnapshots.ts     # Scheduled: delete snapshots older than 90 days
│
├── weather/
│   └── refreshWeatherCache.ts     # Scheduled: refresh weather for active robots
│
├── firmware/
│   └── generateDownloadUrl.ts     # Callable: generate signed URL for firmware
│
└── cleanup/
    ├── cleanupCommands.ts         # Scheduled: delete completed commands older than 7 days
    ├── cleanupAlerts.ts           # Scheduled: delete resolved alerts older than 30 days
    ├── cleanupBatteryHistory.ts   # Scheduled: delete battery entries older than 90 days
    └── cleanupNotificationLog.ts  # Scheduled: delete read notifications older than 90 days
```

### Key Function Implementations

#### `onRobotPair` -- Sync Robot Ownership to Realtime Database

```typescript
// Triggered when robots/{robotId} is created or ownerId changes
// Syncs the ownerId to Realtime Database _robot_owners/{robotId}
// so Realtime Database security rules can verify ownership.

import * as functions from 'firebase-functions/v2';
import { getDatabase } from 'firebase-admin/database';

export const onRobotPair = functions.firestore.onDocumentWritten(
  'robots/{robotId}',
  async (event) => {
    const robotId = event.params.robotId;
    const afterData = event.data?.after?.data();

    if (!afterData) {
      // Robot document deleted -- remove from RTDB lookup
      await getDatabase().ref(`_robot_owners/${robotId}`).remove();
      return;
    }

    const ownerId = afterData.ownerId;
    if (ownerId) {
      await getDatabase().ref(`_robot_owners/${robotId}`).set(ownerId);
    }
  }
);
```

#### `onAlertCreate` -- Send Push on Critical Alert

```typescript
// Triggered when a new alert is created in robots/{robotId}/alerts/{alertId}
// Sends push notification to the robot owner if severity is critical or warning.

import * as functions from 'firebase-functions/v2';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

export const onAlertCreate = functions.firestore.onDocumentCreated(
  'robots/{robotId}/alerts/{alertId}',
  async (event) => {
    const alertData = event.data?.data();
    if (!alertData || alertData.severity === 'info') return;

    const robotId = event.params.robotId;
    const db = getFirestore();

    // Get robot owner
    const robotDoc = await db.collection('robots').doc(robotId).get();
    const ownerId = robotDoc.data()?.ownerId;
    if (!ownerId) return;

    // Check user notification preferences
    const userDoc = await db.collection('users').doc(ownerId).get();
    const prefs = userDoc.data()?.notifications;
    if (!prefs?.taskError) return;

    // Get FCM tokens
    const tokensSnapshot = await db
      .collection('users').doc(ownerId)
      .collection('fcm_tokens').get();

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
    if (tokens.length === 0) return;

    // Send notification
    const message = {
      notification: {
        title: alertData.title,
        body: alertData.message,
      },
      data: {
        type: 'alert',
        robotId: robotId,
        alertId: event.params.alertId,
        severity: alertData.severity,
        route: '/more/diagnostics',
      },
      tokens: tokens,
    };

    const response = await getMessaging().sendEachForMulticast(message);

    // Clean up invalid tokens
    response.responses.forEach((resp, idx) => {
      if (resp.error?.code === 'messaging/registration-token-not-registered') {
        tokensSnapshot.docs[idx].ref.delete();
      }
    });

    // Log notification
    await db.collection('users').doc(ownerId)
      .collection('notification_log').add({
        type: 'task_error',
        title: alertData.title,
        body: alertData.message,
        robotId: robotId,
        data: { route: '/more/diagnostics' },
        read: false,
        createdAt: new Date(),
      });
  }
);
```

#### `cleanupCommands` -- Scheduled Cleanup

```typescript
// Runs every hour. Deletes completed/failed/expired commands older than 7 days.
// Also expires pending commands older than 5 minutes.

import * as functions from 'firebase-functions/v2';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';

export const cleanupCommands = functions.scheduler.onSchedule(
  'every 60 minutes',
  async () => {
    const db = getFirestore();
    const now = Timestamp.now();
    const sevenDaysAgo = Timestamp.fromMillis(
      now.toMillis() - 7 * 24 * 60 * 60 * 1000
    );
    const fiveMinutesAgo = Timestamp.fromMillis(
      now.toMillis() - 5 * 60 * 1000
    );

    // Get all robots
    const robotsSnapshot = await db.collection('robots').get();

    for (const robotDoc of robotsSnapshot.docs) {
      const robotId = robotDoc.id;

      // Delete old completed/failed commands
      const oldCommands = await db
        .collection('robots').doc(robotId)
        .collection('commands')
        .where('status', 'in', ['completed', 'failed', 'expired'])
        .where('createdAt', '<', sevenDaysAgo)
        .limit(100)
        .get();

      const batch1 = db.batch();
      oldCommands.docs.forEach(doc => batch1.delete(doc.ref));
      if (!oldCommands.empty) await batch1.commit();

      // Expire stale pending commands
      const staleCommands = await db
        .collection('robots').doc(robotId)
        .collection('commands')
        .where('status', '==', 'pending')
        .where('expiresAt', '<', now)
        .limit(100)
        .get();

      const batch2 = db.batch();
      staleCommands.docs.forEach(doc => {
        batch2.update(doc.ref, { status: 'expired' });
      });
      if (!staleCommands.empty) await batch2.commit();
    }
  }
);
```

### Robot Authentication Strategy

The robot (Jetson Nano running Python) uses Firebase Admin SDK with a service account. To enforce per-robot authorization (robot A cannot write to robot B's data), we use **custom authentication tokens** with custom claims:

```python
# Robot-side: generate custom token on boot
# The robot's service account JSON is provisioned during manufacturing.

import firebase_admin
from firebase_admin import credentials, auth, firestore, db as rtdb

cred = credentials.Certificate('/etc/chorerobot/firebase-service-account.json')
app = firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://chorerobotics-app-default-rtdb.firebaseio.com',
    'storageBucket': 'chorerobotics-app.firebasestorage.app'
})

# The robot serial number is stored on the device during manufacturing
ROBOT_SERIAL = "CR-MK1-00001"

# For Firestore: Admin SDK bypasses security rules entirely.
# For Realtime Database: We create a custom token with claims.
#
# APPROACH: The robot uses the Admin SDK for Firestore writes
# (Admin SDK has full access, but the robot code is trusted and
#  only writes to its own paths).
# For Realtime Database, we mint a custom token with the robot_serial claim.

custom_token = auth.create_custom_token(
    uid=f"robot_{ROBOT_SERIAL}",
    developer_claims={
        'robot_service_account': True,
        'robot_serial': ROBOT_SERIAL
    }
)

# Initialize Realtime Database client with custom token
# (In production, use the REST API with the custom token)
```

**Security tradeoff acknowledgment:** The Firebase Admin SDK bypasses all Firestore security rules. The robot code is trusted software running on hardware we control, so this is acceptable for MVP. In production (Go + PostgreSQL), every robot request is authenticated via mTLS and authorized per-endpoint. The Firebase security rules are primarily defense against a compromised or misbehaving app, not against a compromised robot.

---

## 10. Indexes

### Composite Indexes Required

Firestore automatically creates single-field indexes. Composite indexes must be explicitly defined for queries that filter/sort on multiple fields.

```
// firestore.indexes.json

{
  "indexes": [
    // ─── COMMANDS ───
    // Query: Get pending commands for a robot, ordered by creation time
    {
      "collectionGroup": "commands",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    },
    // Query: Get expired commands by expiration time
    {
      "collectionGroup": "commands",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "expiresAt", "order": "ASCENDING" }
      ]
    },

    // ─── TASK HISTORY ───
    // Query: Get task history by type, ordered by date
    {
      "collectionGroup": "task_history",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "taskType", "order": "ASCENDING" },
        { "fieldPath": "startedAt", "order": "DESCENDING" }
      ]
    },
    // Query: Get task history by status, ordered by date
    {
      "collectionGroup": "task_history",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startedAt", "order": "DESCENDING" }
      ]
    },
    // Query: Get task history by zone, ordered by date
    {
      "collectionGroup": "task_history",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "zoneId", "order": "ASCENDING" },
        { "fieldPath": "startedAt", "order": "DESCENDING" }
      ]
    },

    // ─── ALERTS ───
    // Query: Get active alerts ordered by severity and time
    {
      "collectionGroup": "alerts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "severity", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    // Query: Get alerts by category
    {
      "collectionGroup": "alerts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // ─── TELEMETRY SNAPSHOTS ───
    // Query: Get snapshots in time range
    {
      "collectionGroup": "telemetry_snapshots",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },

    // ─── BATTERY HISTORY ───
    // Query: Get battery history ordered by date
    {
      "collectionGroup": "battery_history",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },

    // ─── SCHEDULES ───
    // Query: Get enabled schedules
    {
      "collectionGroup": "schedules",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isEnabled", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "ASCENDING" }
      ]
    },

    // ─── NOTIFICATION LOG ───
    // Query: Get unread notifications, most recent first
    {
      "collectionGroup": "notification_log",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "read", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // ─── ZONES ───
    // Query: Get active zones by type
    {
      "collectionGroup": "zones",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "type", "order": "ASCENDING" }
      ]
    },

    // ─── FIRMWARE ───
    // Query: Get firmware by artifact type and channel, latest first
    {
      "collectionGroup": "firmware",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "artifactType", "order": "ASCENDING" },
        { "fieldPath": "releaseChannel", "order": "ASCENDING" },
        { "fieldPath": "versionCode", "order": "DESCENDING" }
      ]
    }
  ],

  "fieldOverrides": [
    // Disable indexing on large fields that are never queried
    {
      "collectionGroup": "zones",
      "fieldPath": "vertices",
      "indexes": []
    },
    {
      "collectionGroup": "task_history",
      "fieldPath": "taskResults",
      "indexes": []
    },
    {
      "collectionGroup": "telemetry_snapshots",
      "fieldPath": "motors",
      "indexes": []
    },
    {
      "collectionGroup": "firmware",
      "fieldPath": "artifact",
      "indexes": []
    }
  ]
}
```

---

## 11. Data Sync Strategy

### Flow Diagrams

#### App <-> Firebase (Always When Online)

```
┌──────────────┐                              ┌──────────────────┐
│  FLUTTER APP │                              │    FIREBASE      │
│              │   Firestore SDK (cached)     │                  │
│              │◄════════════════════════════►│  Firestore       │
│              │   Automatic offline sync     │                  │
│              │   Snapshot listeners          │                  │
│              │                              │                  │
│              │   Realtime DB SDK            │                  │
│              │◄════════════════════════════►│  Realtime DB     │
│              │   .onValue() listener        │  (telemetry)     │
│              │                              │                  │
│              │   Firebase Auth SDK          │                  │
│              │◄════════════════════════════►│  Auth            │
│              │                              │                  │
└──────────────┘                              └──────────────────┘

READS (App ← Firebase):
  - Dashboard opens      → listen robots/{id} + RTDB telemetry
  - Battery screen       → listen RTDB telemetry (battery fields only)
  - Map screen           → get robots/{id}/zones (cached after first read)
  - Schedule screen      → get robots/{id}/schedules
  - History screen       → query robots/{id}/task_history (paginated)
  - Diagnostics          → query robots/{id}/alerts (active first)
  - Firmware screen      → query firmware collection
  - Settings             → get users/{uid}

WRITES (App → Firebase):
  - Sign up              → create users/{uid}
  - Update settings      → update users/{uid}
  - Pair robot           → create robots/{serialNumber}
  - Rename robot         → update robots/{id}.name
  - Create zone          → create robots/{id}/zones/{zoneId}
  - Edit zone            → update robots/{id}/zones/{zoneId}
  - Delete zone          → delete robots/{id}/zones/{zoneId}
  - Create schedule      → create robots/{id}/schedules/{scheduleId}
  - Send cloud command   → create robots/{id}/commands/{commandId}
  - Register FCM token   → create users/{uid}/fcm_tokens/{tokenId}
  - Acknowledge alert    → update robots/{id}/alerts/{alertId}
```

#### Robot -> Firebase (Upload)

```
┌──────────────────┐                          ┌──────────────────┐
│  ROBOT (Jetson)  │                          │    FIREBASE      │
│                  │   Admin SDK (Python)     │                  │
│                  │                          │                  │
│  Telemetry loop  │                          │                  │
│  (every 5 sec)   │─────────────────────────►│  Realtime DB     │
│                  │   Set telemetry path     │  robots/{id}/    │
│                  │                          │  telemetry       │
│                  │                          │                  │
│  Snapshot loop   │                          │                  │
│  (every 1 min)   │─────────────────────────►│  Firestore       │
│                  │   Add to subcollection   │  telemetry_      │
│                  │                          │  snapshots       │
│                  │                          │                  │
│  Task complete   │─────────────────────────►│  Firestore       │
│                  │   Add to subcollection   │  task_history    │
│                  │                          │                  │
│  Daily battery   │─────────────────────────►│  Firestore       │
│                  │   Set (date as doc ID)   │  battery_history │
│                  │                          │                  │
│  Fault detected  │─────────────────────────►│  Firestore       │
│                  │   Add to subcollection   │  alerts          │
│                  │                          │                  │
│  Status change   │─────────────────────────►│  Firestore       │
│                  │   Update robot document  │  robots/{id}     │
│                  │                          │  (status field)  │
│                  │                          │                  │
│  Heartbeat       │─────────────────────────►│  Realtime DB     │
│  (every 30 sec)  │   Set robot_status path  │  robot_status/   │
│                  │                          │  {id}            │
│                  │                          │                  │
│  Coverage path   │─────────────────────────►│  Storage         │
│  (on task end)   │   Upload JSON file       │  robots/{id}/    │
│                  │                          │  coverage/       │
│                  │                          │                  │
└──────────────────┘                          └──────────────────┘
```

#### Firebase -> Robot (Download)

```
┌──────────────────┐                          ┌──────────────────┐
│  ROBOT (Jetson)  │                          │    FIREBASE      │
│                  │   Firestore listeners    │                  │
│                  │                          │                  │
│  Zone sync       │◄─────────────────────────│  Firestore       │
│  (on connect +   │   Snapshot listener on   │  robots/{id}/    │
│   on change)     │   zones subcollection    │  zones           │
│                  │                          │                  │
│  Schedule sync   │◄─────────────────────────│  Firestore       │
│  (on connect +   │   Snapshot listener on   │  robots/{id}/    │
│   on change)     │   schedules subcollection│  schedules       │
│                  │                          │                  │
│  Command listen  │◄─────────────────────────│  Firestore       │
│  (continuous)    │   Query: status==pending │  robots/{id}/    │
│                  │                          │  commands        │
│                  │                          │                  │
│  Firmware check  │◄─────────────────────────│  Firestore       │
│  (every 6 hours) │   Query: latest version  │  firmware        │
│                  │                          │                  │
│  Firmware DL     │◄─────────────────────────│  Storage         │
│  (on OTA trigger)│   Download binary        │  firmware/       │
│                  │                          │  {version}/      │
│                  │                          │                  │
└──────────────────┘                          └──────────────────┘
```

#### App <-> Robot (Direct -- Bypasses Firebase)

```
┌──────────────┐                              ┌──────────────────┐
│  FLUTTER APP │                              │  ROBOT (Jetson)  │
│              │   BLE (flutter_blue_plus)    │                  │
│              │◄════════════════════════════►│  BLE GATT Server │
│  Joystick    │   30Hz write, 10Hz read     │                  │
│  Telemetry   │   Lowest latency            │                  │
│  E-Stop      │   No internet required      │                  │
│  Manual ctrl │                              │                  │
│              │   WiFi WebSocket             │                  │
│              │◄════════════════════════════►│  WebSocket Server│
│  Same as BLE │   Bidirectional, low latency│  (port 8765)     │
│  + zone sync │   Robot's local IP/mDNS     │                  │
│  + schedules │                              │                  │
│              │                              │                  │
└──────────────┘                              └──────────────────┘

LOCAL-ONLY DATA (never touches Firebase during local operation):
  - Joystick drive commands (30Hz velocity + heading)
  - Live telemetry stream (10Hz sensor data)
  - E-Stop command (immediate, multi-channel)
  - Blade on/off toggle
  - Manual/auto mode switch
  - Boundary recording GPS breadcrumbs
  - Motor speed readings
  - Compass heading
```

### Conflict Resolution Strategy

| Scenario | Strategy |
|---|---|
| App and robot both online, app edits zone | App writes to Firestore. Robot's Firestore listener receives update. Last write wins. |
| App offline, edits zone, comes back online | Firestore SDK queues the write. On reconnect, the write is applied. Last-write-wins. Zone version field detects stale edits. |
| Two app instances edit same zone | Version field in zone document. Update requires `version == current + 1`. Second write fails, app re-fetches and retries. |
| Robot reports telemetry while app is offline | Realtime DB stores latest state. When app reconnects, listener fires with current value. No conflict -- telemetry is always overwritten. |
| Schedule created while robot is offline | Schedule is stored in Firestore. When robot reconnects, its Firestore listener fires and downloads the new schedule. |

---

## 12. Offline Strategy

### Scenario Matrix

```
┌────────────────────────────────────────────────────────────────────────┐
│                      OFFLINE SCENARIO MATRIX                            │
├──────────────────┬─────────────┬────────────────────────────────────────┤
│ SCENARIO         │ AVAILABLE   │ BEHAVIOR                              │
├──────────────────┼─────────────┼────────────────────────────────────────┤
│                  │             │                                        │
│ 1. App has       │ BLE + WiFi  │ FULL FUNCTIONALITY                     │
│    internet +    │ + Internet  │ - Real-time control via BLE/WiFi       │
│    local robot   │ + Firebase  │ - Firebase sync for persistence        │
│                  │             │ - Best case scenario                   │
│                  │             │                                        │
├──────────────────┼─────────────┼────────────────────────────────────────┤
│                  │             │                                        │
│ 2. App has       │ BLE or WiFi │ OPERATIONAL, NO CLOUD SYNC             │
│    NO internet   │ only        │ - Full manual control via BLE/WiFi     │
│    but has       │             │ - Telemetry streaming works            │
│    BLE/WiFi      │             │ - Boundary recording works             │
│    to robot      │             │ - Zones cached locally (Hive/drift)    │
│                  │             │ - Schedules cached locally             │
│                  │             │ - NO cloud commands, history, updates  │
│                  │             │ - Firestore SDK queues writes          │
│                  │             │ - On reconnect: queued writes sync     │
│                  │             │                                        │
├──────────────────┼─────────────┼────────────────────────────────────────┤
│                  │             │                                        │
│ 3. App has       │ Internet    │ CLOUD-ONLY MODE                        │
│    internet but  │ + Firebase  │ - Dashboard shows last-known state     │
│    NO BLE/WiFi   │ only        │ - Cloud commands (start/stop/dock)     │
│    to robot      │             │ - No joystick (too high latency)       │
│                  │             │ - No blade control (safety)            │
│                  │             │ - Telemetry via Realtime DB (5s delay) │
│                  │             │ - Zone/schedule editing works          │
│                  │             │ - Firmware updates work                │
│                  │             │ - Task history available               │
│                  │             │                                        │
├──────────────────┼─────────────┼────────────────────────────────────────┤
│                  │             │                                        │
│ 4. App has       │ Nothing     │ READ-ONLY CACHED MODE                  │
│    NO internet   │ (offline    │ - Show cached dashboard from Hive      │
│    and NO        │  app)       │ - Show cached zones (last known)       │
│    BLE/WiFi      │             │ - Show cached schedules                │
│                  │             │ - Show "Offline" connection status     │
│                  │             │ - NO control, NO telemetry             │
│                  │             │ - Retry connection every 5 seconds     │
│                  │             │                                        │
├──────────────────┼─────────────┼────────────────────────────────────────┤
│                  │             │                                        │
│ 5. Robot has     │ Local only  │ ROBOT AUTONOMOUS MODE                  │
│    NO internet   │ (BLE/WiFi   │ - Robot executes cached schedules      │
│    at all        │  to app)    │ - Robot uses locally stored zones      │
│                  │             │ - App controls robot via BLE/WiFi      │
│                  │             │ - Robot buffers telemetry history       │
│                  │             │ - On internet restore: robot uploads   │
│                  │             │   buffered task_history and telemetry   │
│                  │             │   to Firebase                          │
│                  │             │                                        │
├──────────────────┼─────────────┼────────────────────────────────────────┤
│                  │             │                                        │
│ 6. Robot has     │ Robot       │ ROBOT FULLY AUTONOMOUS                 │
│    NO internet   │ standalone  │ - Executes cached schedules            │
│    and NO app    │             │ - Uses cached zones                    │
│                  │             │ - Stores task history locally           │
│                  │             │ - Safety: returns to dock on errors    │
│                  │             │ - On any connection restore: uploads    │
│                  │             │   all buffered data                    │
│                  │             │                                        │
└──────────────────┴─────────────┴────────────────────────────────────────┘
```

### Firestore Offline Persistence Configuration

```dart
// main.dart -- Enable Firestore offline persistence

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> configureFirestore() async {
  // Firestore offline persistence is enabled by default on mobile.
  // Configure cache size (default is 100 MB, we reduce to 40 MB).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,         // Default: true on mobile
    cacheSizeBytes: 40 * 1024 * 1024, // 40 MB local cache
  );
}
```

### Local Cache Strategy (Hive)

The app maintains a Hive cache independent of Firestore's offline cache. This is for:
1. Data that comes from the robot directly (not through Firebase)
2. Faster reads than Firestore cache on app launch
3. Offline-first display before Firestore SDK initializes

```dart
// Hive boxes for local caching

enum HiveBoxes {
  robot,          // Robot config (name, serial, model, firmware version)
  zones,          // Zone polygons (synced from Firestore + updated via BLE/WiFi)
  schedules,      // Schedules (synced from Firestore)
  telemetry,      // Last-known telemetry (for offline dashboard)
  settings,       // User settings (synced from Firestore)
  presets,        // Saved task presets (Phase 2)
  history,        // Recent task history (last 20 items for offline viewing)
}
```

---

## 13. Cost Optimization

### Firestore Operations Estimate

#### Per Robot Per Day

| Operation | Writes/Day | Reads/Day | Notes |
|---|---|---|---|
| **Telemetry snapshots** | 1,440 (active: 1/min for 24h) | 100 (app opens battery/analytics) | Reduce to 288 if idle 16h (1/5min when idle) |
| **Robot status updates** | 48 (avg 1 state change every 30 min) | 50 (app opens dashboard) | Mostly idle: ~10/day |
| **Battery history** | 1-3 (daily + charge events) | 7 (7-day chart on battery screen) | Document ID dedup prevents over-writes |
| **Task history** | 1-5 (per completed task) | 20 (history screen + analytics) | Varies by usage |
| **Alerts** | 0-10 (depends on faults) | 20 (diagnostics screen) | Usually 0 for healthy robot |
| **Zones** | 0-2 (user editing zones) | 10 (map screen opens) | Cached after first read |
| **Schedules** | 0-2 (user editing schedules) | 5 (schedule screen opens) | Cached after first read |
| **Commands** | 2-10 (cloud commands) | 10 (status polling) | Only when no local connection |
| **User document** | 0-1 (settings changes) | 5 (app opens) | Heavily cached |
| **Firmware check** | 0 | 1-4 (periodic check) | Robot checks every 6 hours |
| **App config** | 0 | 1 (app launch) | Cached |
| **FCM tokens** | 0-1 (token refresh) | 0 (only read by Cloud Functions) | |
| **TOTAL** | **~1,500 - 1,800** | **~230 - 350** | |

#### Fleet Size Projections

| Robots | Writes/Day | Reads/Day | Write Cost | Read Cost | Total/Day | Total/Month |
|---|---|---|---|---|---|---|
| **1** | 1,800 | 350 | $0.003 | $0.0001 | $0.003 | **$0.09** |
| **5** | 9,000 | 1,750 | $0.016 | $0.0006 | $0.017 | **$0.50** |
| **10** | 18,000 | 3,500 | $0.032 | $0.001 | $0.033 | **$1.00** |
| **50** | 90,000 | 17,500 | $0.16 | $0.006 | $0.17 | **$5.00** |
| **100** | 180,000 | 35,000 | $0.32 | $0.013 | $0.33 | **$10.00** |
| **500** | 900,000 | 175,000 | $1.62 | $0.06 | $1.68 | **$50.00** |

**Pricing used:** Firestore $0.18 per 100K writes, $0.06 per 100K reads (us-central1).

### Realtime Database Bandwidth Estimate

| Robots | Data/Day | Cost/Day | Cost/Month |
|---|---|---|---|
| **1** | 5.2 MB | Free (10 GB/month free) | **$0.00** |
| **5** | 26 MB | Free | **$0.00** |
| **10** | 52 MB | Free | **$0.00** |
| **50** | 260 MB | Free (7.8 GB/month) | **$0.00** |
| **100** | 520 MB | $0.13/day (15.6 GB, 5.6 over free) | **$3.90** |
| **500** | 2.6 GB | $2.16/day | **$64.80** |

**Pricing used:** Realtime Database: 10 GB/month free, $1/GB after.

### Storage Estimate

| Content | 1 Robot | 10 Robots | 100 Robots |
|---|---|---|---|
| Firmware binaries (shared) | 500 MB | 500 MB | 500 MB |
| Coverage maps | 15 MB/mo | 150 MB/mo | 1.5 GB/mo |
| Profile images | 0.5 MB | 5 MB | 50 MB |
| **Total** | **515 MB** | **655 MB** | **2 GB** |

Free tier: 5 GB storage, 1 GB/day download. Sufficient through ~50 robots.

### Cloud Functions Estimate

| Function | Invocations/Day (1 Robot) | Invocations/Day (100 Robots) |
|---|---|---|
| onRobotPair | <1 | <5 |
| onAlertCreate | 0-10 | 0-1000 |
| onTaskComplete | 1-5 | 100-500 |
| cleanupCommands | 24 (hourly) | 24 |
| cleanupAlerts | 24 | 24 |
| cleanupSnapshots | 1 (daily) | 1 |
| refreshWeather | 48 (every 30 min) | 48 |
| **Total** | **~100** | **~1,600** |

Free tier: 2M invocations/month. Sufficient through hundreds of robots.

### Free Tier Summary

```
┌──────────────────────────────────────────────────────────────────┐
│                    FREE TIER CAPACITY                              │
├──────────────────┬─────────────────┬─────────────────────────────┤
│ Service          │ Free Tier Limit │ Robots Supported            │
├──────────────────┼─────────────────┼─────────────────────────────┤
│ Auth             │ 50K MAU         │ Unlimited for our scale     │
│ Firestore reads  │ 50K/day         │ ~140 robots                 │
│ Firestore writes │ 20K/day         │ ~11 robots                  │
│ RTDB bandwidth   │ 10 GB/month     │ ~60 robots                  │
│ RTDB storage     │ 1 GB            │ Unlimited (ephemeral data)  │
│ Storage          │ 5 GB            │ ~10 robots                  │
│ Storage DL       │ 1 GB/day        │ ~20 robots                  │
│ Functions        │ 2M invoc/month  │ ~1000 robots                │
│ FCM              │ Unlimited       │ Unlimited                   │
├──────────────────┼─────────────────┼─────────────────────────────┤
│ BOTTLENECK       │ Firestore writes│ ~11 robots on free tier     │
│                  │ (20K/day)       │                             │
└──────────────────┴─────────────────┴─────────────────────────────┘
```

### Cost Optimization Strategies

1. **Reduce telemetry snapshot rate when idle.** Idle robot writes 1 snapshot every 5 minutes (288/day) instead of every 1 minute (1,440/day). Saves 80% of telemetry writes. The robot knows its own state; idle detection is trivial.

2. **Client-side caching aggressively.** Zones and schedules rarely change. The app reads them once and caches in Hive. Subsequent opens use the cache and listen for changes (1 read on listener setup, not repeated reads).

3. **Paginate task history.** Load 10 tasks at a time, not all history at once. Users rarely scroll past 20 tasks.

4. **Batch telemetry snapshots.** Instead of 1 Firestore write per minute, buffer 5 snapshots and write them as an array in a single document every 5 minutes. This reduces writes by 5x but makes queries slightly more complex.

5. **Use Realtime Database for all live data.** Never poll Firestore for frequently-changing data. Realtime Database is billed by bandwidth (pennies), not by operation count (expensive at scale).

6. **Disable unused indexes.** Large map fields (vertices), nested objects (motors, taskResults), and binary references (artifact) do not need Firestore indexes. Disabling them reduces storage and write cost.

7. **TTL policies for ephemeral data.** Firestore TTL (time-to-live) policies auto-delete:
   - Telemetry snapshots after 90 days
   - Completed commands after 7 days
   - Resolved alerts after 30 days
   - Read notifications after 90 days

```
// Firestore TTL policies (configured in Firebase Console or via gcloud CLI)

gcloud firestore fields ttls update expiresAt \
  --collection-group=commands \
  --project=chorerobotics-app

gcloud firestore fields ttls update createdAt \
  --collection-group=telemetry_snapshots \
  --project=chorerobotics-app
  // Note: TTL field must contain the expiration timestamp.
  // For snapshots, add an expiresAt field = createdAt + 90 days.
```

---

## 14. Migration Path to Production

When the fleet exceeds ~100 robots, Firebase costs and limitations make migration to the production stack necessary. This section maps every Firebase entity to its production equivalent.

### Service Migration Map

| Firebase Service | Production Replacement | Migration Strategy |
|---|---|---|
| Firebase Auth | Keep (or migrate to custom JWT with Go auth service) | Firebase Auth can remain as the identity provider. The Go auth service wraps it and adds custom JWT claims. Alternatively, fully replace with bcrypt + RS256 JWT. |
| Firestore `users` | PostgreSQL `public.users` | Export documents, transform to SQL rows. One-time migration script. |
| Firestore `robots` | PostgreSQL `public.robots` | Export documents, transform to SQL rows. Serial number mapping is 1:1. |
| Firestore `zones` | PostgreSQL `zones.zones` with PostGIS | Transform vertices array to PostGIS GEOGRAPHY(POLYGON). Area becomes computed column via ST_Area. |
| Firestore `schedules` | PostgreSQL `tasks.schedules` | Direct field mapping. Parameters JSONB is identical structure. |
| Firestore `commands` | Redis Streams + MQTT publish | Commands become MQTT messages via EMQX. Redis Streams provide ordering and persistence. No Firestore equivalent needed. |
| Firestore `task_history` | PostgreSQL `tasks.task_history` | Export and bulk insert. Timestamps map directly. |
| Firestore `telemetry_snapshots` | TimescaleDB `telemetry.telemetry_raw` | Export and bulk insert into hypertable. TimescaleDB handles retention and aggregation. |
| Firestore `battery_history` | TimescaleDB continuous aggregate | Battery data becomes part of telemetry aggregation. 1-day continuous aggregate provides the same daily summary. |
| Firestore `alerts` | PostgreSQL `notifications.alert_log` | Direct field mapping. |
| Firestore `firmware` | PostgreSQL `ota.firmware_versions` | Direct field mapping. Storage path becomes S3 key. |
| Realtime Database telemetry | EMQX MQTT broker + Redis cache | Robot publishes to `robot/{id}/telemetry` MQTT topic. EMQX rule engine writes to Redis `robot:{id}:state`. App subscribes via MQTT over WebSocket. |
| Firebase Storage (firmware) | Amazon S3 + CloudFront | Pre-signed URLs for robot firmware downloads. CDN for global distribution. |
| Firebase Storage (coverage) | Amazon S3 | Same path structure, different bucket. |
| FCM (push notifications) | Keep FCM (it IS the delivery mechanism) | FCM remains. The Go notification service replaces Cloud Functions for triggering notifications. |
| Cloud Functions | Go microservices | Each Cloud Function becomes a handler in the Go modular monolith. Firestore triggers become MQTT subscriptions or PostgreSQL triggers. |

### Migration Execution Plan

```
PHASE 1: Dual-Write (2 weeks)
  - Deploy Go backend alongside Firebase
  - App writes to BOTH Firebase AND Go API
  - Verify data consistency between systems
  - Robot continues writing to Firebase

PHASE 2: Read Migration (1 week)
  - App reads from Go API instead of Firebase
  - Firebase becomes write-only backup
  - Verify all screens work with Go API data

PHASE 3: Robot Migration (2 weeks)
  - Robot connects to EMQX instead of Firebase
  - Robot writes telemetry to MQTT, not Realtime DB
  - Robot reads commands from MQTT, not Firestore
  - Robot downloads firmware from S3, not Firebase Storage

PHASE 4: Firebase Decommission (1 week)
  - Stop dual-writes
  - Archive Firebase data
  - Disable Firestore/RTDB write access
  - Keep Firebase Auth (optional) or migrate to custom JWT
  - Keep FCM (required for push notifications regardless)

Total migration duration: ~6 weeks
Zero downtime if dual-write phase verifies correctly.
```

### Flutter App Changes for Migration

The app's data layer is abstracted behind repository interfaces (per the clean architecture in 00-overview.md). Migration requires swapping the repository implementation, not changing any UI or state management code.

```dart
// Current (Firebase MVP)
abstract class RobotRepository {
  Stream<Robot> watchRobot(String robotId);
  Future<void> updateRobot(String robotId, Map<String, dynamic> fields);
  Future<List<Zone>> getZones(String robotId);
  Future<void> createZone(String robotId, Zone zone);
  // ...
}

class FirebaseRobotRepository implements RobotRepository {
  // Uses Firestore SDK
}

// Production (Go + PostgreSQL)
class ApiRobotRepository implements RobotRepository {
  // Uses Dio HTTP client to Go REST API
  // Uses mqtt_client for real-time telemetry
}
```

The Riverpod provider is configured at app startup to inject the correct implementation:

```dart
final robotRepositoryProvider = Provider<RobotRepository>((ref) {
  // Toggle between Firebase and API backend
  if (AppConfig.useFirebase) {
    return FirebaseRobotRepository(ref.watch(firestoreProvider));
  } else {
    return ApiRobotRepository(ref.watch(dioProvider), ref.watch(mqttProvider));
  }
});
```

---

## 15. Flutter Integration Patterns

### Riverpod Providers for Firebase Data

```dart
// ─── AUTH ───

@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// ─── USER DOCUMENT ───

@riverpod
Stream<UserDocument> userDocument(Ref ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) throw Exception('Not authenticated');

  return FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .snapshots()
    .map((snap) => UserDocument.fromFirestore(snap));
}

// ─── ROBOT DOCUMENT ───

@riverpod
Stream<RobotDocument> robotDocument(Ref ref, String robotId) {
  return FirebaseFirestore.instance
    .collection('robots')
    .doc(robotId)
    .snapshots()
    .map((snap) => RobotDocument.fromFirestore(snap));
}

// ─── LIVE TELEMETRY (Realtime Database) ───

@riverpod
Stream<Telemetry> liveTelemetry(Ref ref, String robotId) {
  final dbRef = FirebaseDatabase.instance
    .ref('robots/$robotId/telemetry');

  return dbRef.onValue.map((event) {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) throw Exception('No telemetry data');
    return Telemetry.fromRealtimeDb(data);
  });
}

// ─── ZONES ───

@riverpod
Stream<List<Zone>> zones(Ref ref, String robotId) {
  return FirebaseFirestore.instance
    .collection('robots')
    .doc(robotId)
    .collection('zones')
    .where('isActive', isEqualTo: true)
    .snapshots()
    .map((snap) => snap.docs
      .map((doc) => Zone.fromFirestore(doc))
      .toList());
}

// ─── TASK HISTORY (paginated) ───

@riverpod
class TaskHistoryNotifier extends _$TaskHistoryNotifier {
  static const _pageSize = 10;
  DocumentSnapshot? _lastDoc;

  @override
  Future<List<TaskHistory>> build(String robotId) async {
    return _fetchPage(robotId);
  }

  Future<List<TaskHistory>> _fetchPage(String robotId) async {
    var query = FirebaseFirestore.instance
      .collection('robots')
      .doc(robotId)
      .collection('task_history')
      .orderBy('startedAt', descending: true)
      .limit(_pageSize);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
    }

    return snap.docs
      .map((doc) => TaskHistory.fromFirestore(doc))
      .toList();
  }

  Future<void> loadMore() async {
    final current = state.value ?? [];
    final next = await _fetchPage(robotId);
    state = AsyncData([...current, ...next]);
  }
}

// ─── ALERTS ───

@riverpod
Stream<List<Alert>> activeAlerts(Ref ref, String robotId) {
  return FirebaseFirestore.instance
    .collection('robots')
    .doc(robotId)
    .collection('alerts')
    .where('isActive', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .limit(20)
    .snapshots()
    .map((snap) => snap.docs
      .map((doc) => Alert.fromFirestore(doc))
      .toList());
}

// ─── BATTERY HISTORY (7-day chart) ───

@riverpod
Future<List<BatteryHistory>> batteryHistory(Ref ref, String robotId) async {
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

  final snap = await FirebaseFirestore.instance
    .collection('robots')
    .doc(robotId)
    .collection('battery_history')
    .where('timestamp', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
    .orderBy('timestamp', descending: false)
    .get();

  return snap.docs
    .map((doc) => BatteryHistory.fromFirestore(doc))
    .toList();
}

// ─── CLOUD COMMAND SENDER ───

@riverpod
class CloudCommandSender extends _$CloudCommandSender {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String> sendCommand({
    required String robotId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    state = const AsyncLoading();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final now = Timestamp.now();

      final docRef = await FirebaseFirestore.instance
        .collection('robots')
        .doc(robotId)
        .collection('commands')
        .add({
          'type': type,
          'payload': payload,
          'status': 'pending',
          'error': null,
          'createdAt': now,
          'acknowledgedAt': null,
          'executingAt': null,
          'completedAt': null,
          'expiresAt': Timestamp.fromMillis(
            now.millisecondsSinceEpoch + 5 * 60 * 1000, // 5 minutes
          ),
          'createdBy': uid,
        });

      state = const AsyncData(null);
      return docRef.id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // Watch command status after sending
  Stream<String> watchCommandStatus(String robotId, String commandId) {
    return FirebaseFirestore.instance
      .collection('robots')
      .doc(robotId)
      .collection('commands')
      .doc(commandId)
      .snapshots()
      .map((snap) => snap.data()?['status'] as String? ?? 'unknown');
  }
}
```

### Connection-Aware Data Source Selection

The app must decide whether to read telemetry from the local robot connection or from Firebase. This decision is made at the provider level:

```dart
@Riverpod(keepAlive: true)
Stream<Telemetry> telemetry(Ref ref) {
  final connectionMode = ref.watch(connectionModeProvider);
  final robotId = ref.watch(activeRobotIdProvider);

  switch (connectionMode) {
    case ConnectionMode.ble:
    case ConnectionMode.wifi:
      // LOCAL: Read from BLE/WebSocket stream (10Hz, low latency)
      return ref.watch(localTelemetryStreamProvider);

    case ConnectionMode.cloud:
      // CLOUD: Read from Realtime Database (0.2Hz, higher latency)
      return ref.watch(liveTelemetryProvider(robotId!));

    case ConnectionMode.disconnected:
      // OFFLINE: Read last-known from Hive cache
      return Stream.value(ref.read(cachedTelemetryProvider));
  }
}
```

---

## 16. Appendix: TypeScript Type Definitions

Complete type definitions for all Firestore documents, for use in Cloud Functions and admin tooling.

```typescript
// ========================================================
// types/firestore.ts
// Complete Firestore document type definitions
// ========================================================

import { Timestamp } from 'firebase-admin/firestore';

// ─── ENUMS ───

type UnitSystem = 'metric' | 'imperial';
type TemperatureUnit = 'celsius' | 'fahrenheit';
type ThemeMode = 'system' | 'light' | 'dark';
type AccountStatus = 'active' | 'suspended' | 'deleted';
type Platform = 'ios' | 'android';

type RobotStatus = 'online' | 'offline' | 'charging' | 'working' |
                   'paused' | 'error' | 'estop' | 'docked';
type AttachmentType = 'mower_blade' | 'snow_plow' | 'leaf_collector' | 'none';
type AttachmentStatus = 'connected' | 'disconnected';

type ZoneType = 'mow' | 'snow' | 'leaf' | 'no_go';

type TaskType = 'mow' | 'plow' | 'collect';
type TaskStatus = 'completed' | 'failed' | 'cancelled' | 'interrupted';

type CommandType = 'start_task' | 'stop_task' | 'pause_task' | 'resume_task' |
                   'dock' | 'estop' | 'clear_estop' |
                   'update_firmware' | 'sync_zones' | 'sync_schedules';
type CommandStatus = 'pending' | 'acknowledged' | 'executing' |
                     'completed' | 'failed' | 'expired';

type MowPattern = 'straight' | 'diagonal' | 'checker' | 'spiral';
type SnowDepth = 'light' | 'medium' | 'heavy';
type StartPosition = 'entrance' | 'garage' | 'center' | 'custom';
type DisposalDirection = 'left' | 'right' | 'pile_zone';
type CollectionMode = 'mulch' | 'bag';
type LeafMode = 'full_zone' | 'spot_clean';

type AlertSeverity = 'critical' | 'warning' | 'info';
type AlertCategory = 'motor' | 'blade' | 'battery' | 'connection' |
                     'gps' | 'sensor' | 'system' | 'safety';

type RtkStatus = 'fix' | 'float' | 'single' | 'none';
type RobotState = 'idle' | 'working' | 'charging' | 'paused' |
                  'error' | 'estop' | 'docked';

type NotificationType = 'task_complete' | 'task_error' | 'battery_low' |
                        'connection_lost' | 'weather_alert' | 'ota_available' |
                        'estop_triggered';

type ArtifactType = 'robot_firmware' | 'ros2_package' | 'jetson_system';
type ReleaseChannel = 'canary' | 'beta' | 'stable';
type RolloutStage = 'created' | 'canary' | 'partial_10' | 'partial_50' |
                    'full' | 'halted' | 'completed';

// ─── COMMON TYPES ───

interface GeoPoint {
  lat: number;
  lng: number;
}

interface MotorSpeeds {
  fl: number;   // Front-left RPM
  fr: number;   // Front-right RPM
  rl: number;   // Rear-left RPM
  rr: number;   // Rear-right RPM
}

// ─── DOCUMENT TYPES ───

interface UserDocument {
  email: string;
  displayName: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  settings: {
    units: UnitSystem;
    temperatureUnit: TemperatureUnit;
    theme: ThemeMode;
  };
  notifications: {
    taskComplete: boolean;
    taskError: boolean;
    batteryLow: boolean;
    connectionLost: boolean;
    weatherAlert: boolean;
    otaAvailable: boolean;
    estopTriggered: boolean;
  };
  robotIds: string[];
  accountStatus: AccountStatus;
}

interface FcmTokenDocument {
  token: string;
  platform: Platform;
  deviceId: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface NotificationLogDocument {
  type: NotificationType;
  title: string;
  body: string;
  robotId: string;
  data: Record<string, string>;
  read: boolean;
  createdAt: Timestamp;
}

interface RobotDocument {
  serialNumber: string;
  model: string;
  ownerId: string;
  pairedAt: Timestamp;
  name: string;
  firmwareVersion: string;
  status: RobotStatus;
  lastSeenAt: Timestamp;
  lastKnownPosition: GeoPoint | null;
  attachment: {
    type: AttachmentType;
    status: AttachmentStatus;
    detectedAt: Timestamp;
  };
  wifiConfig: {
    ssid: string;
    configuredAt: Timestamp;
  } | null;
  dockLocation: GeoPoint | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface ZoneDocument {
  name: string;
  type: ZoneType;
  color: string;
  vertices: GeoPoint[];
  areaSqM: number;
  perimeterM: number;
  version: number;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}

interface ScheduleDocument {
  name: string;
  taskType: TaskType;
  zoneId: string;
  daysOfWeek: number[];
  startTime: string;
  timezone: string;
  parameters: MowParameters | PlowParameters | CollectParameters;
  isEnabled: boolean;
  weatherHold: boolean;
  lastExecutedAt: Timestamp | null;
  nextScheduledAt: Timestamp | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}

interface MowParameters {
  pattern: MowPattern;
  angleDeg: number;
  overlapPct: number;
  cuttingHeightMm: number;
}

interface PlowParameters {
  startPosition: StartPosition;
  customStartPoint: GeoPoint | null;
  snowDepth: SnowDepth;
  disposalDirection: DisposalDirection;
  pileZoneId: string | null;
}

interface CollectParameters {
  mode: LeafMode;
  spotCleanVertices: GeoPoint[] | null;
  collectionMode: CollectionMode;
  dumpPoint: GeoPoint | null;
}

interface CommandDocument {
  type: CommandType;
  payload: StartTaskPayload | StopTaskPayload | FirmwarePayload |
           Record<string, never>;
  status: CommandStatus;
  error: { code: string; message: string } | null;
  createdAt: Timestamp;
  acknowledgedAt: Timestamp | null;
  executingAt: Timestamp | null;
  completedAt: Timestamp | null;
  expiresAt: Timestamp;
  createdBy: string;
}

interface StartTaskPayload {
  taskType: TaskType;
  zoneId: string;
  parameters: MowParameters | PlowParameters | CollectParameters;
}

interface StopTaskPayload {
  reason: 'user_requested' | 'weather' | 'schedule_end';
}

interface FirmwarePayload {
  firmwareId: string;
  version: string;
  downloadUrl: string;
}

interface TaskHistoryDocument {
  taskType: TaskType;
  zoneId: string;
  zoneName: string;
  scheduleId: string | null;
  status: TaskStatus;
  startedAt: Timestamp;
  completedAt: Timestamp;
  durationMinutes: number;
  activeDurationMinutes: number;
  areaCoveredSqM: number;
  areaTotalSqM: number;
  coveragePct: number;
  distanceTraveledM: number;
  batteryStartPct: number;
  batteryEndPct: number;
  batteryUsedPct: number;
  taskResults: {
    stripesCompleted?: number;
    cuttingHeightMm?: number;
    pattern?: string;
    passesCompleted?: number;
    estimatedSnowDepthMm?: number;
    bagsCollected?: number;
    estimatedVolumeL?: number;
    dumpTrips?: number;
  };
  failureReason: string | null;
  pathSummary: {
    pointCount: number;
    storageRef: string | null;
    boundingBox: {
      north: number;
      south: number;
      east: number;
      west: number;
    };
  };
  createdAt: Timestamp;
}

interface BatteryHistoryDocument {
  date: string;
  timestamp: Timestamp;
  batteryPct: number;
  voltage: number;
  currentAmps: number;
  temperatureC: number;
  healthPct: number;
  cycleCount: number;
  dailyStats: {
    minPct: number;
    maxPct: number;
    chargeCount: number;
    totalRuntimeMinutes: number;
    totalChargeMinutes: number;
    energyUsedWh: number;
  };
}

interface AlertDocument {
  severity: AlertSeverity;
  category: AlertCategory;
  code: string;
  title: string;
  message: string;
  component: string;
  telemetrySnapshot: {
    batteryPct: number;
    speedMs: number;
    position: GeoPoint | null;
    systemTempC: number;
  } | null;
  isActive: boolean;
  acknowledgedAt: Timestamp | null;
  resolvedAt: Timestamp | null;
  createdAt: Timestamp;
}

interface TelemetrySnapshotDocument {
  timestamp: Timestamp;
  batteryPct: number;
  batteryVoltage: number;
  batteryCurrentAmps: number;
  batteryTempC: number;
  latitude: number;
  longitude: number;
  headingDeg: number;
  speedMs: number;
  rtkStatus: RtkStatus;
  satelliteCount: number;
  positionAccuracyCm: number;
  motors: MotorSpeeds;
  systemTempC: number;
  state: RobotState;
  activeTaskId: string | null;
  signalStrength: number;
}

interface FirmwareDocument {
  version: string;
  versionCode: number;
  artifactType: ArtifactType;
  releaseNotes: string;
  releaseChannel: ReleaseChannel;
  releasedAt: Timestamp;
  minCompatibleVersion: string;
  targetModels: string[];
  artifact: {
    storagePath: string;
    sizeBytes: number;
    sha256: string;
  };
  preInstallChecks: {
    minBatteryPct: number;
    requiredState: string[];
    attachmentDetached: boolean;
  };
  requiresReboot: boolean;
  estimatedInstallTimeSec: number;
  rolloutStage: RolloutStage;
  rolloutStats: {
    totalEligible: number;
    deployed: number;
    succeeded: number;
    failed: number;
  };
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
}

interface WeatherCacheDocument {
  geohash: string;
  centerLat: number;
  centerLng: number;
  current: {
    tempC: number;
    humidity: number;
    windSpeedMs: number;
    condition: string;
    icon: string;
  };
  hourly: Array<{
    dt: Timestamp;
    tempC: number;
    precipProbability: number;
    precipMm: number;
    windSpeedMs: number;
    condition: string;
  }>;
  recommendation: {
    safeMow: boolean;
    safeSnow: boolean;
    reason: string | null;
  };
  fetchedAt: Timestamp;
  expiresAt: Timestamp;
}

interface AppConfigDocument {
  telemetryWriteIntervalSec: number;
  telemetrySnapshotIntervalSec: number;
  commandExpirationSec: number;
  estopTimeoutMs: number;
  features: {
    weatherIntegration: boolean;
    multiRobot: boolean;
    spotClean: boolean;
    rtKDisplay: boolean;
  };
  maintenanceMode: boolean;
  maintenanceMessage: string | null;
  minAppVersion: string;
  latestAppVersion: string;
  forceUpdate: boolean;
  updatedAt: Timestamp;
}

// ─── REALTIME DATABASE TYPES ───

interface RealtimeDbTelemetry {
  battery_pct: number;
  battery_voltage: number;
  battery_current_amps: number;
  battery_temp_c: number;
  battery_health_pct: number;
  battery_cycles: number;
  speed_ms: number;
  heading_deg: number;
  latitude: number;
  longitude: number;
  rtk_status: RtkStatus;
  satellite_count: number;
  position_accuracy_cm: number;
  motor_fl_rpm: number;
  motor_fr_rpm: number;
  motor_rl_rpm: number;
  motor_rr_rpm: number;
  system_temp_c: number;
  state: RobotState;
  active_task_id: string | null;
  signal_strength: number;
  attachment_type: AttachmentType;
  timestamp: number;       // Unix milliseconds
  _updated_at: number;     // Server timestamp (Unix ms)
}

interface RealtimeDbRobotStatus {
  online: boolean;
  last_heartbeat: number;  // Unix milliseconds
  connection_type: 'ble' | 'wifi' | 'cloud';
}
```

---

## Quick Reference: Screen-to-Data Mapping

| Screen | Firestore Collections Read | RTDB Path Read | Firestore Collections Written |
|---|---|---|---|
| Auth (01) | -- | -- | `users/{uid}` (create) |
| BLE Scan (02a) | -- | -- | -- |
| Pairing (02b) | -- | -- | `robots/{id}` (create) |
| WiFi Setup (02c) | -- | -- | `robots/{id}` (update wifiConfig) |
| Setup Complete (02d) | `robots/{id}` | -- | -- |
| Dashboard (03) | `robots/{id}`, `alerts` | `telemetry` | -- |
| Manual Control (04) | -- | `telemetry` | -- (commands via BLE/WiFi) |
| Map/Zones (05) | `zones` | `telemetry` (position) | `zones` (CRUD) |
| Battery (06) | `battery_history` | `telemetry` (battery fields) | -- |
| Diagnostics (07) | `alerts` | `telemetry` | `alerts` (acknowledge) |
| Mowing (08) | `zones` | -- | `commands` (start_task) |
| Snow (09) | `zones` | -- | `commands` (start_task) |
| Leaf (10) | `zones` | -- | `commands` (start_task) |
| Scheduling (11) | `schedules`, `zones` | -- | `schedules` (CRUD) |
| Settings (12) | `users/{uid}`, `robots/{id}` | -- | `users/{uid}`, `robots/{id}` |
| Firmware (13) | `firmware` | -- | `commands` (update_firmware) |
| History (14) | `task_history` | -- | -- |
| Weather (20) | `weather_cache` | -- | -- |
| Multi-robot (21) | `users/{uid}`.robotIds | -- | -- |

---

## Document Revision History

| Version | Date | Changes |
|---|---|---|
| 1.0.0 | 2026-03-23 | Initial complete specification |
