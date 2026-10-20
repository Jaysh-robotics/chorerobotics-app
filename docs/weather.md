# Homepage Weather

The weather widget uses the device's foreground location and Open-Meteo's
current model-based conditions. It displays Fahrenheit, the current hour's
chance of precipitation, and a weather-code-based icon. Coordinates sent to
the provider are rounded to three decimal places. No robot connection or
Firebase account is required.

Refresh runs every 15 minutes while the homepage is active and when the app
resumes. Tapping the widget opens details, the model timestamp, attribution,
and a manual refresh. Failed requests hide the previous values and show a
warning icon; tapping it explains how to enable location or restore internet
and retry. Missing rain probability is omitted rather than replaced with 0%.

Allow location permission when prompted. Browser geolocation requires HTTPS
or localhost; an unsecured LAN IP URL may not work. Android uses foreground
location permissions. iOS includes the when-in-use purpose string. On a Mac,
when using Swift Package Manager, build the foreground-only iOS app with:

```sh
BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter build ios
```

For CocoaPods, set the equivalent `BYPASS_PERMISSION_LOCATION_ALWAYS=1`
compiler definition for `geolocator_apple` in the Podfile's post-install hook,
as described at https://pub.dev/packages/geolocator. Native iOS builds have
not been verified on this Windows machine.

Source: https://open-meteo.com/en/docs
Attribution: Open-Meteo, CC BY 4.0 (shown in the weather dialog).

The public endpoint is intended for non-commercial testing. Before delivery
as a commercial product, connect a licensed weather service through the
cloud backend; never embed a paid secret API key in the app or web bundle.
Provider terms: https://open-meteo.com/en/terms

This is informational weather, not a robot safety interlock or a physical
rain sensor. Current conditions are weather-model estimates, not continuous
measurements taken outside the device.
