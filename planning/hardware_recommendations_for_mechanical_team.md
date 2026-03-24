# Hardware Recommendations for the Mechanical Team

> From the app/software side — what hardware we need on the robot for connectivity, and why. This document is meant to be shared with the mechanical/hardware team so they can factor these requirements into their component selection.

---

## Summary

The app needs to connect to the robot three ways: direct Wi-Fi hotspot, shared home Wi-Fi, and cloud. To make this seamless for the user (no manual Wi-Fi switching, auto-discovery, one-tap pairing), we need **two wireless radios** on the robot:

1. **Wi-Fi module** (required — already assumed)
2. **BLE (Bluetooth Low Energy) module** (strongly recommended)

Without BLE, the user experience degrades significantly. See the comparison at the end of this document.

---

## 1. BLE Module

### What It Does for Us

| Function | How BLE Is Used |
|---|---|
| **Robot discovery** | Robot broadcasts a BLE beacon continuously (like an AirTag). App detects the robot is nearby before any Wi-Fi connection exists. |
| **First-time pairing** | Secure key exchange (SRP protocol) happens over BLE. User never leaves the app. |
| **Hotspot SSID broadcast** | BLE advertisement contains the robot's current hotspot SSID. App reads it and auto-connects — user doesn't have to find "CHOREROBOT-XXXX" in their Wi-Fi list. |
| **Wi-Fi credential delivery** | During setup, app sends the user's home Wi-Fi SSID + password to the robot over BLE. Robot joins the network. |
| **Fallback side-channel** | If Wi-Fi drops (router changed, password changed), BLE still works. App can detect the robot and re-initiate Wi-Fi configuration without the user manually hunting for the hotspot. |
| **Connection state signaling** | Robot tells the app via BLE: "I'm in hotspot mode" or "I'm on home Wi-Fi at IP 192.168.1.x" — app knows which connection path to take. |

### What We Need from the Hardware

| Requirement | Specification | Why |
|---|---|---|
| BLE version | **BLE 5.0 minimum**, BLE 5.2+ preferred | BLE 5.0 gives 2x range over 4.2. BLE 5.2 adds LE Audio and improved power efficiency (not needed now, but future-proof). |
| Advertising payload | Must support **extended advertising** (BLE 5.0+) | We need to fit: device ID (16 bytes), hotspot SSID (up to 32 bytes), connection state (1 byte), pairing code hint (4 bytes) in the advertisement. Classic advertising is limited to 31 bytes. Extended gives us 254 bytes. |
| Range | **30m+ outdoor line-of-sight** | The robot is in the yard. Phone might be inside the house or across the yard. BLE 5.0 long range mode can do 100m+ outdoors. |
| Power consumption | **Low** — beacon runs continuously | Robot should broadcast BLE even when docked/idle so the app can always discover it. A BLE beacon typically draws < 1mA average. |
| Concurrent operation | Must work **simultaneously with Wi-Fi** | We need BLE for discovery while Wi-Fi handles data. The module must support both radios active at once. |
| Security | Support for **LE Secure Connections (LESC)** | Required for the SRP key exchange during pairing. LESC uses ECDH (Elliptic Curve Diffie-Hellman) for key generation. |

### Recommended Module Options

These are suggestions, not mandates. The mechanical team should factor in physical size, power budget, antenna placement, and cost.

| Option | Description | Why It Fits |
|---|---|---|
| **ESP32-S3** or **ESP32-C3** | Low-cost combo Wi-Fi + BLE 5.0 chip. Widely used in IoT. | If the AIP (Jetson or similar) doesn't have built-in BLE, a separate ESP32 can handle both the Wi-Fi AP mode and BLE beacon, communicating with the AIP over UART or SPI. Very cheap (~$3-5). Huge community, well-documented. |
| **Built-in on the AIP** | If using Jetson Orin Nano or similar, check if it has onboard BLE | Jetson Orin Nano does NOT have built-in Bluetooth. You'd need a USB BLE dongle or a separate module. Raspberry Pi CM4 has built-in BLE 5.0 (but probably not your AIP). |
| **Dedicated BLE module (e.g., Nordic nRF52840)** | Standalone BLE 5.0 SoC | Overkill for our needs unless you want BLE mesh or long-range mode. More expensive and more complex than just using an ESP32. |
| **Intel AX200/AX210 M.2 card** | Wi-Fi 6 + BLE 5.2 combo card | If the AIP has an M.2 slot, this gives you both radios in one card. Common in Jetson carrier boards. |

### Antenna Placement Note for Mechanical Team

BLE and Wi-Fi antennas should be placed:
- **Not inside a metal enclosure** — metal blocks RF completely
- **As high on the robot as practical** — ground proximity reduces range
- **Away from motor drivers and power electronics** — EMI from H-bridges and PWM will degrade signal quality
- **If using PCB antennas**, keep a ground plane clearance zone around the antenna area per the module datasheet
- **If using external antennas**, an SMA connector with a small stubby antenna on top of the robot housing works well for outdoor range

---

## 2. Wi-Fi Module

### What It Does for Us

| Function | How Wi-Fi Is Used |
|---|---|
| **Hotspot mode (AP)** | Robot creates its own Wi-Fi network for first-time setup and fallback when home Wi-Fi is unavailable |
| **Station mode (STA)** | Robot joins the user's home Wi-Fi for daily operation |
| **Data transport** | All real-time control (joystick, telemetry, E-Stop) runs over Wi-Fi via WebSocket |
| **Cloud uplink** | When on home Wi-Fi, robot can reach the cloud server for OTA updates and telemetry upload |

### What We Need from the Hardware

| Requirement | Specification | Why |
|---|---|---|
| Wi-Fi standard | **Wi-Fi 5 (802.11ac) minimum**, Wi-Fi 6 preferred | 802.11n (Wi-Fi 4) works but has worse outdoor range and more interference susceptibility. Wi-Fi 5/6 has better MIMO and beamforming for outdoor use. |
| Dual-band | **2.4 GHz required, 5 GHz preferred** | 2.4 GHz has better range and wall penetration (critical — robot is outside, router is inside). 5 GHz is faster but shorter range. Having both gives the robot options. |
| AP + STA concurrent | **Nice to have, not required** | Some chips (ESP32) can run AP and STA simultaneously. This means the robot could stay on home Wi-Fi while also running its hotspot for a secondary phone. Not critical for v1. |
| Outdoor range | **50m+ from a typical home router** | The back of a large yard. With 2.4 GHz and a decent antenna, this is achievable. |
| Throughput | **Minimum 5 Mbps** | Telemetry is tiny (< 10 KB/s). But if we add a camera feed later, we'll want bandwidth headroom. |
| Security | **WPA3-Personal support** | WPA2 is acceptable for v1 but WPA3 is the direction everything is moving. |

### Combo Module vs Separate

If the AIP already has Wi-Fi (many Jetson carrier boards include it), a separate module isn't needed for Wi-Fi. In that case, you only need to add BLE capability.

| AIP Has Wi-Fi? | AIP Has BLE? | What to Add |
|---|---|---|
| Yes | Yes | Nothing — use what's there |
| Yes | No | Add BLE-only module (ESP32-C3 is cheapest) or USB BLE dongle |
| No | No | Add combo module (ESP32-S3 recommended) or M.2 Wi-Fi+BLE card |

---

## 3. What Happens If We Skip BLE

BLE is not strictly required. The app will work without it. But the user experience degrades substantially.

### First-Time Pairing

| Step | With BLE | Without BLE |
|---|---|---|
| 1 | Open app, tap "Set Up Robot" | Open app, tap "Set Up Robot" |
| 2 | App scans BLE, finds robot. Shows "Robot found nearby. Tap to pair." | App shows: "Go to your phone's Settings > Wi-Fi and connect to the network named CHOREROBOT-XXXX" |
| 3 | User taps. App reads hotspot SSID from BLE, auto-connects to robot hotspot | User leaves the app, opens Settings, scrolls through Wi-Fi list, finds CHOREROBOT-XXXX, taps it, waits for connection, goes back to the app |
| 4 | Secure pairing happens automatically | Secure pairing happens |
| 5 | App asks "Connect robot to your home Wi-Fi?" User picks SSID, enters password | Same |
| 6 | Robot joins home Wi-Fi. BLE confirms success. App auto-switches back to home Wi-Fi | Robot joins home Wi-Fi. App shows: "Now go back to Settings > Wi-Fi and reconnect to your home network" |
| 7 | Done. 2 taps. Never left the app. | Done. 6+ steps. Left the app twice. User confused about which Wi-Fi to be on. |

### Daily Reconnection When Wi-Fi Fails

| Scenario | With BLE | Without BLE |
|---|---|---|
| Router rebooted, robot fell back to hotspot mode | App detects robot via BLE, shows "Robot is nearby but not on your network. Reconnect?" One tap. | App shows "Robot not found." User has to figure out that the robot is in hotspot mode, go to Settings > Wi-Fi, manually connect, then reconfigure. |
| User changed Wi-Fi password | BLE side-channel still works. App detects robot, prompts for new Wi-Fi credentials. | Robot is completely unreachable until user manually connects to its hotspot. |
| Robot is in the yard, mDNS is slow | BLE confirms robot is nearby instantly (~1s). App shows "connecting..." with confidence. | App spins on mDNS discovery with no feedback. User doesn't know if robot is on or off. |

### Cost of Adding BLE

| Approach | Part Cost | Complexity |
|---|---|---|
| ESP32-C3 module (BLE only, Wi-Fi bonus) | ~$3-5 | UART connection to AIP, firmware for BLE beacon + GATT service |
| USB BLE dongle | ~$10-15 | Plug into AIP USB port, use BlueZ on Linux |
| M.2 combo card (if AIP has slot) | ~$15-25 | Driver support varies by card and AIP platform |

**Recommendation:** The UX improvement from BLE is massive relative to the ~$5 cost. Strongly recommend including it.

---

## 4. Physical E-Stop Button

This is a hardware requirement from the safety architecture, not the app. But it directly affects the app's UX so it's documented here.

### What We Need

A physical button on the robot body that:
- **Immediately cuts all motor power** (hardware circuit, not software — the TC397 firmware already supports this via the GPIO enable pin)
- **Is brightly colored (red) and clearly labeled**
- **Is accessible from multiple angles** — someone approaching a misbehaving robot shouldn't have to reach around to the back
- **Is latching** — once pressed, stays pressed. Robot stays stopped until physically reset. The app cannot override this.

### Why It Matters for the App

The app's software E-Stop sends a CAN command (0x102, stop_type=0x01). This depends on:
- The Wi-Fi connection working
- The AIP receiving and forwarding the command
- The CAN bus being functional
- The TC397 firmware processing the command

If any of those fail, the software E-Stop does nothing. The physical button bypasses all of them.

The app's E-Stop flow:
1. User taps E-Stop in app
2. App sends command over WebSocket + UDP broadcast
3. If no acknowledgment in 1 second, app displays: **"E-Stop not confirmed. Press the physical button on the robot."**

The app must always assume the software E-Stop might fail and guide the user to the physical backup.

---

## 5. LED Indicator or Small Display on Robot (Nice to Have)

### What It Would Do

| Indicator | Purpose |
|---|---|
| **Status LED (RGB)** | Green = nominal, Yellow = warning, Red = fault/ESTOP, Blue flashing = pairing mode, White flashing = hotspot active |
| **Small OLED display** (128x64 or similar) | Show pairing code during setup, current IP address, battery %, error codes. Useful for debugging without the app. |

### Why It Helps

- During first-time pairing, the 6-digit pairing code needs to be displayed SOMEWHERE on the robot. Without a screen, you'd have to use a fixed code printed on a sticker (less secure) or blink it via LED (terrible UX).
- When troubleshooting connectivity, being able to see the robot's IP address or "Wi-Fi: connected" vs "Wi-Fi: disconnected" on the robot itself is invaluable.
- A status LED visible from 20+ meters lets the user confirm the robot's state without pulling out their phone.

### If Rejected

If the mechanical team can't include a display:
- Pairing code can be printed on a label inside the battery/maintenance compartment (static code, less secure but workable)
- Status can be communicated via LED color only (limited but functional)
- All debugging requires the app or a laptop connected to the AIP

---

## 6. Summary Table for Mechanical Team

| Component | Priority | Estimated Cost | Impact on User Experience |
|---|---|---|---|
| **Wi-Fi module** (2.4 GHz, AP+STA capable) | REQUIRED | $0 if AIP has it, ~$5 if separate | Without it, no app at all |
| **BLE 5.0 module** | STRONGLY RECOMMENDED | ~$3-5 (ESP32-C3) | Without it: clunky pairing, manual Wi-Fi switching, no proximity detection |
| **Physical E-Stop button** (latching, hardware kill) | REQUIRED (safety) | ~$5-15 | Without it: no backup when software E-Stop fails |
| **Status LED (RGB)** | RECOMMENDED | ~$1 | Without it: no visible robot state from distance |
| **Small OLED display** | NICE TO HAVE | ~$5-10 | Without it: pairing code on a sticker, no on-robot debugging |
| **External antenna (Wi-Fi)** | RECOMMENDED for outdoor range | ~$3-5 | Without it: reduced range, more dropouts in large yards |
| **External antenna (BLE)** | OPTIONAL | ~$2-3 | PCB antenna is usually sufficient for BLE range |
