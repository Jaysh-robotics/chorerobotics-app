# Navigation Flow — GoRouter Architecture

## Route Tree

```
/splash                          ← App entry point
    │
    ├── [No token] → /auth       ← Sign In / Create Account
    │                   │
    │                   └── [Authenticated] → Check robot pairing status
    │
    ├── [Token + No robot] → /onboarding
    │   ├── /onboarding/scan         ← BLE Scan (02a)
    │   ├── /onboarding/pair         ← Pair Robot (02b)
    │   ├── /onboarding/wifi         ← Wi-Fi Setup (02c)
    │   └── /onboarding/complete     ← Setup Complete (02d)
    │                                      │
    │                                      └── → /dashboard
    │
    └── [Token + Robot paired] → /dashboard (ShellRoute with bottom nav)
        │
        ├── /dashboard                ← Dashboard Hub (03) [Tab 1: Home]
        │
        ├── /control                  ← Manual Control (04) [Tab 2: Control]
        │                              (forces landscape, hides bottom nav)
        │
        ├── /map                      ← Zone Map Editor (05) [Tab 3: Map]
        │                              (forces landscape, hides bottom nav)
        │
        ├── /battery                  ← Battery Status (06) [Tab 4: Battery]
        │
        └── /more                     ← More Menu [Tab 5: More]
            ├── /more/diagnostics     ← Diagnostics (07)
            ├── /more/settings        ← Settings (12) [Phase 2]
            ├── /more/firmware        ← Firmware Update (13) [Phase 3]
            └── /more/history         ← Task History (14) [Phase 3]

        (Modal routes — pushed on top of any tab)
        ├── /mowing/:zoneId           ← Mowing Patterns (08)
        ├── /snow/:zoneId             ← Snow Plowing (09)
        ├── /leaf/:zoneId             ← Leaf Collection (10)
        └── /schedule                 ← Task Scheduler (11) [Phase 2]
```

## GoRouter Configuration

```dart
// Route constants
abstract class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const onboardingScan = '/onboarding/scan';
  static const onboardingPair = '/onboarding/pair';
  static const onboardingWifi = '/onboarding/wifi';
  static const onboardingComplete = '/onboarding/complete';
  static const dashboard = '/dashboard';
  static const control = '/control';
  static const map = '/map';
  static const battery = '/battery';
  static const more = '/more';
  static const diagnostics = '/more/diagnostics';
  static const settings = '/more/settings';
  static const firmware = '/more/firmware';
  static const history = '/more/history';
  static const mowing = '/mowing/:zoneId';
  static const snow = '/snow/:zoneId';
  static const leaf = '/leaf/:zoneId';
  static const schedule = '/schedule';
}
```

## Route Guards

```
┌─────────────────────────────────────────────────────┐
│                    ROUTE GUARD CHAIN                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. AuthGuard                                        │
│     ├── Has valid token? → Continue                  │
│     └── No token? → Redirect /auth                   │
│                                                      │
│  2. PairingGuard                                     │
│     ├── Robot paired? → Continue                     │
│     └── Not paired? → Redirect /onboarding/scan      │
│                                                      │
│  3. ConnectionGuard                                  │
│     ├── Connected? → Continue                        │
│     └── Disconnected? → Show reconnect overlay       │
│         (Don't redirect — keep current screen)       │
│                                                      │
│  4. SafetyGuard (for control/map screens)            │
│     ├── E-Stop active? → Block navigation            │
│     └── E-Stop clear? → Continue                     │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Bottom Navigation Tab Mapping

```
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│   Home   │ Control  │   Map    │ Battery  │   More   │
│    ⊞     │    ◎     │    ◫    │    ⚡    │    ≡     │
│  Tab 0   │  Tab 1   │  Tab 2   │  Tab 3   │  Tab 4   │
│ Portrait │Landscape │Landscape │ Portrait │ Portrait │
└──────────┴──────────┴──────────┴──────────┴──────────┘
```

## Screen Orientation Rules

| Screen | Orientation | Bottom Nav | E-Stop |
|---|---|---|---|
| Auth | Portrait | Hidden | Hidden |
| Onboarding (all) | Portrait | Hidden | Hidden |
| Dashboard | Portrait | Visible | Visible |
| Control | **Landscape** | **Hidden** | Visible (landscape) |
| Map | **Landscape** | **Hidden** | Visible (landscape) |
| Battery | Portrait | Visible | Visible |
| Diagnostics | Portrait | Visible | Visible |
| Mowing | Portrait | Visible | Visible |
| Snow | Portrait | Visible | Visible |
| Leaf | Portrait | Visible | Visible |
| Schedule | Portrait | Visible | Visible |
| Settings | Portrait | Visible | Hidden |

## Navigation Transitions

| Transition | Animation | Duration |
|---|---|---|
| Tab switch | Instant (no animation) | 0ms |
| Push to detail screen | Slide from right | 250ms |
| Modal (mowing/snow/leaf) | Slide from bottom | 300ms |
| Landscape transition | Rotate + fade | 400ms |
| Auth → Dashboard | Fade through | 500ms |
| Onboarding steps | Slide from right | 300ms |

## Deep Link Support

| URL Pattern | Action |
|---|---|
| `chorerobotics://dashboard` | Open dashboard |
| `chorerobotics://control` | Open manual control |
| `chorerobotics://battery` | Open battery screen |
| `chorerobotics://mow/zone1` | Open mowing config for zone1 |
| `chorerobotics://pair` | Start pairing flow |

## State Persistence on Navigation

| State | Behavior |
|---|---|
| Joystick position | Reset to center on leave |
| Map zoom/pan | Preserved across tab switches |
| Zone edits | Auto-save on Done, discard on Back |
| Form inputs | Preserved until submitted |
| Telemetry stream | Continuous (never paused by navigation) |
| E-Stop state | Global (never affected by navigation) |
