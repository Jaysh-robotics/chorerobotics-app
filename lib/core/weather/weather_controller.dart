import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

typedef WeatherLocation = ({double latitude, double longitude});

class WeatherFailure implements Exception {
  const WeatherFailure(this.message);
  final String message;
}

class LocalWeather {
  const LocalWeather({
    required this.temperatureF,
    required this.code,
    required this.isDay,
    required this.time,
    this.rainChance,
  });
  final double temperatureF;
  final int code;
  final bool isDay;
  final DateTime time;
  final int? rainChance;

  factory LocalWeather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map ||
        current['temperature_2m'] is! num ||
        current['weather_code'] is! num ||
        current['time'] is! num ||
        current['is_day'] is! num) {
      throw const FormatException('Missing current weather');
    }
    final temperature = (current['temperature_2m'] as num).toDouble();
    if (!temperature.isFinite) {
      throw const FormatException('Invalid temperature');
    }
    final seconds = (current['time'] as num).toInt();
    int? rainChance;
    final hourly = json['hourly'];
    if (hourly is Map &&
        hourly['time'] is List &&
        hourly['precipitation_probability'] is List) {
      final times = hourly['time'] as List;
      final probabilities = hourly['precipitation_probability'] as List;
      for (var i = 0; i < times.length && i < probabilities.length; i++) {
        final time = times[i];
        final chance = probabilities[i];
        if (time is num &&
            seconds >= time &&
            seconds < time + 3600 &&
            chance is num &&
            chance.isFinite &&
            chance >= 0 &&
            chance <= 100) {
          rainChance = chance.round();
          break;
        }
      }
    }
    return LocalWeather(
      temperatureF: temperature,
      code: (current['weather_code'] as num).toInt(),
      isDay: current['is_day'] == 1,
      time: DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true),
      rainChance: rainChance,
    );
  }

  String get summary =>
      '${temperatureF.round()}\u00B0F${rainChance == null ? '' : ' \u2022 $rainChance%'}';

  String get condition => switch (code) {
    0 => isDay ? 'Clear sky' : 'Clear night',
    1 || 2 => 'Partly cloudy',
    3 => 'Overcast',
    45 || 48 => 'Fog',
    >= 51 && <= 57 => 'Drizzle',
    >= 61 && <= 67 || >= 80 && <= 82 => 'Rain',
    >= 71 && <= 77 || 85 || 86 => 'Snow',
    >= 95 && <= 99 => 'Thunderstorm',
    _ => 'Local weather',
  };
}

class WeatherController extends ChangeNotifier {
  WeatherController({
    http.Client? client,
    Future<WeatherLocation> Function(bool requestPermission)? locate,
  }) : _client = client ?? http.Client(),
       _locate = locate ?? _deviceLocation;

  final http.Client _client;
  final Future<WeatherLocation> Function(bool requestPermission) _locate;
  Timer? _timer;
  bool _disposed = false;
  bool active = true;
  bool loading = false;
  LocalWeather? weather;
  String? error;
  DateTime? _lastFetch;

  void start() {
    _timer ??= Timer.periodic(const Duration(minutes: 15), (_) {
      if (active) unawaited(refresh(force: true, requestPermission: false));
    });
  }

  Future<void> refresh({
    bool force = false,
    bool requestPermission = true,
  }) async {
    if (_disposed || loading) return;
    if (!force &&
        weather != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 15)) {
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final location = await _locate(requestPermission);
      if (_disposed) return;
      final response = await _client
          .get(
            // shortcut: use a licensed weather backend for a commercial release; this endpoint is for non-commercial testing.
            Uri.https('api.open-meteo.com', '/v1/forecast', {
              'latitude': location.latitude.toStringAsFixed(3),
              'longitude': location.longitude.toStringAsFixed(3),
              'current': 'temperature_2m,weather_code,is_day',
              'hourly': 'precipitation_probability',
              'temperature_unit': 'fahrenheit',
              'timeformat': 'unixtime',
              'forecast_days': '1',
              'timezone': 'auto',
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw const WeatherFailure(
          'Weather service is unavailable. Please retry shortly.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid weather response');
      }
      final result = LocalWeather.fromJson(decoded);
      if (_disposed) return;
      weather = result;
      _lastFetch = DateTime.now();
    } on WeatherFailure catch (failure) {
      if (!_disposed) {
        weather = null;
        error = failure.message;
      }
    } on FormatException {
      if (!_disposed) {
        weather = null;
        error =
            'Weather service returned incomplete data. Please retry shortly.';
      }
    } catch (_) {
      if (!_disposed) {
        weather = null;
        error = 'Connect to the internet to see local weather, then tap Retry.';
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  static Future<WeatherLocation> _deviceLocation(bool requestPermission) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const WeatherFailure(
          kIsWeb
              ? 'Enable location access and open the app over HTTPS or localhost, then tap Retry.'
              : 'Turn on location services to see the weather outside, then tap Retry.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const WeatherFailure(
          'Allow location access in your app or browser settings to see local weather, then tap Retry.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on WeatherFailure {
      rethrow;
    } catch (_) {
      throw const WeatherFailure(
        'Could not get your location. Enable location access and retry. In a browser, use HTTPS or localhost.',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
