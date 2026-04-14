"""
Hardware Control module.

Provides direct GPIO and LED strip control for the Jetson Nano.
The LED controller manages the WS2812B (NeoPixel) LED strip for
visual feedback during pairing, operation, and error states.
"""

from .led_controller import LedController
from .gpio import GpioManager

__all__ = ["LedController", "GpioManager"]
