# Product Requirement Document (PRD): ChoreRobotics Companion Application

## 1. Document Control
- **Document Title**: Product Requirement Document (PRD) - ChoreRobotics Companion Application
- **Version**: 1.1.0
- **Status**: Active Reference
- **Author**: Antigravity AI
- **Related Docs**: `00-overview.md`, `01-features.md`, `04-screens.md`, `05-phases.md`, `11-database-and-user-flows.md`, `13-robot-state-machine.md`

---

## 2. Executive Summary & Product Vision

### 2.1 Product Description
ChoreRobotics is an autonomous, multi-season outdoor robot designed for lawn care (mowing), winter maintenance (snow plowing), and yard cleanup (leaf collection) via interchangeable modular attachments. 

The **ChoreRobotics Companion Application** is a cross-platform mobile app built in Flutter (Dart). It serves as the unified interface for users to configure, train, monitor, and manually operate the robot. The hardware side is powered by a Jetson Nano running ROS2 and Python, communicating with the app via three distinct network layers.

### 2.2 Core Value Proposition
- **Multi-Season Utility**: Seamless transition between Mowing, Snow Plowing, and Leaf Collection through hardware detection and UI adaptation.
- **Offline-First Resilience**: Full operation without internet. The system utilizes a 3-tier connectivity abstraction (Bluetooth Low Energy → Local Wi-Fi WebSockets → Firebase Cloud MQTT) to guarantee low-latency control and failsafe operation.
- **Safety-Critical Design**: Hardware-linked Emergency Stop (E-Stop) overlays, continuous 30Hz safety heartbeats during manual control, and graduated fault recovery states.

---

## 3. User Personas

### 3.1 Persona A: Suburban Homeowner (The Time-Saver)
- **Profile**: Lives in a single-family home experiencing all four seasons.
- **Needs**: Set-and-forget scheduling, simple map drawing, reliable operation without deep technical troubleshooting.
- **App Usage**: Occasional monitoring via Dashboard, heavy reliance on task scheduling and push notifications.

### 3.2 Persona B: Property / Fleet Manager (The Operator)
- **Profile**: Manages multiple properties, highly engaged with hardware health.
- **Needs**: Deep diagnostics, battery cycle tracking, precise boundary recording (via manual driving), and remote cloud monitoring.
- **App Usage**: Frequent use of manual joystick, map editor, and diagnostics screens.

---

## 4. Functional Requirements & Screen Specifications

### 4.1 Authentication & Profile (Screen 01)
- **Req 4.1.1**: Email/password authentication, account creation, and password reset.
- **Req 4.1.2**: Google OAuth sign-in integration.
- **Req 4.1.3**: **Guest Mode**: Allows bypass of cloud authentication for local BLE-only testing and operation.

### 4.2 Onboarding & BLE Pairing (Screens 02a-02d)
- **Req 4.2.1**: **BLE Scanning**: Discover nearby robots with pulse animations and RSSI signal strength bars.
- **Req 4.2.2**: **Secure Pairing**: App displays an input field for a 6-digit code shown on the robot's physical LCD. Initiates SRP (Secure Remote Password) key exchange.
- **Req 4.2.3**: **Wi-Fi Handoff**: App retrieves local SSIDs, prompts for password, and provisions the robot for local LAN and Cloud access.

### 4.3 Dashboard & Monitoring (Screen 03)
- **Req 4.3.1**: **Robot Status Card**: Displays current state (Idle, Working, Charging, etc.), detected attachment, and battery percentage with estimated runtime.
- **Req 4.3.2**: **Live Metrics**: Shows battery cycles, signal strength, blade status, speed (m/s), and internal temperature.
- **Req 4.3.3**: **Quick Actions & Logs**: Start, Dock, Pause commands, and a rolling log of recent activity.
- **Req 4.3.4**: **Connection Bar**: Displays active connection tier (`LOCAL BLE`, `WIFI`, or `CLOUD`) to set latency expectations.

### 4.4 Manual Control (Screen 04 - Landscape)
- **Req 4.4.1**: **Virtual Joystick**: Spring-back directional stick for manual driving.
- **Req 4.4.2**: **Telemetry HUD**: Compass heading, speed, and real-time output grid for all 4 motors (FL, FR, RL, RR).
- **Req 4.4.3**: **Safety Restrictions**: Manual blade engagement is strictly prohibited over Cloud connections; requires BLE or local Wi-Fi.

### 4.5 Map Editor & Boundary Training (Screen 05 - Landscape)
- **Req 4.5.1**: **Canvas Editor**: Vector map with grid supporting polygon drawing for Mow, Snow, Leaf, and No-Go zones.
- **Req 4.5.2**: **Drive-to-Record**: Users can drive the robot along the perimeter using the joystick, dropping pins to form boundary vertices.

### 4.6 Multi-Task Configurations (Screens 08, 09, 10)
- **Mowing (08)**: Select patterns (Straight, Diagonal, Checker, Spiral), adjust stripe angle, overlap %, and cutting height slider.
- **Snow Plowing (09)**: Select start position, snow depth (Light/Med/Heavy), and disposal route (Push Left/Right/Pile).
- **Leaf Collection (10)**: Toggle Full Zone vs. Spot Clean, select mode (Mulch vs. Bag), and drop dump point markers.

### 4.7 Battery & Diagnostics (Screens 06, 07)
- **Req 4.7.1**: **Battery Health**: Visual gradients, voltage/amperage draw, cycle count, and a 7-day historical usage chart.
- **Req 4.7.2**: **Diagnostics**: 3-tab layout (Overview, Technical, Faults) monitoring motors, data links, and component status with exportable logs.

### 4.8 Task Scheduling & Settings (Screens 11, 12 - Phase 2)
- **Req 4.8.1**: **Scheduler**: Day-of-week selection, time picker, and saved presets (e.g., "Sunday Front Yard").
- **Req 4.8.2**: **Settings**: Robot renaming, unit toggles (Metric/Imperial), notification preferences, and factory reset.

---

## 5. System Architecture & State Machines

### 5.1 Connectivity Abstraction & Failover
Managed by the `ConnectionManager`, the app never talks to hardware directly, but streams through an auto-failing-over pipeline:
1. **BLE_CONNECTED**: Preferred for setup and manual drive (Lowest Latency).
2. **WIFI_CONNECTED**: Seamless fallback when on the same LAN (WebSockets).
3. **CLOUD_CONNECTED**: Remote telemetry and queued commands via Firebase/MQTT.
4. **DISCONNECTED**: Triggers UI gray-out and safety pauses.

### 5.2 Robot Operational State Machine
The app mirrors the hardware state to enforce valid commands:
- **IDLE**: Awaiting commands. Motors locked, blades OFF.
- **WORKING**: Autonomous or manual maneuvering.
- **PAUSED**: Suspended task. Stores progress path.
- **DOCKED / CHARGING**: Returning to or resting in station.
- **ERROR / ESTOP**: Hardware fault or manual emergency stop. Power relays cut.

### 5.3 Active Task State (BLoC)
Tracks progress of jobs: `IDLE` → `RUNNING` ↔ `PAUSED` / `STUCK` → `COMPLETED` / `FAILED` / `CANCELLED`.

### 5.4 Safety Loop & E-Stop Requirements
- **Global E-Stop**: A fixed overlay present on *every* operational screen. Bypasses app state and triggers an immediate hardware motor/blade relay cut.
- **30Hz Keepalive (Heartbeat)**: During manual drive, the app must send commands at 30Hz. If the robot receives no packets for **2.0 seconds**, it automatically triggers a safe `PAUSED` state (motors 0 m/s, blades off).

---

## 6. Data Architecture & Offline Strategy

- **Local Persistence (Hive)**: Zone boundaries, configurations, presets, and auth tokens are stored locally. The app functions 100% without internet.
- **Cloud Sync (Firebase)**: Firestore structured data (user profiles, robot registry), Realtime Database (remote telemetry), and Storage (firmware binaries, generated map images). Data syncs automatically upon internet restoration.

---

## 7. Phased Development Roadmap

| Phase | Milestone / Features | Target Duration |
|---|---|---|
| **Phase 1: Core MVP** | Auth, BLE Onboarding, Dashboard, Manual Control, Map Boundary Training, Battery, Diagnostics, and all 3 Task Configs. | 14 Weeks |
| **Phase 2: Table Stakes** | Task Scheduling, App Settings, Active Task UI overlays, Saved presets, Cutting height controls. | 6 Weeks |
| **Phase 3: Power User** | RTK/GPS Satellite Status, Firebase Push Notifications, OTA Firmware Updates, Task History Analytics. | 8 Weeks |
| **Phase 4: Differentiators**| Weather API integration, Satellite map layers, FPV Camera streaming, Fleet management, Voice controls. | Future |

---

## 8. Release & Quality Criteria
- **Latency Target**: Manual drive joystick-to-wheel latency < 150ms over BLE/Wi-Fi.
- **Reliability**: Connection failover (BLE → Wi-Fi) must occur seamlessly without dropping the active telemetry stream.
- **Safety Testing**: 100% pass rate on E-Stop trigger latency (< 100ms) and 2.0s communication timeout halts.
