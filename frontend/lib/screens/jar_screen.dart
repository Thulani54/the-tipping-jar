import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/jar_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

// ─── Public jar tip page ──────────────────────────────────────────────────────
class JarScreen extends StatefulWidget {
  final String creatorSlug;
  final String jarSlug;
  const JarScreen({super.key, required this.creatorSlug, required this.jarSlug});

  @override
  State<JarScreen> createState() => _JarScreenState();
}

class _JarScreenState extends State<JarScreen> {
  JarModel? _jar;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final jar = await ApiService().getPublicJar(widget.creatorSlug, widget.jarSlug);
      if (mounted) setState(() { _jar = jar; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kDark,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }
    if (_error != null || _jar == null) {
      return Scaffold(
        backgroundColor: kDark,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.savings_outlined, color: kMuted, size: 56),
          const SizedBox(height: 16),
          Text('Jar not found', style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          Text('This jar may have been closed or the link is invalid.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/creator/${widget.creatorSlug}'),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary,
                foregroundColor: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))),
            child: Text('View creator page', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ])),
      );
    }

    final jar = _jar!;
    final wide = MediaQuery.of(context).size.width > 860;

    return Scaffold(
      backgroundColor: kDark,
      body: Column(children: [
        _JarNav(jar: jar, creatorSlug: widget.creatorSlug),
        Expanded(
          child: wide
              ? _WideLayout(jar: jar, onTipSent: _load)
              : _NarrowLayout(jar: jar, onTipSent: _load),
        ),
      ]),
    );
  }
}

// ─── Nav bar ─────────────────────────────────────────────────────────────────
class _JarNav extends StatelessWidget {
  final JarModel jar;
  final String creatorSlug;
  const _JarNav({required this.jar, required this.creatorSlug});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        const SizedBox(width: 12),
        const Icon(Icons.chevron_right_rounded, color: kMuted, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: GestureDetector(
            onTap: () => context.go('/creator/$creatorSlug'),
            child: Text(creatorSlug,
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: kMuted, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(jar.name,
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
        const Spacer(),
        // Copy share link
        _ShareButton(jar: jar),
      ]),
    );
  }
}

class _ShareButton extends StatefulWidget {
  final JarModel jar;
  const _ShareButton({required this.jar});
  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _copied = false;

  void _copy() {
    final url = 'www.tippingjar.co.za${widget.jar.shareUrl}';
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _copy,
    child: AnimatedContainer(
      duration: 200.ms,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _copied ? kPrimary.withValues(alpha: 0.15) : kCardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: _copied ? kPrimary : kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_copied ? Icons.check_rounded : Icons.link_rounded,
            color: _copied ? kPrimary : kMuted, size: 14),
        const SizedBox(width: 6),
        Text(_copied ? 'Copied!' : 'Share link',
            style: GoogleFonts.dmSans(
                color: _copied ? kPrimary : kMuted,
                fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── Wide layout ─────────────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final JarModel jar;
  final VoidCallback onTipSent;
  const _WideLayout({required this.jar, required this.onTipSent});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left — jar info
      Expanded(
        flex: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: _JarInfo(jar: jar),
        ),
      ),
      Container(width: 1, color: kBorder),
      // Right — tip form
      Expanded(
        flex: 5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: _JarTipForm(jar: jar, onTipSent: onTipSent),
        ),
      ),
    ],
  );
}

// ─── Narrow layout ────────────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final JarModel jar;
  final VoidCallback onTipSent;
  const _NarrowLayout({required this.jar, required this.onTipSent});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _JarInfo(jar: jar),
      const SizedBox(height: 28),
      _JarTipForm(jar: jar, onTipSent: onTipSent),
    ]),
  );
}

// ─── Jar info panel ───────────────────────────────────────────────────────────
class _JarInfo extends StatelessWidget {
  final JarModel jar;
  const _JarInfo({required this.jar});

  @override
  Widget build(BuildContext context) {
    final progress = jar.progressPct != null ? jar.progressPct! / 100 : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Jar icon + name
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.savings_rounded, color: kPrimary, size: 28),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
      const SizedBox(height: 20),
      Text(jar.name,
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 28, letterSpacing: -0.8))
          .animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.1),
      if (jar.description.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(jar.description,
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.6))
            .animate().fadeIn(delay: 140.ms, duration: 400.ms),
      ],
      const SizedBox(height: 28),

      // Stats row
      Row(children: [
        _StatPill(label: 'Raised', value: 'R${jar.totalRaised.toStringAsFixed(0)}'),
        const SizedBox(width: 10),
        _StatPill(label: 'Tips', value: '${jar.tipCount}'),
        if (jar.goal != null) ...[
          const SizedBox(width: 10),
          _StatPill(label: 'Goal', value: 'R${jar.goal!.toStringAsFixed(0)}'),
        ],
      ]).animate().fadeIn(delay: 200.ms, duration: 400.ms),

      // Progress bar
      if (progress != null) ...[
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Progress', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          Text('${jar.progressPct!.toStringAsFixed(1)}%',
              style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: kBorder,
            valueColor: const AlwaysStoppedAnimation(kPrimary),
            minHeight: 10,
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
      ],

      const SizedBox(height: 24),
      // Back link
      GestureDetector(
        onTap: () => context.go('/creator/${jar.creatorSlug}'),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.arrow_back_rounded, color: kMuted, size: 14),
          const SizedBox(width: 6),
          Text('Back to creator page',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13,
                  decoration: TextDecoration.underline)),
        ]),
      ),
    ]);
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
      Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
    ]),
  );
}

// ─── Jar tip form ─────────────────────────────────────────────────────────────
class _JarTipForm extends StatefulWidget {
  final JarModel jar;
  final VoidCallback onTipSent;
  const _JarTipForm({required this.jar, required this.onTipSent});
  @override
  State<_JarTipForm> createState() => _JarTipFormState();
}

class _JarTipFormState extends State<_JarTipForm> {
  static const _presets = [5.0, 10.0, 20.0, 50.0, 100.0, 200.0];
  static const _platformFeePct = 3.0;
  static const _serviceFeePct  = 3.0;

  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _customCtrl  = TextEditingController();

  double _amount     = 20.0;
  double? _custom;
  bool _submitting   = false;
  bool _success      = false;
  bool _awaitingPayment = false;
  String? _paystackReference;
  bool _verifying    = false;
  String? _error;
  Timer? _pollTimer;

  double get _final => _custom ?? _amount;
  double get _platformFee => double.parse((_final * _platformFeePct / 100).toStringAsFixed(2));
  double get _serviceFee  => double.parse((_final * _serviceFeePct  / 100).toStringAsFixed(2));
  double get _creatorNet  => double.parse((_final - _platformFee - _serviceFee).toStringAsFixed(2));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    _customCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _successState();
    if (_awaitingPayment) return _awaitingState();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Drop a tip into this jar',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 22, letterSpacing: -0.5))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('Supporting: ${widget.jar.name}',
          style: GoogleFonts.dmSans(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600))
          .animate().fadeIn(delay: 80.ms, duration: 400.ms),
      const SizedBox(height: 24),

      // Amount presets
      Text('Choose amount', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _presets.map((v) {
          final active = _custom == null && _amount == v;
          return GestureDetector(
            onTap: () {
              _customCtrl.clear();
              setState(() { _amount = v; _custom = null; });
            },
            child: AnimatedContainer(
              duration: 150.ms,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: active ? kPrimary.withValues(alpha: 0.12) : kDark,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
              ),
              child: Text('R${v.toInt()}', style: GoogleFonts.dmSans(
                  color: active ? kPrimary : Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),

      // Custom amount
      TextField(
        controller: _customCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15),
        onChanged: (v) {
          final d = double.tryParse(v);
          setState(() => _custom = (d != null && d > 0) ? d : null);
        },
        decoration: InputDecoration(
          hintText: 'Or enter custom amount',
          hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
          prefixText: 'R  ',
          prefixStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
          filled: true, fillColor: kCardBg,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      const SizedBox(height: 20),

      // Fee breakdown pill
      if (_final >= 1) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.savings_rounded, color: kPrimary, size: 13),
              const SizedBox(width: 8),
              Expanded(child: Text('Sending to ${widget.jar.name}',
                  style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
              Text('R${_final.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            _jarFeeRow('Platform fee (${_platformFeePct.toInt()}%)', '- R${_platformFee.toStringAsFixed(2)}', kMuted),
            _jarFeeRow('Service fee (${_serviceFeePct.toInt()}%)',   '- R${_serviceFee.toStringAsFixed(2)}',  kMuted),
            const Divider(color: kBorder, height: 10),
            _jarFeeRow('Creator receives', 'R${_creatorNet.toStringAsFixed(2)}', Colors.white, bold: true),
          ]),
        ).animate().fadeIn(duration: 300.ms),
      ],
      const SizedBox(height: 20),

      // Name field
      _label('Your name (optional)'),
      const SizedBox(height: 8),
      TextField(
        controller: _nameCtrl,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: _inputDeco('Anonymous'),
      ),
      const SizedBox(height: 14),

      // Email field
      _label('Email (for payment receipt, optional)'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: _inputDeco('you@example.com'),
      ),
      const SizedBox(height: 16),

      // Message field
      _label('Leave a message (optional)'),
      const SizedBox(height: 8),
      TextField(
        controller: _messageCtrl,
        maxLines: 3,
        maxLength: 280,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: _inputDeco('Say something nice…').copyWith(counterStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
      ),
      const SizedBox(height: 4),

      // Error
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13)),
        const SizedBox(height: 8),
      ],

      // Submit
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _submitting || _final < 1 ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            disabledBackgroundColor: kPrimary.withValues(alpha: 0.4),
            elevation: 0, shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: _submitting
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  _final < 1 ? 'Enter an amount' : 'Tip R${_final.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _successState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.favorite_rounded, color: kPrimary, size: 64)
          .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),
      Text('Thank you! 🎉',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28))
          .animate().fadeIn(delay: 200.ms, duration: 400.ms),
      const SizedBox(height: 10),
      Text('Your tip was sent to the "${widget.jar.name}" jar.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.5),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 300.ms, duration: 400.ms),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: _reset,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary.withValues(alpha: 0.12), foregroundColor: kPrimary,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
        ),
        child: Text('Send another tip', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
      ).animate().fadeIn(delay: 400.ms),
    ],
  );

  Widget _awaitingState() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.10), shape: BoxShape.circle),
        child: const Icon(Icons.open_in_browser_rounded, color: kPrimary, size: 28),
      ).animate().scale(duration: 400.ms),
      const SizedBox(height: 16),
      Text('Complete your payment',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))
          .animate().fadeIn(delay: 100.ms),
      const SizedBox(height: 8),
      Text('Finish the payment in your browser and tap below to confirm.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5),
          textAlign: TextAlign.center)
          .animate().fadeIn(delay: 150.ms),
      const SizedBox(height: 16),
      // Fee summary
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kDark, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
        child: Column(children: [
          _jarFeeRow('Tip amount', 'R${_final.toStringAsFixed(2)}', Colors.white),
          _jarFeeRow('Platform fee (${_platformFeePct.toInt()}%)', '- R${_platformFee.toStringAsFixed(2)}', kMuted),
          _jarFeeRow('Service fee (${_serviceFeePct.toInt()}%)',   '- R${_serviceFee.toStringAsFixed(2)}',  kMuted),
          const Divider(color: kBorder, height: 10),
          _jarFeeRow('Creator receives', 'R${_creatorNet.toStringAsFixed(2)}', kPrimary, bold: true),
        ]),
      ).animate().fadeIn(delay: 200.ms),
      const SizedBox(height: 24),
      if (_verifying)
        const CircularProgressIndicator(color: kPrimary, strokeWidth: 2)
      else ...[
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _checkPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text("I've paid — confirm",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _cancelPayment,
          child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        ),
      ],
    ]),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
    filled: true, fillColor: kCardBg,
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _label(String t) => Text(t,
      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13));

  Future<void> _submit() async {
    setState(() { _submitting = true; _error = null; });
    try {
      final resp = await ApiService().initiateTip(
        creatorSlug: widget.jar.creatorSlug,
        amount: _final,
        tipperName: _nameCtrl.text.trim().isEmpty ? 'Anonymous' : _nameCtrl.text.trim(),
        tipperEmail: _emailCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
        jarId: widget.jar.id,
      );

      // Dev mode
      if (resp['dev_mode'] == true) {
        widget.onTipSent();
        setState(() { _success = true; _submitting = false; });
        return;
      }

      // Production: open Paystack
      final authUrl = resp['authorization_url'] as String?;
      final reference = resp['reference'] as String?;
      if (authUrl != null && authUrl.isNotEmpty) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        setState(() {
          _paystackReference = reference;
          _awaitingPayment = true;
          _submitting = false;
        });
        _startPolling(reference!);
      } else {
        widget.onTipSent();
        setState(() { _success = true; _submitting = false; });
      }
    } catch (e) {
      setState(() { _error = 'Something went wrong. Please try again.'; _submitting = false; });
    }
  }

  void _startPolling(String reference) {
    _pollTimer?.cancel();
    int polls = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
      polls++;
      if (polls > 36 || !mounted) { t.cancel(); return; }
      try {
        final result = await ApiService().verifyTip(reference);
        final s = result['status'] as String? ?? '';
        if (s == 'completed') {
          t.cancel();
          widget.onTipSent();
          if (mounted) setState(() { _success = true; _awaitingPayment = false; });
        } else if (s == 'failed') {
          t.cancel();
          if (mounted) setState(() {
            _awaitingPayment = false;
            _error = 'Payment failed. Please try again.';
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _checkPayment() async {
    if (_paystackReference == null) return;
    setState(() => _verifying = true);
    try {
      final result = await ApiService().verifyTip(_paystackReference!);
      final s = result['status'] as String? ?? '';
      if (s == 'completed') {
        _pollTimer?.cancel();
        widget.onTipSent();
        setState(() { _success = true; _awaitingPayment = false; _verifying = false; });
      } else if (s == 'failed') {
        _pollTimer?.cancel();
        setState(() { _awaitingPayment = false; _verifying = false;
            _error = 'Payment failed. Please try again.'; });
      } else {
        setState(() => _verifying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment not confirmed yet — finish it in your browser.',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
            backgroundColor: kCardBg, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    } catch (_) {
      setState(() => _verifying = false);
    }
  }

  void _cancelPayment() {
    _pollTimer?.cancel();
    setState(() { _awaitingPayment = false; _paystackReference = null; _submitting = false; });
  }

  void _reset() {
    _pollTimer?.cancel();
    _nameCtrl.clear(); _emailCtrl.clear(); _messageCtrl.clear(); _customCtrl.clear();
    setState(() {
      _success = false; _awaitingPayment = false;
      _paystackReference = null; _amount = 20.0; _custom = null; _error = null;
    });
  }

  Widget _jarFeeRow(String label, String value, Color color, {bool bold = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.dmSans(
            color: color, fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400))),
        Text(value, style: GoogleFonts.dmSans(
            color: color, fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      ]),
    );
}
