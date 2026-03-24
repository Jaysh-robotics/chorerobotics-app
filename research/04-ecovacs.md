# Ecovacs — Competitive Research

> Premium indoor robot vacuum/mop (Deebot series).
> "Smart Home Command Center" — professional tech + user-friendly modernity.

## Design Philosophy

Map-centric design with the floor plan occupying 60-70% of screen space. Blends professional tech aesthetics with accessible modernity. Uses 3D map views as a differentiator.

## Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| Brand Anchor | `#1D3E7F` ("Chathams Blue") | Deep professional blue |
| Electric Blue | Accent blue | AI assistant, active cleaning paths |
| Crete Green | `#56782C` | Ready status, full battery |
| Alerts | Red | Virtual boundaries, critical alerts |
| Surfaces | White + soft grays | Cards, secondary elements |

## Typography

- Modern sans-serif (Inter/Roboto family)
- Large bold headers for robot name and status
- Smaller lighter weights for technical metrics

## Features List

### Core Features
| # | Feature | Description | Relevance to ChoreRobotics |
|---|---------|-------------|---------------------------|
| 1 | **2D/3D Map Toggle** | Switch between top-down and isometric 3D view with furniture | LOW — Indoor-specific. Our outdoor maps don't need 3D furniture |
| 2 | **Interactive 3D Objects** | Tap sofa to command "clean under sofa" | LOW — Indoor-specific context |
| 3 | **YIKO AI Voice Assistant** | In-app AI assistant for natural language commands | LOW — Future roadmap. Complex to implement |
| 4 | **Slide-Up Control Panel** | Persistent bottom drawer with Start/Charge/Stop | MEDIUM — Drawer pattern could work for our control screens |
| 5 | **Suction + Water Flow Controls** | Multi-step selector for cleaning intensity | MEDIUM — Analogous to our blade speed / plow depth controls |
| 6 | **Video Manager (FPV)** | Landscape-mode live stream with joystick controls | MEDIUM — Similar to Yarbo's FPV. Requires camera hardware |
| 7 | **Color-Coded Room Maps** | Pastel-colored rooms (blues, pinks, yellows) | LOW — Indoor room segmentation. Not applicable outdoors |
| 8 | **Pinch-to-Zoom Map Editing** | Place virtual walls and no-mop zones via gestures | HIGH — We should support pinch-to-zoom on our map screen |
| 9 | **Semi-Transparent HUD on Map** | Area cleaned, elapsed time, current mode overlaid on map | HIGH — Our map screen has zone info overlay. Match this data density |
| 10 | **Live Robot Trail on Map** | Pulsing icon leaving breadcrumb trail | HIGH — We show robot position. Add trail visualization |

### UX Patterns
| # | Pattern | Description | Relevance |
|---|---------|-------------|-----------|
| 11 | **Glassmorphism Overlays** | Blurred semi-transparent backgrounds on menus | MEDIUM — Premium feel. Consider for overlay panels |
| 12 | **Mode Selector Tabs** | Auto/Area/Custom horizontal scroll | HIGH — We use toggle groups. Similar pattern |
| 13 | **Granular Intensity Controls** | 4-level slider with visual icons | MEDIUM — Could apply to blade speed or mow height |
| 14 | **Map-Centric Layout (60-70%)** | Map dominates screen space | CRITICAL — Our landscape map screen already does this |
| 15 | **Floating White Cards** | Soft drop shadows, 16-20px radius | HIGH — Our card design is similar but tighter (10px) for industrial feel |

## Key Takeaways for ChoreRobotics

1. **Ecovacs is mostly indoor-specific** — Limited direct applicability, but good UX patterns.
2. **Map HUD overlay** — Show real-time stats (area, time, mode) overlaid on map during active tasks.
3. **Pinch-to-zoom** — Essential gesture for our map editing.
4. **Glassmorphism** — Consider for overlays and modals for premium feel.
5. **Intensity controls pattern** — Apply to blade speed/height settings.
