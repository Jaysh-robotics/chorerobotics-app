import 'dart:async';

import 'package:chorerobotics/core/robot/robot_command_client.dart';
import 'package:chorerobotics/core/robot/mower_defaults.dart';
import 'package:chorerobotics/features/redesign/mower_defaults_screen.dart';
import 'package:chorerobotics/core/weather/weather_controller.dart';
import 'package:chorerobotics/features/redesign/attachment_screens.dart';
import 'package:chorerobotics/features/redesign/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _Client extends RobotCommandClient {
  final inbound = StreamController<Map<String, dynamic>>.broadcast();
  bool connected = false;
  String? selected;
  int requests = 0;
  bool? scheduleEnabled;
  String? startedZone;
  MowerDefaults? savedDefaults;
  bool savedOnRobot = false;
  @override
  bool get hasSavedMowerDefaults => savedOnRobot;
  @override
  String? getMowerDefaults() => null;
  @override
  String? saveMowerDefaults(MowerDefaults defaults) {
    savedDefaults = defaults;
    return 'save-defaults';
  }

  @override
  void sendScheduleSet({
    required String scheduleId,
    required int hour,
    required int minute,
    required String period,
    required List<int> days,
    required Map<String, dynamic> taskParameters,
    bool? enabled,
  }) {
    scheduleEnabled = enabled;
  }

  @override
  void sendTaskStart({
    required String taskId,
    required String taskType,
    required String zoneId,
    required String zoneName,
    required double totalAreaSqM,
    Map<String, dynamic> parameters = const {},
  }) {
    startedZone = zoneName;
  }

  @override
  bool get isConnected => connected;
  @override
  Stream<Map<String, dynamic>> get messages => inbound.stream;
  @override
  String? sendAttachmentSelected(
    String attachment, {
    required bool supported,
    String? serialNumber,
  }) {
    selected = attachment;
    return connected ? 'request-${++requests}' : null;
  }

  @override
  String? sendAttachmentDetect() => connected ? 'request-${++requests}' : null;

  void ack(String id, String status, {String? attachment}) => inbound.add({
    'type': 'command_ack',
    'payload': {
      'command_id': id,
      'status': status,
      'message': 'test response',
      'attachment': attachment,
    },
  });

  @override
  void dispose() {
    inbound.close();
    super.dispose();
  }
}

Future<GoRouter> _mount(
  WidgetTester tester,
  _Client client,
  String path, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final weather = WeatherController(
    locate: (_) async => throw const WeatherFailure(
      'Allow location access to see local weather, then tap Retry.',
    ),
  );
  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(
        path: '/mower-defaults',
        builder: (_, _) => const MowerDefaultsScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/attachments',
        builder: (_, _) => const AttachmentSelectionScreen(),
      ),
      GoRoute(
        path: '/attachment-setup',
        builder: (_, _) => const AttachmentSetupScreen(),
      ),
      GoRoute(
        path: '/connect-attachment/:id',
        builder: (_, state) => ConnectAttachmentScreen(
          attachmentId: state.pathParameters['id']!,
          autoDetect: state.uri.queryParameters['mode'] == 'auto',
        ),
      ),
      GoRoute(
        path: '/setup-ready/:id',
        builder: (_, state) => AttachmentReadyScreen(
          attachmentId: state.pathParameters['id']!,
          confirmed: state.uri.queryParameters['confirmed'] == 'true',
        ),
      ),
    ],
  );
  addTearDown(() {
    router.dispose();
    client.dispose();
    weather.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RobotCommandClient>.value(value: client),
        ChangeNotifierProvider<WeatherController>.value(value: weather),
      ],
      child: MaterialApp.router(routerConfig: router, theme: ThemeData.dark()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return router;
}

void main() {
  test('defaults reject invalid server values before rendering sliders', () {
    final payload = const MowerDefaults().toJson();
    expect(MowerDefaults.fromJson(payload).cutHeight, 65);
    payload['cut_height_mm'] = 1000;
    expect(() => MowerDefaults.fromJson(payload), throwsFormatException);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final poppins = FontLoader('Poppins');
    for (final style in ['ExtraLight', 'Regular', 'Medium', 'Bold']) {
      poppins.addFont(rootBundle.load('assets/fonts/Poppins-$style.ttf'));
    }
    await poppins.load();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });
  testWidgets(
    'every attachment opens its own setup preview, Done returns home',
    (tester) async {
      final client = _Client();
      final router = await _mount(tester, client, '/attachments');
      for (final attachment in choreAttachments) {
        router.go('/attachments');
        await tester.pumpAndSettle();
        final tile = find.text(attachment.name).first;
        await tester.scrollUntilVisible(
          tile,
          140,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(tile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(client.selected, attachment.id);
        await tester.scrollUntilVisible(
          find.text('Next'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        if (attachment.id == 'mower') {
          await tester.scrollUntilVisible(
            find.text('Save'),
            160,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Offline preview'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image && widget.semanticLabel == attachment.name,
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.text('Configure New Attachment'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'Next requires the matching accepted ACK and Retry ignores stale replies',
    (tester) async {
      final client = _Client()..connected = true;
      await _mount(tester, client, '/connect-attachment/collector');
      client.ack('another-command', 'accepted');
      await tester.pump();
      expect(find.text('Chore Collector Connected'), findsNothing);
      client.ack('request-1', 'rejected');
      await tester.pump();
      expect(find.text('test response'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      client.ack('request-1', 'accepted');
      await tester.pump();
      expect(find.text('Chore Collector Connected'), findsNothing);
      client.ack('request-2', 'accepted');
      await tester.pump();
      expect(find.text('Chore Collector Connected'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved to robot'), findsOneWidget);
    },
  );

  testWidgets('Auto Detect uses the attachment returned by the server', (
    tester,
  ) async {
    final client = _Client()..connected = true;
    await _mount(tester, client, '/connect-attachment/mower?mode=auto');
    client.ack('request-1', 'accepted', attachment: 'patrol');
    await tester.pump();
    expect(find.text('Chore Patrol Connected'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == 'Chore Patrol',
      ),
      findsOneWidget,
    );
  });

  testWidgets('new screens remain usable on a short narrow phone', (
    tester,
  ) async {
    final router = await _mount(
      tester,
      _Client(),
      '/home',
      size: const Size(320, 568),
    );
    for (final path in [
      '/home',
      '/attachments',
      '/attachment-setup',
      '/connect-attachment/mower',
      '/setup-ready/mower',
      '/mower-defaults',
    ]) {
      router.go(path);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: path);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('defaults Save waits for matching ACK and surfaces rejection', (
    tester,
  ) async {
    final client = _Client()..connected = true;
    await _mount(tester, client, '/mower-defaults');
    await tester.tap(find.text('Diagonal'));
    await tester.scrollUntilVisible(
      find.text('Save'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(client.savedDefaults?.pattern, 'diagonal');
    expect(client.savedDefaults?.cutHeight, 65);
    client.ack('unrelated', 'accepted');
    await tester.pump();
    expect(find.text('Saving...'), findsOneWidget);
    client.ack('save-defaults', 'rejected');
    await tester.pump();
    expect(find.text('test response'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pump();
    client.ack('save-defaults', 'accepted');
    await tester.pumpAndSettle();
    expect(find.text('Settings saved to robot'), findsOneWidget);
  });

  testWidgets(
    'offline connection shows unreachable and retries after five seconds',
    (tester) async {
      final client = _Client();
      await _mount(tester, client, '/connect-attachment/mower');
      expect(find.text('Robot not reachable'), findsOneWidget);
      client.connected = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(client.requests, 1);
      client.ack('request-1', 'accepted');
      await tester.pump();
      expect(find.text('Chore Mower Connected'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'homepage schedule toggle survives navigation and re-run sends the Front Yard task',
    (tester) async {
      final client = _Client();
      final router = await _mount(tester, client, '/home');
      expect(find.text('Upcoming Schedule'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Enable mower schedule',
        ),
      );
      await tester.pumpAndSettle();
      expect(client.scheduleEnabled, isFalse);
      router.go('/attachments');
      await tester.pumpAndSettle();
      router.go('/home');
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await tester.tap(find.text('Re-run: Chore Mower | Front Yard'));
      await tester.pump();
      expect(client.startedZone, 'Front Yard');
      await tester.tap(find.text('Configure New Attachment'));
      await tester.pumpAndSettle();
      expect(find.text('Auto Detect'), findsOneWidget);
    },
  );

  testWidgets(
    'homepage displays saved time, days and zone, never sample schedule',
    (tester) async {
      final client = _Client();
      await _mount(tester, client, '/home');
      expect(find.text('No saved schedule loaded'), findsOneWidget);
      expect(find.textContaining('08:00'), findsNothing);
      client.savedOnRobot = true;
      client.mowerDefaults = const MowerDefaults(
        hour: 23,
        minute: 15,
        zone: 'Side Yard',
        days: [2, 4],
      );
      await tester.pump();
      expect(find.textContaining('Tue, Thu, 23:15'), findsOneWidget);
      expect(find.textContaining('08:00'), findsNothing);
    },
  );

  testWidgets(
    'weather failure shows a warning and a short helpful retry note',
    (tester) async {
      await _mount(tester, _Client(), '/home');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.textContaining('72'), findsNothing);
      await tester.tap(find.byIcon(Icons.error_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Weather unavailable'), findsOneWidget);
      expect(find.textContaining('Allow location access'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    },
  );
}
