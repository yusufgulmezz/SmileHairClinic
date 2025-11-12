import 'package:go_router/go_router.dart';
import '../../screens/login_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/instructions_screen.dart';
import '../../screens/camera_screen.dart';
import '../../screens/summary_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/instructions',
      name: 'instructions',
      builder: (context, state) => const InstructionsScreen(),
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

