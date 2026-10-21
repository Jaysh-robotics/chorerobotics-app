import 'dart:convert';
import 'dart:io';
import 'package:chorerobotics/core/robot/mower_defaults.dart';
import 'package:chorerobotics/core/robot/robot_command_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saved schedule loads on connection and survives a fresh app client',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var defaults = const MowerDefaults(
        hour: 23,
        minute: 15,
        zone: 'Side Yard',
      ).toJson();
      var saved = false;
      final sockets = <WebSocket>[];
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        sockets.add(socket);
        socket.listen((raw) {
          final command = jsonDecode(raw as String) as Map;
          if (command['type'] == 'mower_defaults_set') {
            defaults = Map<String, dynamic>.from(command['payload']);
            saved = true;
          }
          if (command['type'] == 'mower_defaults_get' ||
              command['type'] == 'mower_defaults_set') {
            socket.add(
              jsonEncode({
                'type': 'command_ack',
                'payload': {
                  'command_id': command['id'],
                  'status': 'accepted',
                  'defaults': defaults,
                  'saved': saved,
                },
              }),
            );
          }
        });
      });
      final clients = <RobotCommandClient>[];
      addTearDown(() async {
        for (final client in clients) {
          await client.disconnect();
          client.dispose();
        }
        for (final socket in sockets) {
          await socket.close();
        }
        await server.close(force: true);
      });
      Future<void> waitFor(
        RobotCommandClient client,
        bool Function() done,
      ) async {
        for (var attempt = 0; attempt < 100 && !done(); attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(done(), isTrue);
      }

      final client = RobotCommandClient();
      clients.add(client);
      await client.connect('ws://127.0.0.1:${server.port}/ws');
      await waitFor(client, () => client.ackCount > 0);
      expect(client.hasSavedMowerDefaults, isFalse);
      client.saveMowerDefaults(
        const MowerDefaults(
          hour: 23,
          minute: 15,
          zone: 'Side Yard',
          days: [2, 4],
        ),
      );
      await waitFor(client, () => client.hasSavedMowerDefaults);
      expect(client.mowerDefaults.hour, 23);
      expect(client.mowerDefaults.minute, 15);
      await client.disconnect();
      final fresh = RobotCommandClient();
      clients.add(fresh);
      await fresh.connect('ws://127.0.0.1:${server.port}/ws');
      await waitFor(fresh, () => fresh.hasSavedMowerDefaults);
      expect(fresh.mowerDefaults.zone, 'Side Yard');
      expect(fresh.mowerDefaults.days, [2, 4]);
      expect(fresh.mowerDefaults.hour, 23);
    },
  );
}
