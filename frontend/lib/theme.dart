import 'package:flutter/material.dart';

// ─── Brand palette ────────────────────────────────────────────────────────────
const kDark    = Color(0xFF0A0F0D);
const kDarker  = Color(0xFF060A08);
const kPrimary = Color(0xFF00C896); // emerald green
const kTeal    = Color(0xFF0097B2); // ocean teal
const kBlue    = Color(0xFF2563EB); // electric blue
const kCardBg  = Color(0xFF111A16);
const kBorder  = Color(0xFF1E2E26);
const kMuted   = Color(0xFF7A9088);

// ─── Gradient helpers ─────────────────────────────────────────────────────────
const kGradient = LinearGradient(colors: [kPrimary, kTeal]);

BoxDecoration gradientBox({double radius = 36}) => BoxDecoration(
      color: kPrimary,
      borderRadius: BorderRadius.circular(radius),
    );

// ─── Text styles ─────────────────────────────────────────────────────────────
TextStyle headingXL(BuildContext ctx) => TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: MediaQuery.of(ctx).size.width < 700 ? 32 : 46,
      letterSpacing: -1.5,
      height: 1.1,
    );

const kBodyStyle = TextStyle(color: kMuted, fontSize: 16, height: 1.65);
