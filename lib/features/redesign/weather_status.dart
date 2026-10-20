import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/weather/weather_controller.dart';
import 'chore_ui.dart';

class WeatherStatus extends StatefulWidget {
  const WeatherStatus({super.key});
  @override
  State<WeatherStatus> createState() => _WeatherStatusState();
}

class _WeatherStatusState extends State<WeatherStatus>
    with WidgetsBindingObserver {
  late final WeatherController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<WeatherController>();
    _controller.active = true;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.active = state == AppLifecycleState.resumed;
    if (_controller.active) {
      _controller.refresh(force: true, requestPermission: false);
    }
  }

  @override
  void dispose() {
    _controller.active = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WeatherController>();
    final weather = controller.weather;
    final failed = controller.error != null;
    return SizedBox(
      width: 60,
      height: 54,
      child: Tooltip(
        message:
            controller.error ??
            (weather == null
                ? 'Loading local weather'
                : '${weather.condition}. ${weather.rainChance == null ? '' : '${weather.rainChance}% chance of rain.'} Weather data: Open-Meteo.'),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: choreSurface,
              title: Text(
                failed ? 'Weather unavailable' : 'Local weather',
                style: choreText(17, weight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.error ??
                        (weather == null
                            ? 'Getting the weather for your current location...'
                            : '${weather.condition}\n${weather.summary}\nUpdated ${TimeOfDay.fromDateTime(weather.time.toLocal()).format(context)}'),
                    style: choreText(13),
                  ),
                  if (weather != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      'Weather data: Open-Meteo (CC BY 4.0)\nhttps://open-meteo.com/',
                      style: choreText(10, color: choreMuted),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: controller.loading
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          _controller.refresh(force: true);
                        },
                  child: Text(failed ? 'Retry' : 'Refresh'),
                ),
              ],
            ),
          ),
          child: Semantics(
            label: failed
                ? 'Weather unavailable. Tap for help.'
                : 'Local weather',
            button: true,
            child: Column(
              children: [
                if (controller.loading && weather == null)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: choreOrange,
                      ),
                    ),
                  )
                else
                  Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : _weatherIcon(weather),
                    size: 28,
                    color: failed ? choreOrange : const Color(0xFFA5B4BE),
                  ),
                const SizedBox(height: 3),
                Text(
                  failed ? 'Unavailable' : weather?.summary ?? 'Loading',
                  maxLines: 1,
                  style: choreText(9, weight: FontWeight.w200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _weatherIcon(LocalWeather? weather) => switch (weather?.code ?? -1) {
    0 => weather!.isDay ? PhosphorIcons.sunFill : PhosphorIcons.moonFill,
    1 || 2 => PhosphorIcons.cloudSunFill,
    45 || 48 => PhosphorIcons.cloudFogFill,
    >= 51 && <= 67 || >= 80 && <= 82 => PhosphorIcons.cloudRainFill,
    >= 71 && <= 77 || 85 || 86 => PhosphorIcons.cloudSnowFill,
    >= 95 && <= 99 => PhosphorIcons.cloudLightningFill,
    _ => PhosphorIcons.cloudFill,
  };
}
