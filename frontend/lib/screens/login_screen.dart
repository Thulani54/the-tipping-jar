import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 860;

    return Scaffold(
      backgroundColor: kDark,
      body: wide ? _wideLayout(context) : _narrowLayout(context),
    );
  }

  // ─── Wide: side-by-side ──────────────────────────────────────────────────
  Widget _wideLayout(BuildContext ctx) {
    return Row(children: [
      // Left panel — branding
      Expanded(
        child: Container(
          color: kDarker,
          padding: const EdgeInsets.all(56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _logo(ctx),
              const Spacer(),
              Text('Welcome\nback.',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w800,
                      fontSize: 52, height: 1.1, letterSpacing: -2))
                  .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
              const SizedBox(height: 20),
              Text('Sign in to manage your tip page,\ntrack earnings, and connect with fans.',
                  style: GoogleFonts.inter(color: kMuted, fontSize: 16, height: 1.65))
                  .animate().fadeIn(delay: 150.ms, duration: 500.ms),
              const SizedBox(height: 48),
              ..._benefits()
                  .asMap()
                  .entries
                  .map((e) => _BenefitRow(text: e.value, delay: 200 + e.key * 80)),
              const Spacer(),
              Text('© 2026 TippingJar',
                  style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
      // Right panel — form
      Expanded(
        child: Container(
          color: kDark,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _form(ctx),
          ),
        ),
      ),
    ]);
  }

  // ─── Narrow: stacked ────────────────────────────────────────────────────
  Widget _narrowLayout(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(children: [
        _logo(ctx),
        const SizedBox(height: 40),
        _form(ctx),
      ]),
    );
  }

  // ─── Logo row ────────────────────────────────────────────────────────────
  Widget _logo(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.go('/'),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const AppLogoIcon(size: 36),
        const SizedBox(width: 10),
        Text('TippingJar',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3)),
      ]),
    );
  }

  // ─── Form card ───────────────────────────────────────────────────────────
  Widget _form(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in to your account',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8))
            .animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
        const SizedBox(height: 6),
        Row(children: [
          Text("Don't have an account? ",
              style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
          GestureDetector(
            onTap: () => ctx.go('/register'),
            child: Text('Sign up',
                style: GoogleFonts.inter(
                    color: kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ]).animate().fadeIn(delay: 80.ms, duration: 400.ms),
        const SizedBox(height: 36),
        Form(
          key: _formKey,
          child: Column(children: [
            _field(
              ctrl: _emailCtrl,
              label: 'Email address',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v?.contains('@') ?? false) ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 16),
            _field(
              ctrl: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: kMuted, size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => (v?.length ?? 0) >= 8 ? null : 'Min 8 characters',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Forgot password?',
                  style: GoogleFonts.inter(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
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
                  Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            Consumer<AuthProvider>(builder: (_, auth, __) =>
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kPrimary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                    elevation: 0,
                  ),
                  child: auth.loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Sign in', style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Divider(color: kBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or continue with',
                    style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
              ),
              Expanded(child: Divider(color: kBorder)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _socialBtn('Google', Icons.g_mobiledata_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _socialBtn('GitHub', Icons.code_rounded)),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: kMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: kMuted, size: 18),
          suffixIcon: suffix,
          filled: true,
          fillColor: kCardBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Widget _socialBtn(String label, IconData icon) => OutlinedButton.icon(
    onPressed: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label sign-in coming soon!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: kCardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    },
    icon: Icon(icon, size: 18, color: Colors.white),
    label: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 13),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
    ),
  );

  List<String> _benefits() => [
    'Real-time tip notifications',
    'Stripe payouts in 2 days',
    'Live fan activity dashboard',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (auth.isCreator) {
        context.go('/dashboard');
      } else if (auth.isEnterprise) {
        context.go('/enterprise-portal');
      } else {
        context.go('/fan-dashboard');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;
  final int delay;
  const _BenefitRow({required this.text, required this.delay});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.check, color: kPrimary, size: 13),
        ),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut);
  }
}
