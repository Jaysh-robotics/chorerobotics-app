import 'package:go_router/go_router.dart';

import '../../features/connection/presentation/connection_screen.dart';
import '../../features/redesign/home_screen.dart';
import '../../features/redesign/attachment_screens.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/connection',
        name: 'connection',
        builder: (context, state) => const ConnectionScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const OpeningScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/attachments',
        builder: (context, state) => const AttachmentSelectionScreen(),
      ),
      GoRoute(
        path: '/attachment-setup',
        builder: (context, state) => const AttachmentSetupScreen(),
      ),
      GoRoute(
        path: '/connect-attachment/:attachment',
        builder: (context, state) => ConnectAttachmentScreen(
          attachmentId: state.pathParameters['attachment']!,
          autoDetect: state.uri.queryParameters['mode'] == 'auto',
        ),
      ),
      GoRoute(
        path: '/setup-ready/:attachment',
        builder: (context, state) => AttachmentReadyScreen(
          attachmentId: state.pathParameters['attachment']!,
          confirmed: state.uri.queryParameters['confirmed'] == 'true',
        ),
      ),
    ],
  );
}
