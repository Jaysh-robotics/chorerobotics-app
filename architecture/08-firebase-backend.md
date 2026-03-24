# Firebase Backend — Sample A / MVP

> Replaces the custom Go backend (07-backend-architecture.md) for the prototype phase.
> The Go architecture remains the production roadmap for 1000+ robots.

## Why Firebase for MVP

| Need | Custom Go Backend | Firebase |
|---|---|---|
| Auth | Build JWT system | Firebase Auth (email, Google, Apple) — done |
| User data | PostgreSQL + API | Cloud Firestore — done |
| Robot data | PostgreSQL + API | Cloud Firestore — done |
| Telemetry | TimescaleDB + MQTT | Firestore or Realtime Database — done |
| OTA binaries | S3 + CloudFront | Firebase Storage — done |
| Push notifications | FCM + custom server | Firebase Cloud Messaging — done |
| Offline sync | Custom sync layer | Firestore offline persistence — done |
| Hosting | ECS + load balancer | Firebase Hosting — done |
| Cost (1 robot) | ~$50/mo minimum | Free tier covers it |
| Setup time | 4-6 weeks | 1-2 days |

## Firebase Services Used

```
┌─────────────────────────────────────────────────────┐
│                   FIREBASE PROJECT                   │
│                 chorerobotics-app                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │ Firebase     │  │ Cloud        │  │ Firebase  │  │
│  │ Auth         │  │ Firestore    │  │ Storage   │  │
│  │              │  │              │  │           │  │
│  │ • Email/pass │  │ • Users      │  │ • OTA     │  │
│  │ • Google     │  │ • Robots     │  │   firmware│  │
│  │ • Apple      │  │ • Zones      │  │ • Robot   │  │
│  │              │  │ • Tasks      │  │   images  │  │
│  └──────┬───────┘  │ • Schedules  │  │ • Logs    │  │
│         │          │ • Telemetry  │  └───────────┘  │
│         │          │ • History    │                   │
│         │          └──────┬───────┘                   │
│         │                 │                           │
│  ┌──────▼─────────────────▼──────┐  ┌─────────────┐  │
│  │  Flutter App (Mobile)         │  │ Robot        │  │
│  │  • firebase_core              │  │ (Jetson)     │  │
│  │  • firebase_auth              │  │              │  │
│  │  • cloud_firestore            │  │ • Python SDK │  │
│  │  • firebase_storage           │  │ • Writes     │  │
│  │  • firebase_messaging         │  │   telemetry  │  │
│  └───────────────────────────────┘  │ • Reads      │  │
│                                      │   commands   │  │
│  ┌───────────────────────────────┐  │ • Downloads  │  │
│  │  Firebase Cloud Messaging     │  │   OTA from   │  │
│  │  • Task complete              │  │   Storage    │  │
│  │  • Error alerts               │  └─────────────┘  │
│  │  • Battery warnings           │                    │
│  └───────────────────────────────┘                    │
│                                                       │
└───────────────────────────────────────────────────────┘
```

## Firestore Data Model

### Collections Structure

```
firestore/
├── users/
│   └── {userId}/
│       ├── email: string
│       ├── displayName: string
│       ├── createdAt: timestamp
│       ├── settings: {
│       │     units: "metric" | "imperial",
│       │     notifications: { taskComplete: true, errors: true, battery: true }
│       │   }
│       └── robots/  (subcollection)
│           └── {robotId}/
│               ├── pairedAt: timestamp
│               └── nickname: string
│
├── robots/
│   └── {robotId}/
│       ├── serialNumber: string
│       ├── model: string
│       ├── firmwareVersion: string
│       ├── ownerId: string (ref → users)
│       ├── name: string
│       ├── status: "online" | "offline" | "charging" | "working" | "error" | "estop"
│       ├── attachment: {
│       │     type: "mower" | "snow_plow" | "leaf_collector" | "none",
│       │     id: string,
│       │     status: "connected" | "disconnected"
│       │   }
│       ├── lastSeen: timestamp
│       │
│       ├── telemetry/  (subcollection — latest snapshot overwritten)
│       │   └── latest/
│       │       ├── battery: { percent: number, voltage: number, current: number, temp: number, health: number, cycles: number }
│       │       ├── position: { lat: number, lng: number, heading: number, speed: number }
│       │       ├── rtk: { status: "fix" | "float" | "single" | "none", satellites: number }
│       │       ├── motors: { fl: number, fr: number, rl: number, rr: number }
│       │       ├── signal: number (0-4)
│       │       ├── systemTemp: number
│       │       ├── state: string
│       │       ├── activeTaskId: string | null
│       │       └── timestamp: timestamp
│       │
│       ├── telemetry_history/  (subcollection — append-only, TTL 90 days)
│       │   └── {autoId}/
│       │       ├── ... (same fields as latest)
│       │       └── timestamp: timestamp
│       │
│       ├── zones/  (subcollection)
│       │   └── {zoneId}/
│       │       ├── name: string
│       │       ├── type: "mow" | "snow" | "leaf" | "noGo"
│       │       ├── vertices: [{ lat: number, lng: number }]
│       │       ├── areaSqM: number
│       │       ├── createdAt: timestamp
│       │       └── updatedAt: timestamp
│       │
│       ├── schedules/  (subcollection)
│       │   └── {scheduleId}/
│       │       ├── name: string
│       │       ├── taskType: "mow" | "plow" | "collect"
│       │       ├── zoneId: string (ref → zones)
│       │       ├── daysOfWeek: [number] (0=Sun, 6=Sat)
│       │       ├── startTime: string ("08:00")
│       │       ├── enabled: boolean
│       │       ├── parameters: {
│       │       │     pattern: string,
│       │       │     angle: number,
│       │       │     overlap: number,
│       │       │     bladeHeight: number,
│       │       │     snowDepth: string,
│       │       │     ... (task-specific)
│       │       │   }
│       │       └── createdAt: timestamp
│       │
│       ├── commands/  (subcollection — robot polls this)
│       │   └── {commandId}/
│       │       ├── type: "start" | "stop" | "pause" | "dock" | "estop" | "update_firmware"
│       │       ├── payload: map (task-specific params)
│       │       ├── status: "pending" | "acknowledged" | "executing" | "completed" | "failed"
│       │       ├── createdAt: timestamp
│       │       └── acknowledgedAt: timestamp | null
│       │
│       └── history/  (subcollection)
│           └── {taskId}/
│               ├── type: string
│               ├── zoneId: string
│               ├── startedAt: timestamp
│               ├── completedAt: timestamp
│               ├── durationMinutes: number
│               ├── areaCoveredSqM: number
│               ├── batteryUsedPercent: number
│               ├── status: "completed" | "failed" | "cancelled"
│               └── path: [{ lat, lng, timestamp }] (coverage trace)
│
└── firmware/
    └── {firmwareId}/
        ├── version: string
        ├── releaseNotes: string
        ├── fileUrl: string (Firebase Storage ref)
        ├── fileSizeMB: number
        ├── checksum: string (SHA-256)
        ├── targetModel: string
        ├── createdAt: timestamp
        └── rolloutStage: "canary" | "partial" | "full"
```

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /robots/{robotId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Robot data — owner can read everything, write commands
    match /robots/{robotId} {
      allow read: if request.auth != null &&
        resource.data.ownerId == request.auth.uid;

      // Only the robot itself (service account) can write telemetry
      allow write: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;

      match /telemetry/{docId} {
        allow read: if request.auth != null;
        // Robot writes telemetry (via service account or custom token)
        allow write: if true; // TODO: restrict to robot's service account
      }

      match /telemetry_history/{docId} {
        allow read: if request.auth != null;
        allow write: if true; // Robot writes
      }

      match /zones/{zoneId} {
        allow read, write: if request.auth != null;
      }

      match /schedules/{scheduleId} {
        allow read, write: if request.auth != null;
      }

      match /commands/{commandId} {
        allow read: if true; // Robot reads commands
        allow create: if request.auth != null; // App creates commands
        allow update: if true; // Robot updates status
      }

      match /history/{taskId} {
        allow read: if request.auth != null;
        allow write: if true; // Robot writes history
      }
    }

    // Firmware — anyone authenticated can read, only admin writes
    match /firmware/{firmwareId} {
      allow read: if request.auth != null;
      allow write: if false; // Admin console only
    }
  }
}
```

## Firebase Storage Structure

```
storage/
├── firmware/
│   ├── v1.0.0/
│   │   ├── chorerobot-firmware-v1.0.0.bin
│   │   └── manifest.json
│   └── v1.1.0/
│       ├── chorerobot-firmware-v1.1.0.bin
│       └── manifest.json
│
├── robots/
│   └── {robotId}/
│       └── coverage/
│           └── {taskId}.json  (coverage path data, large files)
│
└── users/
    └── {userId}/
        └── profile.jpg
```

## Flutter Firebase Dependencies

```yaml
# Add to pubspec.yaml
dependencies:
  firebase_core: ^3.12.0
  firebase_auth: ^5.5.0
  cloud_firestore: ^5.6.0
  firebase_storage: ^12.4.0
  firebase_messaging: ^15.2.4
```

## How the Robot Connects to Firebase

The robot (Jetson Nano running Python/ROS2) uses the Firebase Admin SDK:

```python
# Robot-side Python code (runs on Jetson)
import firebase_admin
from firebase_admin import credentials, firestore, storage

# Initialize with service account
cred = credentials.Certificate('/etc/chorerobot/firebase-service-account.json')
firebase_admin.initialize_app(cred, {'storageBucket': 'chorerobotics-app.appspot.com'})

db = firestore.client()

# Write telemetry at 1Hz (downsampled from 10Hz internal)
def publish_telemetry(robot_id: str, data: dict):
    # Overwrite latest
    db.collection('robots').document(robot_id) \
      .collection('telemetry').document('latest').set(data)
    # Append to history (sampled — every 10th write)
    db.collection('robots').document(robot_id) \
      .collection('telemetry_history').add(data)

# Poll for commands
def listen_for_commands(robot_id: str, callback):
    doc_ref = db.collection('robots').document(robot_id) \
              .collection('commands')
    doc_ref.where('status', '==', 'pending') \
           .on_snapshot(callback)

# Download firmware update
def download_firmware(version: str, dest_path: str):
    bucket = storage.bucket()
    blob = bucket.blob(f'firmware/{version}/chorerobot-firmware-{version}.bin')
    blob.download_to_filename(dest_path)
```

## Data Flow

### App → Robot (Commands)

```
User taps "Start Mowing"
    ↓
App BLoC creates command document in Firestore:
    robots/{robotId}/commands/{auto-id}
    { type: "start", payload: { taskType: "mow", zoneId: "z1", pattern: "straight" }, status: "pending" }
    ↓
Robot is listening (on_snapshot) to commands collection
    ↓
Robot reads command, sets status: "acknowledged"
    ↓
Robot executes, sets status: "executing"
    ↓
Robot completes, sets status: "completed"
    ↓
App BLoC sees status change, updates UI
```

### Robot → App (Telemetry)

```
Robot sensors produce data at 10Hz
    ↓
Robot downsamples to 1Hz
    ↓
Robot writes to Firestore:
    robots/{robotId}/telemetry/latest  (overwrite)
    ↓
App has Firestore snapshot listener
    ↓
App BLoC receives real-time update
    ↓
UI rebuilds with new data
```

### E-Stop (Special Case)

```
User long-presses E-Stop
    ↓
App writes command: { type: "estop", status: "pending" }
    ↓
App ALSO sends BLE command directly (if connected)
    ↓
Whichever arrives first triggers the stop
    ↓
Robot confirms: command status → "completed"
```

## BLoC Integration Pattern

```dart
// Firebase telemetry stream → BLoC
class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  StreamSubscription? _telemetrySub;

  TelemetryBloc({required String robotId}) : super(TelemetryInitial()) {
    on<StartListening>((event, emit) {
      _telemetrySub = FirebaseFirestore.instance
          .collection('robots')
          .doc(robotId)
          .collection('telemetry')
          .doc('latest')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          add(TelemetryUpdated(Telemetry.fromFirestore(snapshot)));
        }
      });
    });

    on<TelemetryUpdated>((event, emit) {
      emit(TelemetryLoaded(event.telemetry));
    });
  }

  @override
  Future<void> close() {
    _telemetrySub?.cancel();
    return super.close();
  }
}
```

## Cost Estimate (Free Tier Coverage)

| Service | Free Tier | Our Usage (1 robot) | Fits? |
|---|---|---|---|
| Auth | 10K auth/month | ~10 logins/month | Yes |
| Firestore reads | 50K/day | ~86K/day (1Hz telemetry) | **Tight — optimize** |
| Firestore writes | 20K/day | ~86K/day (1Hz telemetry) | **Over — need to reduce** |
| Storage | 5GB | ~500MB firmware | Yes |
| FCM | Unlimited | ~50 notifications/day | Yes |

### Optimization for Free Tier

**Problem:** 1Hz telemetry = 86,400 writes/day, exceeds 20K free writes.

**Solutions:**
1. **Reduce telemetry write rate to 0.2Hz** (every 5 seconds) = 17,280 writes/day — fits free tier
2. **Use Realtime Database for telemetry** instead of Firestore (100K simultaneous connections, billed by bandwidth not operations)
3. **Batch writes** — buffer 10 readings, write as array in one document every 10 seconds
4. **Write to Realtime DB for live, Firestore for historical** — hybrid approach

**Recommended: Option 4 (Hybrid)**

```
Live telemetry (high frequency):  Realtime Database
    robots/{robotId}/telemetry  → overwritten at 1Hz
    Cost: ~10MB/day bandwidth = free tier

Historical data (append-only):   Cloud Firestore
    robots/{robotId}/telemetry_history  → 1 write per minute = 1,440/day
    Cost: well within free tier
```

```yaml
# Additional dependency for hybrid approach
dependencies:
  firebase_database: ^11.3.0  # Realtime Database for live telemetry
```

## Migration Path to Production

When you outgrow Firebase (100+ robots, need MQTT, need custom logic):

| Firebase Service | Production Replacement |
|---|---|
| Firebase Auth | Keep (or migrate to custom JWT) |
| Cloud Firestore | PostgreSQL + TimescaleDB |
| Realtime Database | EMQX MQTT broker |
| Firebase Storage | S3 + CloudFront |
| FCM | Keep (FCM is the delivery mechanism either way) |
| Firestore Security Rules | Go API + RBAC middleware |

The Flutter app's BLoC layer abstracts the data source, so swapping Firebase for custom APIs requires changing only the repository/service layer, not the UI or state management.
