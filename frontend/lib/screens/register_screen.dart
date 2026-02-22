import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  String _role = 'creator';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 860;
    return Scaffold(
      backgroundColor: kDark,
      body: wide ? _wideLayout(context) : _narrowLayout(context),
    );
  }

  Widget _wideLayout(BuildContext ctx) {
    return Row(children: [
      // Left — branding panel
      Expanded(
        child: Container(
          color: kDarker,
          padding: const EdgeInsets.all(56),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _logo(ctx),
            const Spacer(),
            Text('Start earning\nfrom day one.',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 52, height: 1.1, letterSpacing: -2))
                .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
            const SizedBox(height: 20),
            Text('Join 2,400+ creators already filling\ntheir jar every day.',
                style: GoogleFonts.inter(color: kMuted, fontSize: 16, height: 1.65))
                .animate().fadeIn(delay: 150.ms, duration: 500.ms),
            const SizedBox(height: 48),
            ..._perks().asMap().entries.map((e) =>
              _PerkCard(icon: e.value.$1, title: e.value.$2, body: e.value.$3, delay: 200 + e.key * 100)),
            const Spacer(),
            Text('© 2026 TippingJar',
                style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
          ]),
        ),
      ),
      // Right — form
      Expanded(
        child: Container(
          color: kDark,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _form(ctx),
          ),
        ),
      ),
    ]);
  }

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

  Widget _form(BuildContext ctx) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Create your account',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
      const SizedBox(height: 6),
      Row(children: [
        Text('Already have an account? ',
            style: GoogleFonts.inter(color: kMuted, fontSize: 14)),
        GestureDetector(
          onTap: () => ctx.go('/login'),
          child: Text('Sign in',
              style: GoogleFonts.inter(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ]).animate().fadeIn(delay: 80.ms, duration: 400.ms),
      const SizedBox(height: 28),

      // Role toggle
      Text('I want to…', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 10),
      Row(children: [
        _roleBtn(Icons.volunteer_activism, 'Tip creators', 'fan'),
        const SizedBox(width: 10),
        _roleBtn(Icons.star_rounded, 'Receive tips', 'creator'),
        const SizedBox(width: 10),
        _roleBtn(Icons.business_rounded, 'Manage creators', 'enterprise'),
      ]).animate().fadeIn(delay: 100.ms, duration: 400.ms),
      const SizedBox(height: 24),

      Form(
        key: _formKey,
        child: Column(children: [
          _field(
            ctrl: _usernameCtrl,
            label: 'Username',
            hint: 'yourname',
            icon: Icons.alternate_email_rounded,
            validator: (v) => (v?.length ?? 0) >= 3 ? null : 'Min 3 characters',
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          _field(
            ctrl: _phoneCtrl,
            label: 'Phone number (optional)',
            hint: '+27 82 123 4567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
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
                Expanded(child: Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 22),
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
                    : Text('Create account',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'By signing up you agree to our Terms of Service and Privacy Policy.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 11, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    ]);
  }

  Widget _roleBtn(IconData icon, String label, String value) {
    final active = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: active ? kPrimary.withOpacity(0.12) : kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? kPrimary : kBorder, width: active ? 2 : 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: active ? kPrimary : kMuted, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: active ? kPrimary : kMuted,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      ),
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

  List<(IconData, String, String)> _perks() => [
    (Icons.flash_on_rounded,       'Live in 60 seconds', 'Your tip page is public the moment you save.'),
    (Icons.account_balance_rounded, '2-day payouts',     'Stripe sends funds direct to your bank.'),
    (Icons.bar_chart_rounded,      'Real-time analytics','Watch tips roll in on your dashboard.'),
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final auth = context.read<AuthProvider>();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      await auth.register(
          username: _usernameCtrl.text.trim(),
          email: email,
          password: password,
          role: _role,
          phoneNumber: _phoneCtrl.text.trim());
      // Auto-login so the user lands on their home page without a second sign-in step
      await auth.login(email, password);
      if (!mounted) return;
      if (_role == 'creator') {
        context.go('/onboarding');
      } else if (_role == 'enterprise') {
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
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}

class _PerkCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final int delay;
  const _PerkCard({required this.icon, required this.title, required this.body, required this.delay});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: kPrimary, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(body,  style: GoogleFonts.inter(color: kMuted, fontSize: 13, height: 1.5)),
        ])),
      ]),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut);
  }
}
