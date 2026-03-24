# Connection Flow Diagrams

> Simple flow diagrams for each connection method and the auto-connection logic.

---

## 1. First-Time Setup (With BLE)

```
┌──────────────────────────────────────────────────────────────────────┐
│                        FIRST-TIME SETUP                              │
└──────────────────────────────────────────────────────────────────────┘

  USER                          APP                           ROBOT
   │                             │                              │
   │  Opens app for first time   │                              │
   │ ──────────────────────────> │                              │
   │                             │                              │
   │                             │   Scans for BLE beacons      │
   │                             │ ──────────────────────────> │
   │                             │                              │
   │                             │   BLE beacon found:          │
   │                             │   "CHOREROBOT-A1B2"          │
   │                             │   State: HOTSPOT_MODE        │
   │                             │ <────────────────────────── │
   │                             │                              │
   │  "Robot found nearby.       │                              │
   │   Tap to pair."             │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   │  Taps "Pair"                │                              │
   │ ──────────────────────────> │                              │
   │                             │                              │
   │                             │   Reads hotspot SSID from    │
   │                             │   BLE advertisement          │
   │                             │                              │
   │                             │   Auto-connects phone to     │
   │                             │   robot hotspot              │
   │                             │ ──────────────────────────> │
   │                             │                              │
   │                             │   Wi-Fi connected            │
   │                             │ <────────────────────────── │
   │                             │                              │
   │                             │ ┌──────────────────────────┐ │
   │                             │ │  SECURE PAIRING (over    │ │
   │                             │ │  hotspot Wi-Fi):         │ │
   │                             │ │                          │ │
   │                             │ │  1. SRP key exchange     │ │
   │                             │ │  2. Derive shared secret │ │
   │                             │ │  3. Exchange certs       │ │
   │                             │ │  4. Store in Keychain/   │ │
   │                             │ │     Keystore             │ │
   │                             │ └──────────────────────────┘ │
   │                             │                              │
   │  "Connect robot to your     │                              │
   │   home Wi-Fi?"              │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   │  Picks SSID, enters         │                              │
   │  password                   │                              │
   │ ──────────────────────────> │                              │
   │                             │                              │
   │                             │   Sends Wi-Fi credentials    │
   │                             │   to robot (encrypted)       │
   │                             │ ──────────────────────────> │
   │                             │                              │
   │                             │                              │  Robot joins
   │                             │                              │  home Wi-Fi
   │                             │                              │
   │                             │   BLE confirms:              │
   │                             │   "Connected to HomeWiFi     │
   │                             │    IP: 192.168.1.42"         │
   │                             │ <────────────────────────── │
   │                             │                              │
   │                             │   App switches phone back    │
   │                             │   to home Wi-Fi              │
   │                             │                              │
   │                             │   mDNS discovers robot       │
   │                             │   on LAN                     │
   │                             │ <────────────────────────── │
   │                             │                              │
   │  "Setup complete!"          │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   ▼                             ▼                              ▼
                          READY (LAN MODE)
```

---

## 2. First-Time Setup (Without BLE)

```
┌──────────────────────────────────────────────────────────────────────┐
│                   FIRST-TIME SETUP (NO BLE)                          │
└──────────────────────────────────────────────────────────────────────┘

  USER                          APP                           ROBOT
   │                             │                              │
   │  Opens app for first time   │                              │
   │ ──────────────────────────> │                              │
   │                             │                              │
   │                             │   Scans BLE — nothing found  │
   │                             │   Scans mDNS — nothing found │
   │                             │                              │
   │  "No robot found.           │                              │
   │   Go to Settings > Wi-Fi    │                              │
   │   and connect to            │                              │
   │   CHOREROBOT-XXXX"          │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   │  ┌─────────────────────┐    │                              │
   │  │ USER LEAVES THE APP │    │                              │
   │  │ Opens Settings       │    │                              │
   │  │ Scrolls Wi-Fi list   │    │                              │
   │  │ Finds CHOREROBOT-    │    │                              │
   │  │   XXXX               │    │                              │
   │  │ Taps to connect      │    │                              │
   │  │ Waits...             │    │                              │
   │  │ Returns to app       │    │                              │
   │  └─────────────────────┘    │                              │
   │                             │                              │
   │ ──────────────────────────> │                              │
   │                             │                              │
   │                             │   Detects: on robot hotspot  │
   │                             │                              │
   │                             │ ┌──────────────────────────┐ │
   │                             │ │  SECURE PAIRING          │ │
   │                             │ │  (same as with BLE)      │ │
   │                             │ └──────────────────────────┘ │
   │                             │                              │
   │  "Connect robot to your     │                              │
   │   home Wi-Fi?"              │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   │  Picks SSID, enters         │                              │
   │  password                   │                              │
   │ ──────────────────────────> │                              │
   │                             │                              │
   │                             │   Sends Wi-Fi credentials    │
   │                             │ ──────────────────────────> │
   │                             │                              │
   │                             │                              │  Robot joins
   │                             │                              │  home Wi-Fi
   │                             │                              │
   │  "Robot joined your Wi-Fi.  │                              │
   │   Now go to Settings >      │                              │
   │   Wi-Fi and reconnect to    │                              │
   │   your home network."       │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   │  ┌─────────────────────┐    │                              │
   │  │ USER LEAVES THE APP │    │                              │
   │  │   AGAIN              │    │                              │
   │  │ Opens Settings       │    │                              │
   │  │ Switches to home     │    │                              │
   │  │   Wi-Fi              │    │                              │
   │  │ Returns to app       │    │                              │
   │  └─────────────────────┘    │                              │
   │                             │                              │
   │ ──────────────────────────> │                              │
   │                             │   mDNS discovers robot       │
   │                             │ <────────────────────────── │
   │                             │                              │
   │  "Setup complete!"          │                              │
   │ <────────────────────────── │                              │
   │                             │                              │
   ▼                             ▼                              ▼
                          READY (LAN MODE)

          User left the app TWICE. 6+ manual steps.
```

---

## 3. Daily Use — Auto-Connection Priority

```
┌──────────────────────────────────────────────────────────────────────┐
│                     APP OPEN — AUTO-CONNECTION                       │
└──────────────────────────────────────────────────────────────────────┘

                              App Opens
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  Try mDNS discovery    │
                    │  on current Wi-Fi      │
                    │  (timeout: 3 seconds)  │
                    └────────────┬───────────┘
                                 │
                       ┌─────────┴─────────┐
                       │                   │
                    FOUND              NOT FOUND
                       │                   │
                       ▼                   ▼
              ┌─────────────────┐  ┌────────────────────┐
              │  Connect via    │  │  Scan BLE for      │
              │  mTLS WebSocket │  │  robot beacon       │
              │                 │  │  (timeout: 3 sec)   │
              └────────┬────────┘  └─────────┬──────────┘
                       │                     │
                       ▼              ┌──────┴──────┐
              ┌─────────────────┐     │             │
              │   MODE 2: LAN  │  FOUND        NOT FOUND
              │   Full control  │     │             │
              │   Joystick: ON  │     ▼             ▼
              │   Blade: ON     │  ┌──────────┐  ┌──────────────────┐
              │   Telemetry:    │  │ Robot is  │  │  Try cloud       │
              │     real-time   │  │ nearby    │  │  server           │
              └─────────────────┘  │ but not   │  │  (timeout: 5 sec) │
                                   │ on LAN    │  └────────┬─────────┘
                                   └─────┬────┘           │
                                         │          ┌─────┴─────┐
                                         ▼          │           │
                                   ┌───────────┐ FOUND     NOT FOUND
                                   │ Is robot   │   │           │
                                   │ in hotspot │   ▼           ▼
                                   │ mode?      │ ┌────────┐ ┌────────────┐
                                   └──┬────┬───┘ │MODE 3: │ │ OFFLINE    │
                                      │    │     │CLOUD   │ │            │
                                    YES    NO    │Limited │ │ "Robot not │
                                      │    │     │control │ │  found"    │
                                      ▼    ▼     │        │ │            │
                              ┌──────────┐ ┌───┐ │Joystick│ │ Show       │
                              │ Prompt:  │ │Try│ │ : OFF  │ │ trouble-   │
                              │ "Connect │ │to │ │Blade:  │ │ shooting   │
                              │ directly │ │re-│ │  OFF   │ │ steps      │
                              │ to robot?│ │con│ │Start   │ └────────────┘
                              │ (1 tap)" │ │fig│ │ auto:  │
                              └────┬─────┘ │Wi-│ │  YES   │
                                   │       │Fi │ │Tele-   │
                                   ▼       └───┘ │ metry: │
                              ┌──────────┐       │ delayed│
                              │ MODE 1:  │       └────────┘
                              │ HOTSPOT  │
                              │ Full     │
                              │ control  │
                              │ No cloud │
                              └──────────┘
```

---

## 4. Mode 1: Direct Hotspot — Command Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                    MODE 1: DIRECT HOTSPOT                            │
└──────────────────────────────────────────────────────────────────────┘

  PHONE                              ROBOT
    │                                  │
    │    Wi-Fi: Connected to           │
    │    CHOREROBOT-A1B2 (robot AP)    │
    │    Internet: NONE                │
    │                                  │
    │                                  │
    │     ┌───────────────────────────────────────────┐
    │     │  WebSocket over TLS 1.3 (mTLS)            │
    │     │  wss://192.168.4.1:8443/control           │
    │     │  Latency: ~5-15ms                         │
    │     └───────────────────────────────────────────┘
    │                                  │
    │  Joystick input (x, y)           │
    │ ────────────────────────────────>│
    │                                  │  AIP processes
    │                                  │  Sends CAN 0x100
    │                                  │  to TC397
    │                                  │
    │          Telemetry frame         │
    │ <────────────────────────────────│
    │  (battery, state, speed,         │
    │   position, signal strength)     │
    │                                  │
    │  E-Stop tap                      │
    │ ────── WebSocket ───────────────>│
    │ ────── UDP broadcast ───────────>│  (redundant path)
    │                                  │
    │          Ack / No Ack            │
    │ <────────────────────────────────│
    │                                  │
    │                                  │
    │  ┌─────────────────────────┐     │
    │  │  AVAILABLE:             │     │
    │  │  ✓ Joystick             │     │
    │  │  ✓ Start Autonomous     │     │
    │  │  ✓ Pause / Resume       │     │
    │  │  ✓ Return to Dock       │     │
    │  │  ✓ E-Stop               │     │
    │  │  ✓ Blade On/Off         │     │
    │  │  ✓ Mapping              │     │
    │  │  ✓ Real-time telemetry  │     │
    │  │                         │     │
    │  │  NOT AVAILABLE:         │     │
    │  │  ✗ OTA Updates          │     │
    │  │  ✗ Cloud telemetry sync │     │
    │  │  ✗ Push notifications   │     │
    │  └─────────────────────────┘     │
    │                                  │
    ▼                                  ▼
```

---

## 5. Mode 2: Shared Wi-Fi (LAN) — Command Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                    MODE 2: SHARED WI-FI (LAN)                        │
└──────────────────────────────────────────────────────────────────────┘

  PHONE                    HOME ROUTER               ROBOT
    │                          │                       │
    │  Wi-Fi: Home network     │   Wi-Fi: Home network │
    │  Internet: YES           │   Internet: YES       │
    │                          │                       │
    │                          │                       │
    │  mDNS: "chorerobot.local"│                       │
    │  resolved to 192.168.1.42│                       │
    │                          │                       │
    │     ┌─────────────────────────────────────────┐  │
    │     │  WebSocket over TLS 1.3 (mTLS)          │  │
    │     │  wss://192.168.1.42:8443/control        │  │
    │     │  Routed through home router              │  │
    │     │  Latency: ~10-30ms                       │  │
    │     └─────────────────────────────────────────┘  │
    │                          │                       │
    │  Joystick / Commands ────┼──────────────────────>│
    │                          │                       │
    │  Telemetry <─────────────┼───────────────────────│
    │                          │                       │
    │                          │                       │
    │     ┌─────────────────────────────────────────┐  │
    │     │  SIMULTANEOUSLY (phone has internet):    │  │
    │     │                                         │  │
    │     │  Phone ──── HTTPS ────> Cloud Server    │  │
    │     │  (telemetry upload, push notifications, │  │
    │     │   OTA check)                            │  │
    │     │                                         │  │
    │     │  Robot ──── HTTPS ────> Cloud Server    │  │
    │     │  (crash logs, battery health)           │  │
    │     └─────────────────────────────────────────┘  │
    │                          │                       │
    │  ┌─────────────────────────┐                     │
    │  │  AVAILABLE:             │                     │
    │  │  ✓ Everything from      │                     │
    │  │    Mode 1, PLUS:        │                     │
    │  │  ✓ OTA Updates          │                     │
    │  │  ✓ Cloud telemetry sync │                     │
    │  │  ✓ Push notifications   │                     │
    │  │                         │                     │
    │  │  THIS IS THE BEST MODE  │                     │
    │  └─────────────────────────┘                     │
    │                          │                       │
    ▼                          ▼                       ▼
```

---

## 6. Mode 3: Cloud Relay — Command Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│                    MODE 3: CLOUD RELAY                                │
└──────────────────────────────────────────────────────────────────────┘

  PHONE                   CLOUD SERVER                ROBOT
    │                          │                        │
    │  On: cellular or         │     On: home Wi-Fi     │
    │  different Wi-Fi         │     Internet: YES      │
    │                          │                        │
    │  No direct path to robot │                        │
    │                          │                        │
    │     ┌──────────────┐     │     ┌──────────────┐   │
    │     │   HTTPS +    │     │     │  WebSocket   │   │
    │     │   WebSocket  ├─────┼─────┤  (persistent │   │
    │     │   to cloud   │     │     │   from robot) │   │
    │     └──────────────┘     │     └──────────────┘   │
    │                          │                        │
    │  Latency: 100-500ms+     │                        │
    │  (phone -> cloud -> robot -> cloud -> phone)      │
    │                          │                        │
    │                          │                        │
    │  "Start Autonomous"      │                        │
    │ ────────────────────────>│                        │
    │                          │  Relay command          │
    │                          │───────────────────────>│
    │                          │                        │
    │                          │                        │  Robot checks:
    │                          │                        │  - Geofence defined?
    │                          │                        │  - Battery > 15%?
    │                          │                        │  - No active faults?
    │                          │                        │
    │                          │  Ack: "Starting"       │
    │                          │<───────────────────────│
    │  Ack: "Robot starting"   │                        │
    │ <────────────────────────│                        │
    │                          │                        │
    │                          │                        │
    │  Telemetry (delayed)     │  Telemetry             │
    │ <────────────────────────│<───────────────────────│
    │  (1-3 second delay       │                        │
    │   from real-time)        │                        │
    │                          │                        │
    │                          │                        │
    │  ┌────────────────────────────────────────────┐   │
    │  │  AVAILABLE:                                │   │
    │  │  ✓ Start Autonomous                        │   │
    │  │  ✓ Pause / Resume                          │   │
    │  │  ✓ Return to Dock                          │   │
    │  │  ✓ E-Stop (software, with warning)         │   │
    │  │  ✓ View telemetry (delayed)                │   │
    │  │  ✓ OTA Updates                             │   │
    │  │  ✓ Push notifications                      │   │
    │  │                                            │   │
    │  │  NOT AVAILABLE (unsafe over cloud):        │   │
    │  │  ✗ Joystick — latency too high             │   │
    │  │  ✗ Blade On/Off — no real-time feedback    │   │
    │  │  ✗ Mapping — requires real-time joystick   │   │
    │  └────────────────────────────────────────────┘   │
    │                          │                        │
    ▼                          ▼                        ▼
```

---

## 7. Automatic Mode Switching

```
┌──────────────────────────────────────────────────────────────────────┐
│                 AUTOMATIC MODE TRANSITIONS                           │
└──────────────────────────────────────────────────────────────────────┘


    MODE 2 (LAN)                                      MODE 3 (CLOUD)
  ┌──────────────┐                                  ┌──────────────┐
  │ Full control │                                  │ Limited      │
  │ Joystick: ON │   ──── Wi-Fi drops ──────────>   │ Joystick: OFF│
  │ Best mode    │                                  │ Delayed data │
  │              │   <─── mDNS rediscovers ──────   │              │
  └──────┬───────┘                                  └──────┬───────┘
         │                                                 │
         │                                                 │
     BLE detects                                    Cloud loses
     robot nearby                                   robot heartbeat
     but LAN failed                                 (> 30 seconds)
         │                                                 │
         ▼                                                 ▼
  ┌──────────────┐                                  ┌──────────────┐
  │ MODE 1       │                                  │ OFFLINE      │
  │ (HOTSPOT)    │                                  │              │
  │ Full control │   ──── Robot has no internet ─>  │ "Robot not   │
  │ No cloud     │                                  │  reachable"  │
  │              │   <─── User reconfigures Wi-Fi   │              │
  └──────────────┘                                  └──────────────┘


  What the user sees during transitions:

  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │  LAN ──> Cloud:  Toast: "Switched to remote. Some controls  │
  │                   unavailable."                              │
  │                   Joystick fades out and disappears.         │
  │                                                              │
  │  Cloud ──> LAN:  Toast: "Local connection restored."        │
  │                   Joystick appears.                          │
  │                                                              │
  │  Any ──> Hotspot: Toast: "Connected directly to robot.     │
  │                    No internet access."                      │
  │                                                              │
  │  Any ──> Offline: Red banner: "Robot not reachable."        │
  │                    Only E-Stop button remains (queued).      │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
```

---

## 8. E-Stop Flow (All Modes)

```
┌──────────────────────────────────────────────────────────────────────┐
│                         E-STOP FLOW                                  │
└──────────────────────────────────────────────────────────────────────┘

  USER                     APP                    AIP              TC397
   │                        │                      │                 │
   │  Taps E-Stop button    │                      │                 │
   │ ──────────────────────>│                      │                 │
   │                        │                      │                 │
   │                        │── WebSocket ────────>│                 │
   │                        │── UDP broadcast ────>│ (redundant)     │
   │                        │                      │                 │
   │                        │  Start 1s timer      │                 │
   │                        │                      │                 │
   │                        │                      │  CAN 0x102      │
   │                        │                      │  stop_type=0x01 │
   │                        │                      │────────────────>│
   │                        │                      │                 │
   │                        │                      │                 │ Core 0
   │                        │                      │                 │ writes
   │                        │                      │                 │ CMD_ESTOP
   │                        │                      │                 │ to shared
   │                        │                      │                 │ memory
   │                        │                      │                 │
   │                        │                      │                 │ Core 2
   │                        │                      │                 │ detects
   │                        │                      │                 │ ESTOP
   │                        │                      │                 │ Pulls GPIO
   │                        │                      │                 │ enable LOW
   │                        │                      │                 │ ══════════
   │                        │                      │                 │ MOTORS
   │                        │                      │                 │ KILLED
   │                        │                      │                 │
   │                        │                      │  CAN 0x201      │
   │                        │                      │<────────────────│
   │                        │                      │  safety_level=3 │
   │                        │                      │  (ESTOP)        │
   │                        │  Ack: ESTOP active   │                 │
   │                        │<─────────────────────│                 │
   │                        │                      │                 │
   │                        │  Cancel 1s timer     │                 │
   │                        │                      │                 │
   │  "Robot stopped."      │                      │                 │
   │ <──────────────────────│                      │                 │
   │                        │                      │                 │
   ▼                        ▼                      ▼                 ▼


  IF NO ACK WITHIN 1 SECOND:

   │                        │                      │                 │
   │                        │  Timer expires       │                 │
   │                        │  No ack received     │                 │
   │                        │                      │                 │
   │  ┌─────────────────────────────────────────┐  │                 │
   │  │  "E-STOP NOT CONFIRMED"                 │  │                 │
   │  │                                         │  │                 │
   │  │  Press the physical E-Stop button       │  │                 │
   │  │  on the robot immediately.              │  │                 │
   │  │                                         │  │                 │
   │  │           [DIAGRAM OF BUTTON]           │  │                 │
   │  └─────────────────────────────────────────┘  │                 │
   │ <──────────────────────│                      │                 │
   │                        │                      │                 │
   ▼                        ▼                      ▼                 ▼
```

---

## 9. Graduated Connection Loss Response

```
┌──────────────────────────────────────────────────────────────────────┐
│              GRADUATED CONNECTION LOSS (LOCAL MODES)                  │
└──────────────────────────────────────────────────────────────────────┘


  TIME SINCE         APP UI                    ROBOT BEHAVIOR
  LAST TELEMETRY
       │
       │
   0 seconds     Normal UI                 Normal operation
       │
       │
   2 seconds     ┌─────────────────────┐
       │         │ ▓ SIGNAL WEAK       │   Normal operation
       │         │ (yellow banner)     │   (no change)
       │         │ All controls active │
       │         └─────────────────────┘
       │
       │
   5 seconds     ┌─────────────────────┐
       │         │ ▓ CONNECTION        │   Robot slows to 25% speed
       │         │   UNSTABLE          │   Blades remain on
       │         │ (orange banner)     │
       │         │ All controls active │
       │         └─────────────────────┘
       │
       │
  15 seconds     ┌─────────────────────┐
       │         │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │   FULL PAUSE
       │         │ CONNECTION LOST     │   Blades OFF
       │         │ (red overlay)       │   Hold position
       │         │                     │
       │         │ Joystick: DISABLED  │
       │         │ E-Stop: ACTIVE      │
       │         │ (queued for when    │
       │         │  connection returns)│
       │         └─────────────────────┘
       │
       │
  30 seconds     ┌─────────────────────┐
       │         │ ROBOT RETURNING     │   Autonomous return-to-dock
       │         │ TO DOCK             │   Using onboard navigation
       │         │                     │
       │         │ Last known position │
       │         │ shown on map        │
       │         └─────────────────────┘
       │
       │
  60 seconds     ┌─────────────────────┐
       │         │ ROBOT STOPPED       │   Full shutdown in place
       │         │                     │   (dock was unreachable)
       │         │ Manual retrieval    │
       │         │ required            │
       │         │                     │
       │         │ Last coordinates:   │
       │         │ shown on map        │
       │         └─────────────────────┘
       │
       ▼
```
