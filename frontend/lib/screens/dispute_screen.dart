import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dispute_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

// ─── File Dispute screen (POST) ───────────────────────────────────────────────

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key});
  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _tipCtrl   = TextEditingController();

  String  _reason   = 'other';
  bool    _loading  = false;
  String? _error;
  Map<String, dynamic>? _result; // success payload

  static const _reasons = [
    ('tip_not_received', 'Tip Not Received by Creator'),
    ('wrong_amount',     'Wrong Amount Charged'),
    ('unauthorized',     'Unauthorized Transaction'),
    ('payout_issue',     'Payout / Withdrawal Issue'),
    ('account_access',   'Account Access Problem'),
    ('other',            'Other'),
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
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _descCtrl.dispose(); _tipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.api.fileDispute(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        reason: _reason,
        description: _descCtrl.text.trim(),
        tipRef: _tipCtrl.text.trim(),
      );
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/dispute'),
      body: SingleChildScrollView(
        child: Column(children: [
          _header(w),
          _result != null ? _successView(w) : _formView(w),
          _footer(),
        ]),
      ),
    );
  }

  Widget _header(double w) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
    color: kDarker,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFBBF24).withOpacity(0.1),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
        ),
        child: Text('Dispute Centre · tippingjar.co.za',
            style: GoogleFonts.inter(color: const Color(0xFFFBBF24),
                fontWeight: FontWeight.w600, fontSize: 11)),
      ).animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),
      Text('File a dispute',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: w > 700 ? 44 : 30,
              letterSpacing: -1.5, height: 1.1),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
      const SizedBox(height: 14),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Text(
          'Tell us what went wrong. You\'ll receive a tracking link by email so you can follow your case.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 15, height: 1.65),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 160.ms),
      ),
    ]),
  );

  Widget _formView(double w) => Container(
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 64),
    color: kDark,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _infoBox(
              icon: Icons.info_outline_rounded,
              color: kTeal,
              text: 'Already filed a dispute? Check your email for the tracking link, or enter your token at tippingjar.co.za/dispute/{your-token}',
            ),
            const SizedBox(height: 28),
            Text('Your details',
                style: GoogleFonts.inter(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            _row(w,
              _field(_nameCtrl, 'Full name', Icons.person_outline_rounded,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              _field(_emailCtrl, 'Email address', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Valid email required'),
            ),
            const SizedBox(height: 20),
            Text('Dispute details',
                style: GoogleFonts.inter(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 14),
            _reasonDropdown(),
            const SizedBox(height: 14),
            _field(_tipCtrl, 'Tip ID / Payment reference (optional)',
                Icons.receipt_outlined),
            const SizedBox(height: 14),
            _field(_descCtrl,
                'Describe what happened in detail…',
                Icons.description_outlined,
                maxLines: 6,
                validator: (v) => v!.trim().length < 20
                    ? 'Please provide at least 20 characters' : null),
            if (_error != null) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF0A0F0D),
                  elevation: 0, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF0A0F0D)))
                    : Text('Submit dispute',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800,
                            fontSize: 15, color: const Color(0xFF0A0F0D))),
              ),
            ),
          ]),
        ),
      ),
    ),
  );

  Widget _successView(double w) => Container(
    padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 64),
    color: kDark,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.assignment_turned_in_rounded,
                  color: Color(0xFFFBBF24), size: 30),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Dispute filed successfully',
                style: GoogleFonts.inter(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 22),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(_result?['message'] ?? '',
                style: GoogleFonts.inter(color: kMuted, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1A14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reference number',
                      style: GoogleFonts.inter(color: kMuted, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(_result?['reference'] ?? '',
                      style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFFBBF24),
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const Spacer(),
                _CopyButton(text: _result?['reference'] ?? ''),
              ]),
            ),
            const SizedBox(height: 16),
            Text('A tracking link has been sent to ${_emailCtrl.text}.',
                style: GoogleFonts.inter(color: kMuted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/contact'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Back to contact',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms),
      ),
    ),
  );

  Widget _row(double w, Widget a, Widget b) {
    if (w > 600) {
      return Row(children: [
        Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)]);
    }
    return Column(children: [a, const SizedBox(height: 14), b]);
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text,
       String? Function(String?)? validator}) =>
    TextFormField(
      controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 14),
        prefixIcon: maxLines == 1 ? Icon(icon, color: kMuted, size: 18) : null,
        filled: true, fillColor: kCardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF87171))),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 14 : 0),
      ),
    );

  Widget _reasonDropdown() => DropdownButtonFormField<String>(
    value: _reason,
    onChanged: (v) => setState(() => _reason = v ?? 'other'),
    dropdownColor: kCardBg,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.help_outline_rounded, color: kMuted, size: 18),
      filled: true, fillColor: kCardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    ),
    items: _reasons.map((r) => DropdownMenuItem(
      value: r.$1,
      child: Text(r.$2, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
    )).toList(),
  );

  Widget _infoBox({required IconData icon, required Color color, required String text}) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: GoogleFonts.inter(color: kMuted, fontSize: 12, height: 1.55))),
      ]),
    );

  Widget _footer() => Container(
    color: kDarker, padding: const EdgeInsets.all(24),
    child: Text('© 2026 TippingJar · support@tippingjar.co.za · tippingjar.co.za',
        style: GoogleFonts.inter(color: kMuted, fontSize: 12),
        textAlign: TextAlign.center),
  );
}

// ─── Dispute Tracking screen (GET by token) ───────────────────────────────────

class DisputeTrackingScreen extends StatefulWidget {
  final String token;
  const DisputeTrackingScreen({super.key, required this.token});
  @override
  State<DisputeTrackingScreen> createState() => _DisputeTrackingScreenState();
}

class _DisputeTrackingScreenState extends State<DisputeTrackingScreen> {
  DisputeModel? _dispute;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiService().getDisputeByToken(widget.token);
      if (mounted) setState(() { _dispute = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Dispute not found. Please check your tracking link.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/dispute'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? _errorView(w)
              : _detailView(w),
    );
  }

  Widget _errorView(double w) => Center(child: Padding(
    padding: EdgeInsets.all(w > 600 ? 80 : 28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.search_off_rounded, color: kMuted, size: 48),
      const SizedBox(height: 16),
      Text('Dispute not found',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w700, fontSize: 22),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(_error!, style: GoogleFonts.inter(color: kMuted, fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => context.go('/dispute'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('File a dispute',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    ]),
  ));

  Widget _detailView(double w) {
    final d = _dispute!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back
            GestureDetector(
              onTap: () => context.go('/contact'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.arrow_back_ios_new_rounded, color: kMuted, size: 13),
                const SizedBox(width: 6),
                Text('Support', style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 28),

            // Reference + status badge
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.reference,
                    style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFFBBF24),
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Dispute Details',
                    style: GoogleFonts.inter(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.5)),
              ])),
              _StatusBadge(status: d.status, label: d.statusLabel),
            ]).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            // Status timeline
            _StatusTimeline(status: d.status).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // Details card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Case details', style: GoogleFonts.inter(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
                const SizedBox(height: 16),
                _detail('Name', d.name),
                _detail('Email', d.email),
                _detail('Reason', d.reasonLabel),
                if (d.tipRef.isNotEmpty) _detail('Tip reference', d.tipRef),
                _detail('Filed on', _fmt(d.createdAt)),
                _detail('Last updated', _fmt(d.updatedAt)),
              ]),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Description', style: GoogleFonts.inter(
                    color: kMuted, fontSize: 11, fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
                const SizedBox(height: 12),
                Text(d.description, style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 14, height: 1.65)),
              ]),
            ).animate().fadeIn(delay: 200.ms),

            if (d.adminNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withOpacity(0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.support_agent_rounded, color: kPrimary, size: 15),
                    const SizedBox(width: 8),
                    Text('Notes from our team', style: GoogleFonts.inter(
                        color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  Text(d.adminNotes, style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14, height: 1.6)),
                ]),
              ).animate().fadeIn(delay: 250.ms),
            ],

            const SizedBox(height: 32),
            Center(
              child: Text(
                'Need help? Email support@tippingjar.co.za with your reference ${d.reference}',
                style: GoogleFonts.inter(color: kMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120,
          child: Text(label, style: GoogleFonts.inter(
              color: kMuted, fontSize: 12, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: GoogleFonts.inter(
          color: Colors.white, fontSize: 13))),
    ]),
  );

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status, label;
  const _StatusBadge({required this.status, required this.label});

  Color get _color => switch (status) {
    'open'          => const Color(0xFFFBBF24),
    'investigating' => kTeal,
    'resolved'      => kPrimary,
    'closed'        => kMuted,
    _               => kMuted,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color.withOpacity(0.4)),
    ),
    child: Text(label, style: GoogleFonts.inter(
        color: _color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    ('open',          'Opened',              'Dispute received and queued for review'),
    ('investigating', 'Under Investigation', 'Our team is reviewing your case'),
    ('resolved',      'Resolved',            'A resolution has been reached'),
    ('closed',        'Closed',              'Case closed'),
  ];

  int get _activeIdx => switch (status) {
    'open'          => 0,
    'investigating' => 1,
    'resolved'      => 2,
    'closed'        => 3,
    _               => 0,
  };

  @override
  Widget build(BuildContext context) {
    final active = _activeIdx;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(children: _steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        final done = i < active;
        final current = i == active;
        final color = done || current ? kPrimary : kMuted;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: done ? kPrimary : current ? kPrimary.withOpacity(0.15) : kCardBg,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done || current ? kPrimary : kMuted.withOpacity(0.3),
                    width: 2),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                  : current
                      ? Center(child: Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)))
                      : null,
            ),
            if (i < _steps.length - 1)
              Container(
                width: 2, height: 32,
                color: i < active ? kPrimary : kMuted.withOpacity(0.2)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(step.$2, style: GoogleFonts.inter(
                  color: done || current ? Colors.white : kMuted,
                  fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(step.$3, style: GoogleFonts.inter(
                  color: color.withOpacity(0.7), fontSize: 11)),
              SizedBox(height: i < _steps.length - 1 ? 12 : 0),
            ]),
          )),
        ]);
      }).toList()),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});
  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _copy,
    child: AnimatedContainer(
      duration: 200.ms,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _copied ? kPrimary.withOpacity(0.1) : kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _copied ? kPrimary : kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
            color: _copied ? kPrimary : kMuted, size: 13),
        const SizedBox(width: 4),
        Text(_copied ? 'Copied' : 'Copy',
            style: GoogleFonts.inter(color: _copied ? kPrimary : kMuted,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
