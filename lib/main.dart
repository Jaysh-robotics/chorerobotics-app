import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/robot/robot_command_client.dart';
import 'core/router/app_router.dart';
import 'core/weather/weather_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ChoreRoboticsApp());
}

class ChoreRoboticsApp extends StatefulWidget {
  const ChoreRoboticsApp({super.key});

  @override
  State<ChoreRoboticsApp> createState() => _ChoreRoboticsAppState();
}

class _ChoreRoboticsAppState extends State<ChoreRoboticsApp> {
  late final RobotCommandClient _commandClient;

  @override
  void initState() {
    super.initState();
    _commandClient = RobotCommandClient();
  }

  @override
  void dispose() {
    _commandClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _commandClient),
        ChangeNotifierProvider(create: (_) => WeatherController()..start()),
      ],
      child: MaterialApp.router(
        title: 'Chore Robotics',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Poppins',
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF8400),
            surface: Color(0xFF0E0E10),
          ),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
