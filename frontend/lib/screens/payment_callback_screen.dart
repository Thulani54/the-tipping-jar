import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

/// Landing page after Paystack redirects back from checkout.
/// Verifies the payment and shows success, failure, or pending state.
class PaymentCallbackScreen extends StatefulWidget {
  final String reference;
  const PaymentCallbackScreen({super.key, required this.reference});

  @override
  State<PaymentCallbackScreen> createState() => _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends State<PaymentCallbackScreen> {
  bool _loading = true;
  // 'completed' | 'failed' | 'pending' | 'error'
  String _state = 'pending';
  String? _creatorSlug;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  /// Calls the verify endpoint up to 4 times (2-second gaps) to handle the
  /// brief window where Paystack's processing may lag behind the redirect.
  Future<void> _verify({int attempt = 1}) async {
    try {
      final result = await ApiService().verifyTip(widget.reference);
      final status = result['status'] as String? ?? '';
      final slug   = result['creator_slug'] as String?;

      if (status == 'completed') {
        if (mounted) setState(() { _loading = false; _state = 'completed'; _creatorSlug = slug; });
        return;
      }

      if (status == 'failed') {
        if (mounted) setState(() { _loading = false; _state = 'failed'; _creatorSlug = slug; });
        return;
      }

      // Still pending — retry a few times before giving up
      if (attempt < 4) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) await _verify(attempt: attempt + 1);
      } else {
        if (mounted) setState(() { _loading = false; _state = 'pending'; _creatorSlug = slug; });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _state = 'error'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const AppLogoIcon(size: 32),
                  const SizedBox(width: 10),
                  Text('TippingJar', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
              ),
              const SizedBox(height: 48),
              if (_loading) ...[
                const CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
                const SizedBox(height: 20),
                Text('Confirming your payment…',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 15)),
              ] else if (_state == 'completed') ...[
                _iconCircle(Icons.favorite_rounded, kPrimary),
                const SizedBox(height: 24),
                Text('Payment received!',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text('Your tip has been sent. The creator will love it!',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                _btn('Back to TippingJar', kPrimary, () => context.go('/')),
              ] else if (_state == 'failed') ...[
                _iconCircle(Icons.credit_card_off_rounded, Colors.redAccent),
                const SizedBox(height: 24),
                Text('Payment was not completed',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  'Your card was not charged. This can happen if the payment window was closed, '
                  'the card was declined, or the session timed out.',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_creatorSlug != null)
                  _btn('Try again', kPrimary,
                      () => context.go('/creator/$_creatorSlug')),
                const SizedBox(height: 10),
                _btn('Go home', kCardBg, () => context.go('/')),
              ] else if (_state == 'pending') ...[
                _iconCircle(Icons.hourglass_top_rounded, Colors.amber),
                const SizedBox(height: 24),
                Text('Payment still processing',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  'Your payment is taking a bit longer than usual. '
                  'If your card was charged, the tip will be confirmed shortly.',
                  style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _btn('Check again', kPrimary, () {
                  setState(() => _loading = true);
                  _verify();
                }),
                const SizedBox(height: 10),
                _btn('Go home', kCardBg, () => context.go('/')),
              ] else ...[
                _iconCircle(Icons.wifi_off_rounded, kMuted),
                const SizedBox(height: 24),
                Text('Could not reach the server',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text('Check your connection and try again.',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                _btn('Retry', kPrimary, () {
                  setState(() => _loading = true);
                  _verify();
                }),
                const SizedBox(height: 10),
                _btn('Go home', kCardBg, () => context.go('/')),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon, Color color) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 32),
  );

  Widget _btn(String label, Color bg, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
  );
}
