# Phase 1 Command Pipeline Demo

This is the first showable slice for phone-to-server robot control.

## What it proves

- The Flutter app connects to a laptop WebSocket server over Wi-Fi.
- Joystick movement sends `drive_command` messages with `linear_x` and `angular_z`.
- Forward, backward, left, and right test commands reach the server.
- The server returns `command_ack`.
- The app shows `received ✓` after an acknowledgement.
- E-stop sends an `estop` command through the same pipeline.

## Start the laptop server

From the repo root:

```powershell
python -m pip install -r scripts/robot_server/requirements.txt
python scripts/dev_server/command_echo_server.py
```

The server prints one or more URLs like:

```text
ws://192.168.1.25:8765/ws
```

Use the URL that matches the laptop's Wi-Fi network IP.

## Run the app on the phone

```powershell
flutter run -d 1196625439012888
```

On the dashboard, scroll to the `Command Server` card, replace the default
server URL with the URL printed by the laptop server, then tap `Connect`.

The same WebSocket pipeline is also wired into the manual joystick control
screen, but the dashboard card is the easiest demo path.

## Demo checklist

1. Tap `Ping`; app should show `received ✓`.
2. Tap `Forward`, `Backward`, `Left`, and `Right`; server terminal should log each command.
3. Tap `Send E-Stop`; server terminal should log `estop` and app should receive an ACK.
4. Open the manual joystick screen if you want to show continuous joystick
   `linear_x` / `angular_z` messages.

## Current limits

- This is a laptop simulator, not the physical robot.
- The command JSON is a temporary app-server contract until the robotics team gives the final command spec.
- Telemetry streaming is not part of this slice.
