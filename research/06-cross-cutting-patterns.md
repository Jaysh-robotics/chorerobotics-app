# Cross-Cutting Design Patterns — Professional Robotics Apps

> Design DNA shared across Yarbo, Husqvarna, Mammotion, DJI, and Tesla interfaces.
> These are the patterns that make an app feel "professional, stable, heavy-duty, ruggedized."

## 1. Dark Mode as Default Foundation

All outdoor/industrial robotics apps default to dark themes for three reasons:
- Outdoor visibility in varying light conditions
- OLED battery efficiency
- Premium/technical aesthetic

**Common background values:**
| Layer | Hex | Usage |
|-------|-----|-------|
| Primary | `#000000` | Pure black (Tesla, DJI) |
| Secondary | `#121212` | Material dark (Husqvarna, Yarbo) |
| Elevated | `#1E1E1E` | Cards, modals |

**ChoreRobotics:** We use `#0A0C10` / `#10131A` / `#151820` — correctly dark with neutral charcoal tone.

## 2. Restrained, Purposeful Color Usage

Color is NEVER decorative — it always communicates state:

| State | Color | Hex Range | Usage |
|-------|-------|-----------|-------|
| Ready / Operational | Green | `#00E676` — `#4CAF50` | System go, battery OK, RTK fixed |
| Warning / Degraded | Orange/Yellow | `#FF9800` — `#FFB300` | Low battery, weak signal, RTK float |
| Error / Emergency | Red | `#FF3B30` — `#FF5252` | E-stop, no-go zones, critical faults |
| Brand / Primary Action | Blue/Orange | App-specific | CTAs, active paths, selections |

**ChoreRobotics:** Our palette follows this exactly. Blue (`#0078FF`) for brand, green/yellow/red for state.

## 3. Emergency Stop — Industry Standard Design

| Element | Specification |
|---------|--------------|
| Placement | Always visible. Top-right corner OR full-width floating bar |
| Color | Red center (`#FF3B30` — `#FF5252`) |
| Border | Safety Yellow (`#FFD600`) 2-4px outer ring/glow |
| Size | 56-64dp height (large enough for panicked thumb) |
| Interaction | Long-press (1.5s) or slide-to-confirm to prevent accidents |
| Resume | Multi-step unlock process after stop |

**ChoreRobotics:** We have full-width red bar with yellow border. Matches standard. Consider adding long-press confirmation.

## 4. Signal Health as First-Class Citizens

Professional apps display connectivity status prominently:

| Indicator | Design | Level of Detail |
|-----------|--------|-----------------|
| GPS/RTK | Text labels: "FIX" / "FLOAT" / "SINGLE" with color coding | High |
| Signal Bars | 4-5 vertical bars, 2px gaps, inactive at 30% opacity | Medium |
| Battery | Horizontal pill + percentage + "time remaining" | High |
| Satellite Count | Numeric (e.g., "SAT: 26") alongside bars | High |

**ChoreRobotics:** We show basic signal/battery. Should add RTK status and satellite count.

## 5. Data Density Over Simplicity

Professional apps expose granular telemetry that consumer apps hide:

| Data Point | Consumer Apps | Professional Apps |
|------------|---------------|-------------------|
| Speed | Hidden | Shown in m/s |
| GPS | Hidden | Exact coordinates |
| Satellite Count | Hidden | Shown with signal quality |
| Blade RPM | Hidden | Shown in telemetry panel |
| Positioning Accuracy | Hidden | FIX/FLOAT/SINGLE labels |
| Temperature | Hidden | Shown (motor/battery temp) |

**ChoreRobotics:** Our dashboard shows speed, temperature. Diagnostics shows more. Good foundation.

## 6. High-Fidelity Hardware Visualization

Every professional app shows:
- 3D render or high-quality 2D sprite of the user's exact hardware model
- Real-time orientation/heading during operation
- Attachment status visualization
- Setup guides with 3D renders of physical hardware assembly

**ChoreRobotics:** We use photos. Consider upgrading to 3D renders for more polished feel.

## 7. Map as Mission Control

| Element | Specification |
|---------|--------------|
| Screen space | 60-70% of screen in landscape mode |
| Base layer | Satellite imagery (Husqvarna) or high-contrast vectors (Yarbo) |
| Zone overlays | 25-40% opacity fills with high-opacity strokes |
| Robot position | Updates at high frame rate with directional indicator |
| Path trace | Shows coverage history as breadcrumb trail |
| Scale indicator | Physical distance reference (e.g., "5m") |

**ChoreRobotics:** Our map screen covers most of this. Add satellite base layer option and path trace.

## 8. Card Design Specifications

| Property | Consumer (iRobot) | Prosumer (Ecovacs) | Professional (Yarbo/Husqvarna) |
|----------|-------------------|--------------------|-------------------------------|
| Border Radius | 16-24px (soft) | 16-20px (modern) | 8-16px (tighter, mechanical) |
| Shadows | Drop shadow | Soft neumorphism | 1px border, no/minimal shadow |
| Elevation | Via shadows | Via shadows + blur | Via brightness stepping |
| Padding | Generous (20px+) | Moderate (16-20px) | Compact (12-16px) |

**ChoreRobotics:** Our 10px radius and 1px borders with minimal shadow align with professional tier.

## 9. Typography for Outdoor Readability

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| Main status/headers | 24-28px | Bold (700) | High contrast, glanceable |
| Body text | 14-16px | Regular (400) | Readable in sunlight |
| Labels/subtext | 12px | Medium (500) at 60% opacity | Secondary info |
| Telemetry values | 14-16px | Bold (700), Monospace | Fixed-width for data alignment |
| Minimum contrast ratio | 7:1 | WCAG AAA | Not standard 4.5:1 |

**ChoreRobotics:** Our Inter font + monospace for values matches this pattern.

## 10. Navigation: 4-5 Bottom Tabs

| # | Standard Tab | Icon |
|---|-------------|------|
| 1 | Dashboard / Home | Gauge or Robot |
| 2 | Map / Control | Map or Crosshairs |
| 3 | Schedule / History | Calendar or Clock |
| 4 | Settings / More | Cog |
| 5 | (Optional) Battery / Shop | Battery or Cart |

**ChoreRobotics:** We use Home, Control, Map, Battery, More — matches the standard.

## Summary: Professional vs Consumer Design DNA

| Element | Consumer (iRobot) | Professional (Yarbo/Husqvarna/Mammotion) | ChoreRobotics Status |
|---------|-------------------|-----------------------------------------|---------------------|
| Default Theme | Light | Dark | Dark |
| Primary Accent | Friendly green | Industrial blue/orange | Industrial blue |
| Data Density | Low (plain English) | High (telemetry dashboard) | Medium (room to grow) |
| Map Priority | Secondary | Primary (60-70%) | Primary |
| E-Stop | None | Always visible, red+yellow | Always visible, red+yellow |
| Signal Display | Hidden | Prominent (GPS/RTK/LTE) | Basic (needs RTK) |
| Corner Radius | 16-24px | 8-16px | 10px |
| Hardware Imagery | Friendly 3D render | Technical robot silhouette | Photos (upgrade to 3D) |
| Font | Rounded sans | Geometric sans (Inter) | Inter |
| Color Usage | Decorative | Purely functional/state | Functional |
