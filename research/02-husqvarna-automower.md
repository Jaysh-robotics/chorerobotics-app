# Husqvarna Automower — Competitive Research

> Industry benchmark for robotic mower interfaces. Swedish design heritage.
> "Automotive Dashboard" philosophy — feels like a luxury vehicle cockpit.

## Design Philosophy

Leverages Husqvarna's Swedish design heritage to create a luxury vehicle cockpit feel. Widely regarded as the benchmark for robotic mower interfaces. Uses dark theme by default.

## Color Palette

| Token | Value | Usage |
|-------|-------|-------|
| Default Theme | Dark charcoal/black | Premium, automotive feel |
| Signature Orange | `#FF6900` / `#FD4F00` | CTAs (Start), active selections, edit icons |
| Go Green | Semantic green | "Mowing", "Ready", full battery |
| Warning | Yellow/Red | "Stuck", "Outside Boundary" |
| Text Primary | White | Headers |
| Text Secondary | `#A0A0A0` | Light gray, secondary info |

## Typography

- Custom sans-serif ("Husqvarna Gothic" or geometric sans)
- Bold white headings, lighter weights for secondary
- Clear hierarchy through weight and opacity

## Features List

### Core Features
| # | Feature | Description | Relevance to ChoreRobotics |
|---|---------|-------------|---------------------------|
| 1 | **Satellite Map with Custom Overlays** | Google Earth imagery with green mowing zones, red stay-out zones | HIGH — We use vector maps. Consider satellite view option |
| 2 | **Real-Time Robot Tracking** | Live robot icon on satellite view with coverage heat map | HIGH — We show robot position. Add path trace/coverage map |
| 3 | **Cutting Height Slider** | Smooth slider with real-time numeric updates and blade graphic | HIGH — We have sliders for overlap. Add cutting height control |
| 4 | **Timeline Scheduling** | Day-of-week list with colored bars on 24-hour timeline | HIGH — We lack scheduling. This is a good UX pattern to follow |
| 5 | **Weather Timer Override** | Cloud/sun toggle that overrides schedule based on rain/grass growth | MEDIUM — Nice-to-have. Requires weather API integration |
| 6 | **3D Model Dashboard** | High-res 3D rendering of user's specific Automower model | MEDIUM — We use photos. 3D renders more premium |
| 7 | **5-Tab Bottom Navigation** | Dashboard, Map, Messages, History, Settings | HIGH — We already have 5-tab nav (Home, Control, Map, Battery, More) |
| 8 | **Battery with Charging Animation** | Pill icon with %, lightning bolt, pulsing green fill | HIGH — Our battery screen shows this. Match the animation quality |
| 9 | **Mowing Progress Ring** | Circular progress or percentage for task completion | MEDIUM — We show estimated time. Add progress tracking during active mow |
| 10 | **Micro-Interactions** | Haptic feedback, smooth transitions between views | HIGH — We have animations. Ensure haptic in Flutter |

### UX Patterns
| # | Pattern | Description | Relevance |
|---|---------|-------------|-----------|
| 11 | **Contextual Model Imagery** | Shows exact user hardware model, not generic robot | HIGH — We could render different attachment configurations |
| 12 | **Dual Schedule Windows** | Two mowing windows per day (morning + evening) | MEDIUM — Scheduling feature we should support |
| 13 | **Hidden Advanced Settings** | Loop signal, installation settings buried deep | HIGH — We should follow same pattern. Keep main UI clean |
| 14 | **Dark Space Design** | Generous whitespace in dark theme for breathing room | HIGH — Our cards could use slightly more padding |
| 15 | **Status Card Priority** | Large status card at top with current state in bold | CRITICAL — Already implemented in our dashboard |

## Key Takeaways for ChoreRobotics

1. **Satellite map option** — Consider hybrid vector/satellite map view.
2. **Scheduling with weather override** — Important for lawn care automation.
3. **Cutting height control** — We should add blade height settings.
4. **Coverage heat map** — Show mowed area vs remaining during active task.
5. **Progressive disclosure** — Hide technical settings deep, keep main UI focused.
