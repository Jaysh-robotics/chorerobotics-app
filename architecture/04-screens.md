# Screen Specifications — Component Breakdown

## Screen 01: Authentication

```
┌─────────────────────────────┐
│         Status Bar           │
├─────────────────────────────┤
│                              │
│     ┌──────────────────┐     │
│     │   LOGO (180x124) │     │
│     │  chore-robots.png│     │
│     └──────────────────┘     │
│     Autonomous lawn care,    │
│     snow clearing & more     │
│                              │
│  ┌──────────────────────┐    │
│  │ Email                │    │
│  │ [input field]        │    │
│  └──────────────────────┘    │
│  ┌──────────────────────┐    │
│  │ Password             │    │
│  │ [input field]        │    │
│  └──────────────────────┘    │
│  [✓] Remember me    Forgot?  │
│                              │
│  ┌──────────────────────┐    │
│  │     SIGN IN (blue)   │    │
│  └──────────────────────┘    │
│  ┌──────────────────────┐    │
│  │  CREATE ACCOUNT      │    │
│  └──────────────────────┘    │
│     Continue as Guest        │
│                              │
└─────────────────────────────┘

Widgets: BrandLogo, InputField, BrandButton, TextLink
State: AuthNotifier (email, password, loading, error)
Navigation: → /onboarding/scan (on success + no robot)
            → /dashboard (on success + robot paired)
API: POST /auth/login { email, password }
```

## Screen 02a: BLE Scan

```
┌─────────────────────────────┐
│         Status Bar           │
│  [1]───[2]───[3]───[4]      │ ← Step indicator
├─────────────────────────────┤
│  Find Your Robot             │
│  Scanning for nearby robots  │
│                              │
│      ┌─── ─── ───┐          │
│     (  (  ( ⚡ )  )  )       │ ← Pulse animation
│      └─── ─── ───┘          │
│     ● Scanning via BLE...    │
│                              │
│  ┌──────────────────────┐    │
│  │ [img] ChoreBot Alpha │    │
│  │  ● Found nearby  ||||│    │ ← Signal bars
│  └──────────────────────┘    │
│                              │
│  ┌──────────────────────┐    │
│  │ ℹ How pairing works   │    │
│  └──────────────────────┘    │
│                              │
│  ┌──────────────────────┐    │
│  │   PAIR THIS ROBOT    │    │
│  └──────────────────────┘    │
│     Can't find your robot?   │
└─────────────────────────────┘

Widgets: StepIndicator, ScanPulseAnimation, RobotFoundCard, SignalBars
State: BleScanNotifier (scanning, discovered_robots, selected)
BLE: startScan(), stopScan(), onDiscovered(robot)
Navigation: → /onboarding/pair (on select + tap Pair)
```

## Screen 03: Dashboard

```
┌─────────────────────────────┐
│         Status Bar           │
│ ═══ brand gradient line ═══ │
│ ● Local          🔋 78%     │ ← Connection bar
├─────────────────────────────┤
│ [logo] Dashboard        [⚙] │
│         ChoreBot Alpha       │
├─────────────────────────────┤
│  ┌──────────────────────┐    │
│  │ ROBOT STATUS  [● Idle]│    │
│  │ [img]  Ready to work  │    │
│  │        Mower attached │    │
│  │ Battery ━━━━━━░░ 78%  │    │
│  └──────────────────────┘    │
│                              │
│  ┌──Start──┐┌──Dock──┐┌Pause┐│
│  │   ▶     ││   🏠   ││  ⏸  ││
│  └─────────┘└────────┘└─────┘│
│                              │
│  ┌──────────────────────┐    │
│  │ LIVE METRICS  [● LIVE]│    │
│  │ Cycles    142/500     │    │
│  │ Signal    Strong      │    │
│  │ Blade     Standby     │    │
│  │ Speed     0.0 m/s     │    │
│  │ Temp      32°C        │    │
│  └──────────────────────┘    │
│                              │
│  ┌──────────────────────┐    │
│  │ RECENT ACTIVITY  All→ │    │
│  │ ● Mowed Front Yard   │    │
│  │ ● Returned to dock   │    │
│  │ ● Connection unstable │    │
│  └──────────────────────┘    │
│                              │
│  ┌══════════════════════┐    │
│  ║   EMERGENCY STOP     ║    │ ← E-Stop (red+yellow)
│  └══════════════════════┘    │
│                              │
│ [Home] [Ctrl] [Map] [🔋] [≡]│ ← Bottom nav
└─────────────────────────────┘

Widgets: ConnectionBar, BrandLine, RobotStatusCard,
         QuickActions, MetricCard, ActivityLog,
         EStopButton, BottomNavigation
State: DashboardNotifier (consumes telemetryStream)
Data: ref.watch(telemetryStreamProvider)
      ref.watch(connectionProvider)
      ref.watch(robotProvider)
```

## Screen 04: Manual Control (Landscape)

```
┌───────────────────────────────────────────────────────────────────┐
│ ● Local [MANUAL]    Speed 0.8 m/s │ Heading 045°    🔋 78%       │
├──────────────┬────────────────────────────┬────────────────────────┤
│              │         ┌─────┐            │  ┌──────────────────┐ │
│   ┌──────┐   │         │  N  │            │  │ 🔪 Blade    [OFF]│ │
│   │      │   │    ┌────┤  ↗  ├────┐       │  └──────────────────┘ │
│   │  ⚫  │   │    │ W  │  ●  │ E  │       │                       │
│   │ JOY  │   │    └────┤     ├────┘       │  ┌──────────────────┐ │
│   │ STICK│   │         │  S  │            │  │   Auto Mode  ▶   │ │
│   └──────┘   │         └─────┘            │  └──────────────────┘ │
│   DRIVE      │    ┌────┬────┐             │  ┌──────────────────┐ │
│              │    │FL  │FR  │             │  │  Return to Dock  │ │
│              │    │0.8 │0.7 │             │  └──────────────────┘ │
│              │    ├────┼────┤             │  ┌──────────────────┐ │
│              │    │RL  │RR  │             │  │     Pause   ⏸   │ │
│              │    │0.8 │0.7 │             │  └──────────────────┘ │
│              │    └────┴────┘             │                       │
├──────────────┴────────────────────────────┴────────────────────────┤
│              ┌══════════ EMERGENCY STOP ══════════┐                │
│              └════════════════════════════════════┘                │
└───────────────────────────────────────────────────────────────────┘

Layout: Row [ JoystickPanel | CompassPanel | ControlsPanel ]
Orientation: ForceLandscape
Input: JoystickWidget → sends commands at 30Hz via joystickCommandProvider
State: ControlNotifier (blade_on, mode)
Critical: E-Stop always visible and functional
```

## Screen 05: Map Editor (Landscape)

```
┌───────────────────────────────────────────────────────────────────┐
│ ● Local  Map Your Yard    [● Mow][Snow][Leaf][✕ No-Go]  [Undo][Done]│
├──────────────┬────────────────────────────────────────────────────┤
│              │                                                    │
│   ┌──────┐   │   ╔═══════════════════════════════════════════╗    │
│   │      │   │   ║  ●──────────────────●                     ║    │
│   │  ⚫  │   │   ║  │   MOW ZONE 1     │  ┌───────┐         ║    │
│   │ JOY  │   │   ║  │   142 m²         │  │NO-GO  │         ║    │
│   │ STICK│   │   ║  │                  │  │Flower │         ║    │
│   └──────┘   │   ║  │                  │  └───────┘         ║    │
│  DRIVE ALONG │   ║  ●──────────────────●      LEAF ZONE     ║    │
│  BOUNDARY    │   ║              ⌂ (dock)      Under Oak      ║    │
│              │   ║  ────SNOW DRIVEWAY────                    ║    │
│  ┌─────────┐ │   ╚═══════════════════════════════════════════╝    │
│  │📍Drop Pin│ │   Zones: ● Mow:1 ● Snow:1 ● Leaf:1 ✕ No-Go:1   │
│  └─────────┘ │   ● Drawing Mow Zone — 5 pins         ──── 5m    │
├──────────────┴────────────────────────────────────────────────────┤
│              ┌══════════ EMERGENCY STOP ══════════┐                │
│              └════════════════════════════════════┘                │
└───────────────────────────────────────────────────────────────────┘

Layout: Row [ JoystickPanel | MapCanvas ]
Map: CustomPainter or flutter_map with polygon overlays
Gestures: Tap (place pin), Drag (move vertex), Pinch (zoom)
State: MapEditorNotifier (zones, active_zone_type, recording, vertices)
```

## Screen 06-10: See design HTML files for visual specs

Each follows the standard portrait layout:
```
┌─────────────────────────────┐
│ Status Bar                   │
│ ═══ brand line ═══           │
│ Connection Bar               │
│ App Bar (title + subtitle)   │
├─────────────────────────────┤
│                              │
│   Scrollable Content         │
│   (cards, forms, controls)   │
│                              │
├─────────────────────────────┤
│ ┌══ EMERGENCY STOP ══┐      │
│ └═════════════════════┘      │
│ [Home][Ctrl][Map][🔋][More]  │
└─────────────────────────────┘
```

## Screen 11: Task Scheduler (Phase 2)

```
┌─────────────────────────────┐
│ Status Bar + Brand Line      │
│ Connection Bar               │
│ Schedules              [+ Add]│
├─────────────────────────────┤
│                              │
│  ┌──────────────────────┐    │
│  │ Sunday Front Yard ☀️  │    │
│  │ Mow │ 8:00 AM │ On ● │    │
│  │ Zone 1 │ Straight     │    │
│  └──────────────────────┘    │
│  ┌──────────────────────┐    │
│  │ Wed/Sat Driveway ❄️   │    │
│  │ Plow │ 6:30 AM │ On ● │    │
│  │ Auto-trigger on snow  │    │
│  └──────────────────────┘    │
│  ┌──────────────────────┐    │
│  │ Friday Leaf Cleanup 🍂│    │
│  │ Collect│3:00 PM│Off ○ │    │
│  │ Full Zone │ Bag mode  │    │
│  └──────────────────────┘    │
│                              │
│ ┌══ EMERGENCY STOP ══┐      │
│ [Home][Ctrl][Map][🔋][More]  │
└─────────────────────────────┘
```
