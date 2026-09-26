// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';

class ReferralTab extends StatefulWidget {
  const ReferralTab({super.key});
  @override
  State<ReferralTab> createState() => _ReferralTabState();
}

class _ReferralTabState extends State<ReferralTab> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  // Bank details form
  int? _bankFormReferralId;
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  bool _bankSubmitting = false;
  String? _bankError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.getMyReferrals();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _submitBankDetails(int referralId) async {
    setState(() { _bankSubmitting = true; _bankError = null; });
    try {
      final api = context.read<AuthProvider>().api;
      await api.submitReferralBankDetails(
        referralId: referralId,
        bankName: _bankNameCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
      );
      setState(() { _bankFormReferralId = null; });
      await _load();
    } catch (e) {
      setState(() => _bankError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _bankSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 14)),
        const SizedBox(height: 16),
        TextButton(onPressed: _load, child: const Text('Retry', style: TextStyle(color: kPrimary))),
      ]));
    }

    final code = (_data!['code'] as Map<String, dynamic>)['code'] as String? ?? '';
    final rate = ((_data!['code'] as Map<String, dynamic>)['commission_rate'] as num?)?.toDouble() ?? 0.01;
    final total = _data!['total_referrals'] as int? ?? 0;
    final active = _data!['active_referrals'] as int? ?? 0;
    final referrals = (_data!['referrals'] as List<dynamic>?) ?? [];
    final shareUrl = 'https://tippingjar.co.za/register?ref=$code';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ───────────────────────────────────────────────────────────
        Text('Referrals',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800,
                fontSize: 26, letterSpacing: -0.8))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text('Earn ${(rate * 100).toStringAsFixed(1)}% of tips from every creator you refer — for 6 months.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5))
            .animate().fadeIn(delay: 80.ms),

        const SizedBox(height: 28),

        // ── Your referral code card ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004423), Color(0xFF006B3A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.card_giftcard_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text('Your referral code',
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Text(code,
                  style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700, letterSpacing: 6)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Copy', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(shareUrl,
                style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _ShareBtn(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: shareUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              _ShareBtn(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                onTap: () => html.window.open(
                  'https://wa.me/?text=${Uri.encodeComponent("Hey! Sign up on TippingJar using my referral code $code and start earning today: $shareUrl")}',
                  '_blank',
                ),
              ),
              _ShareBtn(
                icon: Icons.alternate_email_rounded,
                label: 'Twitter / X',
                onTap: () => html.window.open(
                  'https://twitter.com/intent/tweet?text=${Uri.encodeComponent("Im earning on @TippingJar — join using my code $code and we both win! $shareUrl")}',
                  '_blank',
                ),
              ),
            ]),
          ]),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

        const SizedBox(height: 24),

        // ── Stats row ─────────────────────────────────────────────────────────
        Row(children: [
          _StatCard(Icons.group_rounded, '$total', 'Total referrals'),
          const SizedBox(width: 16),
          _StatCard(Iconsax.activity, '$active', 'Active (earning)'),
          const SizedBox(width: 16),
          _StatCard(Icons.calendar_month_rounded, '6 mo', 'Commission window'),
        ]).animate().fadeIn(delay: 160.ms),

        const SizedBox(height: 28),

        // ── Referrals list ────────────────────────────────────────────────────
        Text('Your referrals',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),

        if (referrals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kCardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(children: [
              const Icon(Icons.group_add_outlined, color: kMuted, size: 36),
              const SizedBox(height: 12),
              Text('No referrals yet',
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Share your code above to start earning commission.',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
            ]),
          )
        else
          ...referrals.asMap().entries.map((e) {
            final r = e.value as Map<String, dynamic>;
            final rid = r['id'] as int;
            final name = r['referred_user_name'] as String? ?? '';
            final email = r['referred_user_email'] as String? ?? '';
            final rStatus = r['status'] as String? ?? 'pending';
            final days = r['days_remaining'] as int? ?? 0;
            final rate2 = (r['commission_rate'] as num?)?.toDouble() ?? 0.01;
            final bankSubmitted = r['bank_details_submitted_at'] != null;
            final showForm = _bankFormReferralId == rid;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: kCardBg, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kPrimary.withOpacity(0.12),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(email, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      _StatusBadge(rStatus),
                      const SizedBox(height: 4),
                      Text('${(rate2 * 100).toStringAsFixed(1)}% • $days days left',
                          style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
                    ]),
                  ]),
                ),
                // Bank details prompt
                if (!bankSubmitted && rStatus != 'expired') ...[
                  Divider(height: 1, color: kBorder),
                  if (!showForm)
                    InkWell(
                      onTap: () => setState(() { _bankFormReferralId = rid; _bankError = null; }),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          const Icon(Icons.account_balance_rounded, color: kPrimary, size: 14),
                          const SizedBox(width: 8),
                          Text('Submit bank details to receive commission →',
                              style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _bankDetailsForm(rid),
                    ),
                ],
              ]),
            ).animate().fadeIn(delay: (200 + e.key * 60).ms);
          }),

        const SizedBox(height: 32),

        // ── How it works ─────────────────────────────────────────────────────
        Text('How it works',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...[
          (Icons.share_rounded, 'Share your code',
              'Send your referral link to creators you know. They enter your code at signup.'),
          (Icons.check_circle_outline_rounded, 'They sign up',
              'When a creator registers with your code, a 6-month commission window starts.'),
          (Icons.account_balance_rounded, 'Submit your bank details',
              'You\'ll get an email — submit your bank account so we can pay your commission.'),
          (Icons.payments_rounded, 'Earn ${(rate * 100).toStringAsFixed(1)}% of their tips',
              'For every tip they receive in 6 months, you earn ${(rate * 100).toStringAsFixed(1)}%, paid directly to your account.'),
        ].asMap().entries.map((e) => _HowStep(e.key + 1, e.value.$1, e.value.$2, e.value.$3)),
      ]),
    );
  }

  Widget _bankDetailsForm(int referralId) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bank account details',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 12),
      _BankField('Bank name', _bankNameCtrl, hint: 'e.g. FNB, Capitec, Standard Bank'),
      const SizedBox(height: 10),
      _BankField('Account holder name', _accountNameCtrl, hint: 'As it appears on your account'),
      const SizedBox(height: 10),
      _BankField('Account number', _accountNumberCtrl,
          hint: '000 000 0000', keyboard: TextInputType.number),
      if (_bankError != null) ...[
        const SizedBox(height: 8),
        Text(_bankError!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
      ],
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _bankSubmitting ? null : () => setState(() { _bankFormReferralId = null; _bankError = null; }),
            style: OutlinedButton.styleFrom(
              foregroundColor: kMuted,
              side: BorderSide(color: kBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _bankSubmitting ? null : () => _submitBankDetails(referralId),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kPrimary.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _bankSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save details', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ]),
    ]);
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _BankField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  const _BankField(this.label, this.ctrl, {required this.hint, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
        filled: true, fillColor: kDark,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary)),
      ),
    ),
  ]);
}

class _ShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ShareBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: kPrimary, size: 18),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11, height: 1.4)),
      ]),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'active':   bg = kPrimary.withOpacity(0.15); fg = kPrimary; label = 'Active'; break;
      case 'expired':  bg = Colors.grey.withOpacity(0.15); fg = Colors.grey; label = 'Expired'; break;
      default:         bg = Colors.orange.withOpacity(0.15); fg = Colors.orange; label = 'Pending'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.dmSans(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _HowStep extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String body;
  const _HowStep(this.step, this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kPrimary, size: 17),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(body, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
      ])),
    ]),
  ).animate().fadeIn(delay: (step * 80).ms);
}
