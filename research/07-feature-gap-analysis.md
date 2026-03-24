# Feature Gap Analysis — ChoreRobotics vs Competitors

> Prioritized list of features we have, features we're missing, and what to build next.

## Features We Already Have (Competitive Parity)

These features exist across all major competitors and we already implement them:

| Feature | Our Screen | Competitor Reference | Status |
|---------|-----------|---------------------|--------|
| Dark mode professional UI | All screens | Yarbo, Husqvarna, DJI | DONE |
| E-Stop with safety yellow | All screens | Yarbo, DJI | DONE |
| Multi-attachment support | Dashboard, Snow, Leaf | Yarbo | DONE (unique strength) |
| BLE discovery + pairing flow | 02a-02d screens | All | DONE |
| Wi-Fi network setup | 02c screen | All | DONE |
| Dashboard with status cards | 03 screen | All | DONE |
| Landscape joystick control | 04 screen | Yarbo, Mammotion | DONE |
| Boundary mapping via driving | 05 screen | Yarbo, Mammotion | DONE |
| Multi-zone map (mow/snow/leaf/no-go) | 05 screen | Yarbo, Husqvarna | DONE |
| Battery health & visualization | 06 screen | All | DONE |
| Diagnostics & system health | 07 screen | All | DONE |
| Mowing pattern selection | 08 screen | Mammotion, Husqvarna | DONE |
| Snow plowing mode | 09 screen | Yarbo | DONE |
| Leaf collection mode | 10 screen | Yarbo | DONE |
| Live telemetry (speed, temp) | 03, 04 screens | Yarbo, Mammotion | DONE |
| Compass/heading display | 04 screen | All | DONE |
| Motor speed per wheel | 04 screen | Yarbo | DONE |
| 5-tab bottom navigation | All screens | Husqvarna | DONE |
| Connection mode indicators | Connection bar | All | DONE |
| Signal strength visualization | 02a screen | All | DONE |

## Features We're Missing (Gaps to Fill)

### Priority 1 — Critical (Expected by all users)

| Feature | Competitor | Description | Effort |
|---------|-----------|-------------|--------|
| **Task Scheduling** | Yarbo, Husqvarna, Mammotion | Schedule mow/plow/collect jobs by day/time. Calendar or "When/What/Where" pattern | Large |
| **Real-Time Coverage Map** | Husqvarna, Mammotion | Semi-transparent fill showing mowed area during active task | Medium |
| **Path Trace / Breadcrumb Trail** | All | Show where robot has been during current task | Medium |
| **Cutting Height Control** | Husqvarna, Mammotion | Slider to set blade height before mowing | Small |
| **Active Task Progress** | All | Progress % and area completed during active mow/plow | Medium |

### Priority 2 — High (Expected by power users)

| Feature | Competitor | Description | Effort |
|---------|-----------|-------------|--------|
| **RTK/GPS Status Display** | Mammotion | FIX/FLOAT/SINGLE indicators with satellite count | Medium |
| **Saved Job Presets** | Mammotion | Name and reuse task configurations (e.g., "Sunday Front Yard") | Medium |
| **Notification System** | All | Push notifications for task complete, errors, weather alerts | Medium |
| **Firmware Update Screen** | All | OTA firmware updates with progress bar | Medium |
| **Settings Screen** | All | Robot configuration, units, notifications, account | Medium |

### Priority 3 — Medium (Differentiators)

| Feature | Competitor | Description | Effort |
|---------|-----------|-------------|--------|
| **Weather Integration** | Husqvarna | Auto-adjust schedule based on rain forecast | Medium |
| **Task History / Analytics** | iRobot, Husqvarna | Log of past jobs with area/time/battery stats | Medium |
| **Satellite View Map** | Husqvarna | Google Maps satellite imagery as map background | Medium |
| **Pinch-to-Zoom Map** | Ecovacs, Mammotion | Gesture-based map interaction for zone editing | Small |
| **Robot Orientation on Map** | Yarbo, Mammotion | Live heading arrow on robot position marker | Small |
| **Boundary Recording Feedback** | Mammotion | Pulsing/glowing line during active boundary recording | Small |

### Priority 4 — Low (Future / Nice-to-Have)

| Feature | Competitor | Description | Effort |
|---------|-----------|-------------|--------|
| **FPV Camera Feed** | Yarbo, Ecovacs | Live video from robot camera | Large (requires hardware) |
| **3D Robot Renders** | Husqvarna, Yarbo | Replace photos with 3D models | Large (requires 3D assets) |
| **AI Voice Commands** | Ecovacs (YIKO) | Natural language task control | Large |
| **Dual Joystick** | Yarbo | Second stick for attachment control | Medium |
| **Dynamic Font Sizing** | Mammotion | User-adjustable text size for outdoor use | Small |
| **Multi-Robot Support** | Husqvarna | Manage fleet of robots | Large |

## Our Unique Strengths (No Competitor Matches All)

| Strength | Details | Competitors with Similar |
|----------|---------|------------------------|
| **Triple-mode operation** | Mow + Snow + Leaf in one app | Only Yarbo (but they have separate modules) |
| **Graduated connection failsafe** | 0-30s+ safety degradation with auto-dock | None this detailed |
| **mTLS + SRP security** | ISO 26262 / ISO 21434 compliant security architecture | None publish this level |
| **Three connection modes** | Direct hotspot + LAN + Cloud with automatic switching | None this transparent |
| **Spot clean for leaf collection** | Draw custom polygon for targeted leaf pickup | None |

## Recommended Build Order (Next 3 Phases)

### Phase 1: Table Stakes
1. Task Scheduling screen (new screen 11)
2. Settings screen (new screen 12)
3. Cutting height slider (add to mowing patterns)
4. Active task progress overlay

### Phase 2: Power User Features
5. RTK/GPS status indicators in connection bar
6. Real-time coverage map during active tasks
7. Path trace / breadcrumb trail
8. Saved job presets
9. Push notifications

### Phase 3: Differentiators
10. Task history & analytics
11. Weather integration
12. Satellite map view option
13. Firmware update screen
14. Robot orientation on map with heading arrow
