# Complete Feature List — Phased Build Plan

## Phase 1: Core MVP (Screens 01-10)

> Goal: Functional app that can pair, control, and operate the robot for all three tasks.

### 1.1 Authentication (Screen 01)
| Feature | Priority | Description |
|---|---|---|
| Email/password sign in | P0 | Standard auth with validation |
| Remember me toggle | P0 | Persist session token |
| Create account | P0 | Registration flow |
| Forgot password | P1 | Email reset link |
| Guest mode | P2 | Limited access without account |
| Biometric login | P2 | Face ID / fingerprint after first login |

### 1.2 Onboarding / Robot Setup (Screens 02a-02d)
| Feature | Priority | Description |
|---|---|---|
| BLE scanning | P0 | Discover nearby robots via Bluetooth |
| Scan animation | P1 | Pulse rings + blinking dot during scan |
| Signal strength bars | P0 | 4-bar strength indicator |
| Robot selection | P0 | Tap discovered robot to select |
| UUID verification | P0 | Display robot UUID for physical label check |
| 6-digit pairing code | P0 | Enter code shown on robot's display |
| Attachment detection | P0 | Auto-detect connected attachment type |
| Wi-Fi network picker | P0 | Scan and list available networks |
| Wi-Fi password entry | P0 | Password field with show/hide toggle |
| Success confirmation | P0 | Summary of paired robot + connection info |
| What's Next guide | P1 | 3-step onboarding checklist |

### 1.3 Dashboard (Screen 03)
| Feature | Priority | Description |
|---|---|---|
| Robot status card | P0 | State (Idle/Mowing/Charging/Error) + attachment info |
| Battery progress bar | P0 | % with estimated runtime |
| Quick actions (Start/Dock/Pause) | P0 | 3-button row with brand gradient icons |
| Live metrics | P0 | Battery cycles, signal, blade status, speed, temp |
| LIVE badge | P1 | Magenta pulsing indicator when streaming telemetry |
| Recent activity log | P0 | Last 3-5 events with severity dots + timestamps |
| Connection bar | P0 | Connection mode (Local/Remote/Offline) + battery % |
| Brand line | P1 | 2px gradient strip below status bar |
| Logo in app bar | P1 | Small logo mark next to "Dashboard" title |
| Settings icon | P0 | Navigate to settings |

### 1.4 Manual Control (Screen 04 — Landscape)
| Feature | Priority | Description |
|---|---|---|
| Virtual joystick | P0 | Single stick for drive control, spring-back to center |
| Speed/heading HUD | P0 | Real-time speed (m/s) + heading (degrees) |
| Compass indicator | P0 | Circular compass with N/S/E/W + heading needle |
| Motor speed grid | P0 | FL/FR/RL/RR individual motor values |
| Blade toggle | P0 | On/off switch for blade/attachment |
| Auto Mode button | P0 | Switch from manual to autonomous |
| Return to Dock button | P0 | Send robot home |
| Pause button | P0 | Pause current operation |
| E-Stop | P0 | ALWAYS visible, safety yellow border |
| MANUAL badge | P1 | Purple badge indicating manual mode |
| Battery indicator | P0 | % in top bar |
| Landscape lock | P0 | Force landscape orientation |

### 1.5 Map / Boundary Training (Screen 05 — Landscape)
| Feature | Priority | Description |
|---|---|---|
| Map canvas with grid | P0 | Vector map with background grid |
| Mow zone polygon | P0 | Green zone with vertices |
| Snow zone polygon | P0 | Blue zone |
| Leaf zone polygon | P0 | Orange zone |
| No-go zone (hatched) | P0 | Red hatched polygon |
| Zone type selector | P0 | Tab bar: Mow/Snow/Leaf/No-Go |
| Vertex pins (draggable) | P0 | Edit zone shape by dragging vertices |
| Joystick for boundary driving | P0 | Drive robot along perimeter to record |
| Drop Pin button | P0 | Place vertex at current robot position |
| Robot position marker | P0 | Animated blue dot with pulse |
| Robot trail (breadcrumb) | P1 | Dashed line showing boundary recording path |
| Dock icon | P1 | Show charging station location |
| Zone info overlay | P1 | Count of defined zones |
| Scale indicator | P1 | "5m" reference bar |
| Undo button | P0 | Remove last vertex |
| Done button | P0 | Finalize zone |
| E-Stop | P0 | Always visible |

### 1.6 Battery (Screen 06)
| Feature | Priority | Description |
|---|---|---|
| Big battery visualization | P0 | Vertical battery icon with gradient fill + percentage |
| Estimated runtime | P0 | "~2h 15m mowing" |
| Charge status badge | P0 | Discharging/Charging/Full |
| Cycle count + progress bar | P0 | 142/500 with visual bar |
| Battery health % | P0 | Overall health indicator |
| Temperature | P0 | Current battery temp |
| Voltage | P0 | Current voltage reading |
| Current draw | P0 | Amperage |
| 7-day history chart | P1 | Line chart with gradient fill showing charge/discharge |

### 1.7 Diagnostics (Screen 07)
| Feature | Priority | Description |
|---|---|---|
| System health summary | P0 | Checkmark icon + "All Systems Normal" |
| Tab toggle (Overview/Technical/Faults) | P0 | 3-tab view switcher |
| Component status rows | P0 | Motors, Blade, Battery, Connection, Data Link |
| NOMINAL badge | P1 | Purple badge in connection bar |
| Recent alerts log | P0 | Severity-colored dots + descriptions + timestamps |
| Export button | P1 | Export diagnostics as file |

### 1.8 Mowing Patterns (Screen 08)
| Feature | Priority | Description |
|---|---|---|
| Zone summary card | P0 | Zone name + area + no-go count + Ready badge |
| Pattern selection grid | P0 | 4 patterns: Straight, Diagonal, Checker, Spiral |
| Pattern preview SVGs | P0 | Visual preview with brand gradient colors |
| Stripe angle slider | P0 | 0-180 degrees |
| Pass overlap slider | P0 | 0-30% |
| Estimated time | P0 | Calculated from zone size + pattern |
| Battery needed % | P0 | Estimated battery consumption |
| Start Mowing button | P0 | Primary action |
| Cutting height slider | P0 | **NEW** — blade height setting (missing feature) |

### 1.9 Snow Plowing (Screen 09)
| Feature | Priority | Description |
|---|---|---|
| Attachment check card | P0 | Snow plow detected + Ready badge |
| Start position selector | P0 | 4 radio options: Entrance/Garage/Center/Custom |
| Snow depth toggle | P0 | Light/Medium/Heavy |
| Snow disposal grid | P0 | Push Left/Right/Pile Zone |
| Estimated time + passes | P0 | Calculation display |
| Start Plowing button | P0 | Primary action |

### 1.10 Leaf Collection (Screen 10)
| Feature | Priority | Description |
|---|---|---|
| Attachment check card | P0 | Leaf collector detected + orange Ready badge |
| Mode toggle | P0 | Full Zone / Spot Clean |
| Spot clean map | P0 | Mini map with drawable polygon |
| Collection mode selector | P0 | Mulch vs Collect to Bag |
| Dump point marker | P0 | Set/change leaf dump location |
| Estimated time + bag capacity | P0 | Calculation display |
| Start Collection button | P0 | Primary action (orange) |

### 1.11 E-Stop (Global Overlay)
| Feature | Priority | Description |
|---|---|---|
| Floating E-Stop bar | P0 | Red + yellow border, always visible except auth |
| Pulse animation | P0 | White dot with breathing animation |
| Long-press to activate | P0 | Prevent accidental triggers |
| Immediate hardware command | P0 | Bypasses all state management |
| Recovery flow | P1 | Multi-step unlock after E-Stop |

---

## Phase 2: Table Stakes (Screens 11-12 + Enhancements)

> Goal: Features every competitor has. Users expect these.

### 2.1 Task Scheduling (NEW Screen 11)
| Feature | Priority | Description |
|---|---|---|
| Day-of-week selector | P0 | Toggle which days to schedule |
| Time picker | P0 | Set start time for each day |
| Task type selector | P0 | Mow/Plow/Collect |
| Zone selector | P0 | Which zone to operate on |
| Pattern/settings per schedule | P1 | Save mowing pattern with schedule |
| Dual windows per day | P1 | Morning + evening schedules |
| Calendar view | P1 | Visual weekly timeline |
| Enable/disable toggle | P0 | Turn individual schedules on/off |
| Saved presets | P1 | Name and reuse configs ("Sunday Front Yard") |

### 2.2 Settings (NEW Screen 12)
| Feature | Priority | Description |
|---|---|---|
| Robot info | P0 | Name, model, serial, firmware version |
| Rename robot | P0 | Custom name |
| Connection settings | P0 | Wi-Fi network, BLE auto-connect |
| Notification preferences | P0 | Toggle push notifications by type |
| Units (metric/imperial) | P0 | Distance, temperature units |
| Account settings | P0 | Email, password change, sign out |
| About / legal | P1 | Version info, licenses |
| Factory reset | P1 | Full robot reset (with confirmation) |

### 2.3 Active Task Progress (Enhancement)
| Feature | Priority | Description |
|---|---|---|
| Progress overlay on dashboard | P0 | % complete + area done during active task |
| Coverage map on active map | P0 | Semi-transparent fill showing completed area |
| Path trace during operation | P0 | Real-time breadcrumb trail |
| ETA countdown | P1 | Estimated time remaining |

### 2.4 Cutting Height Control (Enhancement)
| Feature | Priority | Description |
|---|---|---|
| Height slider on mowing screen | P0 | Set blade height before task |
| Height presets | P1 | Low/Medium/High quick select |

---

## Phase 3: Power User Features

> Goal: Features that build trust and loyalty with engaged users.

### 3.1 RTK/GPS Status (Enhancement)
| Feature | Priority | Description |
|---|---|---|
| RTK status in connection bar | P0 | FIX/FLOAT/SINGLE color-coded labels |
| Satellite count | P1 | Number of visible satellites |
| Position accuracy | P1 | Accuracy in cm/m |

### 3.2 Push Notifications
| Feature | Priority | Description |
|---|---|---|
| Task complete notification | P0 | "Front Yard mowing complete" |
| Error/fault notification | P0 | "Robot stuck — manual intervention needed" |
| Battery low warning | P0 | "Battery at 15% — returning to dock" |
| Connection lost alert | P1 | "Lost connection to ChoreBot" |
| Weather alert | P2 | "Rain expected — skipping scheduled mow" |

### 3.3 Firmware Updates (NEW Screen 13)
| Feature | Priority | Description |
|---|---|---|
| Update available banner | P0 | Show on dashboard when update ready |
| Release notes | P0 | What's new in this version |
| Download + install progress | P0 | Progress bar with status |
| Rollback option | P1 | Revert to previous firmware |

### 3.4 Task History & Analytics (NEW Screen 14)
| Feature | Priority | Description |
|---|---|---|
| Job history list | P0 | Past tasks with date/time/duration/area |
| Area mowed over time chart | P1 | Weekly/monthly trends |
| Battery usage trends | P1 | Charge cycles over time |
| Efficiency metrics | P2 | m2/minute, battery per m2 |

---

## Phase 4: Differentiators

> Goal: Features that set ChoreRobotics apart from all competitors.

| Feature | Phase | Description |
|---|---|---|
| Weather integration | P4 | Auto-adjust schedule based on forecast |
| Satellite map view | P4 | Toggle between vector and satellite |
| FPV camera feed | P4 | Live video from robot (requires hardware) |
| Dual joystick | P4 | Second stick for attachment-specific control |
| Multi-robot fleet | P4 | Manage multiple ChoreBot units |
| AI voice commands | P4 | "Hey ChoreBot, mow the front yard" |
| Dynamic font sizing | P4 | Adjustable text size for outdoor use |
| 3D robot model | P4 | Interactive 3D render on dashboard |

---

## Feature Count Summary

| Phase | New Screens | Features | Status |
|---|---|---|---|
| Phase 1 | 10 screens | ~85 features | Designed (HTML mockups ready) |
| Phase 2 | 2 screens + enhancements | ~20 features | Planned |
| Phase 3 | 2 screens + enhancements | ~15 features | Planned |
| Phase 4 | Enhancements only | ~8 features | Future |
| **Total** | **14 screens** | **~128 features** | |
