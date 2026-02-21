import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

/// Landing page after Paystack redirects back from checkout.
/// Verifies the payment and shows success or failure.
class PaymentCallbackScreen extends StatefulWidget {
  final String reference;
  const PaymentCallbackScreen({super.key, required this.reference});

  @override
  State<PaymentCallbackScreen> createState() => _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends State<PaymentCallbackScreen> {
  bool _loading = true;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      final result = await ApiService().verifyTip(widget.reference);
      final status = result['status'] as String? ?? '';
      if (mounted) {
        setState(() {
          _success = status == 'completed';
          _loading = false;
          if (!_success) _error = 'Payment could not be confirmed. Status: $status';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Could not verify payment.'; });
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
                  Text('TippingJar', style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
              ),
              const SizedBox(height: 48),
              if (_loading) ...[
                const CircularProgressIndicator(color: kPrimary, strokeWidth: 2),
                const SizedBox(height: 20),
                Text('Confirming your payment…',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 15)),
              ] else if (_success) ...[
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: kPrimary, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Payment received!',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text('Your tip has been sent. The creator will love it!',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 15, height: 1.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    elevation: 0, minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                  child: Text('Back to TippingJar',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ] else ...[
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
                const SizedBox(height: 20),
                Text('Something went wrong',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(_error ?? 'Payment could not be verified.',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCardBg, foregroundColor: Colors.white,
                    elevation: 0, minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                  ),
                  child: Text('Go home',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
