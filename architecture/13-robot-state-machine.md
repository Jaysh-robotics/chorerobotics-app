# ChoreRobotics State Machine & Maneuvering Specification

This document provides a detailed specification of the state machines that control the **ChoreRobotics Robot** and the **ChoreRobotics Companion Application**, including how they interact during manual and autonomous maneuvering.

---

## 1. Overview of State Domains

State management is synchronized across three distinct layers:
1. **Robot Operational State**: Governs the physical robot's behavior, safety status, and low-level control.
2. **BLE Pairing & Onboarding**: Manages the secure authentication process when registering a new robot.
3. **App Connection Mode**: Determines the active communication channel (BLE, WiFi, or Cloud) based on latency and availability.
4. **App Task State**: Mirrors the robot's active task execution in the Flutter interface (BLoC state).

---

## 2. Robot Operational State Machine

The robot's physical controller runs a central state machine that determines what commands it can accept and how it behaves in safety-critical situations.

```mermaid
stateDiagram-v2
    [*] --> DOCKED : Power On (in dock)
    [*] --> IDLE : Power On (out of dock)
    
    DOCKED --> CHARGING : Charger Connected
    CHARGING --> DOCKED : Charge Complete / Disconnected
    DOCKED --> IDLE : Manual Undock / Drive Out
    
    IDLE --> WORKING : Start Task (Mow/Plow/Collect) / Start Manual Drive
    WORKING --> IDLE : Task Completed / Manual Drive Stop
    
    WORKING --> PAUSED : Pause Command / Temporary Obstacle / Connection Loss (>2s)
    PAUSED --> WORKING : Resume Command
    PAUSED --> IDLE : Cancel Task
    
    WORKING --> ERROR : Critical System Error / Sensor Failure / Hardware Fault
    IDLE --> ERROR : Self-Diagnostic Fault
    CHARGING --> ERROR : Charging Fault
    
    IDLE --> ESTOP : E-Stop Triggered (App or Hardware Button)
    WORKING --> ESTOP : E-Stop Triggered (App or Hardware Button)
    PAUSED --> ESTOP : E-Stop Triggered (App or Hardware Button)
    CHARGING --> ESTOP : E-Stop Triggered (App or Hardware Button)
    ERROR --> ESTOP : E-Stop Triggered (App or Hardware Button)
    
    ESTOP --> IDLE : E-Stop Cleared & Safety Validation Passed
    ERROR --> IDLE : System Reset / Fault Clear
```

### State Definitions

| State | Description | Safety-Critical Actions | Allowed Transitions |
|---|---|---|---|
| **IDLE** | The robot is active, stationery, and waiting for commands. | Drive motors locked (0 m/s), Blades **OFF**. | `WORKING`, `DOCKED`, `ESTOP`, `ERROR` |
| **WORKING** | The robot is actively maneuvering, either autonomously executing a task or driven manually. | Drive motors active, Blades/Attachments **ON** (if configured). | `IDLE`, `PAUSED`, `ESTOP`, `ERROR` |
| **PAUSED** | An active task is suspended. The robot remembers its path progress and can resume. | Drive motors stopped, Blades immediately **OFF**. | `WORKING`, `IDLE`, `ESTOP` |
| **DOCKED** | The robot is situated in its charging dock. | Drive motors disabled, Blades **OFF**. | `CHARGING`, `IDLE`, `ESTOP` |
| **CHARGING** | The battery pack is actively receiving power from the dock. | Drive motors disabled, Blades **OFF**. | `DOCKED`, `ESTOP`, `ERROR` |
| **ERROR** | A non-critical sensor or hardware fault is active. Manual inspection may be required. | Drive motors disabled, Blades **OFF**. | `IDLE`, `ESTOP` |
| **ESTOP** | **Emergency Stop Engaged.** Hardware power to motors and blades is cut. | Relay cut (safe-state), Blades immediately **OFF**. | `IDLE` (Manual release only) |

---

## 3. Onboarding & BLE Pairing State Machine

ペアリング (pairing) sequence handles the transition from discovery to mTLS secure connection setup. The pairing phases directly control the LED states of the robot.

```mermaid
stateDiagram-v2
    [*] --> DISCOVERABLE : Boot / Factory Reset (LED: White Slow Blink)
    
    DISCOVERABLE --> FOUND : BLE Connection Established (LED: White Fast Blink)
    FOUND --> PAIRING : Shared Secret Derivation Started (LED: White Double Blink)
    
    PAIRING --> AWAITING_CODE : Display 6-digit Code (LED: White Solid)
    AWAITING_CODE --> VERIFYING : Code Entered in App, Start SRP Key Exchange (LED: White Rapid Blink)
    
    VERIFYING --> SUCCESS : Token Verified, certs written (LED: Green 3 Flashes -> Solid)
    VERIFYING --> FAILED : Code Mismatch / Connection Timed Out (LED: Red 3 Flashes)
    
    SUCCESS --> WIFI_SETUP : Prompt WiFi Details in App (LED: Green Slow Blink)
    WIFI_SETUP --> COMPLETE : App & Robot Connected via local WiFi/Cloud (LED: Green Solid)
    
    FAILED --> DISCOVERABLE : Reset State Machine (after 3 seconds)
```

---

## 4. App Connection & Auto-Switching State Machine

The companion application automatically handles connection transitions based on latency and network availability.

```mermaid
stateDiagram-v2
    [*] --> DISCONNECTED
    
    DISCONNECTED --> BLE_CONNECTED : Bluetooth Scan & Connect (Preferred - Lowest Latency)
    
    BLE_CONNECTED --> WIFI_CONNECTED : Bluetooth Link Lost / LAN WiFi WebSocket Found
    WIFI_CONNECTED --> BLE_CONNECTED : Bluetooth Re-established
    
    WIFI_CONNECTED --> CLOUD_CONNECTED : Local WiFi Link Lost / Cloud MQTT Active
    CLOUD_CONNECTED --> WIFI_CONNECTED : Local WiFi Link Restored
    
    BLE_CONNECTED --> DISCONNECTED : Bluetooth Lost (No WiFi/Cloud available)
    WIFI_CONNECTED --> DISCONNECTED : WiFi & Cloud Lost
    CLOUD_CONNECTED --> DISCONNECTED : Cloud Lost
```

---

## 5. Maneuvering Interaction Loop (Manual Drive)

When maneuvering the robot manually via the app (Joystick or D-Pad), low-latency control is protected by a continuous safety loop.

```mermaid
sequenceDiagram
    participant User as User (App UI)
    participant App as App ConnectionManager
    participant Robot as Robot Server (asyncio)
    participant HW as Robot Hardware (Motors/Blade)

    User->>App: Touch Joystick / D-Pad
    loop 30Hz Heartbeat Control Loop (BLE / WebSocket Local Only)
        App->>Robot: Send DriveCommand(vx, vy, omega, blade_on)
        Note over Robot: Validate Command & Connection
        Robot->>HW: Set Motor Speeds (CAN bus)
        HW-->>Robot: Feedback (ticks, current)
        Robot-->>App: TelemetryUpdate(speed, heading, battery, faults)
        App-->>User: Update HUD & Status UI
    end
    
    Note over App, Robot: Connection Loss Detected (> 2.0s)
    Robot->>Robot: Trigger Connection-Loss Safety Handler
    Robot->>HW: Stop Motors (0m/s) & Disengage Blade
    Robot->>Robot: Transition to PAUSED state
    Robot-->>App: (If reconnected) State = PAUSED, fail_reason = connection_lost
```

### Safety Features in Maneuvering:
1. **Local connection restriction**: Manual controls (especially blade engagement) are strictly forbidden over cloud connections (`CLOUD_CONNECTED`) and require local BLE or LAN WiFi connections to minimize latency-induced hazards.
2. **30Hz Keepalive Heartbeat**: If a manual drive command is not received for **2.0 seconds**, the robot automatically stops drive motors and halts the blade.
3. **Hardwired E-Stop Override**: Emergency stop triggers bypass the application layer, communicating directly to cut power relays to the motor drivers.

---

## 6. App Active Task State Machine

The Flutter application mirrors the task state through the `ActiveTaskBloc` to show overlay notifications and progress updates.

```mermaid
stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> RUNNING : TaskStarted (mow/plow/collect)
    RUNNING --> PAUSED : TaskPaused
    PAUSED --> RUNNING : TaskResumed
    
    RUNNING --> STUCK : TaskProgressUpdated (stuck = true)
    STUCK --> RUNNING : TaskResumed (after clearing path)
    STUCK --> FAILED : Timeout / Cancelled
    
    RUNNING --> COMPLETED : TaskCompleted (100% progress)
    RUNNING --> FAILED : TaskFailed (obstacle / battery low / connection lost)
    RUNNING --> CANCELLED : TaskCancelled
    
    PAUSED --> CANCELLED : TaskCancelled
    
    COMPLETED --> IDLE : Reset
    FAILED --> IDLE : Reset / Resume Task
    CANCELLED --> IDLE : Reset
```

---

## 7. State Transition Matrix

The table below outlines the core operational transitions triggered by events across the robot and app.

| Source State | Event | Target State | Guard Conditions | Actions / Output |
|---|---|---|---|---|
| **IDLE** | `START_TASK` (App Command) | **WORKING** | Robot paired, GPS RTK has Fix, no active E-Stop. | Start blades, activate autonomous navigation. |
| **IDLE** | `MANUAL_DRIVE` (App Control) | **WORKING** | Connection type is local (`BLE` or `WEBSOCKET`). | Accept 30Hz drive vectors. |
| **WORKING** | `PAUSE` (App Command / Obstacle) | **PAUSED** | None. | Stop motors, shut down blade. Save task position. |
| **WORKING** | `CONNECTION_LOSS` (>2.0s) | **PAUSED** | Communication heartbeat fails. | Stop motors, shut down blade. Log connection_lost. |
| **PAUSED** | `RESUME_TASK` (App Command) | **WORKING** | Connection re-established, path is clear. | Start blades, resume autonomous navigation. |
| **PAUSED** | `CANCEL_TASK` (App Command) | **IDLE** | None. | Reset task parameters, clear active task overlay. |
| **WORKING** | `TASK_COMPLETED` (Auton.) | **IDLE** | Progress reached 100%. | Stop blades, return to dock or wait for command. |
| **ANY** | `E_STOP` (App / Hardware Button) | **ESTOP** | None. | Cut power relay. Stop blades/motors. Mark task failed. |
| **ESTOP** | `CLEAR_E_STOP` (App Command) | **IDLE** | Hardware switch released, system diagnostics clear. | Restore power relay. Initialize sensors. |
| **WORKING** | `CRITICAL_FAULT` (Hardware) | **ERROR** | Sensor or motor failure detected. | Stop drive and blades immediately. Emit alert to app. |
