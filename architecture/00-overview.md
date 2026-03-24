# ChoreRobotics App — Architecture Overview

## Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| **Framework** | Flutter 3.x (Dart) | Cross-platform, single codebase, Mammotion uses it |
| **State Management** | Riverpod + code gen | Compile-safe, testable, auto-dispose |
| **Navigation** | GoRouter | Deep linking, typed routes, shell routes for tabs |
| **Connectivity** | BLE + WebSocket + MQTT | 3-tier: direct → LAN → cloud |
| **Local Storage** | Hive / SharedPreferences | Offline-first, fast key-value |
| **Serialization** | json_serializable + freezed | Immutable models, union types for states |
| **Security** | Dio + mTLS certificates | Mutual TLS for cloud, SRP for BLE |

## Architecture Pattern

**Feature-first with Clean Architecture layers:**

```
lib/
├── main.dart
├── app.dart                        # MaterialApp + theme + router
│
├── core/                           # Shared infrastructure
│   ├── theme/                      # AppColors, AppTheme, brand tokens
│   │   ├── app_colors.dart         # Brand spectrum + functional colors
│   │   ├── app_theme.dart          # ThemeData
│   │   ├── app_typography.dart     # Type scale (Inter + JetBrains Mono)
│   │   └── components/            # Reusable styled widgets
│   │       ├── brand_card.dart
│   │       ├── brand_button.dart
│   │       ├── brand_badge.dart
│   │       ├── brand_line.dart     # Logo gradient accent line
│   │       ├── estop_button.dart   # Emergency stop (always visible)
│   │       ├── connection_bar.dart
│   │       └── metric_row.dart
│   │
│   ├── router/                    # GoRouter config
│   │   ├── app_router.dart
│   │   └── route_guards.dart      # Auth, pairing, connection guards
│   │
│   ├── connectivity/              # Connection layer abstraction
│   │   ├── connection_manager.dart # Auto-switch BLE→WiFi→Cloud
│   │   ├── ble/
│   │   │   ├── ble_service.dart
│   │   │   ├── ble_scanner.dart
│   │   │   └── ble_commands.dart   # Command protocol encoding
│   │   ├── wifi/
│   │   │   ├── websocket_service.dart
│   │   │   └── lan_discovery.dart
│   │   └── cloud/
│   │       ├── mqtt_service.dart
│   │       ├── api_client.dart     # Dio + mTLS
│   │       └── auth_service.dart
│   │
│   ├── models/                    # Shared domain models
│   │   ├── robot.dart             # Robot entity
│   │   ├── telemetry.dart         # Real-time telemetry data
│   │   ├── zone.dart              # Map zone (polygon + type)
│   │   ├── task.dart              # Scheduled/active task
│   │   ├── attachment.dart        # Mower/snow plow/leaf collector
│   │   └── diagnostic.dart        # System health data
│   │
│   ├── providers/                 # Global Riverpod providers
│   │   ├── connection_provider.dart
│   │   ├── robot_provider.dart
│   │   ├── telemetry_provider.dart
│   │   └── auth_provider.dart
│   │
│   └── utils/
│       ├── constants.dart
│       ├── extensions.dart
│       └── formatters.dart        # Duration, distance, battery %
│
├── features/                      # Feature modules (screens)
│   ├── auth/                      # Sign in / sign up
│   ├── onboarding/                # BLE scan → Pair → WiFi → Complete
│   ├── dashboard/                 # Main hub screen
│   ├── control/                   # Landscape joystick + manual drive
│   ├── map/                       # Zone mapping + boundary recording
│   ├── battery/                   # Battery status + health + history
│   ├── diagnostics/               # System health + logs
│   ├── mowing/                    # Mowing config + pattern selection
│   ├── snow/                      # Snow plowing config
│   ├── leaf/                      # Leaf collection config
│   ├── scheduling/                # Task scheduler (new)
│   ├── settings/                  # App + robot settings (new)
│   ├── history/                   # Task history + analytics (phase 2)
│   └── firmware/                  # OTA updates (phase 2)
│
└── shared/                        # Shared UI widgets
    ├── widgets/
    │   ├── joystick_widget.dart
    │   ├── compass_widget.dart
    │   ├── signal_bars.dart
    │   ├── battery_indicator.dart
    │   ├── zone_map.dart          # Reusable map component
    │   ├── pattern_preview.dart
    │   └── step_indicator.dart
    └── animations/
        ├── scan_pulse.dart
        ├── charging_animation.dart
        └── brand_shimmer.dart
```

## Key Architectural Decisions

### 1. Connection Abstraction Layer
All features talk to `ConnectionManager`, never directly to BLE/WiFi/MQTT. The manager handles:
- Auto-detection of best available connection
- Seamless failover (BLE → WiFi → Cloud)
- Unified command/telemetry interface
- Connection state as a Riverpod provider

### 2. Telemetry Stream Architecture
```
Robot Hardware
    ↓ (BLE/WiFi/MQTT)
ConnectionManager
    ↓ (Dart Stream)
TelemetryProvider (Riverpod StreamProvider)
    ↓ (ref.watch)
UI Widgets (auto-rebuild on new data)
```

### 3. Command Pipeline
```
UI Action (joystick move, start task, e-stop)
    ↓
CommandEncoder (serialize to protocol buffer or JSON)
    ↓
ConnectionManager (route to active connection)
    ↓
Robot Hardware
```

### 4. Offline-First
- Zone maps, saved presets, robot config cached in Hive
- BLE mode works with zero internet
- Cloud sync when available

### 5. Safety Architecture
- E-Stop button rendered as an overlay on EVERY screen (except auth)
- E-Stop bypasses all state management — direct hardware command
- Connection loss → graduated safety response (pause → dock → shutdown)
- E-Stop state is a global provider that blocks all other commands
