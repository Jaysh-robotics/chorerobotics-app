# Phased Build Plan

## Phase 1: Core MVP

> Goal: Pair robot, drive it, map boundaries, run all 3 tasks.

### Sprint 1: Foundation (Week 1-2)
| Task | Files | Dependencies |
|---|---|---|
| Project restructure to feature-first arch | `lib/` restructure | None |
| Brand design system (AppColors, AppTheme, AppTypography) | `core/theme/` | Brand identity doc |
| Reusable components (BrandCard, BrandButton, EStopButton, ConnectionBar) | `core/theme/components/` | Theme |
| GoRouter setup with all Phase 1 routes | `core/router/` | None |
| Freezed models (Robot, Telemetry, Zone, Task, Attachment) | `core/models/` | freezed |
| Mock data service (returns fake telemetry stream) | `core/services/` | Models |

### Sprint 2: Auth + Onboarding (Week 3-4)
| Task | Screen | Dependencies |
|---|---|---|
| Auth screen (sign in form + logo) | 01 | Theme, Router |
| BLE scan screen with pulse animation | 02a | Theme, BLE lib |
| Pairing screen (UUID + code entry) | 02b | BLE lib |
| Wi-Fi setup screen (network picker) | 02c | WiFi lib |
| Setup complete screen | 02d | Router (→ dashboard) |
| Auth state management | Provider | Hive (token storage) |

### Sprint 3: Dashboard + Connection (Week 5-6)
| Task | Screen | Dependencies |
|---|---|---|
| Dashboard shell (bottom nav + E-Stop overlay) | Shell | Router |
| Dashboard hub (status card + quick actions + metrics + log) | 03 | Telemetry provider |
| Connection manager (BLE/WiFi/Cloud abstraction) | Core | BLE, WebSocket, MQTT |
| Telemetry stream provider | Core | Connection manager |
| Connection bar widget | Shared | Connection provider |

### Sprint 4: Control + Map (Week 7-8)
| Task | Screen | Dependencies |
|---|---|---|
| Manual control (landscape + joystick + compass) | 04 | Joystick widget |
| Joystick command sender (30Hz) | Core | Connection manager |
| Map editor (landscape + zone polygons) | 05 | Map/Canvas lib |
| Zone CRUD (create, edit, delete zones) | Core | Hive (persistence) |
| Boundary recording mode (drive + drop pin) | 05 | Joystick + GPS |

### Sprint 5: Battery + Diagnostics (Week 9-10)
| Task | Screen | Dependencies |
|---|---|---|
| Battery screen (big display + health metrics + chart) | 06 | Chart lib |
| Diagnostics screen (health summary + alerts + tabs) | 07 | Telemetry |
| 7-day battery history chart | 06 | Chart lib, Hive |

### Sprint 6: Task Screens (Week 11-12)
| Task | Screen | Dependencies |
|---|---|---|
| Mowing patterns (pattern grid + sliders + estimates) | 08 | Zone data |
| Snow plowing (start point + depth + disposal direction) | 09 | Zone data |
| Leaf collection (spot clean map + collection mode + dump) | 10 | Zone data |
| Task command sender (start/stop/pause) | Core | Connection manager |
| Cutting height slider (add to mowing) | 08 | - |

### Sprint 7: Integration + Polish (Week 13-14)
| Task | Description |
|---|---|
| End-to-end flow testing (auth → pair → map → mow) | Full flow |
| E-Stop testing on all screens | Safety critical |
| Connection failover testing (BLE→WiFi→Cloud) | Reliability |
| Brand consistency audit | All screens |
| Performance profiling (joystick latency, telemetry frame rate) | Optimization |
| Bug fixes and polish | - |

**Phase 1 Deliverable:** App that can sign in, pair a robot, map zones, and execute mow/plow/collect tasks with manual override.

---

## Phase 2: Table Stakes (Week 15-20)

### Sprint 8: Scheduling + Settings (Week 15-16)
| Task | Screen | Dependencies |
|---|---|---|
| Task scheduler screen | 11 (NEW) | Zone data, Hive |
| Settings screen | 12 (NEW) | Hive, Auth |
| Schedule persistence (local + sync to robot) | Core | Hive |
| Notification preferences UI | 12 | - |

### Sprint 9: Active Task UX (Week 17-18)
| Task | Description |
|---|---|
| Active task progress overlay on dashboard | Progress %, area, ETA |
| Coverage map (semi-transparent fill during mowing) | Map enhancement |
| Path trace / breadcrumb trail | Map enhancement |
| Task state transitions (pending→active→paused→complete) | State machine |

### Sprint 10: Cutting Height + Presets (Week 19-20)
| Task | Description |
|---|---|
| Height presets (Low/Med/High quick select) | Mowing enhancement |
| Saved job presets ("Sunday Front Yard") | Scheduling enhancement |
| Preset management (create, rename, delete) | Settings/Scheduling |

**Phase 2 Deliverable:** Scheduling, settings, active task visualization, saved presets.

---

## Phase 3: Power User (Week 21-28)

### Sprint 11-12: RTK + Notifications (Week 21-24)
| Task | Description |
|---|---|
| RTK/GPS status display in connection bar | FIX/FLOAT/SINGLE labels |
| Satellite count indicator | GPS data from telemetry |
| Push notification setup (FCM) | Firebase |
| Notification handlers (task complete, error, battery) | Background service |
| Local notifications (BLE disconnect) | flutter_local_notifications |

### Sprint 13-14: Firmware + History (Week 25-28)
| Task | Screen |
|---|---|
| Firmware update screen | 13 (NEW) |
| OTA update flow (download → verify → install → reboot) | Core |
| Task history screen with job list | 14 (NEW) |
| Analytics charts (area over time, battery trends) | Chart lib |

**Phase 3 Deliverable:** RTK status, notifications, firmware updates, task history.

---

## Phase 4: Differentiators (Week 29+)

| Feature | Effort | Dependency |
|---|---|---|
| Weather integration | Medium | Weather API |
| Satellite map view | Medium | Map tile provider |
| Robot orientation arrow on map | Small | Heading data |
| Boundary recording glow/pulse | Small | Animation |
| FPV camera feed | Large | Camera hardware |
| Dual joystick | Medium | Second stick widget |
| Multi-robot fleet management | Large | Backend changes |

---

## Timeline Summary

| Phase | Duration | Screens | Key Milestone |
|---|---|---|---|
| Phase 1 | 14 weeks | 10 screens | Robot paired + all tasks functional |
| Phase 2 | 6 weeks | +2 screens | Scheduling + settings + presets |
| Phase 3 | 8 weeks | +2 screens | Notifications + firmware + history |
| Phase 4 | Ongoing | Enhancements | Weather, FPV, fleet |
| **Total MVP** | **20 weeks** | **12 screens** | **Production-ready app** |
