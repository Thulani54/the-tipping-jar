import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class PartnerApplyScreen extends StatefulWidget {
  const PartnerApplyScreen({super.key});
  @override
  State<PartnerApplyScreen> createState() => _PartnerApplyScreenState();
}

class _PartnerApplyScreenState extends State<PartnerApplyScreen> {
  int _step = 0; // 0=Company, 1=Contact, 2=Documents, 3=Success

  // Step 1 — Company
  final _companyFormKey = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _websiteCtrl     = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _useCtrl         = TextEditingController();
  final _legalNameCtrl   = TextEditingController();
  final _regNumCtrl      = TextEditingController();
  final _vatCtrl         = TextEditingController();

  // Step 2 — Contact
  final _contactFormKey  = GlobalKey<FormState>();
  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl= TextEditingController();
  final _contactPhoneCtrl= TextEditingController();

  // Step 3 — Documents
  final Map<String, (Uint8List, String)?> _docs = {
    'cipc': null,
    'vat':  null,
    'id':   null,
    'bank': null,
  };
  final Map<String, String> _docLabels = {
    'cipc': 'Company Registration (CIPC)',
    'vat':  'VAT Certificate',
    'id':   'Director ID / Passport',
    'bank': 'Bank Confirmation Letter',
  };
  final Map<String, bool> _uploading = {};

  bool _submitting = false;
  String? _error;
  int? _platformId;

  @override
  void dispose() {
    _nameCtrl.dispose(); _websiteCtrl.dispose(); _descCtrl.dispose();
    _useCtrl.dispose(); _legalNameCtrl.dispose(); _regNumCtrl.dispose();
    _vatCtrl.dispose(); _contactNameCtrl.dispose(); _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _nextFromStep0() async {
    if (!_companyFormKey.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _nextFromStep1() async {
    if (!_contactFormKey.currentState!.validate()) return;
    // Submit application now
    setState(() { _submitting = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().api;
      final result = await api.applyForPlatform({
        'name': _nameCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'intended_use': _useCtrl.text.trim(),
        'company_name_legal': _legalNameCtrl.text.trim(),
        'company_registration_number': _regNumCtrl.text.trim(),
        'vat_number': _vatCtrl.text.trim(),
        'contact_name': _contactNameCtrl.text.trim(),
        'contact_email': _contactEmailCtrl.text.trim(),
        'contact_phone': _contactPhoneCtrl.text.trim(),
      });
      _platformId = result['id'] as int?;
      if (mounted) setState(() { _submitting = false; _step = 2; });
    } catch (e) {
      if (mounted) setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickDoc(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() => _docs[docType] = (file.bytes!, file.name));
  }

  Future<void> _uploadDocs() async {
    if (_platformId == null) {
      setState(() => _step = 3);
      return;
    }
    final api = context.read<AuthProvider>().api;
    for (final entry in _docs.entries) {
      if (entry.value == null) continue;
      setState(() => _uploading[entry.key] = true);
      try {
        await api.uploadPlatformDocument(
          _platformId!,
          entry.key,
          entry.value!.$1,
          entry.value!.$2,
        );
      } catch (_) {
        // Continue uploading remaining docs even if one fails
      }
      if (mounted) setState(() => _uploading[entry.key] = false);
    }
    if (mounted) setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/partner-apply'),
      body: _step == 3 ? _successView() : SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w > 640 ? 48 : 24, vertical: 48),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _StepIndicator(current: _step, total: 3),
                const SizedBox(height: 40),
                _stepContent(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent() {
    return switch (_step) {
      0 => _step0Company(),
      1 => _step1Contact(),
      2 => _step2Documents(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Step 0 — Company ───────────────────────────────────────────────────────
  Widget _step0Company() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Company details', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5))
          .animate().fadeIn(duration: 300.ms),
      const SizedBox(height: 8),
      Text('Tell us about your business and how you plan to use the Platform API.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.6))
          .animate().fadeIn(delay: 80.ms),
      const SizedBox(height: 32),
      Form(
        key: _companyFormKey,
        child: Column(children: [
          _Field(_nameCtrl, 'Platform / app name *', required: true),
          const SizedBox(height: 14),
          _Field(_websiteCtrl, 'Website URL'),
          const SizedBox(height: 14),
          _Field(_descCtrl, 'What does your platform do? *', required: true, maxLines: 3),
          const SizedBox(height: 14),
          _Field(_useCtrl, 'How will you use TippingJar? *', required: true, maxLines: 3),
          const SizedBox(height: 24),
          _SectionLabel2('Company info'),
          const SizedBox(height: 12),
          _Field(_legalNameCtrl, 'Legal company name'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Field(_regNumCtrl, 'Registration number (CIPC)')),
            const SizedBox(width: 12),
            Expanded(child: _Field(_vatCtrl, 'VAT number (optional)')),
          ]),
          const SizedBox(height: 32),
          _PrimaryBtn(
            label: 'Continue',
            onTap: _nextFromStep0,
          ),
        ]),
      ),
    ]);
  }

  // ── Step 1 — Contact ───────────────────────────────────────────────────────
  Widget _step1Contact() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Primary contact', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5))
          .animate().fadeIn(duration: 300.ms),
      const SizedBox(height: 8),
      Text('Who should we contact regarding your application?',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.6))
          .animate().fadeIn(delay: 80.ms),
      const SizedBox(height: 32),
      Form(
        key: _contactFormKey,
        child: Column(children: [
          _Field(_contactNameCtrl, 'Full name *', required: true),
          const SizedBox(height: 14),
          _Field(_contactEmailCtrl, 'Email address *',
              required: true, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _Field(_contactPhoneCtrl, 'Phone number',
              keyboardType: TextInputType.phone),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 32),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Back', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: _submitting
                  ? _LoadingBtn()
                  : _PrimaryBtn(label: 'Submit & continue', onTap: _nextFromStep1),
            ),
          ]),
        ]),
      ),
    ]);
  }

  // ── Step 2 — Documents ────────────────────────────────────────────────────
  Widget _step2Documents() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Supporting documents', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5))
          .animate().fadeIn(duration: 300.ms),
      const SizedBox(height: 8),
      Text('Upload verification documents to speed up review. All fields are optional — you can upload later.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.6))
          .animate().fadeIn(delay: 80.ms),
      const SizedBox(height: 32),
      ..._docLabels.entries.map((entry) => _DocRow(
        docType: entry.key,
        label: entry.value,
        picked: _docs[entry.key],
        uploading: _uploading[entry.key] ?? false,
        onPick: () => _pickDoc(entry.key),
      )),
      const SizedBox(height: 32),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _step = 3),
            style: OutlinedButton.styleFrom(
              foregroundColor: kMuted,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Skip for now', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: _PrimaryBtn(
            label: 'Upload & finish',
            onTap: _uploadDocs,
          ),
        ),
      ]),
    ]);
  }

  // ── Success ────────────────────────────────────────────────────────────────
  Widget _successView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.1), shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withOpacity(0.35)),
              ),
              child: const Icon(Icons.check_rounded, color: kPrimary, size: 36),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 28),
            Text('Application submitted!', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.5),
                textAlign: TextAlign.center).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Text(
              'Thank you for applying to the TippingJar Partner Program. '
              'Our team will review your application within 48 business hours '
              'and contact you via the email you provided.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 14, height: 1.7),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/developers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                ),
                child: Text('Back to developer docs',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
              ).animate().fadeIn(delay: 400.ms),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final labels = ['Company', 'Contact', 'Documents'];
    return Row(children: [
      for (int i = 0; i < total; i++) ...[
        Expanded(
          child: Column(children: [
            Row(children: [
              if (i > 0) Expanded(child: Container(height: 1, color: i <= current ? kPrimary : kBorder)),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: i < current
                      ? kPrimary
                      : i == current
                          ? kPrimary.withOpacity(0.15)
                          : kCardBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i <= current ? kPrimary : kBorder, width: 1.5),
                ),
                child: Center(
                  child: i < current
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : Text('${i + 1}', style: GoogleFonts.dmSans(
                          color: i == current ? kPrimary : kMuted,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
              if (i < total - 1) Expanded(child: Container(height: 1, color: i < current ? kPrimary : kBorder)),
            ]),
            const SizedBox(height: 6),
            Text(labels[i], style: GoogleFonts.dmSans(
                color: i == current ? Colors.white : kMuted,
                fontSize: 11, fontWeight: i == current ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ],
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool required;
  final int maxLines;
  final TextInputType keyboardType;

  const _Field(
    this.controller,
    this.hint, {
    this.required = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
      validator: required
          ? (v) => (v?.trim().isNotEmpty ?? false) ? null : 'Required'
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
        filled: true, fillColor: kCardBg,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.withOpacity(0.5))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: maxLines > 1 ? 14 : 13),
        isDense: true,
      ),
    );
  }
}

class _SectionLabel2 extends StatelessWidget {
  final String text;
  const _SectionLabel2(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    const SizedBox(width: 8),
    const Expanded(child: Divider(color: kBorder)),
  ]);
}

class _DocRow extends StatelessWidget {
  final String docType, label;
  final (Uint8List, String)? picked;
  final bool uploading;
  final VoidCallback onPick;
  const _DocRow({
    required this.docType, required this.label,
    required this.picked, required this.uploading, required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: picked != null ? kPrimary.withOpacity(0.4) : kBorder),
      ),
      child: Row(children: [
        Icon(
          picked != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
          color: picked != null ? kPrimary : kMuted, size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(
                color: picked != null ? Colors.white : kMuted,
                fontSize: 13, fontWeight: picked != null ? FontWeight.w500 : FontWeight.w400)),
            if (picked != null) ...[
              const SizedBox(height: 2),
              Text(picked!.$2, style: GoogleFonts.dmSans(
                  color: kPrimary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        uploading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2))
            : TextButton(
                onPressed: onPick,
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: kBorder),
                ),
                child: Text(picked != null ? 'Replace' : 'Select',
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
      ]),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary, foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      ),
      child: Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
    ),
  );
}

class _LoadingBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 52,
    child: ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary.withOpacity(0.4),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      ),
      child: const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
    ),
  );
}
