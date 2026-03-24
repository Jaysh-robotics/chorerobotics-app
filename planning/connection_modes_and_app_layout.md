# Connection Modes, Auto-Connection & App Layout

> How the app connects to the robot, the three connection modes, their strengths and problems, and how the app should look.

---

## 1. The Three Connection Modes

| Mode | How It Works | Latency | Phone Internet? | Range |
|---|---|---|---|---|
| **Direct Hotspot** | Robot creates AP, phone connects to it | ~5-15ms | NO — phone loses internet | ~30-50m (robot's radio) |
| **Shared Wi-Fi (LAN)** | Both on home router, mDNS discovery | ~10-30ms | YES | Home Wi-Fi coverage area |
| **Cloud Relay** | Commands route through cloud server | 100-500ms+ | YES | Anywhere on earth |

---

## 2. Mode 1: Direct Hotspot — Robot as Access Point

### Strengths

- Most reliable. No dependency on home router, ISP, or cloud.
- Lowest latency. Perfect for manual joystick control.
- Works on day one — no home Wi-Fi credentials needed. First-time setup uses this.
- Works in locations with no Wi-Fi (empty lot, rural property, commercial site).

### Problems

- **Phone loses internet.** No push notifications, no cloud telemetry, no OTA checks while connected. User gets the iOS/Android "this network has no internet" nag and some phones will silently switch back to cellular or a known Wi-Fi network, **dropping the robot connection without warning.**
- **User has to switch Wi-Fi networks.** Terrible UX. You open the app, it says "connect to CHOREROBOT-XXXX" and you have to go to Settings > Wi-Fi. Every time.
- **Only one phone can connect at a time** (unless the robot runs a proper AP with DHCP, which adds complexity to onboard compute).
- **No remote monitoring.** If you go inside, you lose the connection. Can't check on an autonomous mow from your couch.

### The Auto-Connect Problem

On Android, you can programmatically suggest a Wi-Fi network via `WifiNetworkSuggestion`. On iOS, you can use `NEHotspotConfiguration`. Both are janky — they prompt the user, they don't always stick, and iOS is especially aggressive about switching away from networks with no internet.

**Resolution:** Don't make the user switch Wi-Fi at all. Use hotspot mode only as a fallback. The primary path should be shared Wi-Fi (Mode 2).

---

## 3. Mode 2: Shared Wi-Fi (LAN) — The Happy Path

### Strengths

- Best UX. Phone stays on home Wi-Fi with internet. Robot is also on home Wi-Fi. App discovers robot via mDNS. User does nothing.
- Low latency. Good enough for joystick (~10-30ms).
- Phone keeps cloud connectivity — push notifications, OTA checks, telemetry uploads all work simultaneously.
- Multiple phones can connect to the same robot.

### Problems

- **Outdoor Wi-Fi coverage is often terrible.** The robot is in the yard. The router is inside the house. Concrete walls, distance, interference. The robot may have weak or intermittent connectivity.
- **AP isolation.** Some consumer routers (especially ISP-provided ones) enable "AP isolation" or "client isolation" by default — devices on the same network can't talk to each other. mDNS discovery fails. The app sees nothing.
- **Captive portals / guest networks.** If the robot is put on a guest network, it's isolated by design.
- **Robot needs Wi-Fi credentials.** Someone has to type the home Wi-Fi password into the robot somehow. Classic IoT bootstrapping chicken-and-egg: the robot can't join Wi-Fi until you tell it the password, but you can't tell it the password unless you're already connected to it.
- **SSID changes / password changes.** User changes their Wi-Fi password, robot is now offline with no way to reconfigure without falling back to hotspot mode.

### The Bootstrapping Solution

This is where the three modes connect to each other:

1. First time: phone connects to robot's hotspot (Mode 1)
2. Phone sends home Wi-Fi credentials to robot over the secure pairing channel
3. Robot joins home Wi-Fi, confirms success
4. Phone switches back to home Wi-Fi
5. From now on, Mode 2 is the default

If Mode 2 ever fails (router changed, robot can't connect), robot automatically falls back to creating its hotspot (Mode 1) so the user can reconfigure.

---

## 4. Mode 3: Cloud Relay — Limited Command Set

### Strengths

- Control from anywhere. Check on the robot from work. Start a mow before you get home.
- No range limitation.
- Works when you're not on the same network.

### Problems

- **Latency makes manual control dangerous.** 200ms+ round-trip means joystick control has visible lag. The robot moves, the user sees the old position, overcorrects. Not safe for a machine with spinning blades.
- **Dependency chain.** Phone internet + cloud server uptime + robot internet. Any link breaks, you're blind.
- **Attack surface.** The cloud server can now send commands to a robot with ASIL C blade hardware. If the cloud is compromised, every robot in the fleet is compromised. Nightmare scenario in ISO/SAE 21434 — a remote, scalable attack.
- **Latency varies unpredictably.** 100ms one second, 2000ms the next. Robot behavior becomes inconsistent from user's perspective.

### Resolution: Tiered Command Authority

Don't ban cloud commands entirely. Limit WHAT commands can be sent through the cloud:

| Command | Direct Hotspot | LAN | Cloud |
|---|---|---|---|
| Joystick (manual drive) | YES | YES | **NO** — latency makes it unsafe |
| Start Autonomous Mow | YES | YES | YES — robot confirms safe conditions locally before starting |
| Pause | YES | YES | YES |
| Return to Dock | YES | YES | YES |
| E-Stop | YES | YES | YES — app also says "if unresponsive, use physical button" |
| Blade On/Off | YES | YES | **NO** — too dangerous without real-time feedback |
| Mapping / Boundary Drawing | YES | YES | **NO** — requires real-time joystick |
| View Telemetry | YES | YES | YES |
| OTA Update | NO (no internet) | YES | YES |

The robot always has final authority. A cloud command is a *request*. The robot's safety system can reject it.

---

## 5. Seamless Auto-Connection

### Priority Logic

```
App Opens
  |
  +--> Try mDNS discovery on current Wi-Fi network (Mode 2: LAN)
  |      Found? --> Connect via mTLS --> DONE (best mode)
  |
  +--> Check BLE for robot advertisement (robot always broadcasts low-power BLE beacon)
  |      Found + LAN failed? --> Robot might be in hotspot mode
  |      App prompts: "Connect to robot directly?" (one tap, app handles Wi-Fi switch)
  |
  +--> Neither local? --> Fall back to cloud (Mode 3)
  |      Cloud has last-known robot status
  |      Limited command set available
  |
  +--> Nothing? --> "Robot not found" screen with troubleshooting
```

### Key Design Decisions

1. **BLE is the glue.** Robot always broadcasts a low-power BLE beacon (like AirTag). App uses this to know the robot is nearby even before Wi-Fi is established. BLE tells the app: "the robot is 10 meters away, it's in hotspot mode, here's its SSID." App then handles Wi-Fi switch automatically.

2. **The user never picks a mode.** The app shows a small indicator showing the current connection type:
   - Green lock icon: "Direct" (hotspot) or "Local" (LAN) — full control
   - Yellow cloud icon: "Remote" — limited control
   - Red X: "Disconnected"

3. **Mode switching is automatic and invisible.** If you walk away and LAN drops, app silently transitions to cloud mode. Joystick disappears from UI (not safe over cloud). Walk back, mDNS discovers robot, joystick reappears. No user action.

4. **Wi-Fi credential bootstrap only happens once.** During first-time pairing (BLE + hotspot), app asks: "Want the robot to join your home Wi-Fi?" User picks SSID, enters password, robot joins. Done forever (until password changes).

---

## 6. Connection Flow Diagrams

### Flow WITH BLE on the Robot

```
First-Time Setup:
  User opens app
    --> App scans BLE, finds robot beacon
    --> App displays: "Robot found nearby. Tap to pair."
    --> User taps. App reads robot's hotspot SSID from BLE advertisement
    --> App auto-connects to robot hotspot (NEHotspotConfiguration / WifiNetworkSuggestion)
    --> Secure pairing over hotspot (SRP key exchange, certificate exchange)
    --> App asks: "Connect robot to your home Wi-Fi?"
    --> User picks SSID, enters password
    --> Robot joins home Wi-Fi, confirms over BLE
    --> App switches back to home Wi-Fi
    --> mDNS discovers robot on LAN
    --> Done. Mode 2 (LAN) is now the default.

Daily Use:
  User opens app
    --> mDNS finds robot on LAN? --> Connect. Done.
    --> mDNS fails, BLE finds robot nearby? --> Robot might be in hotspot fallback
        --> App auto-switches to hotspot, reconnects
        --> Offers to re-enter Wi-Fi credentials if needed
    --> Neither? --> Cloud fallback with limited commands
```

### Flow WITHOUT BLE on the Robot

```
First-Time Setup:
  User opens app
    --> App shows: "Go to Settings > Wi-Fi and connect to CHOREROBOT-XXXX"
    --> User manually switches Wi-Fi (leaves the app, opens Settings, finds network, connects, comes back)
    --> App detects it's on robot's hotspot
    --> Secure pairing over hotspot
    --> App asks: "Connect robot to your home Wi-Fi?"
    --> User picks SSID, enters password
    --> Robot joins home Wi-Fi
    --> App tells user: "Go back to Settings > Wi-Fi and reconnect to your home network"
    --> User manually switches back
    --> mDNS discovers robot on LAN
    --> Done. But the user had to leave the app twice.

Daily Use:
  User opens app
    --> mDNS finds robot on LAN? --> Connect. Done.
    --> mDNS fails? --> App shows: "Robot not found on your network"
        --> "Try connecting directly: Go to Settings > Wi-Fi and connect to CHOREROBOT-XXXX"
        --> User manually switches (leaves app again)
    --> Neither? --> Cloud fallback
```

### The Difference Is Obvious

| Step | With BLE | Without BLE |
|---|---|---|
| First-time pairing | 2 taps, never leave the app | 6+ steps, leave app twice, manual Wi-Fi switching |
| Robot falls back to hotspot | Automatic — app detects via BLE and handles switch | Manual — user must go to Settings > Wi-Fi |
| Know robot is nearby before Wi-Fi | Yes (BLE beacon range ~30m) | No — you only know if mDNS works |
| Hotspot SSID discovery | Automatic from BLE advertisement | User has to visually find "CHOREROBOT-XXXX" in Wi-Fi list |
| Wi-Fi credential re-entry | BLE maintains side-channel even when Wi-Fi changes | Dead in the water until user manually connects to hotspot |

---

## 7. How the App Should Look

### Connection Bar (persistent, top of every screen)

Thin status bar showing: connection mode (Local/Remote/Disconnected) + signal strength + robot battery. Always visible. Color-coded. This is the user's trust indicator — "am I actually talking to the robot right now?"

### Home / Dashboard

- Robot status card (battery, state, current activity)
- Quick actions: Start Mow, Return to Dock, Pause
- Last activity summary
- Connection mode is obvious but not intrusive

### Control Screen

- Joystick (only visible in Local/Direct mode — **hidden** in Cloud mode, not grayed out)
- E-Stop button (always visible, always reachable, always red, full width)
- Current speed, blade state, heading indicator
- Mode indicator: Manual / Autonomous / Returning

### Map Screen

- Boundary polygons (mow zones, snow zones, exclusion zones)
- Robot position (real-time in Local, delayed in Cloud)
- Boundary editing tools (only in Local mode)

### Settings

- Wi-Fi configuration (robot's home network)
- User management (Owner, Household, Guest)
- Firmware update
- Activity logs
- Data privacy controls

### UI Rules for Safety

- **E-Stop:** minimum 80dp tall, full width, red, present on every screen as a floating overlay — not just the control screen
- **Connection mode change:** brief toast notification so user knows when they shift from Local to Cloud (and that joystick is now unavailable)
- **Cloud-forbidden actions:** buttons are **gone**, not grayed out. Don't show a disabled joystick in cloud mode — it confuses people. Just don't show it.
- **Latency indicator:** if round-trip > 100ms in local mode, show warning. Something is wrong with the network.
