import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/firebase/messaging_service.dart';
import 'features/active_task/bloc/active_task_bloc.dart';
import 'features/onboarding/bloc/onboarding_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase init temporarily disabled — the app boots straight into the UI
  // so we can iterate on visuals without auth/Firestore round-trips.
  // ignore: dead_code
  if (false) {
    final fbReady = await FirebaseInitializer.init();
    if (fbReady) {
      MessagingService().initAndGetToken();
    }
  }

  runApp(const ChoreRoboticsApp());
}

class ChoreRoboticsApp extends StatelessWidget {
  const ChoreRoboticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ActiveTaskBloc()),
        BlocProvider(create: (_) => OnboardingBloc()),
      ],
      child: MaterialApp.router(
        title: 'ChoreRobotics',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
