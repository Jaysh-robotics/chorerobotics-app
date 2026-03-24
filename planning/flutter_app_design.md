# Flutter Companion App — Prompt Design & Standards Debate

> Everything discussed while designing the master prompt for the chore robot Flutter app. Saved here so we don't have to research this again.

---

## 1. What This App Is

A companion control app for a chore robot (lawn mowing and snow clearing). The robot runs on an AURIX TC397XP motor controller with ISO 26262 ASIL B/C safety architecture (see `tc397xp-motor-control/docs/`). The app is the user-facing interface that ultimately sends commands through the AIP (AI PC) to the TC397 over CAN-FD.

The app is the **outermost perimeter** of a safety-critical system that terminates in ASIL C hardware (spinning blades rated S3 — life-threatening).

---

## 2. Standards Decision

### Why Two Standards, Not One

The system has four distinct security/safety boundaries. No single standard covers all of them:

| Boundary | What Crosses It | Risk |
|---|---|---|
| TC397 firmware (CAN bus, motor control) | Velocity commands, E-stop, blade RPM | ASIL C — someone can get killed |
| AIP <-> TC397 (CAN-FD) | Command messages, status telemetry | Unauthenticated CAN injection = direct motor control |
| App <-> Robot (local Wi-Fi) | User commands -> AIP, telemetry -> app | Compromised app = compromised command source |
| App <-> Cloud (internet) | OTA packages, logs, user auth | Supply chain attack via malicious firmware, privacy leak |

### Standards Selected

| Standard | What It Covers | Why |
|---|---|---|
| **ISO 26262** | Functional safety — TC397 firmware, fault state machine, HARA/ASIL ratings | Already our foundation. Drive motors = ASIL B, blade = ASIL C. Documented in `tc397xp-motor-control/docs/iso_26262_reference.md` |
| **ISO/SAE 21434** | Cybersecurity engineering — TARA for all four boundaries, OTA security, CAN authentication | Designed as the cybersecurity companion to ISO 26262. TARA methodology mirrors our existing HARA. Covers vehicle boundary + external interfaces + OTA |
| **OWASP** (supplementary) | Cloud API security, mobile app security | 21434 doesn't have strong opinions about REST APIs and user auth. OWASP fills that gap |
| **ISO 9241-210** (supplementary) | HMI usability — touch targets, contrast, error prevention | Safety-critical UI needs minimum 48x48dp touch targets, high contrast for E-Stop, unambiguous labeling |

### Standards Considered and Rejected

| Standard | Why Rejected |
|---|---|
| **IEC 62443** (industrial automation security) | Strong for zones/conduits but overlaps with 21434 on the robot side. Using both creates confusion about which framework governs what. 21434 is the better fit because we're already in the ISO 26262 ecosystem |
| **ISO 13482** (personal care robots) | Relevant to the robot hardware, but doesn't add anything to the app layer that 26262 + 21434 don't already cover |
| **IEC 61508** (generic functional safety) | ISO 26262 is the automotive/vehicle-specific derivation of 61508. Since we're already using 26262, referencing 61508 adds nothing |

### Key Insight: ISO 26262 + ISO/SAE 21434 Are a Designed Pair

- **ISO 26262** answers: "What happens when something *fails*?"
- **ISO/SAE 21434** answers: "What happens when something is *attacked*?"
- 21434's TARA (Threat Analysis and Risk Assessment) maps directly onto 26262's HARA (Hazard Analysis and Risk Assessment)
- Both use the same lifecycle approach (concept -> development -> production -> operations)
- Using them together is the natural and consistent choice when you're already in the 26262 world

---

## 3. Critique of the Original Prompt

### Issue 1: ISO/SAE 21434 Was the Only Standard Referenced

The original prompt cited only 21434 for everything. It should reference ISO 26262 as well since the firmware already uses it. The app needs to be aware of the existing safety architecture, not invent its own.

### Issue 2: "Intentionally Ugly UI" Is a Liability

The original prompt said to make the UI look like a beginner built it. But this is a safety-critical control application — the UI IS the safety interface.

- An E-Stop button that "looks unstyled" could be missed in a panic
- Poor visual hierarchy means users might confuse "Start Autonomous" with "Return to Dock"
- Default Flutter widgets with no affordance tuning violate basic HMI principles

**Resolution:** Minimal is fine. Bad is not. Simple layouts, standard widgets, no decorative animations — but every safety-critical element must have high contrast, large touch targets (minimum 48x48dp), and unambiguous labeling.

### Issue 3: Cloud Authority Was Undefined

The original prompt didn't specify whether the cloud server could send control commands.

**Resolution:** The cloud server must be **explicitly never authoritative** for control commands. Only the local robot server (direct Wi-Fi) has command authority. The cloud handles: OTA firmware packages (signed), user account management, anonymized analytics, push notifications. It CANNOT send movement commands, access raw location data, or override local safety states.

### Issue 4: "Encrypted Acknowledgment" Was Vague

"Requiring an encrypted acknowledgment from the robot" means nothing without specifics.

**Resolution:** Must specify:
- mTLS for the local Wi-Fi connection (mutual certificate pinning)
- HMAC-SHA256 signed acknowledgments using session key derived from mTLS
- 500ms timeout for ack, or command is considered failed
- Specific pairing protocol: physical button -> BLE -> SRP key exchange -> mutual certificate exchange

### Issue 5: 2-Second Binary Lockout Was Naive

A 2-second timeout triggering "Safety Lockout" would cause constant false lockouts on outdoor Wi-Fi (trees, walls, interference).

**Resolution:** Graduated response that mirrors the firmware's own fault state machine:

| Duration | App State | Robot Behavior |
|---|---|---|
| 0-2s no telemetry | Yellow "Signal Weak" banner, all controls active | Normal operation |
| 2-5s | Orange "Connection Unstable" banner, autonomous mode soft-paused | Robot slows to 25% speed |
| 5-15s | Red "Connection Lost" overlay, joystick disabled, only E-Stop active | Full pause — blades off, hold position |
| 15-30s | "Robot Returning to Dock" with last-known position | Autonomous return-to-dock |
| 30s+ | "Robot Stopped — Manual Retrieval Required" | Full shutdown in place if dock unreachable |

### Issue 6: The E-Stop Button Needs Honesty

The app's "E-Stop button" sends CAN message 0x102 with stop_type=0x01. It's a **software request**, not a hardware kill. The real E-Stop is Core 2's GPIO pin on the TC397.

**Resolution:** The app should clearly communicate: "This sends an emergency stop command. If the robot is unresponsive, use the physical E-Stop button on the robot." Triple redundancy in the app: WebSocket + UDP broadcast + on-screen instruction to use physical button.

### Issue 7: "Junior Developer Report" Was Fictional Fluff

The original prompt asked for a fake first-person narrative at the end of each phase.

**Resolution:** Replace with deliverables that are actually useful:
1. **Code** — the Flutter implementation
2. **Reference doc** — written like the existing docs in `tc397xp-motor-control/docs/`. Same style: clear tables, simple language. Something you can read 6 months from now without AI and understand what was built and why.
3. **Decision log** — plain-English record: "We chose X over Y because Z. The tradeoff is W."

---

## 4. The Real Threat Model: CAN Injection via the App

Looking at the existing CAN message IDs:

| ID | What It Does |
|---|---|
| 0x100 | Velocity command — directly controls motion |
| 0x102 byte 0x01 | Emergency stop |
| 0x110 | Blade on/off + RPM |

If someone compromises the app -> compromises the AIP's command generation -> sends a crafted 0x110 with enable=1, target_rpm=3000 while the robot is stationary... the firmware currently has **no blade-drive interlock** (FMEA #14 in `iso_26262_failure_analysis.md`). The blade starts spinning on a parked robot.

This is exactly where cybersecurity (21434) and functional safety (26262) intersect. The app is the outermost perimeter.

### Missing Piece: CAN Message Authentication

The CAN protocol currently has no message authentication. Messages 0x100, 0x101, 0x102, 0x110 are plain float/uint payloads. AUTOSAR E2E protection (alive counter + CRC) is mentioned in the FMEA but not implemented.

For the app:
- The app authenticates to the AIP (via mTLS or similar)
- The AIP should authenticate commands to the TC397 via CAN E2E (alive counter + CRC)
- The app cannot and should not authenticate directly to the TC397 — it doesn't speak CAN

---

## 5. Dual-Server Architecture

### Local Robot Server (Direct Wi-Fi, mDNS discovery)

- **Authority:** ONLY server with command authority (joystick, mode transitions, E-Stop)
- **No control commands ever route through the cloud**
- **Latency target:** < 50ms round-trip for control inputs
- **Protocol:** WebSocket over TLS 1.3 with mutual certificate pinning

### Company Cloud Server (HTTPS REST + WebSocket for push)

- **Authority:** Read-only for robot state. Write-only for: OTA firmware packages (signed), user account management, aggregated anonymized analytics
- **Explicitly CANNOT:** Send control commands, access raw location data, override local safety states

### The Handoff Problem

Three connectivity states and the robot's autonomous behavior in each:

| State | Robot Behavior | App Shows |
|---|---|---|
| Full Local Connection | Normal operation, app has real-time control | Normal UI |
| Local Connection Lost, Cloud Available | Safe-stop procedure (blades off, hold position, activate beacon). Cloud notifies user via push. Cloud CANNOT send movement commands | "Connection Lost" + push notification |
| All Connections Lost | Return-to-dock with obstacle avoidance using onboard autonomy. If dock unreachable within 60s, full shutdown in place | Last-known position (when reconnected) |

---

## 6. Data Sovereignty

### User-Local Only (never leaves the device/robot LAN)

- Lawn boundary coordinates
- Snow zone polygons
- Home Wi-Fi SSID/credentials
- Camera feeds (if any)
- Exact GPS coordinates of the dock

### Sent to Cloud (with user consent, anonymizable)

- Crash/fault logs (with coordinates stripped to city-level precision)
- Battery cycle count and degradation curves
- Firmware version
- Session duration (not timestamps)
- Error codes

### Permission Tiers

| Tier | Capabilities |
|---|---|
| **Owner/Admin** | Full control, pair new devices, manage guest access, approve OTA updates, export/delete all data |
| **Household Member** | Full control of paired robot, cannot pair new devices or manage other users |
| **Guest** | Manual joystick only while Owner's app is also connected. No autonomous mode. No mapping data access. Session expires after 4 hours or on Owner revocation |

---

## 7. Secure Pairing Protocol

1. Robot enters pairing mode (physical button press required — no remote trigger)
2. Robot broadcasts a BLE advertisement containing a one-time 6-digit numeric code also displayed on the robot's onboard screen/LED
3. User enters the code in the app. This initiates SRP (Secure Remote Password) key exchange over BLE
4. On successful SRP, both sides derive a shared secret. The app generates a client certificate, the robot generates a device certificate. Both stored in platform-secure storage (Keychain on iOS, Keystore on Android)
5. All subsequent Wi-Fi communication uses mutual TLS (mTLS) with these certificates
6. Certificate rotation every 90 days, triggered by the app, requiring the robot to be on the local network

---

## 8. App Must Mirror the Firmware Safety Architecture

The firmware has this fault state machine (from `tc397xp-motor-control/CLAUDE.md`):

```
NOMINAL --(fault)--> WARNING --(2s)--> FAULT --(500ms)--> ESTOP
   ^                    |                 |
   +--(clears)----------+                 +--(clear + 5s cool)--> NOMINAL
                                    ESTOP requires manual AIP recovery command
```

The app's graduated connection response should mirror this, not invent its own state machine. The app isn't a standalone safety system — it sits upstream of the AIP, which sits upstream of the TC397.

---

## 9. Phase Structure (for the final prompt)

Each phase produces three deliverables:

1. **Code** — Flutter implementation
2. **Reference doc** — same style as existing `tc397xp-motor-control/docs/` files. Clear tables, simple language, "saved here so we don't have to research this again"
3. **Decision log** — plain English: "We chose X over Y because Z. The tradeoff is W"

### Phase 1: Architecture, Threat Model (TARA), Data Sovereignty & Secure Pairing
### Phase 2: Spatial Mapping & Boundary Drawing
### Phase 3: Telemetry Dashboard with Graduated Failure Response
### Phase 4: Command Authority & Emergency Stop
### Phase 5: Operational Readiness (Activity Log, OTA, Push Notifications)

---

## 10. Design Philosophy

The prompt must produce output at a **deliberate, thorough pace** — not because we're slow, but because when working without AI assistance, the output needs to be structured enough to follow, extend, and maintain independently. The company will expect speed regardless, so the prompt builds in discipline and documentation that lets you move confidently without AI as a crutch.

The reference docs are the **independence layer**. When the company expects fast output and you don't have AI, you open the doc, read the decision, and know what to build next.

---

## Related Docs

- `tc397xp-motor-control/docs/iso_26262_reference.md` — Full ISO 26262 reference (ASIL matrix, Part 6 tables, FTTI, diagnostic coverage)
- `tc397xp-motor-control/docs/iso_26262_failure_analysis.md` — 43 failure modes with prevention strategies
- `tc397xp-motor-control/docs/fmea_content.md` — 20 firmware-specific FMEA entries
- `tc397xp-motor-control/docs/system_data_flow_reference.md` — CAN protocol, processing pipeline, data flow diagrams
- `tc397xp-motor-control/docs/CAN_FD_Protocol_Specification.pdf` — CAN-FD protocol spec
- `tc397xp-motor-control/CLAUDE.md` — Firmware architecture overview
