# Robot Scripts

Scripts that run on the robot's Jetson Nano/Orin during operation.

## LED Pairing Controller
- `led_pairing_controller.py` — Main controller that listens to BLE events and drives LEDs
- `led_patterns.py` — Pattern definitions (pulse, flash, breathe, solid, rainbow)
- `ble_pairing_service.py` — BLE GATT service for app connection

## Requirements
- Python 3.10+
- `bleak` (BLE)
- `rpi_ws281x` or `adafruit-circuitpython-neopixel` (LED control)
- Runs as systemd service on Jetson
