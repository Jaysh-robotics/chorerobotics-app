# ChoreRobotics Robot Simulator

This simulator is the local stand-in for the robot-side Jetson server. It is
closer to the real robot environment than the old echo server because it uses
the production-style WebSocket protocol, keeps fake robot/task state, streams
fake telemetry, and logs ROS2-like topic publications.

## Recommended Setup

Use Docker Desktop with WSL2 enabled.

Why:

- The real robot server will run in Linux.
- Jetson deployment is likely containerized because JetPack 6.x and ROS2 Jazzy
  have an OS-version mismatch.
- Docker lets us test a Linux-style server while keeping the Flutter app flow
  unchanged.

You do not need a Docker Hub account for local testing.

## Run With Docker

From PowerShell:

```powershell
cd "C:\Users\Aswab007\Desktop\Folder (D)\chorerobotics-app"
docker compose -f docker-compose.robot-sim.yml up --build
```

The server listens on:

```text
ws://<your-laptop-ip>:8765/ws
```

To stop:

```powershell
Ctrl+C
docker compose -f docker-compose.robot-sim.yml down
```

## Run Without Docker

Windows PowerShell:

```powershell
cd "C:\Users\Aswab007\Desktop\Folder (D)\chorerobotics-app"
python -m pip install -r scripts/robot_server/requirements.txt
python scripts/robot_server/simulated_robot_server.py
```

WSL:

```bash
cd "/mnt/c/Users/Aswab007/Desktop/Folder (D)/chorerobotics-app"
python3 -m pip install -r scripts/robot_server/requirements.txt
python3 scripts/robot_server/simulated_robot_server.py
```

## Connect Phone

1. Start the simulator.
2. Use the URL printed by the simulator, for example:

   ```text
   ws://192.168.1.25:8765/ws
   ```

3. Open the Flutter app.
4. Paste the URL in the dashboard command/server card.
5. Tap Connect.
6. Tap Ping or use joystick/task buttons.
7. The terminal should show command logs and `[ros2] publish ...` lines.

Important:

- `127.0.0.1` only works from the same laptop browser. It does not work from
  your phone because it points to the phone itself.
- Laptop and phone must be on the same Wi-Fi network.
- Your laptop IP changes between office/home networks.
- If the phone cannot connect, allow Docker Desktop or Python through Windows
  Firewall for private networks.

## Implemented Message Types

App to simulator:

```text
ping
drive_command
task_start
task_pause
task_resume
task_stop
estop
estop_clear
dock
blade_control
zone_sync
schedule_sync
```

Simulator to app:

```text
pong
command_ack
telemetry
task_update
estop_status
```

## ROS2 Replacement Boundary

Today the simulator logs fake ROS2 publications:

```text
[ros2] publish /cmd_vel {...}
[ros2] publish /task/start {...}
[ros2] publish /task/pause {...}
[ros2] publish /task/resume {...}
[ros2] publish /task/stop {...}
[ros2] publish /estop/command {...}
```

Later, the robotics team can replace this logging boundary with the real ROS2
publisher implementation on Jetson. The Flutter app should not need to know
whether the command ended in a fake logger or a real ROS2 node.

## Current Scope

Included now:

- Local WebSocket server.
- Production-style command names.
- ACK responses.
- Fake telemetry stream.
- Fake task progress stream.
- Fake ROS2 publish logs.
- Dockerized local runtime.

Not included yet:

- Real ROS2 Jazzy installation.
- Real Jetson hardware access.
- Real BLE GATT peripheral server.
- Real Firebase cloud integration.
- TLS/mTLS or pairing-token auth from Flutter.
- mDNS discovery.

