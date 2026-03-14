import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_logo.dart';

// Shared palette (light theme)
const _ink       = Color(0xFF080F0B);
const _inkMuted  = Color(0xFF7A9487);
const _bgSage    = Color(0xFFF5F9F6);
const _border    = Color(0xFFDBEAE1);
const _greenMid  = Color(0xFF006B3A);
const _greenBright = Color(0xFF00A854);

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = w < 700;
    final cols = [
      ('Product',  [('Features', '/features')]),
      ('Company',  [('About', '/about'), ('Blog', '/blog')]),
      ('Legal',    [('Privacy', '/privacy'), ('Terms', '/terms'), ('Cookies', '/cookies')]),
    ];

    final brand = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const AppLogoIcon(size: 26),
        const SizedBox(width: 8),
        Text('TippingJar', style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.4)),
      ]),
      const SizedBox(height: 12),
      Text('Supporting creators,\none tip at a time.',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, height: 1.65)),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: _greenBright.withOpacity(0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _greenBright.withOpacity(0.22)),
        ),
        child: Text('🇿🇦  Proudly South African', style: GoogleFonts.dmSans(
            color: _greenMid, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    ]);

    Widget col((String, List<(String, String)>) c) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.$1, style: GoogleFonts.dmSans(
            color: _ink, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
        const SizedBox(height: 12),
        ...c.$2.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go(l.$2),
              child: Text(l.$1, style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13, height: 1.4)),
            ),
          ),
        )),
      ],
    );

    return Container(
      color: _bgSage,
      child: Column(children: [
        Container(height: 1, color: _border),
        Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 24 : 64, 52, mobile ? 24 : 64, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (mobile) ...[
              brand,
              const SizedBox(height: 36),
              Wrap(spacing: 40, runSpacing: 28, children: cols.map(col).toList()),
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: brand),
                ...cols.map((c) => Expanded(child: col(c))),
              ]),
            const SizedBox(height: 44),
            Container(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('© 2026 TippingJar (Pty) Ltd.',
                      style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
                  if (!mobile)
                    Text('Made with ♥ for creators.',
                        style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 12)),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
