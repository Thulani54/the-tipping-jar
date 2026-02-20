import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/creator_screen.dart';
import 'screens/creators_screen.dart';
import 'screens/tip_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/features_screen.dart';
import 'screens/how_it_works_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/enterprise_screen.dart';
import 'screens/developer_screen.dart';
import 'screens/pricing_screen.dart';
import 'screens/changelog_screen.dart';
import 'screens/about_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/careers_screen.dart';
import 'screens/legal_screen.dart';

GoRouter buildRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/',             builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/explore',      builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/features',     builder: (_, __) => const FeaturesScreen()),
      GoRoute(path: '/how-it-works', builder: (_, __) => const HowItWorksScreen()),
      GoRoute(path: '/creators',     builder: (_, __) => const CreatorsScreen()),
      GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding',   builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/enterprise',   builder: (_, __) => const EnterpriseScreen()),
      GoRoute(path: '/developers',   builder: (_, __) => const DeveloperScreen()),
      GoRoute(path: '/pricing',      builder: (_, __) => const PricingScreen()),
      GoRoute(path: '/changelog',    builder: (_, __) => const ChangelogScreen()),
      GoRoute(path: '/about',        builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/blog',         builder: (_, __) => const BlogScreen()),
      GoRoute(path: '/careers',      builder: (_, __) => const CareersScreen()),
      GoRoute(path: '/privacy',      builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms',        builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/cookies',      builder: (_, __) => const CookiesScreen()),
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
