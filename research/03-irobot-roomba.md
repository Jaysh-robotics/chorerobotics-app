# iRobot (Roomba) — Competitive Research

> Home robotics benchmark. Indoor robot vacuum/mop.
> "Friendly Home Companion" — prioritizes approachability over technical complexity.

## Design Philosophy

Reduces "robotics anxiety" by making LIDAR mapping and scheduling feel like simple home management. The most consumer-friendly of all competitors. Uses light theme by default.

## Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| Primary Accent | `#6CB86A` ("iRobot Green" / "Fern") | CLEAN button, success states, cleaned areas |
| Base Palette | White + cool grays `#F8F9FA` to `#E9E9EA` | Clean, welcoming feel |
| Dark Mode | `#121212` charcoal | Maintains green accents |
| Dirt Detect | Dark green squares | High-debris events |
| No-Go Zones | Red tinted with "no entry" icon | Restricted areas |

## Typography

- Custom sans-serif (Roboto/SF Pro family)
- Bold headers, light airy body text
- Lowercase logo reinforces "friendly" brand

## Features List

### Core Features
| # | Feature | Description | Relevance to ChoreRobotics |
|---|---------|-------------|---------------------------|
| 1 | **Big Green CLEAN Button** | Large circular/pill CTA — single tap to start | LOW — Our use case requires zone/pattern selection before start |
| 2 | **Smart Map (Vector Floorplans)** | Simplified 2D vector maps with labeled rooms | LOW — Indoor-only. Our outdoor maps need different approach |
| 3 | **Clean Zones** | Tap rooms on map to clean specific areas | MEDIUM — Similar to our zone selection. Different context (indoor rooms vs outdoor zones) |
| 4 | **No-Go Zones** | Red-tinted zones with "no entry" icon | HIGH — We already have this in our map screen |
| 5 | **Routine-Based Scheduling** | "When/What/Where" logic instead of alarm-clock lists | HIGH — Good UX pattern for scheduling. More intuitive than calendar grids |
| 6 | **Plain-English Status** | "Emptying bin", "Heading home" instead of error codes | MEDIUM — We use technical language. Consider friendlier messages for non-tech users |
| 7 | **Cleaning History** | Data visualizations showing sq footage cleaned over time | MEDIUM — Nice analytics feature for our "More" section |
| 8 | **Favorites System** | Quick-access routines (e.g., "Clean Kitchen after Dinner") | LOW — Less relevant for outdoor tasks that are zone-based |
| 9 | **System Dark/Light Mode** | Follows system theme | LOW — We're dark-mode-only (correct for outdoor robotics) |
| 10 | **Battery with Plain-English** | "Ready to clean - 100%" instead of just percentage | MEDIUM — We could add contextual messages alongside battery % |

### UX Patterns
| # | Pattern | Description | Relevance |
|---|---------|-------------|-----------|
| 11 | **Monolinear Icons** | Thin, consistent line icons. Only fill when active | MEDIUM — Our nav icons use unicode. Consider SVG icon set |
| 12 | **Micro-Animations on Start** | Button pulse, 3D model glow when robot starts | HIGH — Add subtle animations when task begins |
| 13 | **Cleaning Path Trace** | Faint trailing line showing robot's coverage | HIGH — We should show this during active mowing |
| 14 | **Vertical Card Stack** | Modular cards with subtle drop shadows | HIGH — Already our pattern |
| 15 | **Day-of-Week Toggles** | Simple toggle for which days to schedule | HIGH — Good pattern for our future scheduling feature |

## Key Takeaways for ChoreRobotics

1. **iRobot is the WRONG model for us** — Their consumer-friendly, light-theme approach is the opposite of what professional outdoor robotics needs.
2. **Plain-English status messages** — Worth borrowing for non-technical users. Add alongside technical data, not replacing it.
3. **Routine-based scheduling** — "When/What/Where" is more intuitive than calendar grids. Adopt this UX pattern.
4. **Cleaning path trace** — We should show real-time coverage during mowing.
5. **History/analytics** — Good post-task feature for the "More" section.
