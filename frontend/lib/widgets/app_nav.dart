import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'app_logo.dart';

class AppNav extends StatelessWidget implements PreferredSizeWidget {
  final String? activeRoute;
  const AppNav({super.key, this.activeRoute});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  static const _links = [
    ('Home',         '/'),
    ('Features',     '/features'),
    ('How it works', '/how-it-works'),
    ('Creators',     '/creators'),
    ('Enterprise',   '/enterprise'),
    ('Developers',   '/developers'),
    ('Contact',      '/contact'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      color: kDarker,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: w > 900 ? 48 : 20, vertical: 12),
          child: Row(children: [
            // Logo
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const AppLogoIcon(size: 30),
                const SizedBox(width: 9),
                Text('TippingJar',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3)),
              ]),
            ),
            const Spacer(),
            if (w > 1000) ...[
              ..._links.map((l) => _NavLink(
                    label: l.$1,
                    route: l.$2,
                    active: activeRoute == l.$2,
                  )),
              const SizedBox(width: 12),
            ],
            _outlineBtn('Sign in', () => context.go('/login')),
            const SizedBox(width: 10),
            _solidBtn('Get started', () => context.go('/register')),
          ]),
        ),
      ),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: kBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500)),
      );

  Widget _solidBtn(String label, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(36)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      );
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  final bool active;
  const _NavLink(
      {required this.label, required this.route, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Text(label,
            style: GoogleFonts.inter(
                color: active ? kPrimary : kMuted,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
