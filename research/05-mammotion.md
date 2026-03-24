# Mammotion (LUBA) — Competitive Research

> RTK GPS robotic mower. Wire-free boundary mapping.
> "Precision Instrument" — balances high-end consumer appeal with industrial tool feel.

## Design Philosophy

Data-driven precision interface. Prioritizes real-time spatial data and RTK GPS feedback. The most technically transparent of all competitors — shows satellite counts, RTK status, and positioning accuracy prominently.

## Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| Primary | Forest green + Tech blue | Lawn + GPS/connectivity |
| Backgrounds (Light) | Soft white/light gray | Light mode |
| Backgrounds (Dark) | Deep charcoal/true black | Night mode |
| Alerts | Orange/Yellow | Path obstacles, critical alerts |
| RTK Fixed | Green | <2cm accuracy |
| RTK Float | Orange | Sub-meter accuracy |
| RTK Single | Red | Standard GPS (unreliable) |
| Vision Fusion | Blue | GPS + Vision combined |

## Typography

- Geometric sans-serif (Inter/Roboto)
- Bold 700 for primary status ("CHARGING") and zone names
- Medium 500 for button labels
- Regular 400 for descriptive text
- Supports user-adjustable font sizing for outdoor readability

## Features List

### Core Features
| # | Feature | Description | Relevance to ChoreRobotics |
|---|---------|-------------|---------------------------|
| 1 | **RTK GPS Status Dashboard** | Sky plot, satellite bar charts, FIX/FLOAT/SINGLE indicators | HIGH — We should show GPS/RTK status. Critical for user trust |
| 2 | **Wire-Free Boundary Mapping** | Drive robot along perimeter to record via RTK GPS | CRITICAL — We use the exact same approach |
| 3 | **Joystick RC During Mapping** | Virtual joystick overlay with pulsing recording indicator | CRITICAL — Already implemented in our map screen |
| 4 | **Mowing Pattern Selection** | Parallel, Grid, Chessboard patterns | CRITICAL — Already implemented (Straight, Diagonal, Checker, Spiral) |
| 5 | **Coverage Map Visualization** | Semi-transparent overlay fills in as mowing progresses | HIGH — Add real-time coverage visualization during active mow |
| 6 | **Job Management System** | Renamable job cards (e.g., "Front Lawn - Fine Cut") | MEDIUM — Our task setup is per-session. Consider saved presets |
| 7 | **Cutting Height Slider** | Vertical slider with numeric increments | HIGH — We should add blade height control |
| 8 | **Path Sequence Options** | "Boundary First" or "Internal First" | MEDIUM — Advanced option for our mowing patterns |
| 9 | **Channel Connections** | Thin dashed lines connecting disconnected zones | MEDIUM — For multi-zone properties with paths between zones |
| 10 | **Real-Time Error Logging** | High-contrast alert icons with "Robot Trapped" / "Rain Detected" | HIGH — Our diagnostics screen covers this. Ensure real-time alerts |

### RTK-Specific Features
| # | Feature | Description | Relevance |
|---|---------|-------------|-----------|
| 11 | **Satellite Count Display** | Shows GPS, GLONASS, Galileo satellite counts | HIGH — Important for RTK-equipped robots |
| 12 | **Positioning Accuracy Label** | FIX/FLOAT/SINGLE with color coding | HIGH — Users need to know positioning quality |
| 13 | **Vision Module Indicator** | Red (lost), Green (GPS-only), Blue (GPS+Vision fusion) | MEDIUM — If we add vision sensors |
| 14 | **Real-Time Heading Arrow** | 60fps rotation matching IMU data | HIGH — Our compass shows heading. Ensure smooth updates |
| 15 | **Dark Map Overlay** | Satellite view with dark overlay for night operation | MEDIUM — Nice touch for evening use |

### UX Patterns
| # | Pattern | Description | Relevance |
|---|---------|-------------|-----------|
| 16 | **4-Tab Bottom Nav** | Dashboard, Map, Task/Schedule, Settings | HIGH — We use 5 tabs. Both patterns work |
| 17 | **Soft UI / Neumorphism-Lite** | 10% opacity shadows, large blur radius for floating panels | MEDIUM — Our current style is clean borders. Consider subtle shadows |
| 18 | **Contextual Floating Actions** | FAB appears when zone is tapped | MEDIUM — Good for map interactions |
| 19 | **Boundary Glow During Recording** | Line pulses/glows during active mapping | HIGH — Add visual feedback during boundary recording |
| 20 | **Adjustable Font Sizes** | User can scale fonts for outdoor readability | MEDIUM — Accessibility feature. Add in settings |

## Key Takeaways for ChoreRobotics

1. **RTK status is table stakes** — If our robot uses RTK, we MUST show FIX/FLOAT/SINGLE status.
2. **Coverage visualization** — Real-time fill-in during mowing is expected.
3. **Saved job presets** — Users want to name and reuse configurations.
4. **Cutting height control** — Essential missing feature.
5. **Boundary glow feedback** — Important UX for our mapping screen.
6. **Most directly comparable competitor** — Mammotion's feature set is closest to ours.
