"""
LED Strip Controller.

Controls the front-mounted WS2812B (NeoPixel-compatible) LED strip for
visual feedback. Implements all 11 LED states defined in led_pairing_spec.md.

Hardware:
    - LED Type: WS2812B addressable RGB
    - Count: 12 LEDs (horizontal bar on robot front)
    - GPIO: Pin 18 (PWM0) on Jetson Nano
    - Power: 5V from robot power supply
    - Library: rpi_ws281x (compatible with Jetson Nano GPIO)

LED States (from led_pairing_spec.md):
    0:  OFF               -- All LEDs off
    1:  Discoverable      -- White slow blink (1s on / 1s off)
    2:  Found             -- White fast blink (300ms on / 300ms off)
    3:  Pairing           -- White double blink (100ms on/off/on, 700ms off)
    4:  Awaiting Code     -- White solid ON
    5:  Verifying         -- White rapid blink (100ms on / 100ms off)
    6:  Success           -- Green 3 flashes then solid
    7:  WiFi Setup        -- Green slow blink (2s on / 0.5s off)
    8:  Complete          -- Green solid ON
    9:  Failed            -- Red 3 flashes then off
    10: E-STOP            -- Red rapid flash (200ms on / 200ms off) NON-STOP

Priority:
    E-STOP (state 10) has HIGHEST PRIORITY and overrides any other state.
"""

import asyncio
import logging
from typing import Optional, Tuple

from ..config import (
    LED_COUNT,
    LED_GPIO_PIN,
    LED_BRIGHTNESS,
    LED_FREQ_HZ,
    LED_DMA_CHANNEL,
    LED_INVERT,
    LED_COLOR_WHITE,
    LED_COLOR_GREEN,
    LED_COLOR_RED,
    LED_COLOR_OFF,
    LED_STATE_OFF,
    LED_STATE_DISCOVERABLE,
    LED_STATE_FOUND,
    LED_STATE_PAIRING,
    LED_STATE_AWAITING_CODE,
    LED_STATE_VERIFYING,
    LED_STATE_SUCCESS,
    LED_STATE_WIFI_SETUP,
    LED_STATE_COMPLETE,
    LED_STATE_FAILED,
    LED_STATE_ESTOP,
)

logger = logging.getLogger(__name__)


class LedController:
    """Controls the WS2812B LED strip for visual feedback.

    The LED controller runs a continuous async loop that updates the LED
    strip based on the current state. Each state defines a color and
    blink pattern.

    E-STOP state overrides all other states and cannot be interrupted
    except by explicitly calling set_estop(False).

    Usage:
        led = LedController()
        await led.initialize()
        await led.set_state(LED_STATE_DISCOVERABLE)  # White slow blink
        ...
        await led.set_state(LED_STATE_SUCCESS)  # Green 3 flashes then solid
        ...
        led.on_estop(True)  # Red rapid flash, overrides everything
        ...
        led.on_estop(False)  # Return to previous state
        ...
        await led.shutdown()
    """

    def __init__(self) -> None:
        """Initialize the LED controller (does not access hardware yet)."""
        self._strip: Optional[Any] = None  # rpi_ws281x.PixelStrip
        self._current_state: int = LED_STATE_OFF
        self._last_normal_state: int = LED_STATE_OFF
        self._estop_active: bool = False
        self._animation_task: Optional[asyncio.Task] = None
        self._is_initialized: bool = False

    async def initialize(self) -> None:
        """Initialize the LED strip hardware.

        Creates the PixelStrip instance and turns off all LEDs.

        Raises:
            RuntimeError: If the WS2812B library cannot access GPIO.
        """
        # TODO: implement
        # from rpi_ws281x import PixelStrip, Color
        #
        # self._strip = PixelStrip(
        #     LED_COUNT,
        #     LED_GPIO_PIN,
        #     LED_FREQ_HZ,
        #     LED_DMA_CHANNEL,
        #     LED_INVERT,
        #     LED_BRIGHTNESS,
        # )
        # self._strip.begin()
        # self._set_all_pixels(LED_COLOR_OFF)
        # self._strip.show()

        self._is_initialized = True
        logger.info(f"LED controller initialized: {LED_COUNT} LEDs on GPIO {LED_GPIO_PIN}")

    async def shutdown(self) -> None:
        """Turn off all LEDs and release hardware resources."""
        if self._animation_task and not self._animation_task.done():
            self._animation_task.cancel()
            try:
                await self._animation_task
            except asyncio.CancelledError:
                pass

        if self._is_initialized:
            self._set_all_pixels(LED_COLOR_OFF)
            # self._strip.show()

        self._is_initialized = False
        logger.info("LED controller shutdown")

    async def set_state(self, state: int) -> None:
        """Set the LED state.

        If E-STOP is active, the state is saved but not applied.
        The saved state will be restored when E-STOP is cleared.

        Args:
            state: LED state ID (0-10). See LED_STATE_* constants.
        """
        if self._estop_active and state != LED_STATE_ESTOP:
            self._last_normal_state = state
            logger.debug(f"LED state {state} saved (E-STOP active)")
            return

        await self._apply_state(state)

    def on_estop(self, active: bool) -> None:
        """Handle E-STOP state change.

        E-STOP has highest priority and overrides any other LED state.

        Args:
            active: True to activate E-STOP (red rapid flash),
                    False to clear and return to previous state.
        """
        self._estop_active = active

        if active:
            self._last_normal_state = self._current_state
            asyncio.create_task(self._apply_state(LED_STATE_ESTOP))
        else:
            asyncio.create_task(self._apply_state(self._last_normal_state))

    def on_pairing_state_changed(self, pairing_state: int) -> None:
        """Callback for pairing state machine changes.

        Maps pairing states (0-8) to LED states (1-9).
        Called by PairingManager.on_state_changed.

        Args:
            pairing_state: Pairing state value (0=DISCOVERABLE through 8=FAILED).
        """
        # Pairing state maps directly to LED state + 1
        # (pairing state 0 = LED state 1, etc.)
        led_state = pairing_state + 1
        if led_state > LED_STATE_FAILED:
            led_state = LED_STATE_FAILED
        asyncio.create_task(self.set_state(led_state))

    async def _apply_state(self, state: int) -> None:
        """Apply an LED state, starting the appropriate animation.

        Cancels any running animation and starts the new one.

        Args:
            state: LED state to apply.
        """
        # Cancel current animation
        if self._animation_task and not self._animation_task.done():
            self._animation_task.cancel()
            try:
                await self._animation_task
            except asyncio.CancelledError:
                pass

        self._current_state = state

        # Start new animation
        if state == LED_STATE_OFF:
            self._set_all_pixels(LED_COLOR_OFF)
        elif state == LED_STATE_DISCOVERABLE:
            self._animation_task = asyncio.create_task(
                self._blink_pattern(LED_COLOR_WHITE, on_ms=1000, off_ms=1000)
            )
        elif state == LED_STATE_FOUND:
            self._animation_task = asyncio.create_task(
                self._blink_pattern(LED_COLOR_WHITE, on_ms=300, off_ms=300)
            )
        elif state == LED_STATE_PAIRING:
            self._animation_task = asyncio.create_task(
                self._double_blink_pattern(LED_COLOR_WHITE)
            )
        elif state == LED_STATE_AWAITING_CODE:
            self._set_all_pixels(LED_COLOR_WHITE)
        elif state == LED_STATE_VERIFYING:
            self._animation_task = asyncio.create_task(
                self._blink_pattern(LED_COLOR_WHITE, on_ms=100, off_ms=100)
            )
        elif state == LED_STATE_SUCCESS:
            self._animation_task = asyncio.create_task(
                self._success_pattern()
            )
        elif state == LED_STATE_WIFI_SETUP:
            self._animation_task = asyncio.create_task(
                self._blink_pattern(LED_COLOR_GREEN, on_ms=2000, off_ms=500)
            )
        elif state == LED_STATE_COMPLETE:
            self._set_all_pixels(LED_COLOR_GREEN)
        elif state == LED_STATE_FAILED:
            self._animation_task = asyncio.create_task(
                self._failure_pattern()
            )
        elif state == LED_STATE_ESTOP:
            self._animation_task = asyncio.create_task(
                self._blink_pattern(LED_COLOR_RED, on_ms=200, off_ms=200)
            )

    # =========================================================================
    # Animation patterns
    # =========================================================================

    async def _blink_pattern(
        self,
        color: Tuple[int, int, int],
        on_ms: int,
        off_ms: int,
    ) -> None:
        """Simple on/off blink pattern.

        Args:
            color: RGB tuple for the on state.
            on_ms: Milliseconds in the on state.
            off_ms: Milliseconds in the off state.
        """
        while True:
            try:
                self._set_all_pixels(color)
                await asyncio.sleep(on_ms / 1000.0)
                self._set_all_pixels(LED_COLOR_OFF)
                await asyncio.sleep(off_ms / 1000.0)
            except asyncio.CancelledError:
                break

    async def _double_blink_pattern(self, color: Tuple[int, int, int]) -> None:
        """Double-blink pattern: 100ms on, 100ms off, 100ms on, 700ms off.

        Used for the "Pairing" state (state 3).

        Args:
            color: RGB tuple for the on state.
        """
        while True:
            try:
                self._set_all_pixels(color)
                await asyncio.sleep(0.1)  # 100ms on
                self._set_all_pixels(LED_COLOR_OFF)
                await asyncio.sleep(0.1)  # 100ms off
                self._set_all_pixels(color)
                await asyncio.sleep(0.1)  # 100ms on
                self._set_all_pixels(LED_COLOR_OFF)
                await asyncio.sleep(0.7)  # 700ms off
            except asyncio.CancelledError:
                break

    async def _success_pattern(self) -> None:
        """Success pattern: green 3 flashes then solid.

        Used for the "Success" state (state 6).
        3 x (150ms on, 150ms off), then solid green.
        """
        try:
            for _ in range(3):
                self._set_all_pixels(LED_COLOR_GREEN)
                await asyncio.sleep(0.15)  # 150ms on
                self._set_all_pixels(LED_COLOR_OFF)
                await asyncio.sleep(0.15)  # 150ms off

            # Solid green
            self._set_all_pixels(LED_COLOR_GREEN)
            # Keep solid until state changes
            await asyncio.sleep(float("inf"))
        except asyncio.CancelledError:
            pass

    async def _failure_pattern(self) -> None:
        """Failure pattern: red 3 flashes then off.

        Used for the "Failed" state (state 9).
        3 x (500ms on, 500ms off), then off.
        After the pattern, the pairing manager resets to discoverable.
        """
        try:
            for _ in range(3):
                self._set_all_pixels(LED_COLOR_RED)
                await asyncio.sleep(0.5)  # 500ms on
                self._set_all_pixels(LED_COLOR_OFF)
                await asyncio.sleep(0.5)  # 500ms off

            # Stay off (pairing manager will transition to discoverable)
            self._set_all_pixels(LED_COLOR_OFF)
            await asyncio.sleep(float("inf"))
        except asyncio.CancelledError:
            pass

    # =========================================================================
    # Low-level pixel control
    # =========================================================================

    def _set_all_pixels(self, color: Tuple[int, int, int]) -> None:
        """Set all pixels to the same color and update the strip.

        Args:
            color: (R, G, B) tuple with values 0-255.
        """
        # TODO: implement with actual hardware
        # from rpi_ws281x import Color
        # c = Color(color[0], color[1], color[2])
        # for i in range(LED_COUNT):
        #     self._strip.setPixelColor(i, c)
        # self._strip.show()
        pass

    def _set_pixel(self, index: int, color: Tuple[int, int, int]) -> None:
        """Set a single pixel color (does not call show).

        Args:
            index: Pixel index (0 to LED_COUNT - 1).
            color: (R, G, B) tuple.
        """
        # TODO: implement
        pass

    @property
    def current_state(self) -> int:
        """The currently active LED state."""
        return self._current_state
