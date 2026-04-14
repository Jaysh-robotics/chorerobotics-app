# LED Behavior During BLE Pairing

## Overview

The robot's front LED strip provides visual feedback during pairing and operation. Three LED colors are available: **White**, **Green**, and **Red**.

## Hardware

- Front-mounted LED strip (horizontal bar)
- 3 colors: White, Green, Red
- Patterns: Solid ON, OFF, Slow blink, Fast blink, Double-blink

## LED States

| # | State | Color | Pattern | Timing | App Screen | Meaning |
|---|---|---|---|---|---|---|
| 1 | Discoverable | **White** | Slow blink | 1s on / 1s off | BLE Scan (scanning) | I'm here. Ready to pair. |
| 2 | Found | **White** | Fast blink | 300ms on / 300ms off | BLE Scan (robot card) | I see your phone. |
| 3 | Pairing | **White** | Double blink | 100ms on, 100ms off, 100ms on, 700ms off | Pair screen (connecting) | Connecting. Please wait. |
| 4 | Awaiting Code | **White** | Solid ON | Constant | Pair screen (code entry) | Enter the code. Your turn. |
| 5 | Verifying | **White** | Rapid blink | 100ms on / 100ms off | Pair screen (checking) | Checking code... |
| 6 | Success | **Green** | 3 flashes → solid | 150ms on/off ×3, then constant | Wi-Fi Setup (banner) | Paired! Ready for Wi-Fi. |
| 7 | Wi-Fi Setup | **Green** | Slow blink | 2s on / 0.5s off | Wi-Fi Setup (connecting) | Connecting to Wi-Fi... |
| 8 | Complete | **Green** | Solid ON | Constant | Setup Complete | All set. Ready to work. |
| 9 | Failed | **Red** | 3 flashes → off | 500ms on/off ×3, then restart #1 | Error / retry | Error. Try again. |
| 10 | E-STOP | **Red** | Rapid flash | 200ms on / 200ms off, NON-STOP | Any screen | EMERGENCY. Robot stopped. |

## State Flow

```
POWER ON → [1.White Slow Blink] → [2.White Fast Blink] → [3.White Double Blink]
→ [4.White Solid] → [5.White Rapid] → OK → [6.Green Flash] → [7.Green Blink] → [8.Green Solid]
                                       → FAIL → [9.Red Flash] → back to [1]
[10.Red Rapid] = E-STOP, overrides ALL states.
```

## Color Meaning

| Color | Meaning | Used In |
|---|---|---|
| **White** | Neutral / in-progress / waiting | States 1-5 (discovery through verification) |
| **Green** | Success / connected / ready | States 6-8 (paired, wifi, complete) |
| **Red** | Error / emergency / failed | States 9-10 (failed, E-Stop) |

## Notes

- E-Stop (#10) is HIGHEST PRIORITY — overrides any pattern immediately
- State 1 is default after power-on. Robot returns to it after failure or 2-min timeout
- Blink timings are approximate — ±50ms acceptable
- If LED strip only supports on/off (no dimming), all patterns use sharp on/off
