import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final int _totalSteps = 6;
  bool _saving = false;

  // Step 0 — Platforms
  final Set<String> _platforms = {};

  // Step 1 — Niche
  String? _niche;

  // Step 2 — Audience size
  String? _audienceSize;

  // Step 3 — Age group
  String? _ageGroup;

  // Step 4 — Audience gender
  String? _audienceGender;

  // Step 5 — Profile setup
  final _taglineCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  Uint8List? _avatarBytes;
  String _avatarFilename = 'avatar.jpg';

  bool get _canProceed => switch (_step) {
    0 => _platforms.isNotEmpty,
    1 => _niche != null,
    2 => _audienceSize != null,
    3 => _ageGroup != null,
    4 => _audienceGender != null,
    5 => _taglineCtrl.text.trim().isNotEmpty,
    _ => false,
  };

  Future<void> _next() async {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      setState(() => _saving = true);
      try {
        final api = context.read<AuthProvider>().api;
        // Upload avatar if the user picked one
        if (_avatarBytes != null) {
          try { await api.updateAvatar(_avatarBytes!, _avatarFilename); } catch (_) {}
        }
        // Save bio to user profile
        if (_bioCtrl.text.trim().isNotEmpty) {
          try { await api.updateUserProfile({'bio': _bioCtrl.text.trim()}); } catch (_) {}
        }
        // Save creator-specific onboarding data
        await api.updateMyCreatorProfile({
          'tagline': _taglineCtrl.text.trim(),
          'category': _niche ?? '',
          'platforms': _platforms.join(','),
          'audience_size': _audienceSize ?? '',
          'age_group': _ageGroup ?? '',
          'audience_gender': _audienceGender ?? '',
        });
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Profile saved with some issues. You can update it later.',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ));
        }
      } finally {
        if (mounted) {
          setState(() => _saving = false);
          context.go('/dashboard');
        }
      }
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  void dispose() {
    _taglineCtrl.dispose();
    _goalCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: w > 600 ? 48 : 24, vertical: 32),
              child: Column(children: [
                _header(),
                const SizedBox(height: 40),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: 300.ms,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _stepContent(),
                  ),
                ),
                const SizedBox(height: 24),
                _footer(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Column(children: [
    // Logo
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const AppLogoIcon(size: 32),
      const SizedBox(width: 8),
      Text('TippingJar', style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700,
          fontSize: 16, letterSpacing: -0.3)),
    ]),
    const SizedBox(height: 28),
    // Progress bar
    Row(children: List.generate(_totalSteps, (i) => Expanded(
      child: Container(
        height: 3,
        margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
        decoration: BoxDecoration(
          color: i <= _step ? kPrimary : kBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ))),
    const SizedBox(height: 10),
    Text('Step ${_step + 1} of $_totalSteps',
        style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
  ]);

  Widget _stepContent() {
    return switch (_step) {
      0 => _StepPlatforms(
          key: const ValueKey(0),
          selected: _platforms,
          onToggle: (p) => setState(() =>
              _platforms.contains(p) ? _platforms.remove(p) : _platforms.add(p)),
        ),
      1 => _StepNiche(
          key: const ValueKey(1),
          selected: _niche,
          onSelect: (n) => setState(() => _niche = n),
        ),
      2 => _StepAudience(
          key: const ValueKey(2),
          selected: _audienceSize,
          onSelect: (a) => setState(() => _audienceSize = a),
        ),
      3 => _StepAgeGroup(
          key: const ValueKey(3),
          selected: _ageGroup,
          onSelect: (a) => setState(() => _ageGroup = a),
        ),
      4 => _StepGender(
          key: const ValueKey(4),
          selected: _audienceGender,
          onSelect: (g) => setState(() => _audienceGender = g),
        ),
      5 => _StepProfile(
          key: const ValueKey(5),
          taglineCtrl: _taglineCtrl,
          goalCtrl: _goalCtrl,
          bioCtrl: _bioCtrl,
          avatarBytes: _avatarBytes,
          onChanged: () => setState(() {}),
          onAvatarPicked: (bytes, name) => setState(() {
            _avatarBytes = bytes;
            _avatarFilename = name;
          }),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _footer() => Row(children: [
    if (_step > 0)
      TextButton(
        onPressed: _saving ? null : _back,
        child: Text('Back', style: GoogleFonts.dmSans(
            color: kMuted, fontWeight: FontWeight.w500)),
      ),
    const Spacer(),
    AnimatedOpacity(
      opacity: _canProceed && !_saving ? 1 : 0.4,
      duration: 200.ms,
      child: ElevatedButton(
        onPressed: (_canProceed && !_saving) ? _next : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary, foregroundColor: Colors.white,
          elevation: 0, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          disabledBackgroundColor: kPrimary.withOpacity(0.4),
        ),
        child: _saving
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(_step == _totalSteps - 1 ? 'Go to dashboard →' : 'Continue',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
      ),
    ),
  ]);
}

// ─── Step 1: Platforms ────────────────────────────────────────────────────────
class _StepPlatforms extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;
  const _StepPlatforms({super.key, required this.selected, required this.onToggle});

  static const _options = [
    (Icons.smart_display_rounded,    'YouTube'),
    (Icons.videocam_rounded,         'Twitch'),
    (Icons.photo_camera_rounded,     'Instagram'),
    (Icons.alternate_email_rounded,  'Twitter / X'),
    (Icons.music_video_rounded,      'TikTok'),
    (Icons.mic_rounded,              'Podcast'),
    (Icons.article_rounded,          'Blog / Newsletter'),
    (Icons.add_circle_outline_rounded,'Other'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Where do you create?',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('Select all that apply.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 60.ms),
      const SizedBox(height: 28),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 3.2,
          children: _options.map((o) {
            final active = selected.contains(o.$2);
            return GestureDetector(
              onTap: () => onToggle(o.$2),
              child: AnimatedContainer(
                duration: 180.ms,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: active ? kPrimary.withOpacity(0.1) : kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? kPrimary : kBorder,
                      width: active ? 2 : 1),
                ),
                child: Row(children: [
                  Icon(o.$1, color: active ? kPrimary : kMuted, size: 18),
                  const SizedBox(width: 10),
                  Flexible(child: Text(o.$2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                          color: active ? kPrimary : Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13))),
                  if (active) ...[
                    const Spacer(),
                    const Icon(Icons.check_circle_rounded,
                        color: kPrimary, size: 16),
                  ],
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

// ─── Step 2: Niche ────────────────────────────────────────────────────────────
class _StepNiche extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _StepNiche({super.key, required this.selected, required this.onSelect});

  static const _niches = [
    (Icons.sports_esports_rounded, 'Gaming',       Color(0xFF818CF8)),
    (Icons.music_note_rounded,     'Music',         Color(0xFFF472B6)),
    (Icons.palette_rounded,        'Art & Design',  Color(0xFFFBBF24)),
    (Icons.computer_rounded,       'Tech',          Color(0xFF60A5FA)),
    (Icons.school_rounded,         'Education',     Color(0xFF34D399)),
    (Icons.fitness_center_rounded, 'Fitness',       Color(0xFFF87171)),
    (Icons.restaurant_rounded,     'Food',          Color(0xFFFF9466)),
    (Icons.camera_rounded,         'Photography',   Color(0xFFA78BFA)),
    (Icons.sentiment_very_satisfied_rounded, 'Comedy', Color(0xFFFCD34D)),
    (Icons.flight_rounded,         'Travel',        Color(0xFF38BDF8)),
    (Icons.menu_book_rounded,      'Writing',       Color(0xFF86EFAC)),
    (Icons.more_horiz_rounded,     'Other',         kMuted),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('What\'s your content niche?',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('Pick the one that best describes your content.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 60.ms),
      const SizedBox(height: 28),
      Expanded(
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: _niches.map((n) {
            final active = selected == n.$2;
            return GestureDetector(
              onTap: () => onSelect(n.$2),
              child: AnimatedContainer(
                duration: 180.ms,
                decoration: BoxDecoration(
                  color: active ? n.$3.withOpacity(0.12) : kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? n.$3 : kBorder,
                      width: active ? 2 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(n.$1, color: active ? n.$3 : kMuted, size: 22),
                    const SizedBox(height: 6),
                    Text(n.$2,
                        style: GoogleFonts.dmSans(
                            color: active ? n.$3 : kMuted,
                            fontWeight: FontWeight.w600, fontSize: 11),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

// ─── Step 3: Audience size ────────────────────────────────────────────────────
class _StepAudience extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _StepAudience({super.key, required this.selected, required this.onSelect});

  static const _sizes = [
    ('Just starting out', 'Under 1,000 followers', Icons.spa_rounded),
    ('Growing',           '1K – 10K followers',    Icons.trending_up_rounded),
    ('Established',       '10K – 100K followers',  Icons.star_rounded),
    ('Large audience',    '100K+ followers',        Icons.rocket_launch_rounded),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('How big is your audience?',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('This helps us tailor your experience.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 60.ms),
      const SizedBox(height: 28),
      ..._sizes.map((s) {
        final active = selected == s.$1;
        return GestureDetector(
          onTap: () => onSelect(s.$1),
          child: AnimatedContainer(
            duration: 180.ms,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: active ? kPrimary.withOpacity(0.08) : kCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: active ? kPrimary : kBorder,
                  width: active ? 2 : 1),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: active ? kPrimary.withOpacity(0.15) : kBorder.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(s.$3,
                    color: active ? kPrimary : kMuted, size: 20),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$1, style: GoogleFonts.dmSans(
                    color: active ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 14)),
                Text(s.$2, style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 12)),
              ]),
              const Spacer(),
              if (active)
                const Icon(Icons.check_circle_rounded, color: kPrimary, size: 20),
            ]),
          ),
        ).animate().fadeIn(
            delay: Duration(milliseconds: 60 * _sizes.indexOf(s)),
            duration: 350.ms);
      }),
    ],
  );
}

// ─── Step 4: Age group ────────────────────────────────────────────────────────
class _StepAgeGroup extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _StepAgeGroup({super.key, required this.selected, required this.onSelect});

  static const _groups = [
    ('Under 13',  'Kids — safe, family-friendly content',     Icons.child_care_rounded),
    ('13 – 17',   'Teens — school-age to late adolescence',   Icons.school_rounded),
    ('18 – 24',   'Young adults — Gen Z',                     Icons.sports_esports_rounded),
    ('25 – 34',   'Millennials — early career adults',        Icons.work_rounded),
    ('35 – 44',   'Mid-life adults',                          Icons.home_rounded),
    ('45+',       'Mature audiences',                         Icons.auto_awesome_rounded),
    ('All ages',  'My content is for everyone',               Icons.diversity_3_rounded),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Who is your content for?',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('Select the primary age group you create for.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 60.ms),
      const SizedBox(height: 20),
      Expanded(
        child: ListView(
          children: _groups.asMap().entries.map((e) {
            final s = e.value;
            final active = selected == s.$1;
            return GestureDetector(
              onTap: () => onSelect(s.$1),
              child: AnimatedContainer(
                duration: 180.ms,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: active ? kPrimary.withOpacity(0.08) : kCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: active ? kPrimary : kBorder,
                      width: active ? 2 : 1),
                ),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: active ? kPrimary.withOpacity(0.15) : kBorder.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.$3, color: active ? kPrimary : kMuted, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.$1, style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(s.$2, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
                  ])),
                  if (active)
                    const Icon(Icons.check_circle_rounded, color: kPrimary, size: 20),
                ]),
              ),
            ).animate().fadeIn(
                delay: Duration(milliseconds: 40 * e.key), duration: 320.ms);
          }).toList(),
        ),
      ),
    ],
  );
}

// ─── Step 5: Audience gender ──────────────────────────────────────────────────
class _StepGender extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _StepGender({super.key, required this.selected, required this.onSelect});

  static const _options = [
    ('Mostly female',    Icons.female_rounded,        Color(0xFFF472B6)),
    ('Mostly male',      Icons.male_rounded,           Color(0xFF60A5FA)),
    ('Both equally',     Icons.people_rounded,         Color(0xFF34D399)),
    ('Prefer not to say', Icons.more_horiz_rounded,   kMuted),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Who watches your content?',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('Helps match you with the right opportunities.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 60.ms),
      const SizedBox(height: 28),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: _options.asMap().entries.map((e) {
            final opt = e.value;
            final active = selected == opt.$1;
            return GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: AnimatedContainer(
                duration: 180.ms,
                decoration: BoxDecoration(
                  color: active ? opt.$3.withOpacity(0.10) : kCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active ? opt.$3 : kBorder,
                      width: active ? 2 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(opt.$2,
                        color: active ? opt.$3 : kMuted, size: 36),
                    const SizedBox(height: 10),
                    Text(opt.$1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                            color: active ? opt.$3 : Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    if (active) ...[
                      const SizedBox(height: 6),
                      Icon(Icons.check_circle_rounded,
                          color: opt.$3, size: 16),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(
                delay: Duration(milliseconds: 60 * e.key), duration: 350.ms);
          }).toList(),
        ),
      ),
    ],
  );
}

// ─── Step 6: Profile setup ────────────────────────────────────────────────────
class _StepProfile extends StatelessWidget {
  final TextEditingController taglineCtrl, goalCtrl, bioCtrl;
  final Uint8List? avatarBytes;
  final VoidCallback onChanged;
  final void Function(Uint8List bytes, String name) onAvatarPicked;
  const _StepProfile({super.key,
      required this.taglineCtrl, required this.goalCtrl,
      required this.bioCtrl, required this.avatarBytes,
      required this.onChanged, required this.onAvatarPicked});

  static const _goals = ['R500', 'R2,000', 'R5,000', 'R10,000'];

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      onAvatarPicked(
        result.files.single.bytes!,
        result.files.single.name.isNotEmpty ? result.files.single.name : 'avatar.jpg',
      );
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Set up your creator profile',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: -0.8))
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 6),
      Text('You can always change these later.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 14))
          .animate().fadeIn(delay: 60.ms),
      const SizedBox(height: 24),

      // ── Profile picture ──────────────────────────────────────────
      Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: kCardBg,
              backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes!) : null,
              child: avatarBytes == null
                  ? const Icon(Icons.person_rounded, color: kMuted, size: 48)
                  : null,
            ),
            Positioned(
              bottom: 0, right: -4,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: kPrimary, shape: BoxShape.circle,
                  border: Border.all(color: kDark, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text('Tap to add a profile photo',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      ),
      const SizedBox(height: 24),

      // Tagline
      Text('Your tagline',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextFormField(
        controller: taglineCtrl,
        onChanged: (_) => onChanged(),
        maxLength: 80,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'e.g. "Indie game dev sharing my journey 🎮"',
          hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
          counterStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
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

      // Bio
      Text('Short bio (optional)',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 4),
      Text('Visible on your public tip page.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      const SizedBox(height: 8),
      TextFormField(
        controller: bioCtrl,
        onChanged: (_) => onChanged(),
        maxLength: 200,
        maxLines: 3,
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tell your fans a bit about you…',
          hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
          counterStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 11),
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
      const SizedBox(height: 16),

      // Monthly goal
      Text('Monthly tip goal (optional)',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      Text('Sets a visible goal bar on your tip page.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 10, children: [
        ..._goals.map((g) {
          final active = goalCtrl.text == g;
          return GestureDetector(
            onTap: () {
              goalCtrl.text = g;
              onChanged();
            },
            child: AnimatedContainer(
              duration: 150.ms,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? kPrimary.withOpacity(0.1) : kCardBg,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                    color: active ? kPrimary : kBorder,
                    width: active ? 2 : 1),
              ),
              child: Text(g, style: GoogleFonts.dmSans(
                  color: active ? kPrimary : kMuted,
                  fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        }),
        // Custom input
        SizedBox(
          width: 120,
          child: TextFormField(
            controller: goalCtrl.text.startsWith('\$') &&
                !_goals.contains(goalCtrl.text) ? goalCtrl : TextEditingController(),
            onChanged: (v) {
              goalCtrl.text = v;
              onChanged();
            },
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Custom',
              hintStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
              prefixText: '\$',
              prefixStyle: GoogleFonts.dmSans(color: kMuted, fontSize: 13),
              filled: true, fillColor: kCardBg,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(36),
                  borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(36),
                  borderSide: const BorderSide(color: kPrimary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ]),
      const SizedBox(height: 24),

      // Preview card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kPrimary.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your tip page preview',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
            Text(
              taglineCtrl.text.isEmpty ? 'Your tagline will appear here…' : taglineCtrl.text,
              style: GoogleFonts.dmSans(
                  color: taglineCtrl.text.isEmpty ? kMuted : Colors.white,
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ])),
        ]),
      ),
    ]),
  );
}
