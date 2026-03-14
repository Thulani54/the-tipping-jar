import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_nav.dart';
import '../widgets/site_footer.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _bgWhite   = Colors.white;
const _bgSage    = Color(0xFFF5F9F6);
const _ink       = Color(0xFF080F0B);
const _inkBody   = Color(0xFF38524A);
const _inkMuted  = Color(0xFF7A9487);
const _border    = Color(0xFFDBEAE1);
const _green     = Color(0xFF004423);
const _greenMid  = Color(0xFF006B3A);
const _teal      = Color(0xFF0097B2);
const _amber     = Color(0xFFF59E0B);

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl   = TextEditingController();

  String _subject   = 'general';
  bool   _loading   = false;
  bool   _submitted = false;
  String? _error;

  static const _subjects = [
    ('general',     'General Enquiry'),
    ('technical',   'Technical Issue'),
    ('billing',     'Billing / Payments'),
    ('partnership', 'Partnership'),
    ('other',       'Other'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _emailCtrl.text = user.email;
        _nameCtrl.text  = user.username;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().submitContact(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        subject: _subject,
        message: _msgCtrl.text.trim(),
      );
      if (mounted) setState(() { _submitted = true; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Something went wrong. Please try again or email us at support@tippingjar.co.za';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: _bgWhite,
      appBar: AppNav(activeRoute: '/contact'),
      body: ScrollConfiguration(
        behavior: _SmoothScroll(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(children: [
            _hero(context, w),
            _body(context, w),
            _statsRow(w),
            _faq(w),
            const SiteFooter(),
          ]),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, double w) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
    color: _bgSage,
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _LightDotPainter())),
      Positioned.fill(child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: _green.withOpacity(0.20)),
            ),
            child: Text('Support · tippingjar.co.za', style: GoogleFonts.dmSans(
                color: _greenMid, fontWeight: FontWeight.w600, fontSize: 11)),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          Text('Get in touch',
              style: GoogleFonts.dmSans(
                  color: _ink, fontWeight: FontWeight.w800,
                  fontSize: w > 700 ? 50 : 34, letterSpacing: -1.8, height: 1.1),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 80.ms).slideY(begin: 0.15),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              'Have a question, partnership idea, or need help? We respond within 1–2 business days.',
              style: GoogleFonts.dmSans(color: _inkBody, fontSize: 16, height: 1.65),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 160.ms),
          ),
        ]),
      )),
    ]),
  );

  Widget _body(BuildContext context, double w) {
    final form = _submitted ? _successCard() : _form(context);
    final cards = _contactCards(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 64),
      color: _bgWhite,
      child: w > 860
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: form),
              const SizedBox(width: 48),
              Expanded(flex: 2, child: cards),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              form,
              const SizedBox(height: 48),
              cards,
            ]),
    );
  }

  Widget _successCard() => Container(
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: _bgSage,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _green.withOpacity(0.25)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
      const SizedBox(height: 24),
      Text('Message sent!', style: GoogleFonts.dmSans(color: _ink,
          fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('Thanks for reaching out. We\'ve sent a confirmation to ${_emailCtrl.text} and will get back to you within 1–2 business days.',
          style: GoogleFonts.dmSans(color: _inkBody, fontSize: 15, height: 1.65),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      OutlinedButton(
        onPressed: () => setState(() { _submitted = false; _msgCtrl.clear(); }),
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: BorderSide(color: _border),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Send another message',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: _inkBody)),
      ),
    ]),
  ).animate().fadeIn(duration: 400.ms);

  Widget _form(BuildContext context) => Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Send us a message', style: GoogleFonts.dmSans(color: _ink,
          fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.6)),
      const SizedBox(height: 6),
      Text('All fields required.',
          style: GoogleFonts.dmSans(color: _inkMuted, fontSize: 13)),
      const SizedBox(height: 28),

      _rowOrStack(context,
        _field(_nameCtrl,  'Full name',      Icons.person_outline_rounded,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null),
        _field(_emailCtrl, 'Email address',  Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.contains('@') ? null : 'Enter a valid email'),
      ),
      const SizedBox(height: 16),
      _dropdownField(),
      const SizedBox(height: 16),
      _field(_msgCtrl, 'Message', Icons.message_outlined,
          maxLines: 6,
          validator: (v) => v!.trim().length < 10 ? 'At least 10 characters' : null),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Text(_error!, style: GoogleFonts.dmSans(
              color: const Color(0xFFDC2626), fontSize: 13)),
        ),
      ],
      const SizedBox(height: 24),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green, foregroundColor: Colors.white,
            elevation: 0, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Send message', style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () => context.go('/dispute'),
          child: Text('Need to raise a dispute? Click here →',
              style: GoogleFonts.dmSans(color: _green, fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: _green)),
        ),
      ),
    ]),
  );

  Widget _rowOrStack(BuildContext context, Widget a, Widget b) {
    final w = MediaQuery.of(context).size.width;
    if (w > 600) {
      return Row(children: [
        Expanded(child: a), const SizedBox(width: 16), Expanded(child: b),
      ]);
    }
    return Column(children: [a, const SizedBox(height: 16), b]);
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    validator: validator,
    style: GoogleFonts.dmSans(color: _ink, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: _inkMuted, fontSize: 14),
      prefixIcon: maxLines == 1 ? Icon(icon, color: _inkMuted, size: 18) : null,
      filled: true, fillColor: _bgSage,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626))),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626))),
      contentPadding: EdgeInsets.symmetric(
          horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
    ),
  );

  Widget _dropdownField() => DropdownButtonFormField<String>(
    value: _subject,
    onChanged: (v) => setState(() => _subject = v ?? 'general'),
    dropdownColor: Colors.white,
    style: GoogleFonts.dmSans(color: _ink, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Subject',
      prefixIcon: Icon(Icons.topic_outlined, color: _inkMuted, size: 18),
      filled: true, fillColor: _bgSage,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    ),
    items: _subjects.map((s) => DropdownMenuItem(
      value: s.$1,
      child: Text(s.$2, style: GoogleFonts.dmSans(color: _ink, fontSize: 14)),
    )).toList(),
  );

  Widget _contactCards(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Other ways to reach us', style: GoogleFonts.dmSans(color: _ink,
          fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.4)),
      const SizedBox(height: 20),
      _InfoCard(icon: Icons.email_rounded, title: 'Support',
          value: 'support@tippingjar.co.za',
          sub: 'Response within 1–2 business days', color: _green),
      const SizedBox(height: 10),
      _InfoCard(icon: Icons.shield_rounded, title: 'Disputes & Billing',
          value: 'support@tippingjar.co.za',
          sub: 'File a formal dispute with reference tracking',
          color: _teal, onTap: () => context.go('/dispute')),
      const SizedBox(height: 10),
      _InfoCard(icon: Icons.language_rounded, title: 'Website',
          value: 'tippingjar.co.za', sub: 'South Africa', color: _amber),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgSage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Icon(Icons.schedule_rounded, color: _inkMuted, size: 16),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Support hours', style: GoogleFonts.dmSans(
                color: _ink, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text('Mon–Fri, 08:00–17:00 SAST', style: GoogleFonts.dmSans(
                color: _inkMuted, fontSize: 12)),
          ]),
        ]),
      ),
    ],
  );

  Widget _statsRow(double w) => Container(
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 48),
    color: _bgSage,
    child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
      children: [
        _StatChip(icon: Icons.timer_outlined, label: '< 2 business days', desc: 'Average response time'),
        _StatChip(icon: Icons.verified_rounded, label: '98% resolved', desc: 'Satisfaction rate'),
        _StatChip(icon: Icons.lock_rounded, label: 'Encrypted', desc: 'All messages secured'),
      ],
    ),
  );

  Widget _faq(double w) {
    const faqs = [
      ('How do I file a dispute?',
       'Visit tippingjar.co.za/dispute, fill in the form, and you\'ll receive a tracking link by email within minutes.'),
      ('How long does it take to process a payout?',
       'Payouts are processed within 2–5 business days after the tip is completed, depending on your bank.'),
      ('My tip didn\'t go through. What should I do?',
       'Check your email for a failed payment notification, then try again or contact us for help.'),
      ('Can I get a refund on a tip?',
       'Tips are generally non-refundable, but file a dispute and we\'ll investigate unauthorized or erroneous transactions.'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 64),
      color: _bgWhite,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Frequently asked questions', style: GoogleFonts.dmSans(color: _ink,
            fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.6)),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: faqs.map((f) => _FaqItem(q: f.$1, a: f.$2)).toList()),
        ),
      ]),
    );
  }
}

// ─── Info card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatefulWidget {
  final IconData icon;
  final String title, value, sub;
  final Color color;
  final VoidCallback? onTap;
  const _InfoCard({required this.icon, required this.title,
      required this.value, required this.sub, required this.color, this.onTap});
  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _hovered ? widget.color.withOpacity(0.35) : const Color(0xFFDBEAE1)),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.color.withOpacity(0.08),
                  blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.03),
                  blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title, style: GoogleFonts.dmSans(color: const Color(0xFF7A9487),
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(widget.value, style: GoogleFonts.dmSans(
                color: const Color(0xFF080F0B), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(widget.sub, style: GoogleFonts.dmSans(
                color: const Color(0xFF7A9487), fontSize: 11)),
          ])),
          if (widget.onTap != null)
            Icon(Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF7A9487), size: 12),
        ]),
      ),
    ),
  );
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  const _StatChip({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFDBEAE1)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: const Color(0xFF004423), size: 20),
      const SizedBox(height: 10),
      Text(label, style: GoogleFonts.dmSans(
          color: const Color(0xFF080F0B), fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 3),
      Text(desc, style: GoogleFonts.dmSans(
          color: const Color(0xFF7A9487), fontSize: 12)),
    ]),
  );
}

// ─── FAQ item ─────────────────────────────────────────────────────────────────
class _FaqItem extends StatefulWidget {
  final String q, a;
  const _FaqItem({required this.q, required this.a});
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: AnimatedContainer(
      duration: 200.ms,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _open ? const Color(0xFFF5F9F6) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _open ? const Color(0xFF004423).withOpacity(0.28) : const Color(0xFFDBEAE1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.q, style: GoogleFonts.dmSans(
              color: const Color(0xFF080F0B), fontWeight: FontWeight.w600, fontSize: 14))),
          Icon(_open ? Icons.remove_rounded : Icons.add_rounded,
              color: _open ? const Color(0xFF004423) : const Color(0xFF7A9487), size: 18),
        ]),
        if (_open) ...[
          const SizedBox(height: 10),
          Text(widget.a, style: GoogleFonts.dmSans(
              color: const Color(0xFF38524A), fontSize: 13, height: 1.65)),
        ],
      ]),
    ),
  );
}

// ─── Light dot painter ────────────────────────────────────────────────────────
class _LightDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF004423).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x <= size.width; x += spacing)
      for (double y = 0; y <= size.height; y += spacing)
        canvas.drawCircle(Offset(x, y), 1.2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Smooth scroll ────────────────────────────────────────────────────────────
class _SmoothScroll extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
