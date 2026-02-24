import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _role = 'creator';
  String? _error;
  String _gender = '';
  DateTime? _dateOfBirth;
  bool _acceptTerms = false;

  // OTP verification step (shown after successful registration)
  bool _showOtp = false;
  bool _otpLoading = false;
  String? _otpError;
  String _otpMethod = 'email';
  final _otpCtrl = TextEditingController();

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
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            Padding(
              padding: const EdgeInsets.all(56),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _logo(ctx),
                const Spacer(),
                Text(_panelHeading(),
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w800,
                        fontSize: 52, height: 1.1, letterSpacing: -2))
                    .animate(key: ValueKey('heading-$_role')).fadeIn(duration: 400.ms).slideY(begin: 0.15),
                const SizedBox(height: 20),
                Text(_panelSubheading(),
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 16, height: 1.65))
                    .animate(key: ValueKey('sub-$_role')).fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 48),
                ..._perks().asMap().entries.map((e) =>
                  _PerkCard(icon: e.value.$1, title: e.value.$2, body: e.value.$3, delay: 200 + e.key * 100)),
                const Spacer(),
                Text('© 2026 TippingJar',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
              ]),
            ),
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
            child: SingleChildScrollView(child: _form(ctx)),
          ),
        ),
      ),
    ]);
  }

  Widget _narrowLayout(BuildContext ctx) {
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(children: [
          _logo(ctx),
          const SizedBox(height: 40),
          _form(ctx),
        ]),
      ),
    ]);
  }

  Widget _logo(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.go('/'),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const AppLogoIcon(size: 36),
        const SizedBox(width: 10),
        Text('TippingJar',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3)),
      ]),
    );
  }

  Widget _form(BuildContext ctx) {
    if (_showOtp) return _otpStep(ctx);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Create your account',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
      const SizedBox(height: 6),
      Row(children: [
        Text('Already have an account? ',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14)),
        GestureDetector(
          onTap: () => ctx.go('/login'),
          child: Text('Sign in',
              style: GoogleFonts.dmSans(color: kPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ]).animate().fadeIn(delay: 80.ms, duration: 400.ms),
      const SizedBox(height: 28),

      // ── Role toggle ──────────────────────────────────────────────
      Text('I am a…', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 10),
      Row(children: [
        _roleBtn(Icons.volunteer_activism, 'Tipper', 'fan'),
        const SizedBox(width: 10),
        _roleBtn(Icons.star_rounded, 'Creator', 'creator'),
        const SizedBox(width: 10),
        _roleBtn(Icons.business_rounded, 'Enterprise', 'enterprise'),
      ]).animate().fadeIn(delay: 100.ms, duration: 400.ms),

      const SizedBox(height: 24),

      Form(
        key: _formKey,
        child: Column(children: [
          // First + last name side by side
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _field(
              ctrl: _firstNameCtrl,
              label: 'First name',
              hint: 'Jane',
              icon: Icons.badge_outlined,
              validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Required',
            )),
            const SizedBox(width: 12),
            Expanded(child: _field(
              ctrl: _lastNameCtrl,
              label: 'Last name',
              hint: 'Doe',
              icon: Icons.badge_outlined,
              validator: (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Required',
            )),
          ]),
          const SizedBox(height: 14),
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
            ctrl: _confirmPasswordCtrl,
            label: 'Confirm password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: kMuted, size: 18),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) => v == _passwordCtrl.text ? null : 'Passwords do not match',
          ),
          const SizedBox(height: 14),
          _field(
            ctrl: _phoneCtrl,
            label: 'Phone number (optional)',
            hint: '+27 82 123 4567',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _genderSelector(),
          const SizedBox(height: 14),
          _dobPicker(),
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
                Expanded(child: Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          // Terms & conditions
          GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AnimatedContainer(
                duration: 150.ms,
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _acceptTerms ? kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _acceptTerms ? kPrimary : kMuted, width: 1.5),
                ),
                child: _acceptTerms
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'I agree to the ',
                        style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.5)),
                    TextSpan(text: 'Terms of Service',
                        style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    TextSpan(text: ' and ',
                        style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                    TextSpan(text: 'Privacy Policy',
                        style: GoogleFonts.dmSans(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
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
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── OTP verification step ──────────────────────────────────────────────────
  Widget _otpStep(BuildContext ctx) {
    final hasPhone = _phoneCtrl.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: kPrimary, size: 30),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
      const SizedBox(height: 24),
      Text('Check your ${_otpMethod == 'sms' ? 'phone' : 'email'}',
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.w800,
              fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(delay: 80.ms),
      const SizedBox(height: 6),
      Text(
        _otpMethod == 'sms'
            ? 'We sent a 6-digit code to your phone number.'
            : 'We sent a 6-digit code to ${_emailCtrl.text.trim()}.',
        style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.5),
      ).animate().fadeIn(delay: 120.ms),
      const SizedBox(height: 32),

      // Code input
      Text('Verification code',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '------',
          hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 22, letterSpacing: 8),
          counterText: '',
          filled: true,
          fillColor: kCardBg,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        onChanged: (v) {
          if (v.length == 6) _submitOtp();
        },
      ),

      if (_otpError != null) ...[
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
            Expanded(child: Text(_otpError!,
                style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13))),
          ]),
        ),
      ],

      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _otpLoading ? null : _submitOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kPrimary.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            elevation: 0,
          ),
          child: _otpLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Verify →',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 16),

      // Resend options
      Wrap(spacing: 16, runSpacing: 8, alignment: WrapAlignment.center, children: [
        GestureDetector(
          onTap: _otpLoading ? null : () => _resendOtp('email'),
          child: Text('Resend via email',
              style: GoogleFonts.dmSans(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        if (hasPhone)
          GestureDetector(
            onTap: _otpLoading ? null : () => _resendOtp('sms'),
            child: Text('Resend via SMS',
                style: GoogleFonts.dmSans(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ]),
      const SizedBox(height: 20),
      Center(
        child: GestureDetector(
          onTap: _otpLoading ? null : _skipVerification,
          child: Text('Skip for now →',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
        ),
      ),
    ]);
  }

  Future<void> _resendOtp(String method) async {
    setState(() { _otpLoading = true; _otpError = null; _otpMethod = method; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.api.sendRegistrationOtp(method: method);
    } catch (e) {
      setState(() => _otpError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _otpLoading = false);
    }
  }

  Future<void> _submitOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 6) return;
    setState(() { _otpLoading = true; _otpError = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.api.confirmRegistrationOtp(code);
      await _finishRegistration(auth);
    } catch (e) {
      setState(() => _otpError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _otpLoading = false);
    }
  }

  Future<void> _skipVerification() async {
    final auth = context.read<AuthProvider>();
    await _finishRegistration(auth);
  }

  Future<void> _finishRegistration(dynamic auth) async {
    // Save gender and DOB if provided
    final profileData = <String, dynamic>{};
    if (_gender.isNotEmpty) profileData['gender'] = _gender;
    if (_dateOfBirth != null) {
      profileData['date_of_birth'] = DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    }
    if (profileData.isNotEmpty) {
      try { await auth.api.updateUserProfile(profileData); } catch (_) {}
    }
    if (!mounted) return;
    if (_role == 'creator') {
      context.go('/onboarding');
    } else if (_role == 'enterprise') {
      context.go('/enterprise-portal');
    } else {
      context.go('/fan-dashboard');
    }
  }

  // ── Gender selector ──────────────────────────────────────────────────────────
  Widget _genderSelector() {
    const options = [
      ('', 'Prefer not to say'),
      ('male', 'Male'),
      ('female', 'Female'),
      ('non_binary', 'Non-binary'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Gender (optional)',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: _gender,
        dropdownColor: kCardBg,
        isExpanded: true,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person_outline_rounded, color: kMuted, size: 18),
          filled: true, fillColor: kCardBg,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: options.map((o) => DropdownMenuItem(
          value: o.$1,
          child: Text(o.$2, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
        )).toList(),
        onChanged: (v) => setState(() => _gender = v ?? ''),
      ),
    ]);
  }

  // ── Date of birth picker ──────────────────────────────────────────────────────
  Widget _dobPicker() {
    final label = _dateOfBirth != null
        ? DateFormat('d MMMM yyyy').format(_dateOfBirth!)
        : 'Select date of birth';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Date of birth (optional, must be 16+)',
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickDob,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Row(children: [
            const Icon(Icons.cake_outlined, color: kMuted, size: 18),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.dmSans(
                color: _dateOfBirth != null ? Colors.white : kMuted, fontSize: 14)),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 16, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? maxDate,
      firstDate: DateTime(1920),
      lastDate: maxDate,
      helpText: 'Select date of birth (16+ only)',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kPrimary, onPrimary: Colors.white,
            surface: kCardBg, onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
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
                style: GoogleFonts.dmSans(
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
      Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
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

  String _panelHeading() {
    switch (_role) {
      case 'fan':        return 'Support creators\nyou love.';
      case 'enterprise': return 'Scale tipping\nfor your platform.';
      default:           return 'Start earning\nfrom day one.';
    }
  }

  String _panelSubheading() {
    switch (_role) {
      case 'fan':        return 'Tip your favourite creators instantly\n— no account needed.';
      case 'enterprise': return 'White-label tipping for teams,\nagencies and platforms.';
      default:           return 'Join 2,400+ creators already filling\ntheir jar every day.';
    }
  }

  List<(IconData, String, String)> _perks() {
    switch (_role) {
      case 'fan':
        return [
          (Icons.bolt_rounded,      'Instant tips',      'Support your favourite creators in seconds.'),
          (Icons.attach_money_rounded, 'Any amount',     'Tip R5 or R5 000 — totally up to you.'),
          (Icons.favorite_rounded,  'Support directly',  'Every cent goes straight to the creator.'),
        ];
      case 'enterprise':
        return [
          (Icons.layers_rounded,        'White-label ready',  'Embed tipping directly into your product.'),
          (Icons.support_agent_rounded, 'Dedicated support',  'Priority onboarding and a dedicated manager.'),
          (Icons.handshake_rounded,     'Custom contracts',   'Revenue share and SLA terms available.'),
        ];
      default: // creator
        return [
          (Icons.flash_on_rounded,        'Live in 60 seconds',  'Your tip page is public the moment you save.'),
          (Icons.account_balance_rounded, '2-day payouts',       'Receive money directly to your bank within 2 days.'),
          (Icons.bar_chart_rounded,       'Real-time analytics', 'Watch tips roll in on your dashboard.'),
        ];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _error = 'Please accept the Terms of Service and Privacy Policy to continue.');
      return;
    }
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
          phoneNumber: _phoneCtrl.text.trim(),
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim());
      // Auto-login to get auth token
      await auth.login(email, password);
      if (!mounted) return;

      // Send verification OTP then show OTP step
      try {
        await auth.api.sendRegistrationOtp(method: 'email');
      } catch (_) {
        // If email delivery fails, still show the OTP screen so they can retry
      }
      setState(() { _showOtp = true; _otpMethod = 'email'; });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }
}

// ─── Dot grid background ─────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    const spacing = 30.0;
    const radius = 1.0;
    for (double x = 0; x <= size.width + spacing; x += spacing) {
      for (double y = 0; y <= size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(body,  style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
        ])),
      ]),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOut);
  }
}
