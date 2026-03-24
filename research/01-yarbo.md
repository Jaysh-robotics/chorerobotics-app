# Yarbo — Competitive Research

> iF Design Award 2024 winner. Multi-function yard robot (mowing, snow blowing, leaf blowing).
> **Primary inspiration** for ChoreRobotics due to identical product category.

## Design Philosophy

"Mission Control" — positions itself as a professional command center for outdoor robotics. Dark-mode-first. Draws from Tesla and DJI drone interfaces, not consumer home appliance apps.

## Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| Primary Background | `#121212` / Jet Black | OLED efficiency, outdoor visibility |
| Elevated Surfaces | `#1E1E1E` | Cards, panels |
| Primary Accent ("Yarbo Blue") | `#007AFF` | Action buttons, active toggles, path tracing |
| Success Green | Semantic green | "Ready" status, completed tasks |
| Warning Orange | Semantic orange | Low battery, weak GPS |
| Error Red | Semantic red | Emergency STOP, critical errors |

## Typography

- Clean modern sans-serif (Inter / SF Pro family)
- Semi-Bold for headers, Medium for data labels
- Sized for outdoor readability

## Features List

### Core Features
| # | Feature | Description | Relevance to ChoreRobotics |
|---|---------|-------------|---------------------------|
| 1 | **Smart Vision (FPV)** | Live 1080p camera feed from robot with GPS map overlay | HIGH — Future feature. Our robot has no camera yet, but this is the gold standard for remote operation |
| 2 | **Dual Joystick Control** | Left stick for movement, right for module-specific controls (chute rotation, auger speed) | HIGH — We have single joystick. Consider dual for blade/attachment control |
| 3 | **Multi-Attachment Support** | App adapts to current attachment (mower, snow blower, leaf blower) | CRITICAL — We already support this (mower, snow plow, leaf collector). Core differentiator |
| 4 | **Boundary Mapping via Driving** | User drives robot along perimeter to record boundaries | CRITICAL — We use the same approach. Our map screen already implements this |
| 5 | **Emergency Stop** | Persistent red STOP button, always accessible | CRITICAL — Already implemented. Our E-Stop with safety yellow border matches industry standard |
| 6 | **Work Plan Scheduling** | Calendar-style task scheduling with multi-zone support | HIGH — Not yet in our app. Should add scheduling screen |
| 7 | **3D Robot Renders** | High-quality 3D renders during setup and calibration | MEDIUM — We use photos. Consider 3D renders for more professional feel |
| 8 | **Signal Health Dashboard** | LTE, GPS, RTK indicators with color-coded status bars | HIGH — We show signal strength but could expose more telemetry |
| 9 | **Modular Dashboard Cards** | Battery, signal, GPS precision in separate cards | HIGH — Our dashboard already uses this pattern |
| 10 | **Point-to-Point Boundary Recording** | Surveying-tool feel for mapping | CRITICAL — Already implemented in our map screen |

### UX Patterns
| # | Pattern | Description | Relevance |
|---|---------|-------------|-----------|
| 11 | **FPV + Map Toggle** | Switch between full-screen video with mini-map, or full-screen map with PIP video | MEDIUM — Requires camera hardware |
| 12 | **Robot Silhouette with Orientation** | Top-down view showing real-time heading and attachment | HIGH — We show robot image but not real-time orientation |
| 13 | **Step-by-Step Setup Flow** | Guided pairing with 3D hardware renders | HIGH — We have a 4-step pairing flow already |
| 14 | **Data-Dense Telemetry** | GPS coordinates, speed in m/s, impeller RPM visible | HIGH — We show some metrics. Consider exposing more raw data |
| 15 | **Landscape Remote Control** | Full landscape mode for manual driving | CRITICAL — Already implemented in our control screen |

## Key Takeaways for ChoreRobotics

1. **Scheduling is missing** — Yarbo has robust work plan scheduling. We should add this.
2. **FPV camera** — Long-term hardware roadmap item.
3. **Dual joystick** — Consider for attachment-specific controls.
4. **Data density** — Show more telemetry to build trust with power users.
5. **Our multi-attachment support is already a match** — This is our strongest competitive alignment.
