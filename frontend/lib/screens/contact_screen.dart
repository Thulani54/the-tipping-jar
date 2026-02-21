import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

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
    // Pre-fill if user is logged in
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
        _error = 'Something went wrong. Please try again or email us directly at support@tippingjar.co.za';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/contact'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(context, w),
          _body(context, w),
          _infoRow(w),
          _faq(w),
          _footer(),
        ]),
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext context, double w) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
    color: kDarker,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: Text('Support · tippingjar.co.za',
            style: GoogleFonts.inter(
                color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('Get in touch',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: w > 700 ? 48 : 32, letterSpacing: -1.5, height: 1.1),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Text(
          'Have a question, partnership idea, or need help? We respond within 1–2 business days.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 16, height: 1.65),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 160.ms),
      ),
    ]),
  );

  // ── Body (form + contact cards) ─────────────────────────────────────────────
  Widget _body(BuildContext context, double w) {
    final form = _submitted ? _successCard() : _form(context);
    final cards = _contactCards();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: kDark,
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
      color: kCardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kPrimary.withOpacity(0.3)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
      const SizedBox(height: 24),
      Text('Message sent!',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text('Thanks for reaching out. We\'ve sent a confirmation to ${_emailCtrl.text} and will get back to you within 1–2 business days.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 15, height: 1.65),
          textAlign: TextAlign.center),
      const SizedBox(height: 28),
      OutlinedButton(
        onPressed: () => setState(() { _submitted = false; _msgCtrl.clear(); }),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: kBorder),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Send another message',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    ]),
  ).animate().fadeIn(duration: 400.ms);

  Widget _form(BuildContext context) => Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Send us a message',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('All fields required.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
      const SizedBox(height: 28),

      // Name + Email row
      _rowOrStack(context,
        _field(_nameCtrl,  'Full name', Icons.person_outline_rounded,
            validator: (v) => v!.trim().isEmpty ? 'Required' : null),
        _field(_emailCtrl, 'Email address', Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.contains('@') ? null : 'Enter a valid email'),
      ),
      const SizedBox(height: 16),

      // Subject dropdown
      _dropdownField(),
      const SizedBox(height: 16),

      // Message
      _field(_msgCtrl, 'Message', Icons.message_outlined,
          maxLines: 6,
          validator: (v) => v!.trim().length < 10 ? 'At least 10 characters' : null),
      const SizedBox(height: 8),

      if (_error != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF87171).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
          ),
          child: Text(_error!, style: GoogleFonts.inter(
              color: const Color(0xFFF87171), fontSize: 13)),
        ),
      ],
      const SizedBox(height: 24),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Send message',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700,
                      fontSize: 15, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: GestureDetector(
          onTap: () => context.go('/dispute'),
          child: Text('Need to raise a dispute? Click here →',
              style: GoogleFonts.inter(color: kPrimary, fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: kPrimary)),
        ),
      ),
    ]),
  );

  Widget _rowOrStack(BuildContext context, Widget a, Widget b) {
    final w = MediaQuery.of(context).size.width;
    if (w > 600) {
      return Row(children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ]);
    }
    return Column(children: [a, const SizedBox(height: 16), b]);
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
    TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 14),
        prefixIcon: maxLines == 1 ? Icon(icon, color: kMuted, size: 18) : null,
        filled: true, fillColor: kCardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimary)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF87171))),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
      ),
    );

  Widget _dropdownField() => DropdownButtonFormField<String>(
    value: _subject,
    onChanged: (v) => setState(() => _subject = v ?? 'general'),
    dropdownColor: kCardBg,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: 'Subject',
      prefixIcon: const Icon(Icons.topic_outlined, color: kMuted, size: 18),
      filled: true, fillColor: kCardBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    ),
    items: _subjects.map((s) => DropdownMenuItem(
      value: s.$1,
      child: Text(s.$2, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
    )).toList(),
  );

  // ── Contact info cards ──────────────────────────────────────────────────────
  Widget _contactCards() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Other ways to reach us',
        style: GoogleFonts.inter(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 18)),
    const SizedBox(height: 20),
    _InfoCard(
      icon: Icons.email_rounded,
      title: 'Support',
      value: 'support@tippingjar.co.za',
      sub: 'Response within 1–2 business days',
      color: kPrimary,
    ),
    const SizedBox(height: 12),
    _InfoCard(
      icon: Icons.shield_rounded,
      title: 'Disputes & Billing',
      value: 'support@tippingjar.co.za',
      sub: 'File a formal dispute with reference tracking',
      color: kTeal,
      onTap: () => context.go('/dispute'),
    ),
    const SizedBox(height: 12),
    _InfoCard(
      icon: Icons.language_rounded,
      title: 'Website',
      value: 'tippingjar.co.za',
      sub: 'South Africa',
      color: const Color(0xFFFBBF24),
    ),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        const Icon(Icons.schedule_rounded, color: kMuted, size: 16),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Support hours', style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Mon–Fri, 08:00–17:00 SAST', style: GoogleFonts.inter(
              color: kMuted, fontSize: 12)),
        ]),
      ]),
    ),
  ]);

  // ── Info row ────────────────────────────────────────────────────────────────
  Widget _infoRow(double w) => Container(
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 56),
    color: kDarker,
    child: Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
      children: const [
        _StatChip(icon: Icons.timer_outlined, label: '< 2 business days', desc: 'Average response time'),
        _StatChip(icon: Icons.verified_rounded, label: '98% resolved', desc: 'Satisfaction rate'),
        _StatChip(icon: Icons.lock_rounded, label: 'Secure', desc: 'All messages encrypted'),
      ],
    ),
  );

  // ── FAQ ─────────────────────────────────────────────────────────────────────
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
      color: kDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Frequently asked questions',
            style: GoogleFonts.inter(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: faqs.map((f) => _FaqItem(q: f.$1, a: f.$2)).toList()),
        ),
      ]),
    );
  }

  Widget _footer() => Container(
    color: kDarker, padding: const EdgeInsets.all(24),
    child: Text('© 2026 TippingJar · support@tippingjar.co.za · tippingjar.co.za',
        style: GoogleFonts.inter(color: kMuted, fontSize: 12),
        textAlign: TextAlign.center),
  );
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title, value, sub;
  final Color color;
  final VoidCallback? onTap;
  const _InfoCard({required this.icon, required this.title,
      required this.value, required this.sub, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onTap != null ? color.withOpacity(0.3) : kBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(color: kMuted, fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(color: Colors.white,
              fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.inter(color: kMuted, fontSize: 11)),
        ])),
        if (onTap != null)
          const Icon(Icons.arrow_forward_ios_rounded, color: kMuted, size: 12),
      ]),
    ),
  ));
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  const _StatChip({required this.icon, required this.label, required this.desc});

  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: kPrimary, size: 20),
      const SizedBox(height: 10),
      Text(label, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 3),
      Text(desc, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
    ]),
  );
}

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
        color: _open ? kPrimary.withOpacity(0.05) : kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _open ? kPrimary.withOpacity(0.3) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.q, style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
          Icon(_open ? Icons.remove_rounded : Icons.add_rounded,
              color: _open ? kPrimary : kMuted, size: 18),
        ]),
        if (_open) ...[
          const SizedBox(height: 10),
          Text(widget.a, style: GoogleFonts.inter(
              color: kMuted, fontSize: 13, height: 1.6)),
        ],
      ]),
    ),
  );
}
