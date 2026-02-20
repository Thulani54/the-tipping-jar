import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/creator_screen.dart';
import 'screens/tip_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';

GoRouter buildRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/creator/:slug',
        builder: (_, state) =>
            CreatorScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/tip/:slug',
        builder: (_, state) =>
            TipScreen(slug: state.pathParameters['slug']!),
      ),
    ],
  );
}
