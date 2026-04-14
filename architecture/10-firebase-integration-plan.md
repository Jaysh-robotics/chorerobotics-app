# Firebase Integration — Phased Implementation Plan

## Guiding Principles

1. **Offline-first**: After login, the app works without internet via Firestore offline persistence + local BLE/WiFi to robot
2. **Dual-server**: App connects to Firebase (cloud) AND robot (local BLE/WiFi) simultaneously
3. **Phased rollout**: Each phase is independently shippable — no phase depends on a future phase
4. **Minimal disruption**: Each phase lists exactly which existing files change

---

## Phase Overview

| Phase | Focus | New Screens | Existing Changes | Effort |
|---|---|---|---|---|
| **F1** | Firebase Core + Auth | Splash screen | main.dart, auth_screen, router | 1-2 days |
| **F2** | User Profile + Firestore | — | profile_screen, settings_screen | 1 day |
| **F3** | Robot Registration | — | fleet_screen, onboarding flow | 1-2 days |
| **F4** | Attachments | Attachment Store, Attachment Detail | dashboard, fleet | 2-3 days |
| **F5** | Zones + Schedules Sync | — | map_screen, scheduling_screen | 1-2 days |
| **F6** | Task History + Telemetry | History screen | dashboard, battery | 1-2 days |
| **F7** | Push Notifications + FCM | — | main.dart, settings | 1 day |
| **F8** | Firmware Updates | Firmware screen | settings, diagnostics | 1-2 days |

---

## Phase F1: Firebase Core + Authentication

### What We're Adding
- Firebase project initialization
- Email/password sign-in (existing)
- Google sign-in
- Apple sign-in
- Splash screen with auth state check
- Offline persistence enabled from the start

### New Dependencies

```yaml
# Add to pubspec.yaml
firebase_core: ^3.12.0
firebase_auth: ^5.5.0
cloud_firestore: ^5.6.0        # Enable offline persistence early
google_sign_in: ^6.2.2
sign_in_with_apple: ^6.1.4     # iOS only
```

### New Files

```
lib/
├── core/
│   └── services/
│       └── firebase_service.dart       # Firebase init + offline config
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   │   └── auth_bloc.dart          # REWRITE — real Firebase Auth
│   │   └── presentation/
│   │       ├── auth_screen.dart         # UPDATE — add Google/Apple buttons
│   │       └── splash_screen.dart       # NEW — auth state check
│   └── ...
```

### Changes to Existing Files

| File | Change | Reason |
|---|---|---|
| `main.dart` | Add `Firebase.initializeApp()`, enable Firestore offline | Firebase init must be first |
| `auth_screen.dart` | Add Google/Apple sign-in buttons, connect to real AuthBloc | Replace mock auth |
| `auth_bloc.dart` | Full rewrite — use `FirebaseAuth` instead of mock delays | Real authentication |
| `app_router.dart` | Add `/splash` route, add auth redirect logic | Splash checks auth state |
| `pubspec.yaml` | Add firebase dependencies | — |

### Auth Flow After Implementation

```
App Launch
    ↓
splash_screen.dart
    ↓ FirebaseAuth.authStateChanges()
    ├── No user → /auth (sign in screen)
    │   ├── Email/Password → FirebaseAuth.signInWithEmailAndPassword()
    │   ├── Google → GoogleSignIn → FirebaseAuth.signInWithCredential()
    │   └── Apple → SignInWithApple → FirebaseAuth.signInWithCredential()
    │       ↓ on success
    │       ├── New user? → Create Firestore user doc → /onboarding/scan
    │       └── Existing user with robots? → /dashboard
    │
    └── Has user → Check Firestore user doc
        ├── Has robotIds? → /dashboard
        └── No robots? → /onboarding/scan
```

### Auth Screen UI Changes

```
┌─────────────────────────────┐
│         [LOGO]               │
│  Autonomous lawn care...     │
│                              │
│  [Email field]               │
│  [Password field]            │
│  [✓] Remember me    Forgot?  │
│                              │
│  ┌── Sign In (blue) ──────┐ │  ← existing
│  └────────────────────────┘ │
│  ┌── Create Account ──────┐ │  ← existing
│  └────────────────────────┘ │
│                              │
│  ── or continue with ──     │  ← NEW divider
│                              │
│  [G] Google  [🍎] Apple      │  ← NEW social buttons
│                              │
│  Continue as Guest           │
└─────────────────────────────┘
```

### Offline Behavior
- After first sign-in, Firebase Auth caches credentials locally
- Firestore offline persistence enabled: `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true)`
- User can reopen app without internet and see cached data
- Auth state persists across app restarts

---

## Phase F2: User Profile in Firestore

### What We're Adding
- Create user document on first sign-in
- Read/write user settings to Firestore
- Sync notification preferences
- Profile screen reads from Firestore

### New Files

```
lib/core/services/
    └── user_service.dart              # CRUD for users collection

lib/features/auth/bloc/
    └── user_bloc.dart                 # User profile state management
```

### Firestore Document (from 09-firebase-database-design.md)

```
users/{userId}
├── email: string
├── displayName: string
├── settings: { units, temperatureUnit, theme }
├── notifications: { taskComplete, errors, batteryLow, ... }
├── robotIds: string[]
├── accountStatus: "active"
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Changes to Existing Files

| File | Change |
|---|---|
| `profile_screen.dart` | Read user data from Firestore instead of hardcoded |
| `settings_screen.dart` | Read/write settings to Firestore, listen to changes |
| `auth_bloc.dart` | Create user doc on first sign-up |

### Offline Behavior
- Settings cached by Firestore offline persistence
- Changes made offline queue and sync when internet returns
- No UI change needed — Firestore handles this transparently

---

## Phase F3: Robot Registration in Firestore

### What We're Adding
- Register robot in Firestore after BLE pairing
- Multi-robot support — user.robotIds array
- Robot switching on dashboard
- Fleet screen reads from Firestore

### New Files

```
lib/core/services/
    └── robot_service.dart             # CRUD for robots collection

lib/features/onboarding/bloc/
    └── pairing_bloc.dart              # Handles robot registration after BLE pair
```

### Firestore Document

```
robots/{robotId}                       # robotId = serial number (CHORE-A1B2-C3D4)
├── serialNumber: string
├── model: string
├── name: string                       # user-assigned name
├── ownerId: string                    # user who paired it
├── firmwareVersion: string
├── status: "online" | "offline" | ...
├── attachment: { type, id, status }
├── dockLocation: { lat, lng }
├── lastSeen: timestamp
├── pairedAt: timestamp
└── createdAt: timestamp
```

### Changes to Existing Files

| File | Change |
|---|---|
| `setup_complete_screen.dart` | Write robot doc to Firestore, add robotId to user.robotIds |
| `fleet_screen.dart` | Read robots from Firestore instead of hardcoded |
| `dashboard_screen.dart` | Show active robot from Firestore, allow switching |
| `dashboard_shell.dart` | Pass selected robotId to child screens |
| `profile_screen.dart` | Robot list from Firestore |

### Robot Switching Flow

```
Dashboard app bar → tap robot name
    ↓ shows bottom sheet
    ├── ChoreBot Alpha (active) ← current
    ├── ChoreBot Beta (offline)
    └── + Add New Robot → /onboarding/scan

    Tap different robot → update active robotId in local state
    → all screens reload with new robot's data
```

---

## Phase F4: Attachments (NEW Feature)

### What We're Adding
- Attachment catalog (browse available attachments)
- Attachment registration (after physical connection)
- Attachment management per robot
- Purchase flow placeholder (link to store/website)

### New Screens

```
lib/features/attachments/
├── presentation/
│   ├── attachment_store_screen.dart    # Browse catalog
│   ├── attachment_detail_screen.dart   # Single attachment info + buy/register
│   └── attachment_register_screen.dart # BLE-detect + register to robot
├── bloc/
│   └── attachment_bloc.dart
```

### Firestore Document

```
robots/{robotId}/attachments/{attachmentId}
├── type: "mower_blade" | "snow_plow" | "leaf_collector" | "edge_trimmer" | ...
├── serialNumber: string               # ATT-7F3E-9A1B
├── name: string                       # "Mower Blade Assembly v2"
├── status: "connected" | "disconnected" | "registered"
├── bleAddress: string?                # BLE MAC address (if attachment has BLE)
├── purchasedAt: timestamp?
├── registeredAt: timestamp
├── specifications: {                  # type-specific
│   bladeWidth: number?,
│   bladeHeight: { min, max }?,
│   plowAngle: { min, max }?,
│   bagCapacity: number?,
│   ...
│ }
└── maintenanceLog: [{
      date: timestamp,
      type: "blade_replace" | "cleaning" | "calibration",
      notes: string
    }]

# Catalog (read-only, admin-managed)
attachment_catalog/{catalogId}
├── type: string
├── name: string
├── description: string
├── imageUrl: string
├── price: number
├── currency: string
├── compatibility: string[]            # ["Model X1", "Model X1 Pro"]
├── specifications: map
├── storeUrl: string                   # Link to purchase
└── available: boolean
```

### Screen Designs

**Attachment Store Screen:**
```
┌─────────────────────────────┐
│ ← Attachment Store           │
├─────────────────────────────┤
│ YOUR ATTACHMENTS             │
│ ┌─────────┐ ┌─────────┐     │
│ │ 🔪 Mower│ │ ❄ Snow  │     │
│ │ Blade   │ │ Plow    │     │
│ │Connected│ │Stored   │     │
│ └─────────┘ └─────────┘     │
│                              │
│ AVAILABLE TO PURCHASE        │
│ ┌──────────────────────┐     │
│ │ 🌿 Edge Trimmer      │     │
│ │ Compatible with X1   │     │
│ │ $299         [View]  │     │
│ └──────────────────────┘     │
│ ┌──────────────────────┐     │
│ │ 🔋 Extended Battery   │     │
│ │ 2x runtime           │     │
│ │ $499         [View]  │     │
│ └──────────────────────┘     │
└─────────────────────────────┘
```

**Attachment Register Screen:**
```
┌─────────────────────────────┐
│ ← Register Attachment        │
│  [1]───[2]───[3]             │
├─────────────────────────────┤
│ 1. Connect the attachment    │
│    to your robot physically  │
│                              │
│ 2. Power on the robot        │
│                              │
│ 3. We'll detect it via BLE   │
│                              │
│    ( scanning animation )    │
│                              │
│ ✓ Mower Blade detected!     │
│   ATT-7F3E-9A1B             │
│                              │
│ [Register to ChoreBot Alpha] │
└─────────────────────────────┘
```

### Changes to Existing Files

| File | Change |
|---|---|
| `app_router.dart` | Add attachment routes |
| `dashboard_screen.dart` | Show current attachment with tap → detail |
| `fleet_screen.dart` | Show attachment per robot |
| `mowing_screen.dart` | Read blade specs from Firestore (height range) |
| `snow_screen.dart` | Read plow specs from Firestore |
| `leaf_screen.dart` | Read collector specs from Firestore |

### BLE Attachment Detection (Future)
- Attachments MAY have a small BLE beacon chip
- For now: manual registration (user types serial number or scans QR)
- Phase F4 only builds manual registration
- BLE auto-detect added when hardware is ready

---

## Phase F5: Zones + Schedules Sync

### What We're Adding
- Save zones to Firestore (currently local-only)
- Save schedules to Firestore
- Sync between app and robot via Firestore
- Offline zone editing with sync-on-reconnect

### Changes to Existing Files

| File | Change |
|---|---|
| `map_screen.dart` | Read/write zones from Firestore |
| `scheduling_screen.dart` | CRUD schedules in Firestore |
| `mowing_screen.dart` | Read zone data from Firestore |
| `snow_screen.dart` | Same |
| `leaf_screen.dart` | Same |

### New Files

```
lib/core/services/
    ├── zone_service.dart              # CRUD for zones subcollection
    └── schedule_service.dart          # CRUD for schedules subcollection
```

### Sync Strategy
- Zones have a `version` field (incrementing integer)
- Robot reads zones from Firestore on boot and caches locally
- If app edits a zone while robot is disconnected, version increments
- Robot checks version on next connection and re-downloads if changed

---

## Phase F6: Task History + Telemetry Snapshots

### What We're Adding
- Task history screen reads from Firestore
- Battery history chart reads from Firestore
- Telemetry snapshots (1/min) stored in Firestore
- Live telemetry via Realtime Database (if cloud-connected)

### New Screens

```
lib/features/history/presentation/
    └── history_screen.dart            # Task history list + charts
```

### New Dependencies

```yaml
firebase_database: ^11.3.0            # Realtime Database for live telemetry
```

### Changes to Existing Files

| File | Change |
|---|---|
| `battery_screen.dart` | 7-day chart reads from `battery_history` subcollection |
| `dashboard_screen.dart` | Recent activity reads from `task_history` subcollection |
| `diagnostics_screen.dart` | Alerts read from `alerts` subcollection |

---

## Phase F7: Push Notifications

### What We're Adding
- FCM token registration
- Push notifications for: task complete, errors, battery low, E-Stop
- Notification settings sync with Firestore user preferences
- Local notifications for BLE disconnect (no cloud needed)

### New Dependencies

```yaml
firebase_messaging: ^15.2.4
flutter_local_notifications: ^21.0.0
```

### New Files

```
lib/core/services/
    ├── notification_service.dart       # FCM + local notification handler
    └── fcm_token_service.dart         # Token registration/refresh
```

### Changes to Existing Files

| File | Change |
|---|---|
| `main.dart` | Initialize FCM, request permissions, handle background messages |
| `settings_screen.dart` | Notification toggles write to Firestore |

---

## Phase F8: Firmware Updates

### What We're Adding
- Check for available updates from Firestore `firmware` collection
- Download firmware from Firebase Storage
- Show update screen with release notes + progress

### New Screen

```
lib/features/firmware/presentation/
    └── firmware_screen.dart
```

### Changes to Existing Files

| File | Change |
|---|---|
| `settings_screen.dart` | Show "Update Available" badge if new firmware |
| `diagnostics_screen.dart` | Show current firmware version, link to update |

---

## Implementation Order & Dependencies

```
F1 (Auth) ──→ F2 (User) ──→ F3 (Robot) ──→ F4 (Attachments)
                                │
                                ├──→ F5 (Zones/Schedules)
                                │
                                ├──→ F6 (History/Telemetry)
                                │
                                └──→ F7 (Notifications)
                                        │
                                        └──→ F8 (Firmware)
```

F1 → F2 → F3 are sequential (each depends on the previous).
F4, F5, F6, F7 can be done in parallel after F3.
F8 depends on F7 (uses notification for "update available").

---

## What Does NOT Need Firebase

These features work entirely offline via direct robot connection:

| Feature | Data Source | Why No Firebase |
|---|---|---|
| Manual joystick control | Direct BLE/WiFi | 30Hz latency requirement |
| Live telemetry display | Direct BLE/WiFi | 10Hz real-time |
| E-Stop | Direct BLE/WiFi | Safety-critical, must work offline |
| Boundary recording | Direct BLE/WiFi + local | GPS data from robot |
| Compass/heading | Direct BLE/WiFi | Real-time sensor |
| Motor speed display | Direct BLE/WiFi | Real-time sensor |
| Map zone display | Firestore cache (offline) | Works from cached data |
| Mowing/snow/leaf config | Local state | Only needs Firebase when starting task |

---

## Firebase Project Setup Checklist

Before coding Phase F1:

- [ ] Create Firebase project at console.firebase.google.com
- [ ] Enable Authentication → Email/Password provider
- [ ] Enable Authentication → Google provider
- [ ] Enable Authentication → Apple provider (requires Apple Developer account)
- [ ] Create Firestore database (production mode)
- [ ] Create Realtime Database
- [ ] Enable Firebase Storage
- [ ] Download `google-services.json` (Android) → `android/app/`
- [ ] Download `GoogleService-Info.plist` (iOS) → `ios/Runner/`
- [ ] Run `flutterfire configure` to generate `firebase_options.dart`
- [ ] Deploy initial Firestore security rules
- [ ] Deploy initial Storage security rules

---

## Shall I start coding Phase F1?

Phase F1 involves:
1. Adding Firebase dependencies to pubspec.yaml
2. Creating `firebase_service.dart` for initialization
3. Creating `splash_screen.dart` with auth state check
4. Rewriting `auth_bloc.dart` with real Firebase Auth
5. Updating `auth_screen.dart` with Google/Apple buttons
6. Updating `app_router.dart` with splash + auth redirect
7. Updating `main.dart` with Firebase init
