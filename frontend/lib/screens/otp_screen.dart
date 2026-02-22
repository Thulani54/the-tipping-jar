import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeCtrl = TextEditingController();
  String? _error;
  bool _verifying = false;
  bool _resending = false;
  bool _smsSwitching = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() { _verifying = true; _error = null; });
    try {
      await context.read<AuthProvider>().verifyOtp(code);
      // Router redirect handles navigation after otpVerified = true
    } catch (_) {
      setState(() => _error = 'Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() { _resending = true; _error = null; });
    try {
      await context.read<AuthProvider>().api.requestOtp();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Code resent to your email.',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          backgroundColor: kPrimary, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not resend code. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _switchToSms() async {
    if (_smsSwitching) return;
    setState(() { _smsSwitching = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().api;
      await api.switchOtpToSms();
      await api.requestOtp(method: 'sms');
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('SMS code sent to your phone.',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          backgroundColor: kPrimary, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not send SMS. Check your phone number.');
    } finally {
      if (mounted) setState(() => _smsSwitching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.user?.email ?? 'your email';
    final hasPhone = (auth.user?.phoneNumber ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: kDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const AppLogoIcon(size: 32),
                  const SizedBox(width: 8),
                  Text('TippingJar',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3)),
                ]),
                const SizedBox(height: 40),

                // Title
                Text('Check your email',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.8)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(color: kMuted, fontSize: 14, height: 1.5),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to '),
                      TextSpan(
                        text: email,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const TextSpan(text: '. Enter it below to continue.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Code input
                Text('Verification code',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8),
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onFieldSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '······',
                    hintStyle: GoogleFonts.inter(
                        color: kMuted, fontSize: 28, letterSpacing: 8,
                        fontWeight: FontWeight.w700),
                    filled: true,
                    fillColor: kCardBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kPrimary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),

                // Inline error
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: kPrimary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(36)),
                      elevation: 0,
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Verify',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),

                // Resend code
                Center(
                  child: _cooldown > 0
                      ? Text('Resend code in ${_cooldown}s',
                          style: GoogleFonts.inter(color: kMuted, fontSize: 13))
                      : TextButton(
                          onPressed: _resending ? null : _resend,
                          child: _resending
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      color: kMuted, strokeWidth: 2))
                              : Text('Resend code',
                                  style: GoogleFonts.inter(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                        ),
                ),

                // SMS option — only if user has a phone number
                if (hasPhone)
                  Center(
                    child: TextButton(
                      onPressed: _smsSwitching ? null : _switchToSms,
                      child: _smsSwitching
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: kMuted, strokeWidth: 2))
                          : Text('Send via SMS instead',
                              style: GoogleFonts.inter(
                                  color: kMuted,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                    ),
                  ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.read<AuthProvider>().logout(),
                    child: Text('Sign out',
                        style: GoogleFonts.inter(
                            color: kMuted, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
