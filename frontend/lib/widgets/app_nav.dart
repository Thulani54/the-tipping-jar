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
    ('Blog',         '/blog'),
    ('Developers',   '/developers'),
    ('Contact',      '/contact'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w <= 1000;

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
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3)),
              ]),
            ),
            const Spacer(),

            // Desktop nav links
            if (!isMobile) ...[
              ..._links
                  .where((l) => l.$2 != '/creators' ||
                      DateTime.now().isAfter(DateTime(2026, 3, 23)))
                  .map((l) => _NavLink(
                        label: l.$1,
                        route: l.$2,
                        active: activeRoute == l.$2,
                      )),
              const SizedBox(width: 12),
            ],

            // Desktop CTA buttons
            if (!isMobile) ...[
              _outlineBtn('Sign in', () => context.go('/login')),
              const SizedBox(width: 10),
              _solidBtn('Get started', () => context.go('/register')),
            ],

            // Mobile: Get started pill + hamburger
            if (isMobile) ...[
              _solidBtn('Get started', () => context.go('/register')),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _openDrawer(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorder),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.centerLeft,
        child: _MobileDrawer(activeRoute: activeRoute),
      ),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: kBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
      );

  Widget _solidBtn(String label, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      );
}

// ─── Mobile drawer panel ──────────────────────────────────────────────────────
class _MobileDrawer extends StatelessWidget {
  final String? activeRoute;
  const _MobileDrawer({this.activeRoute});

  static const _links = [
    (Icons.home_rounded,            'Home',         '/'),
    (Icons.star_rounded,            'Features',     '/features'),
    (Icons.help_outline_rounded,    'How it works', '/how-it-works'),
    (Icons.groups_rounded,          'Creators',     '/creators'),
    (Icons.business_rounded,        'Enterprise',   '/enterprise'),
    (Icons.article_rounded,         'Blog',         '/blog'),
    (Icons.code_rounded,            'Developers',   '/developers'),
    (Icons.mail_outline_rounded,    'Contact',      '/contact'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: kDarker,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header: logo + close
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () { Navigator.pop(context); context.go('/'); },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const AppLogoIcon(size: 28),
                    const SizedBox(width: 8),
                    Text('TippingJar',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.3)),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 8),
            Divider(color: kBorder, height: 32),

            // Nav links
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: _links.map((l) {
                  final active = activeRoute == l.$3;
                  return GestureDetector(
                    onTap: () { Navigator.pop(context); context.go(l.$3); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: active ? kPrimary.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? kPrimary.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(children: [
                        Icon(l.$1,
                            size: 18,
                            color: active ? kPrimary : kMuted),
                        const SizedBox(width: 12),
                        Text(l.$2,
                            style: GoogleFonts.dmSans(
                                color: active ? kPrimary : Colors.white,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14)),
                        if (active) ...[
                          const Spacer(),
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: kPrimary, shape: BoxShape.circle),
                          ),
                        ],
                      ]),
                    ),
                  );
                }).toList()),
              ),
            ),

            // CTA buttons at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(children: [
                Divider(color: kBorder, height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () { Navigator.pop(context); context.go('/login'); },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                    ),
                    child: Text('Sign in',
                        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); context.go('/register'); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                    ),
                    child: Text('Get started',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  final bool active;
  const _NavLink({required this.label, required this.route, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Text(label,
            style: GoogleFonts.dmSans(
                color: active ? kPrimary : kMuted,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
