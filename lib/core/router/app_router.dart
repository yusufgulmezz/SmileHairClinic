import 'package:go_router/go_router.dart';
import '../../screens/login_screen.dart';
import '../../screens/guide_screen.dart';
import '../../screens/camera_screen.dart';
import '../../screens/summary_screen.dart';
import '../../screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/guide',
      name: 'guide',
      builder: (context, state) => const GuideScreen(),
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/summary',
      name: 'summary',
      builder: (context, state) => const SummaryScreen(),
    ),
  ],
);

