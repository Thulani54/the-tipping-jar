import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
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
import 'screens/fan_dashboard_screen.dart';
import 'screens/jar_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/enterprise_screen.dart';
import 'screens/developer_screen.dart';
import 'screens/pricing_screen.dart';
import 'screens/changelog_screen.dart';
import 'screens/about_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/blog_detail_screen.dart';
import 'screens/careers_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/dispute_screen.dart';
import 'screens/enterprise_portal_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/payment_callback_screen.dart';
import 'screens/subscribe_screen.dart';
import 'screens/partner_apply_screen.dart';

/// Routes that require the user to be signed in.
const _protectedRoutes = {'/dashboard', '/onboarding', '/fan-dashboard', '/enterprise-portal', '/otp-verify'};

/// Routes that signed-in users should not visit.
/// Note: /register is intentionally excluded — the register screen manages
/// its own post-registration navigation (OTP step → onboarding → dashboard).
/// Redirecting away from /register while the user is still in the OTP flow
/// would break that flow.
const _authRoutes = {'/login'};

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth, // re-evaluate redirect whenever auth changes
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final path = state.uri.path;

      // Bounce unauthenticated users away from protected pages
      if (_protectedRoutes.contains(path) && !loggedIn) {
        return '/login';
      }

      // Logged-in but OTP not verified — only gate protected routes to /otp-verify.
      // Public pages (creator profiles, jar pages, etc.) are always accessible.
      if (loggedIn && !auth.otpVerified && _protectedRoutes.contains(path)) {
        return '/otp-verify';
      }

      // OTP verified — redirect away from OTP screen
      if (loggedIn && auth.otpVerified && path == '/otp-verify') {
        if (auth.isCreator) return '/dashboard';
        if (auth.isEnterprise) return '/enterprise-portal';
        return '/fan-dashboard';
      }

      // Logged-in users visiting /login or /register go to their home
      if (_authRoutes.contains(path) && loggedIn && auth.otpVerified) {
        if (auth.isCreator) return '/dashboard';
        if (auth.isEnterprise) return '/enterprise-portal';
        return '/fan-dashboard';
      }

      return null; // no redirect needed
    },
    routes: [
      GoRoute(path: '/',             builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/explore',      builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/features',     builder: (_, __) => const FeaturesScreen()),
      GoRoute(path: '/how-it-works', builder: (_, __) => const HowItWorksScreen()),
      GoRoute(path: '/creators',     builder: (_, __) => const CreatorsScreen()),
      GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding',     builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/otp-verify',     builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/dashboard',      builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/fan-dashboard',  builder: (_, __) => const FanDashboardScreen()),
      GoRoute(path: '/enterprise',        builder: (_, __) => const EnterpriseScreen()),
      GoRoute(path: '/enterprise-portal', builder: (_, __) => const EnterprisePortalScreen()),
      GoRoute(path: '/developers',   builder: (_, __) => const DeveloperScreen()),
      GoRoute(path: '/pricing',      builder: (_, __) => const PricingScreen()),
      GoRoute(path: '/changelog',    builder: (_, __) => const ChangelogScreen()),
      GoRoute(path: '/about',        builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/blog',         builder: (_, __) => const BlogScreen()),
      GoRoute(
        path: '/blog/:slug',
        builder: (_, state) =>
            BlogDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/careers',      builder: (_, __) => const CareersScreen()),
      GoRoute(path: '/privacy',      builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/terms',        builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/cookies',      builder: (_, __) => const CookiesScreen()),
      // More specific routes first
      GoRoute(
        path: '/creator/:slug/subscribe',
        builder: (_, state) =>
            SubscribeScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/creator/:slug/jar/:jarSlug',
        builder: (_, state) => JarScreen(
          creatorSlug: state.pathParameters['slug']!,
          jarSlug: state.pathParameters['jarSlug']!,
        ),
      ),
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
      // /u/:slug is the short tip link shared from the dashboard
      GoRoute(
        path: '/u/:slug',
        builder: (_, state) =>
            TipScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/payment/callback',
        builder: (_, state) => PaymentCallbackScreen(
          reference: state.uri.queryParameters['ref'] ?? '',
        ),
      ),
      GoRoute(path: '/partner-apply', builder: (_, __) => const PartnerApplyScreen()),
      GoRoute(path: '/contact',  builder: (_, __) => const ContactScreen()),
      GoRoute(path: '/dispute',  builder: (_, state) => DisputeScreen(tipRef: state.uri.queryParameters['ref'])),
      GoRoute(
        path: '/dispute/:token',
        builder: (_, state) =>
            DisputeTrackingScreen(token: state.pathParameters['token']!),
      ),
    ],
  );
}
