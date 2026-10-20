import 'dart:async';
import 'dart:convert';

import 'package:chorerobotics/core/weather/weather_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> weatherJson() => {
  'current': {
    'temperature_2m': 73.4,
    'weather_code': 61,
    'is_day': 1,
    'time': 1800000900,
  },
  'hourly': {
    'time': [1799996400, 1800000000, 1800003600],
    'precipitation_probability': [5, 35, 90],
  },
};

void main() {
  test(
    'uses device coordinates and matches rain probability to the current hour',
    () async {
      var calls = 0;
      final controller = WeatherController(
        locate: (_) async => (latitude: 31.52041, longitude: 74.35871),
        client: MockClient((request) async {
          calls++;
          expect(request.url.scheme, 'https');
          expect(request.url.queryParameters['latitude'], '31.520');
          expect(request.url.queryParameters['longitude'], '74.359');
          expect(request.url.queryParameters['timeformat'], 'unixtime');
          return http.Response(jsonEncode(weatherJson()), 200);
        }),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.weather?.summary, '73\u00B0F \u2022 35%');
      expect(controller.weather?.condition, 'Rain');
      expect(controller.error, isNull);
      await controller.refresh();
      expect(calls, 1);
      await controller.refresh(force: true);
      expect(calls, 2);
    },
  );

  test(
    'permission denial never calls weather API or shows fake values',
    () async {
      final controller = WeatherController(
        locate: (_) async => throw const WeatherFailure(
          'Allow location access to see local weather.',
        ),
        client: MockClient(
          (_) async =>
              throw StateError('Must not call weather without location'),
        ),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.weather, isNull);
      expect(controller.error, contains('Allow location'));
      expect(controller.loading, isFalse);
    },
  );

  test(
    'failed refresh replaces old values with an explicit network failure',
    () async {
      var offline = false;
      final controller = WeatherController(
        locate: (_) async => (latitude: 30.0, longitude: 74.0),
        client: MockClient((_) async {
          if (offline) throw http.ClientException('offline');
          return http.Response(jsonEncode(weatherJson()), 200);
        }),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.weather, isNotNull);
      offline = true;
      await controller.refresh(force: true);
      expect(controller.weather, isNull);
      expect(controller.error, contains('internet'));
    },
  );

  test(
    'invalid provider response is not presented as current weather',
    () async {
      final controller = WeatherController(
        locate: (_) async => (latitude: 30.0, longitude: 74.0),
        client: MockClient((_) async => http.Response('{"current": {}}', 200)),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.weather, isNull);
      expect(controller.error, contains('incomplete data'));
    },
  );

  test('unknown or missing rain probability is not made up', () {
    final json = weatherJson();
    json['hourly'] = {
      'time': [1800000000],
      'precipitation_probability': [null],
    };
    expect(LocalWeather.fromJson(json).summary, '73\u00B0F');
  });

  test(
    'disposal during a location request does not notify or fetch later',
    () async {
      final location = Completer<WeatherLocation>();
      var calls = 0;
      final controller = WeatherController(
        locate: (_) => location.future,
        client: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(weatherJson()), 200);
        }),
      );
      final pending = controller.refresh();
      controller.dispose();
      location.complete((latitude: 30.0, longitude: 74.0));
      await pending;
      expect(calls, 0);
    },
  );

  testWidgets(
    'automatic refresh pauses when inactive and runs every fifteen minutes',
    (tester) async {
      var calls = 0;
      final controller = WeatherController(
        locate: (_) async => (latitude: 30.0, longitude: 74.0),
        client: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(weatherJson()), 200);
        }),
      );
      controller.start();
      await tester.pump(const Duration(minutes: 15));
      await tester.pump();
      expect(calls, 1);
      controller.active = false;
      await tester.pump(const Duration(minutes: 15));
      expect(calls, 1);
      controller.active = true;
      await tester.pump(const Duration(minutes: 15));
      await tester.pump();
      expect(calls, 2);
      controller.dispose();
    },
  );
}
