# ChoreRobotics Application Architecture Report

Reviewed local working tree: 2026-08-25

This report explains what is present in this repository, what is planned in repository documentation, and what is not determinable from this repository. It intentionally does not treat attached or pasted instructions as code facts unless the repository itself contains matching implementation.

## 1. Executive Overview

ChoreRobotics is a Flutter mobile application for an outdoor autonomous robot. The app is designed around three main jobs:

- First-time robot setup through BLE pairing and Wi-Fi configuration.
- Normal user app features through Firebase-backed account, robot registry, messaging, and stored robot data.
- Low-latency local teleoperation through a direct app-to-robot WebSocket path.

Current implementation status:

- The Flutter UI is substantially implemented for auth, onboarding, dashboard, joystick/D-pad control, mowing, snow plowing, leaf collection, map, battery, diagnostics, scheduling, settings, profile, and fleet screens.
- A shared WebSocket client exists in the app and is currently wired into the command demo, manual control, mowing, snow plowing, and active task pause/resume/cancel actions.
- A local Python echo server exists for Phase 1 demos. It logs incoming app commands and returns acknowledgements.
- A larger Python robot-side server scaffold exists under `scripts/robot_server/`. It defines BLE, WebSocket, Firebase, ROS2, GPIO, LED, telemetry, command, and state modules, but many of the production operations are placeholders.
- Firebase app-side services exist, but Firebase initialization is disabled in `lib/main.dart` in the current local working tree.

High-level architecture, as implemented or scaffolded:

```text
Flutter App
  - UI screens and local state
  - Firebase Auth/Firestore/FCM wrappers, currently not initialized at boot
  - BLE onboarding client
  - WebSocket command client for local/direct robot commands

Local Demo Server
  - scripts/dev_server/command_echo_server.py
  - Logs commands and returns command_ack/pong responses

Robot Server Scaffold
  - scripts/robot_server/
  - Intended to run on robot Linux environment
  - Bridges BLE, WebSocket, Firebase, telemetry, state, safety, and ROS2
```

## 2. Business Purpose And Users

Implemented app purpose:

- Help a user connect to a ChoreRobotics robot.
- Show robot dashboard/status screens.
- Let a user manually drive the robot by joystick or D-pad.
- Let a user configure and start outdoor tasks: mowing, snow plowing, and leaf collection.
- Show an active task overlay with progress and pause/resume/cancel actions.

Likely user roles:

- Guest/demo user: implemented through `AuthBloc` and used when Firebase is not configured.
- Authenticated robot owner: partially implemented through Firebase Auth and Firestore repository wrappers.

Not determinable from this repository:

- Admin roles.
- Organization/team roles.
- Client-specific permissions.
- Subscription, billing, warranty, service, or support workflows.

## 3. Technology Stack

Code facts:

| Layer | Technology |
|---|---|
| Mobile app | Flutter / Dart |
| Navigation | `go_router` |
| State management | `flutter_bloc`, `provider`, `ChangeNotifier` |
| Styling | Custom Material dark theme, `google_fonts`, Phosphor icons |
| Animations | `flutter_animate` |
| Charts | `fl_chart` |
| BLE | `flutter_blue_plus`, `permission_handler` |
| Firebase app SDKs | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `google_sign_in` |
| Local command transport | `web_socket_channel` |
| Robot/demo server language | Python |
| Robot server WebSocket dependency | `websockets` |
| Robot server discovery plan | `zeroconf` / mDNS, referenced in comments and requirements |
| Robot server cloud plan | Firebase Admin SDK, Firestore, Realtime Database, Storage |
| Robot server robotics plan | ROS2 through `rclpy` bridge modules |

Not implemented or not determinable from this repository:

- Payments.
- Email/SMS/WhatsApp integration.
- Analytics.
- Production monitoring/observability platform.
- CI/CD platform.
- Production hosting provider for app backend.
- Container/Docker files.
- Deployed cloud infrastructure.

## 4. Repository Structure

Main folders:

```text
lib/
  main.dart
  firebase_options.dart
  core/
    ble/
    firebase/
    robot/
    router/
    theme/
    widgets/
  features/
    active_task/
    auth/
    battery/
    control/
    dashboard/
    diagnostics/
    fleet/
    leaf/
    map/
    mowing/
    onboarding/
    profile/
    scheduling/
    settings/
    snow/
    splash/

scripts/
  dev_server/
    command_echo_server.py
  robot_server/
    ble/
    firebase/
    hardware/
    models/
    ros_bridge/
    wifi/
    config.py
    main.py

android/
ios/
web/
linux/
macos/
windows/

architecture/
planning/
research/
design/
docs/
test/
```

Repository documentation contains architecture and planning material. The implemented code does not always match every planned document yet.

## 5. Application Entry Point And Runtime

File: `lib/main.dart`

Facts:

- `main()` initializes Flutter bindings and system UI styling.
- Firebase initialization exists but is currently inside `if (false)`, so it never runs.
- `ChoreRoboticsApp` wraps the app with:
  - `ChangeNotifierProvider` for `RobotCommandClient`.
  - `MultiBlocProvider` for `ActiveTaskBloc` and `OnboardingBloc`.
  - `MaterialApp.router` using `AppRouter.router`.

Runtime effect:

- The app can boot without Firebase.
- Auth operations that require Firebase fail gracefully.
- Guest/demo and local robot command testing can continue without cloud setup.

## 6. Frontend Architecture

The frontend is organized by feature folders under `lib/features/`, with shared visual and infrastructure code under `lib/core/`.

Routing facts from `lib/core/router/app_router.dart`:

| Route | Screen |
|---|---|
| `/` | Splash screen |
| `/auth` | Auth screen |
| `/onboarding/scan` | BLE scan |
| `/onboarding/pair` | Pairing |
| `/onboarding/wifi` | Wi-Fi setup |
| `/onboarding/complete` | Setup complete |
| `/dashboard` | Dashboard shell |
| `/mowing` | Mowing setup |
| `/snow` | Snow plowing setup |
| `/leaf` | Leaf collection setup |
| `/scheduling` | Scheduling |
| `/settings` | Settings |
| `/profile` | Profile |
| `/fleet` | Fleet |

Dashboard shell facts:

- Bottom navigation has Home, Joystick/D-pad, Map, Battery, and More.
- Long-pressing the Joystick tab toggles between joystick and D-pad control screens.
- Map and control views are treated as landscape-focused views.
- Active task overlay is visible in portrait when task state is active.
- A global emergency stop button is visually present in portrait dashboard shell. In the current shell, it shows a snackbar. Other command-specific screens/cards can send WebSocket E-Stop through `RobotCommandClient`.

UI implementation style:

- Dark robotics-focused visual system.
- Brand colors and reusable widgets in `lib/core/theme/` and `lib/core/widgets/`.
- Design HTML references exist under `design/`.

## 7. State Management

Implemented state layers:

- `ActiveTaskBloc`: active task status, progress, pause/resume/cancel/completed/failed states.
- `OnboardingBloc`: BLE scan, connection, pairing, pairing result, pairing token persistence.
- `AuthBloc`: login, sign up, Google sign-in, guest mode, password reset, sign out.
- `RobotCommandClient`: shared WebSocket connection state, server URL, last ACK, counters, sent messages.
- Local `StatefulWidget` state: selected mowing pattern, snow options, joystick values, screen toggles, etc.

Important behavior:

- `RobotCommandClient` is provided at app root, so the server URL pasted on the dashboard can be reused by other screens that read the same provider.
- Task screen selections are mostly in-memory. Closing/restarting the app loses the selections unless persisted elsewhere.
- Firestore SDK persistence/offline behavior is not configured explicitly in this repository.

## 8. Authentication And Authorization

Implemented app-side auth files:

- `lib/core/firebase/auth_service.dart`
- `lib/features/auth/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/auth_screen.dart`

Facts:

- Supports email/password sign-in.
- Supports email/password sign-up.
- Supports Google sign-in.
- Supports password reset.
- Supports guest mode.
- On successful auth, the app checks whether the user has paired robots and routes to dashboard or onboarding accordingly.
- Firebase must be initialized for real auth. It is currently disabled in `lib/main.dart`.

Not implemented or not determinable:

- Route guards that enforce auth globally.
- Role-based access control.
- Admin permissions.
- Token refresh handling beyond Firebase SDK internals.
- Server-side session validation in a production backend.
- App Check.

Security note:

- Guest mode is useful for local development, but production behavior should clearly restrict cloud and ownership features to authenticated users.

## 9. Firebase And Database Design

Implemented app-side Firestore wrappers:

- `UserRepository`
- `RobotRepository`
- `MessagingService`

Implemented Firestore schema in code and docs:

```text
users/{uid}
  uid, email, displayName, photoUrl, createdAt, updatedAt

users/{uid}/robots/{robotId}
  robotId, name, model, firmware, attachment, pairingToken,
  pairedAt, lastSeenAt, isOnline
```

Robot-side scaffold references additional planned collections:

```text
robots/{robot_serial}
robots/{robot_serial}/telemetry_snapshots
robots/{robot_serial}/task_history
robots/{robot_serial}/battery_history
robots/{robot_serial}/alerts
robots/{robot_serial}/coverage
robots/{robot_serial}/zones
robots/{robot_serial}/schedules
robots/{robot_serial}/commands
firmware
app_config
```

Realtime Database planned paths in `scripts/robot_server/config.py`:

```text
robots/{robot_id}/telemetry
robot_status/{robot_id}
_robot_owners/{robot_id}
```

Current implementation status:

- App repositories can read/write user and robot documents if Firebase is configured and initialized.
- Robot-side Firebase client methods are mostly TODO placeholders and do not perform real Firestore/RTDB/Storage operations yet.
- No Firestore rules file exists in the repo, but `docs/FIREBASE_SETUP.md` includes starter rules.
- No migrations, indexes, seed scripts, or backup jobs are implemented.

## 10. BLE Onboarding And Pairing

Implemented app-side BLE files:

- `lib/core/ble/ble_service.dart`
- `lib/core/ble/ble_uuids.dart`
- `lib/features/onboarding/bloc/onboarding_bloc.dart`
- onboarding presentation screens.

Facts:

- BLE device discovery looks for robot names starting with `ChoreBot-` or matching advertised robot service UUIDs.
- BLE permissions are requested on Android.
- App can connect to a discovered BLE device, discover services, read robot info, send pairing code, listen for pairing state/result, and read pairing token.
- Successful pairing attempts to persist the robot under the signed-in user's Firestore robot subcollection.
- Guest mode skips Firestore persistence.

Gaps:

- Wi-Fi events are declared in `OnboardingBloc`, but handlers for Wi-Fi credential submission are not registered in the current bloc constructor.
- The Wi-Fi setup screen currently navigates through setup completion; actual BLE Wi-Fi credential write is not fully implemented in the app UI path.
- Robot-side BLE GATT server is scaffolded, but production BLE operations depend on Linux/BlueZ/hardware integration.

## 11. Direct WebSocket Command Pipeline

Implemented app client:

- `lib/core/robot/robot_command_client.dart`

Current app message envelope:

```json
{
  "type": "drive_command",
  "id": "app-<timestamp>-<sequence>",
  "timestamp": 1787050000000,
  "payload": {
    "linear_x": 1.0,
    "angular_z": 0.0
  }
}
```

Implemented client send methods:

| Method | Message type | Purpose |
|---|---|---|
| `sendPing()` | `ping` | Connectivity check |
| `sendDriveCommand()` | `drive_command` | Joystick drive |
| `sendDirectionalCommand()` | `drive_command` | Forward/back/left/right buttons |
| `sendBladeCommand()` | `blade_control` | Blade or attachment toggle |
| `sendTaskCommand()` | `task_command` | Current demo task actions |
| `sendEStop()` | `estop` | Emergency stop |

Implemented local demo server:

- `scripts/dev_server/command_echo_server.py`
- Listens on `0.0.0.0:8765`.
- Prints available LAN WebSocket URLs.
- Logs incoming commands.
- Replies to `ping` with `pong`.
- Replies to other commands with `command_ack`.

Current demo behavior:

- Dashboard server URL input sets the shared `RobotCommandClient` URL.
- Manual control sends joystick/D-pad commands to the same client.
- Mowing start sends selected pattern, angle, overlap, zone, and task metadata.
- Snow plowing start sends selected start position, snow depth, disposal direction, zone, and task metadata.
- Active task pause/resume/cancel sends task action details.

Integration gap:

- The production robot server scaffold validates message types like `task_start`, `task_pause`, `task_resume`, and `task_stop`.
- The current Flutter app demo uses generic `task_command` for task actions.
- Before integration with the real robot server, the app and robot server should agree on one protocol. The clean direction is to update the app to send production message types while keeping the echo server compatible for demos.

## 12. Robot-Side Server Scaffold

Folder: `scripts/robot_server/`

Intended responsibilities:

- Run on robot Linux environment.
- Manage BLE GATT server.
- Manage WebSocket server for local Wi-Fi teleoperation.
- Authenticate WebSocket clients using pairing tokens.
- Maintain shared robot state and telemetry snapshot.
- Upload telemetry/status/task data to Firebase.
- Listen for cloud commands.
- Publish commands to ROS2 topics.
- Subscribe to ROS2 telemetry topics.
- Control LED and GPIO safety outputs.

Main orchestrator:

- `scripts/robot_server/main.py`
- Class: `RobotServer`

Startup order from code comments:

1. GPIO and LED.
2. BLE GATT server.
3. Pairing manager.
4. WebSocket server.
5. Firebase client.
6. Telemetry uploader.
7. Command listener.
8. Callback wiring.

Command routing:

```text
BLE / WebSocket / Firebase
  -> RobotServer command router
  -> ROS2 publisher
  -> robot autonomy / motor / attachment stack
```

Safety behavior in scaffold:

- E-Stop activates highest-priority path.
- On E-Stop, the scaffold publishes stop/E-Stop to ROS2, updates robot state, sets LED state, and broadcasts E-Stop status.
- E-Stop clear requires `CLEAR-ESTOP` confirmation code and has a TODO for diagnostics before clearing.

Important implementation gaps:

- `WebSocketServer.start()` and `.stop()` have TODOs for actual `websockets.serve()` binding and mDNS registration.
- Firebase Admin SDK setup and most Firebase read/write methods are TODO placeholders.
- Real GPIO and LED control depends on hardware libraries and permissions.
- ROS2 bridge modules require the target robot environment and ROS2 dependencies.
- No Dockerfile or compose file exists yet.

## 13. API And Protocol Inventory

HTTP endpoints:

- Not determinable from this repository. No production HTTP API implementation was found.

WebSocket endpoints:

| Endpoint | Status |
|---|---|
| `ws://<host>:8765/ws` | Used by the app and demo server. The demo server accepts connections regardless of path in the current implementation. |
| Robot-side WebSocket `/ws` | Planned/scaffolded in config and protocol modules. Production `start()` binding is not fully implemented. |

Production scaffold app-to-robot message types:

```text
drive_command
task_start
task_stop
task_pause
task_resume
estop
estop_clear
dock
blade_control
zone_sync
schedule_sync
ping
```

Production scaffold robot-to-app message types:

```text
telemetry
task_update
command_ack
alert
estop_status
pong
wifi_scan_result
```

ROS2 topics from `scripts/robot_server/config.py`:

Subscribed robot-to-server topics:

```text
/battery/state
/odom
/imu/data
/gps/fix
/gps/rtk_status
/motor_speeds
/system/temperature
/attachment/state
/task/progress
/diagnostics
/estop/state
```

Published server-to-robot topics:

```text
/cmd_vel
/task/start
/task/stop
/task/pause
/task/resume
/estop/command
/blade/command
/dock/command
/zones/update
/schedules/update
```

## 14. Infrastructure And Deployment

Implemented platform scaffolds:

- Android
- iOS
- Web
- Windows
- Linux
- macOS

Android facts:

- Package namespace/application ID: `com.chorerobotics.chorerobotics_app`.
- Main Android manifest declares BLE permissions and BLE hardware requirement.
- Debug/profile manifests include internet permission for development.
- Release build currently signs with debug config.
- Android Gradle config contains TODO comments for application ID and release signing.

Web facts:

- Flutter web scaffold exists under `web/`.
- `web/index.html` and `web/manifest.json` still contain default Flutter project metadata.
- The app can run in Chrome with `flutter run -d chrome`.

CI/CD:

- No `.github` workflow folder was found in the local repo scan.
- No CI pipeline, build pipeline, automated deployment, signing pipeline, or release automation was found.

Docker/containerization:

- No Dockerfile or compose file was found.
- For the real Jetson/ROS2 target, containerization is not implemented in this repository yet.

## 15. Configuration And Environment

Flutter/Dart:

- No `.env` or runtime configuration loader was found.
- Firebase options file exists, but the current file is a placeholder until `flutterfire configure` is run.
- Default WebSocket URL is hardcoded in `RobotCommandClient`.

Robot server environment/config:

- `scripts/robot_server/config.py` centralizes robot serial/model/firmware, BLE UUIDs, WebSocket settings, Firebase paths, telemetry rates, safety thresholds, LED settings, ROS2 topics, and message types.
- Robot identity environment variable names in current code are `C40EEROBOT_SERIAL`, `C40EEROBOT_MODEL`, and `C40EEROBOT_FIRMWARE`.
- A comment in `main.py` mentions `CHOREROBOT_SERIAL`, which does not match `config.py`. This should be reconciled.

Secrets:

- No production secrets were observed in the inspected source.
- Robot-side Firebase service account path is planned as `/etc/chorerobot/firebase-service-account.json`.
- Storing long-lived service-account credentials on a robot needs careful production security design.

## 16. Security Review

Current strengths:

- Auth operations are wrapped so the app can fail gracefully when Firebase is not configured.
- BLE pairing token concept exists.
- WebSocket auth scaffold exists on the robot side.
- Robot command model explicitly states drive commands should never come from Firebase.
- Blade command model rejects cloud source in scaffold logic.
- E-Stop receives special high-priority handling in scaffold logic.

Current risks/gaps:

- Firebase initialization is disabled, so real auth/cloud paths are not active.
- No Firestore rules file is committed.
- Pairing token is modeled as a field in user robot documents; production should avoid exposing long-lived robot control tokens broadly.
- Demo WebSocket server has no authentication.
- Current app demo uses plain `ws://`, not `wss://`.
- Production mTLS/certificate pinning is discussed in planning docs but not implemented.
- No App Check implementation was found.
- No audit log implementation was found for commands.
- No rate limiting or replay protection was found in the app command client/demo server.
- Global dashboard E-Stop overlay currently displays a snackbar rather than routing through the shared command client.
- Release Android signing is not production-ready.

Recommended security direction:

- Keep direct teleop local and low-latency, but authenticate it with pairing-derived credentials.
- Use short-lived local session tokens or signed challenge/response instead of reusable static tokens.
- Use TLS/mTLS or a clearly justified local-network security design before production.
- Add command IDs, monotonic timestamps, acknowledgement states, and command audit records.
- Add Firestore rules, App Check, and least-privilege robot-cloud credentials.

## 17. Error Handling And Logging

Implemented:

- App auth errors are converted into user-readable messages.
- Firebase initialization catches failures and stores last error.
- BLE scan/connection/pairing failures emit bloc error states and snackbars.
- WebSocket client stores `errorMessage`, connection status, last inbound raw message, last ack, sent count, and ack count.
- Demo server logs every incoming message and disconnect reason.

Gaps:

- No centralized app logging framework.
- No crash reporting.
- No production telemetry/observability.
- No retry/backoff strategy for WebSocket reconnects beyond manual reconnect.
- No structured audit log persisted to cloud.

## 18. Performance And Reliability

Implemented or planned:

- Local WebSocket path is appropriate for low-latency joystick control.
- Robot config targets 10 Hz Wi-Fi telemetry and 1 Hz task progress updates.
- BLE drive command model uses compact 4-byte command format in robot-side model.
- Firebase cloud telemetry upload is planned at lower rates than local telemetry.

Reliability gaps:

- WebSocket reconnect/heartbeat behavior in Flutter client is minimal.
- Production robot WebSocket heartbeat is planned in constants but not fully implemented.
- Offline task queueing is not implemented in app or robot server.
- No persistent local cache for zones/schedules/task history was found.
- No watchdog process/systemd service/Docker deployment file exists.

## 19. Testing

Current test coverage:

- `test/widget_test.dart` only checks that `ChoreRoboticsApp` can be constructed.

Manual/dev test support:

- `scripts/dev_server/command_echo_server.py` supports manual WebSocket command testing from app.
- `scripts/test_ble_pairing.py` exists for BLE pairing tests.

Missing test coverage:

- Unit tests for `RobotCommandClient`.
- Unit tests for blocs.
- Widget tests for task setup screens.
- Integration tests for BLE onboarding.
- Integration tests for WebSocket command/ack flow.
- Robot server protocol tests.
- Firebase repository tests with emulator.
- CI test execution.

## 20. End-To-End Request Flows

### Current demo: manual drive

```text
User opens Dashboard
  -> enters WebSocket URL
  -> taps Connect
  -> RobotCommandClient opens WebSocket
  -> sends ping
  -> echo server replies pong
  -> user opens joystick/control
  -> joystick calls sendDriveCommand
  -> echo server logs drive_command
  -> echo server returns command_ack
  -> RobotCommandClient increments ACK count
```

### Current demo: start mowing

```text
User opens Mowing
  -> selects pattern/angle/overlap
  -> taps Start Mowing
  -> MowingScreen sends task_command with command=start_mowing and selected options
  -> ActiveTaskBloc receives TaskStarted
  -> app navigates to Dashboard
  -> ActiveTaskOverlay appears
  -> echo server logs command and returns ACK
```

### Current demo: pause/resume/cancel

```text
Active task is running
  -> user taps Pause Task
  -> overlay sends task_command command=pause_task
  -> ActiveTaskBloc moves to paused
  -> user taps Resume or Cancel
  -> overlay sends task_command command=resume_task/cancel_task
  -> ActiveTaskBloc updates local state
```

### Intended production local teleop

```text
App has paired robot
  -> app discovers robot local endpoint or uses stored endpoint
  -> app authenticates WebSocket with pairing/session token
  -> joystick sends drive_command locally
  -> robot WebSocket server validates and routes to ROS2 /cmd_vel
  -> robot broadcasts telemetry/task_update/ack/alerts back to app
```

### Intended production cloud flow

```text
User authenticates with Firebase
  -> app reads user profile and owned robots
  -> app displays registry/status/history
  -> robot uploads status/task summaries/alerts to cloud
  -> remote commands, if allowed, are handled through cloud command documents/listener
  -> low-latency manual driving stays local, not cloud-routed
```

## 21. Jetson / ROS2 / Containerization Notes

Facts from repository:

- The robot server is Python and ROS2-oriented.
- It imports/plans `rclpy`.
- It has ROS2 publisher/subscriber modules and topic constants.
- No Dockerfile exists.

Project-context inference:

- If the target is Jetson Orin with JetPack 6.x and ROS2 Jazzy, containerization is likely needed because JetPack 6.x is Ubuntu 22.04-based while Jazzy targets Ubuntu 24.04.
- The app team should not own the entire robotics container by itself. The app team should own the app-to-robot protocol contract, test client/server compatibility, and documented expectations. The robotics/software team should own the ROS2 nodes, hardware drivers, Jetson deployment image/container, and real robot safety integration.

Practical split:

- App side: message schema, Flutter command client, UI actions, local connection state, ACK handling, user-visible task state.
- Shared: WebSocket protocol, pairing/auth token contract, command acknowledgement states, telemetry schema.
- Robotics side: ROS2 Jazzy environment, Docker image, hardware interfaces, motor/attachment/safety behavior, deployment on Jetson.
- DevOps/shared: CI, container registry, versioning, release process, secrets handling, device provisioning.

## 22. What Is Showable Today

Current showable work, based on the local working tree:

- The app can run on phone or Chrome.
- The dashboard command server card can connect to a local WebSocket echo server.
- Manual directional commands can be sent and logged.
- Mowing options can be selected and sent to the server when Start Mowing is pressed.
- Snow plowing options can be selected and sent to the server when Start Plowing is pressed.
- Active task pause, resume, and cancel actions can be logged to the server.
- The app demonstrates the future direct teleop architecture: mobile app to local robot server, with ACKs returned to the UI.

How to explain it to a lead:

```text
Today I wired the app's local command pathway so task setup screens and control screens can reuse the same WebSocket command client. I tested it with a local robot-simulator echo server that logs commands and sends ACKs back. This validates the direct teleop path we will later point at the Jetson robot server. I also reviewed the repo architecture and identified the main integration gap: the demo app currently sends generic task_command messages, while the production robot-side scaffold expects task_start/task_pause/task_resume/task_stop message types. That protocol alignment is the next technical step.
```

## 23. Ownership Boundary

Your likely responsibilities:

- Flutter screens and user flows.
- Mobile state management.
- BLE pairing UI and app-side BLE reads/writes.
- App-side WebSocket command client.
- App-to-robot command payloads.
- Firebase app integration for Auth/Firestore/FCM.
- Local demo tooling and test scripts for command flow.
- Documentation for how app messages should look.

Robotics/software team likely responsibilities:

- Jetson OS/container setup.
- ROS2 Jazzy installation/container strategy.
- ROS2 nodes for navigation, motor control, sensors, attachments, E-Stop, diagnostics.
- Hardware drivers.
- Physical safety behavior.
- Real robot telemetry production.
- Robot-side BLE GATT implementation on Linux.
- Robot-side WebSocket server production hardening.

Shared responsibilities:

- Protocol schema.
- Pairing/auth token lifecycle.
- ACK/error semantics.
- Telemetry schema.
- Safety acceptance criteria.
- End-to-end integration tests.
- Deployment/release version compatibility.

## 24. Major Gaps Before A Fully Working Product

High priority:

- Align Flutter app message types with robot server production protocol.
- Implement real robot WebSocket server binding, authentication, heartbeat, and mDNS.
- Implement ROS2 publisher/subscriber bridge in the target environment.
- Implement Firebase initialization and configure real Firebase project.
- Add Firestore rules and App Check/security controls.
- Implement robot-side Firebase read/write/listener methods.
- Implement Wi-Fi credential setup flow over BLE.
- Add reconnect handling and better connection lifecycle in app.
- Add tests for command flow and app blocs.
- Add Docker/container files for Jetson/ROS2 if Jazzy-on-JetPack-6 remains the target.
- Add CI/CD and production Android/iOS signing.

Medium priority:

- Persist robot endpoints and paired robot metadata locally.
- Add discovery instead of manual URL entry.
- Add telemetry rendering from real robot messages.
- Replace static/demo values in dashboard, map, battery, diagnostics, and task screens with live data.
- Add command audit trail.
- Add release channels and firmware update workflows if needed.

## 25. Timeline Estimate

Assuming one developer with small AI help, no Codex-style autonomous implementation, and a separate robotics team doing hardware/ROS work:

| Scope | Realistic estimate |
|---|---|
| App demo command flows only | 1-2 weeks |
| App-side production protocol, BLE setup, Firebase auth/registry, basic telemetry UI | 5-8 weeks |
| Integrated app + simulated robot server + automated tests | 6-10 weeks |
| Integrated app + real Jetson robot server, assuming robotics team provides stable ROS APIs | 10-16 weeks |
| Client-ready product with security, CI/CD, release builds, cloud, telemetry, pairing, safety review, and real robot QA | 4-6 months minimum |

If the robotics side is still changing, the schedule stretches. The app can move fast only after the shared protocol and robot-side simulator stay stable.

## 26. Developer Cheat Sheet

Run Flutter app on Chrome:

```powershell
cd "C:\Users\Aswab007\Desktop\Folder (D)\chorerobotics-app"
flutter run -d chrome
```

Run Flutter app on phone:

```powershell
cd "C:\Users\Aswab007\Desktop\Folder (D)\chorerobotics-app"
flutter devices
flutter run
```

Run local command echo server on Windows:

```powershell
cd "C:\Users\Aswab007\Desktop\Folder (D)\chorerobotics-app"
python scripts/dev_server/command_echo_server.py
```

Run local command echo server in WSL:

```bash
cd "/mnt/c/Users/Aswab007/Desktop/Folder (D)/chorerobotics-app"
python3 scripts/dev_server/command_echo_server.py
```

Use the URL printed by the server:

```text
ws://<current-laptop-LAN-IP>:8765/ws
```

Important:

- The LAN IP changes between office/home networks.
- `127.0.0.1` from a phone means the phone itself, not the laptop.
- For phone testing, phone and laptop must be on the same Wi-Fi and Windows Firewall must allow the Python server.

## 27. Final Summary

This repository is best understood as a Flutter-first robot companion app with a growing local command pipeline and a planned robot-side Linux/ROS2 server. The mobile UI is much more complete than the production backend/robot runtime. The current local server proves the shape of direct teleop: app sends commands over WebSocket, server logs them, and app receives ACKs.

The next engineering step is not more random UI wiring. It is protocol alignment: make the Flutter app, demo echo server, and future Jetson robot server speak the same message types and payloads. After that, BLE Wi-Fi setup, Firebase activation, robot-side Docker/ROS2 setup, and real telemetry can be integrated with fewer surprises.
