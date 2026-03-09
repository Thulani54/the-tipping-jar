import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

class NotFoundScreen extends StatelessWidget {
  final String path;
  const NotFoundScreen({super.key, this.path = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Column(
        children: [
          // Nav bar
          Container(
            height: 56,
            color: kDarker,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const AppLogoIcon(size: 28),
                  const SizedBox(width: 8),
                  Text('TippingJar', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ]),
          ),

          // Body
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 404 number
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [kPrimary, Color(0xFF0097B2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        '404',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -6,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Page not found',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      path.isNotEmpty
                          ? 'The page "$path" doesn\'t exist or has been moved.'
                          : 'The page you\'re looking for doesn\'t exist or has been moved.',
                      style: GoogleFonts.dmSans(
                          color: kMuted, fontSize: 15, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Actions
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: Text('Go home',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600, fontSize: 14,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/explore'),
                          icon: const Icon(Icons.explore_rounded, size: 18,
                              color: kMuted),
                          label: Text('Browse creators',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600, fontSize: 14,
                                  color: kMuted)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kBorder),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
