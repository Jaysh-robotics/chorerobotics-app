"""
GPIO Pin Manager for Jetson Nano.

Provides safe access to GPIO pins with initialization tracking
and cleanup on shutdown. Used by the LED controller and any future
hardware interfaces (relays, buttons, sensors).

The Jetson Nano uses a different GPIO library than Raspberry Pi.
Jetson.GPIO is pin-compatible but uses a different numbering scheme.
"""

import logging
from typing import Optional, Dict, Set

logger = logging.getLogger(__name__)

# Pin mode constants
PIN_MODE_OUTPUT = "OUT"
PIN_MODE_INPUT = "IN"
PIN_MODE_PWM = "PWM"


class GpioManager:
    """Manages GPIO pin allocation and safe access.

    Tracks which pins are in use and ensures proper cleanup.
    Wraps the Jetson.GPIO library for safe concurrent access.

    Usage:
        gpio = GpioManager()
        gpio.initialize()
        gpio.setup_pin(18, PIN_MODE_PWM)
        gpio.write_pin(18, True)
        ...
        gpio.cleanup()
    """

    def __init__(self) -> None:
        """Initialize the GPIO manager (does not access hardware)."""
        self._initialized: bool = False
        self._allocated_pins: Dict[int, str] = {}  # pin -> mode

    def initialize(self) -> None:
        """Initialize the GPIO subsystem.

        Sets the pin numbering mode to BOARD (physical pin numbers).

        Raises:
            RuntimeError: If Jetson.GPIO cannot be imported or initialized.
        """
        # TODO: implement
        # import Jetson.GPIO as GPIO
        # GPIO.setmode(GPIO.BOARD)
        # GPIO.setwarnings(False)
        self._initialized = True
        logger.info("GPIO manager initialized")

    def setup_pin(self, pin: int, mode: str) -> None:
        """Configure a GPIO pin for a specific mode.

        Args:
            pin: Physical pin number (BOARD numbering).
            mode: Pin mode: 'OUT', 'IN', or 'PWM'.

        Raises:
            ValueError: If pin is already allocated with a different mode.
            RuntimeError: If GPIO is not initialized.
        """
        if not self._initialized:
            raise RuntimeError("GPIO not initialized")

        if pin in self._allocated_pins:
            if self._allocated_pins[pin] != mode:
                raise ValueError(
                    f"Pin {pin} already allocated as {self._allocated_pins[pin]}"
                )
            return  # Already configured

        # TODO: implement
        # import Jetson.GPIO as GPIO
        # if mode == PIN_MODE_OUTPUT:
        #     GPIO.setup(pin, GPIO.OUT)
        # elif mode == PIN_MODE_INPUT:
        #     GPIO.setup(pin, GPIO.IN)

        self._allocated_pins[pin] = mode
        logger.debug(f"GPIO pin {pin} configured as {mode}")

    def write_pin(self, pin: int, value: bool) -> None:
        """Write a digital value to a GPIO pin.

        Args:
            pin: Pin number.
            value: True for HIGH, False for LOW.

        Raises:
            ValueError: If pin is not configured as output.
        """
        if pin not in self._allocated_pins:
            raise ValueError(f"Pin {pin} not allocated")
        if self._allocated_pins[pin] not in (PIN_MODE_OUTPUT, PIN_MODE_PWM):
            raise ValueError(f"Pin {pin} is not configured for output")

        # TODO: implement
        # import Jetson.GPIO as GPIO
        # GPIO.output(pin, GPIO.HIGH if value else GPIO.LOW)

    def read_pin(self, pin: int) -> bool:
        """Read a digital value from a GPIO pin.

        Args:
            pin: Pin number.

        Returns:
            True if HIGH, False if LOW.

        Raises:
            ValueError: If pin is not configured as input.
        """
        if pin not in self._allocated_pins:
            raise ValueError(f"Pin {pin} not allocated")
        if self._allocated_pins[pin] != PIN_MODE_INPUT:
            raise ValueError(f"Pin {pin} is not configured for input")

        # TODO: implement
        # import Jetson.GPIO as GPIO
        # return GPIO.input(pin) == GPIO.HIGH
        return False

    def cleanup(self) -> None:
        """Release all GPIO pins and clean up resources.

        Must be called on shutdown to avoid leaving pins in an
        undefined state.
        """
        if self._initialized:
            # TODO: implement
            # import Jetson.GPIO as GPIO
            # GPIO.cleanup()
            self._allocated_pins.clear()
            self._initialized = False
            logger.info("GPIO manager cleaned up")

    @property
    def allocated_pins(self) -> Dict[int, str]:
        """Dict of currently allocated pins and their modes."""
        return dict(self._allocated_pins)
