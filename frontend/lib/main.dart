import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

const _primary = Color(0xFF004423); // deep forest green

void main() {
  usePathUrlStrategy(); // clean URLs — no /#/ hash prefix
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const TippingJarApp(),
    ),
  );
}

class TippingJarApp extends StatefulWidget {
  const TippingJarApp({super.key});
  @override
  State<TippingJarApp> createState() => _TippingJarAppState();
}

class _TippingJarAppState extends State<TippingJarApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    // Create the router synchronously so GoRouter captures the real browser URL
    // before anything else can reset it to '/'.
    _router = buildRouter(auth);
    // Auth init runs async; when it calls notifyListeners(), refreshListenable
    // triggers a redirect re-evaluation without re-creating the router.
    auth.init();
  }

  @override
  Widget build(BuildContext context) {
    // Always use MaterialApp.router — never fall back to a plain MaterialApp,
    // which would overwrite window.location with '/' and break deep links.
    return MaterialApp.router(
      title: 'The Tipping Jar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _primary),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(color: _primary),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(36)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
