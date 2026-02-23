import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/api_key_model.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _baseUrl = 'https://api.tippingjar.co.za/v1';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});
  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  int _codeTab = 0;
  int _authCodeTab = 0;
  final Set<String> _expanded = {};
  int _activeSidebarIdx = 0;

  final ScrollController _scroll = ScrollController();
  final _heroKey       = GlobalKey();
  final _authKey       = GlobalKey();
  final _quickstartKey = GlobalKey();
  final _referenceKey  = GlobalKey();
  final _errorsKey     = GlobalKey();
  final _rateKey       = GlobalKey();
  final _webhooksKey   = GlobalKey();
  final _sdksKey       = GlobalKey();
  final _platformApiKey  = GlobalKey();
  final _partnerKey      = GlobalKey();

  static const _sidebarItems = [
    (Icons.home_rounded,           'Overview'),
    (Icons.lock_rounded,           'Authentication'),
    (Icons.flash_on_rounded,       'Quick Start'),
    (Icons.list_alt_rounded,       'API Reference'),
    (Icons.error_outline_rounded,  'Error Codes'),
    (Icons.speed_rounded,          'Rate Limits'),
    (Icons.webhook_rounded,        'Webhooks'),
    (Icons.code_rounded,           'SDKs'),
    (Icons.api_rounded,            'Platform API'),
    (Icons.handshake_rounded,      'Partner Program'),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Simple offset-based section detection
    final o = _scroll.offset;
    int idx = 0;
    if (o > 200)  idx = 1;
    if (o > 900)  idx = 2;
    if (o > 1600) idx = 3;
    if (o > 2800) idx = 4;
    if (o > 3400) idx = 5;
    if (o > 4000) idx = 6;
    if (o > 5000) idx = 7;
    if (o > 6200) idx = 8;
    if (o > 7400) idx = 9;
    if (idx != _activeSidebarIdx) setState(() => _activeSidebarIdx = idx);
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    }
  }

  void _scrollToIdx(int idx) {
    setState(() => _activeSidebarIdx = idx);
    final keys = [_heroKey, _authKey, _quickstartKey, _referenceKey,
                  _errorsKey, _rateKey, _webhooksKey, _sdksKey,
                  _platformApiKey, _partnerKey];
    _scrollTo(keys[idx]);
  }


  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final body = SingleChildScrollView(
      controller: _scroll,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hero(context),
        _authSection(context),
        _quickstart(context),
        _fullReference(context),
        _errorCodes(context),
        _rateLimits(context),
        _webhooks(context),
        _sdks(context),
        _platformApiSection(context),
        _partnerProgramSection(context),
        _cta(context),
        _footer(),
      ]),
    );

    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/developers'),
      body: w > 1080
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sidebar(context),
              Expanded(child: body),
            ])
          : body,
    );
  }

  // ─── Sticky sidebar ────────────────────────────────────────────────────────
  Widget _sidebar(BuildContext context) => SizedBox(
    width: 230,
    child: Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: kDarker,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CONTENTS',
              style: GoogleFonts.dmSans(
                  color: kMuted, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 12),
          ..._sidebarItems.asMap().entries.map((e) {
            final active = e.key == _activeSidebarIdx;
            return GestureDetector(
              onTap: () => _scrollToIdx(e.key),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? kPrimary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? kPrimary.withOpacity(0.3) : Colors.transparent),
                ),
                child: Row(children: [
                  Icon(e.value.$1,
                      color: active ? kPrimary : kMuted, size: 14),
                  const SizedBox(width: 10),
                  Text(e.value.$2,
                      style: GoogleFonts.dmSans(
                          color: active ? kPrimary : kMuted,
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            );
          }),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Base URL', style: GoogleFonts.dmSans(
                  color: kMuted, fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(_baseUrl, style: GoogleFonts.jetBrainsMono(
                  color: kPrimary, fontSize: 10)),
            ]),
          ),
        ]),
      ),
    ),
  );

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      key: _heroKey,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: w > 900 ? 80 : 28, vertical: 96),
      decoration: const BoxDecoration(color: kDarker),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: kPrimary.withOpacity(0.3)),
          ),
          child: Text('API v1  ·  REST  ·  JSON',
              style: GoogleFonts.jetBrainsMono(
                  color: kPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        Text('TippingJar\nDeveloper Platform',
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: w > 700 ? 52 : 34,
                letterSpacing: -2,
                height: 1.05),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            'A fast, secure REST API to integrate tipping flows into any product. Accept tips in ZAR, manage creator jars, issue payouts, and react to events with signed webhooks.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 17, height: 1.7),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 160.ms, duration: 500.ms),
        ),
        const SizedBox(height: 40),
        Wrap(spacing: 14, runSpacing: 12, alignment: WrapAlignment.center, children: [
          ElevatedButton.icon(
            onPressed: () => _scrollToIdx(2),
            icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
            label: Text('Quick Start',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _scrollToIdx(1),
            icon: const Icon(Icons.lock_outlined, size: 16),
            label: Text('Get API Key',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
          ),
        ]).animate().fadeIn(delay: 240.ms, duration: 500.ms),
        const SizedBox(height: 56),
        Wrap(spacing: 48, runSpacing: 20, alignment: WrapAlignment.center,
          children: const [
            _Stat(value: '< 200ms', label: 'Median latency'),
            _Stat(value: '99.99%', label: 'API uptime'),
            _Stat(value: 'ZAR', label: 'Default currency'),
            _Stat(value: 'Free', label: 'Sandbox included'),
          ],
        ).animate().fadeIn(delay: 320.ms, duration: 500.ms),
      ]),
    );
  }

  // ─── Authentication & Keys ────────────────────────────────────────────────
  Widget _authSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final authSnippets = [_authCurl, _authPython, _authNode];
    final authTabs    = ['cURL', 'Python', 'Node.js'];

    return Container(
      key: _authKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.lock_rounded, label: 'Authentication'),
        const SizedBox(height: 16),
        Text('API Keys & Bearer Tokens',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'TippingJar uses JWT Bearer tokens for authentication. Obtain a token pair by posting credentials to the token endpoint. Include your access token in every authenticated request via the Authorization header.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.7),
          ),
        ),
        const SizedBox(height: 40),

        // Auth flow cards
        Wrap(spacing: 16, runSpacing: 16, children: [
          _AuthStepCard(step: '01', icon: Icons.person_add_rounded,
              title: 'Register', desc: 'Create an account at tippingjar.co.za or via POST /api/users/register/'),
          _AuthStepCard(step: '02', icon: Icons.login_rounded,
              title: 'Get Token', desc: 'POST credentials to /api/auth/token/ — receive an access + refresh token pair'),
          _AuthStepCard(step: '03', icon: Icons.vpn_key_rounded,
              title: 'Authenticate', desc: 'Pass the access token in the Authorization: Bearer <token> header on every request'),
          _AuthStepCard(step: '04', icon: Icons.refresh_rounded,
              title: 'Refresh', desc: 'Use your refresh token to obtain a new access token before it expires (60 min TTL)'),
        ]),

        const SizedBox(height: 40),

        // API Key panel + code example side by side
        w > 860
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: _ApiKeyPanel(auth: context.watch<AuthProvider>())),
              const SizedBox(width: 24),
              Expanded(flex: 6, child: _authCodeBlock(authTabs, authSnippets)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ApiKeyPanel(auth: context.watch<AuthProvider>()),
              const SizedBox(height: 24),
              _authCodeBlock(authTabs, authSnippets),
            ]),

        const SizedBox(height: 40),

        // Token response reference
        _infoBox(
          icon: Icons.info_outline_rounded,
          color: kTeal,
          title: 'Access token lifetime',
          body: 'Access tokens expire after 60 minutes. Refresh tokens last 7 days. '
              'Your application should detect 401 Unauthorized responses and call '
              '/api/auth/token/refresh/ automatically to obtain a new access token.',
        ),
      ]),
    );
  }


  Widget _authCodeBlock(List<String> tabs, List<String> snippets) =>
    Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Row(children: [
            ...tabs.asMap().entries.map((e) => GestureDetector(
              onTap: () => setState(() => _authCodeTab = e.key),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: _authCodeTab == e.key ? kPrimary : Colors.transparent,
                    width: 2)),
                ),
                child: Text(e.value,
                    style: GoogleFonts.jetBrainsMono(
                        color: _authCodeTab == e.key ? kPrimary : kMuted,
                        fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            )),
            const Spacer(),
            _CopyButton(code: snippets[_authCodeTab]),
            const SizedBox(width: 12),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(20),
          child: Text(snippets[_authCodeTab],
              style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFCDD6F4), fontSize: 12, height: 1.75)),
        ),
      ]),
    );

  // ─── Quick-start ───────────────────────────────────────────────────────────
  Widget _quickstart(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final tabs = ['cURL', 'Python', 'Node.js', 'Dart'];
    final snippets = [_curlSnippet, _pythonSnippet, _nodeSnippet, _dartSnippet];

    return Container(
      key: _quickstartKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDarker,
      child: Column(children: [
        _SectionLabel(icon: Icons.flash_on_rounded, label: 'Quick Start'),
        const SizedBox(height: 16),
        Text('Send your first tip in 5 minutes',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text('Authenticate, then create a tip payment with a single API call.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1A14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: kBorder))),
                child: Row(children: [
                  ...tabs.asMap().entries.map((e) => GestureDetector(
                    onTap: () => setState(() => _codeTab = e.key),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(
                          color: _codeTab == e.key ? kPrimary : Colors.transparent,
                          width: 2)),
                      ),
                      child: Text(e.value,
                          style: GoogleFonts.jetBrainsMono(
                              color: _codeTab == e.key ? kPrimary : kMuted,
                              fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  )),
                  const Spacer(),
                  _CopyButton(code: snippets[_codeTab]),
                  const SizedBox(width: 12),
                ]),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(22),
                child: Text(snippets[_codeTab],
                    style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFCDD6F4),
                        fontSize: 13, height: 1.75)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── Full API Reference ────────────────────────────────────────────────────
  Widget _fullReference(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      key: _referenceKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.list_alt_rounded, label: 'API Reference'),
        const SizedBox(height: 16),
        Text('Complete endpoint reference',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 8),
        Row(children: [
          Text('Base URL  ', style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          Text(_baseUrl, style: GoogleFonts.jetBrainsMono(color: kPrimary, fontSize: 13)),
          const SizedBox(width: 8),
          _CopyButton(code: _baseUrl),
        ]),
        const SizedBox(height: 40),

        // ── Authentication group ──────────────────────────────────────────
        _GroupHeader(icon: Icons.lock_rounded, title: 'Authentication',
            desc: 'Obtain and refresh JWT access tokens.'),
        _ExpandableEndpoint(id: 'auth-1', method: 'POST', path: '/api/auth/token/',
            desc: 'Obtain JWT token pair (access + refresh)',
            auth: false,
            requestBody: _jsonBlock('''{
  "username": "janedoe",
  "password": "SuperSecret123"
}'''),
            responseBody: _jsonBlock('''{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 42,
    "username": "janedoe",
    "email": "jane@example.com",
    "role": "creator"
  }
}'''),
            expanded: _expanded.contains('auth-1'),
            onToggle: () => _toggle('auth-1')),

        _ExpandableEndpoint(id: 'auth-2', method: 'POST', path: '/api/auth/token/refresh/',
            desc: 'Exchange a refresh token for a new access token',
            auth: false,
            requestBody: _jsonBlock('''{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}'''),
            responseBody: _jsonBlock('''{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}'''),
            expanded: _expanded.contains('auth-2'),
            onToggle: () => _toggle('auth-2')),

        _ExpandableEndpoint(id: 'auth-3', method: 'POST', path: '/api/users/register/',
            desc: 'Register a new user account',
            auth: false,
            requestBody: _jsonBlock('''{
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "SuperSecret123",
  "role": "creator"    // "creator" | "fan"
}'''),
            responseBody: _jsonBlock('''{
  "id": 42,
  "username": "janedoe",
  "email": "jane@example.com",
  "role": "creator",
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}'''),
            expanded: _expanded.contains('auth-3'),
            onToggle: () => _toggle('auth-3')),

        const SizedBox(height: 32),

        // ── Creators group ────────────────────────────────────────────────
        _GroupHeader(icon: Icons.person_rounded, title: 'Creators',
            desc: 'Manage creator profiles and retrieve public data.'),

        _ExpandableEndpoint(id: 'cr-1', method: 'GET', path: '/api/creators/',
            desc: 'List all active creator profiles',
            auth: false,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "count": 128,
  "next": "$_baseUrl/creators/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "display_name": "Jane Creates",
      "slug": "jane-creates",
      "tagline": "Digital art & animations",
      "total_tips": "3240.00"
    }
  ]
}'''),
            expanded: _expanded.contains('cr-1'),
            onToggle: () => _toggle('cr-1')),

        _ExpandableEndpoint(id: 'cr-2', method: 'GET', path: '/api/creators/me/',
            desc: 'Retrieve the authenticated creator\'s own profile',
            auth: true,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "id": 1,
  "display_name": "Jane Creates",
  "slug": "jane-creates",
  "tagline": "Digital art & animations",
  "tip_goal": "5000.00",
  "bank_name": "FNB",
  "bank_account_number": "••••••7890",
  "bank_country": "ZA",
  "is_active": true,
  "created_at": "2025-09-01T10:00:00Z"
}'''),
            expanded: _expanded.contains('cr-2'),
            onToggle: () => _toggle('cr-2')),

        _ExpandableEndpoint(id: 'cr-3', method: 'PATCH', path: '/api/creators/me/',
            desc: 'Update the authenticated creator\'s profile',
            auth: true,
            requestBody: _jsonBlock('''{
  "display_name": "Jane Creates",
  "tagline": "Art that moves you",
  "tip_goal": "5000.00",
  "bank_name": "Nedbank",
  "bank_account_number": "1234567890",
  "bank_account_type": "savings",
  "bank_country": "ZA"
}'''),
            responseBody: _jsonBlock('{ /* updated CreatorProfile object */ }'),
            expanded: _expanded.contains('cr-3'),
            onToggle: () => _toggle('cr-3')),

        _ExpandableEndpoint(id: 'cr-4', method: 'GET', path: '/api/creators/me/stats/',
            desc: 'Dashboard stats — earnings, tip count, monthly progress',
            auth: true,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "total_earned": "18740.00",
  "tips_this_month": 47,
  "earned_this_month": "3240.00",
  "tip_goal": "5000.00",
  "goal_progress_pct": 64.8,
  "top_tippers": [
    { "tipper_name": "SuperFan", "total": "1200.00" }
  ]
}'''),
            expanded: _expanded.contains('cr-4'),
            onToggle: () => _toggle('cr-4')),

        _ExpandableEndpoint(id: 'cr-5', method: 'GET', path: '/api/creators/{slug}/',
            desc: 'Fetch a public creator profile by slug',
            auth: false,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "display_name": "Jane Creates",
  "slug": "jane-creates",
  "tagline": "Digital art & animations",
  "total_tips": "3240.00",
  "is_active": true
}'''),
            expanded: _expanded.contains('cr-5'),
            onToggle: () => _toggle('cr-5')),

        const SizedBox(height: 32),

        // ── Jars group ────────────────────────────────────────────────────
        _GroupHeader(icon: Icons.savings_rounded, title: 'Jars',
            desc: 'Campaign-specific tip jars with optional fundraising goals.'),

        _ExpandableEndpoint(id: 'jar-1', method: 'GET', path: '/api/creators/me/jars/',
            desc: 'List all jars owned by the authenticated creator',
            auth: true,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "count": 3,
  "results": [
    {
      "id": 7,
      "name": "Studio Equipment Fund",
      "slug": "studio-equipment-fund",
      "description": "Help me buy a new mic and camera.",
      "goal": "10000.00",
      "total_raised": "4320.00",
      "tip_count": 38,
      "progress_pct": 43.2,
      "is_active": true,
      "creator_slug": "jane-creates",
      "created_at": "2025-11-01T08:00:00Z"
    }
  ]
}'''),
            expanded: _expanded.contains('jar-1'),
            onToggle: () => _toggle('jar-1')),

        _ExpandableEndpoint(id: 'jar-2', method: 'POST', path: '/api/creators/me/jars/',
            desc: 'Create a new jar (slug auto-generated from name)',
            auth: true,
            requestBody: _jsonBlock('''{
  "name": "Studio Equipment Fund",
  "description": "Help me buy a new mic and camera.",
  "goal": "10000.00"       // optional
}'''),
            responseBody: _jsonBlock('{ /* JarObject */ }'),
            expanded: _expanded.contains('jar-2'),
            onToggle: () => _toggle('jar-2')),

        _ExpandableEndpoint(id: 'jar-3', method: 'PATCH', path: '/api/creators/me/jars/{id}/',
            desc: 'Update a jar — name, description, goal, or active status',
            auth: true,
            requestBody: _jsonBlock('''{
  "name": "New Mic Fund",
  "goal": "5000.00",
  "is_active": false
}'''),
            responseBody: _jsonBlock('{ /* updated JarObject */ }'),
            expanded: _expanded.contains('jar-3'),
            onToggle: () => _toggle('jar-3')),

        _ExpandableEndpoint(id: 'jar-4', method: 'DELETE', path: '/api/creators/me/jars/{id}/',
            desc: 'Permanently delete a jar',
            auth: true,
            requestBody: null,
            responseBody: _jsonBlock('HTTP 204 No Content'),
            expanded: _expanded.contains('jar-4'),
            onToggle: () => _toggle('jar-4')),

        _ExpandableEndpoint(id: 'jar-5', method: 'GET', path: '/api/creators/{slug}/jars/',
            desc: 'List all active public jars for a creator',
            auth: false,
            requestBody: null,
            responseBody: _jsonBlock('[ /* array of JarObjects */ ]'),
            expanded: _expanded.contains('jar-5'),
            onToggle: () => _toggle('jar-5')),

        _ExpandableEndpoint(id: 'jar-6', method: 'GET', path: '/api/creators/{slug}/jars/{jar_slug}/',
            desc: 'Fetch a specific public jar by creator slug + jar slug',
            auth: false,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "id": 7,
  "name": "Studio Equipment Fund",
  "slug": "studio-equipment-fund",
  "creator_slug": "jane-creates",
  "goal": "10000.00",
  "total_raised": "4320.00",
  "tip_count": 38,
  "progress_pct": 43.2
}'''),
            expanded: _expanded.contains('jar-6'),
            onToggle: () => _toggle('jar-6')),

        const SizedBox(height: 32),

        // ── Tips group ────────────────────────────────────────────────────
        _GroupHeader(icon: Icons.volunteer_activism_rounded, title: 'Tips',
            desc: 'Initiate tip payments and retrieve tip history.'),

        _ExpandableEndpoint(id: 'tip-1', method: 'POST', path: '/api/tips/initiate/',
            desc: 'Create a tip payment intent (Stripe) or complete tip in sandbox',
            auth: false,
            requestBody: _jsonBlock('''{
  "creator_slug": "jane-creates",
  "amount": 50.00,            // ZAR
  "message": "Love your work!",
  "tipper_name": "Anonymous",  // optional
  "jar_id": 7                  // optional — attribute to a specific jar
}'''),
            responseBody: _jsonBlock('''{
  // Sandbox (no Stripe key configured):
  "success": true,
  "tip_id": 123,
  "amount": "50.00",
  "creator_name": "Jane Creates"

  // Production (Stripe enabled):
  "client_secret": "pi_3Qf8Tz2eZvKYlo..._secret_...",
}'''),
            expanded: _expanded.contains('tip-1'),
            onToggle: () => _toggle('tip-1')),

        _ExpandableEndpoint(id: 'tip-2', method: 'GET', path: '/api/tips/me/',
            desc: 'List completed tips received by the authenticated creator',
            auth: true,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "count": 84,
  "results": [
    {
      "id": 123,
      "tipper_name": "BigFan",
      "amount": "100.00",
      "message": "Keep creating!",
      "jar": 7,
      "jar_name": "Studio Equipment Fund",
      "status": "completed",
      "created_at": "2026-02-10T14:22:00Z"
    }
  ]
}'''),
            expanded: _expanded.contains('tip-2'),
            onToggle: () => _toggle('tip-2')),

        _ExpandableEndpoint(id: 'tip-3', method: 'GET', path: '/api/tips/sent/',
            desc: 'List tips sent by the authenticated fan user',
            auth: true,
            requestBody: null,
            responseBody: _jsonBlock('''{
  "count": 12,
  "results": [
    {
      "id": 99,
      "creator_slug": "jane-creates",
      "creator_display_name": "Jane Creates",
      "amount": "50.00",
      "message": "Love your work!",
      "status": "completed",
      "created_at": "2026-01-28T09:11:00Z"
    }
  ]
}'''),
            expanded: _expanded.contains('tip-3'),
            onToggle: () => _toggle('tip-3')),

        _ExpandableEndpoint(id: 'tip-4', method: 'GET', path: '/api/tips/{slug}/',
            desc: 'Public feed of completed tips for a creator',
            auth: false,
            requestBody: null,
            responseBody: _jsonBlock('[ /* array of tip objects */ ]'),
            expanded: _expanded.contains('tip-4'),
            onToggle: () => _toggle('tip-4')),
      ]),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  // ─── Error Codes ──────────────────────────────────────────────────────────
  Widget _errorCodes(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const errors = [
      ('400', 'Bad Request',           'Invalid request body or missing required fields.'),
      ('401', 'Unauthorized',          'Missing or invalid Bearer token. Re-authenticate.'),
      ('403', 'Forbidden',             'Authenticated but not allowed to perform this action.'),
      ('404', 'Not Found',             'Resource does not exist or has been deleted.'),
      ('405', 'Method Not Allowed',    'HTTP method not supported on this endpoint.'),
      ('422', 'Validation Error',      'Request body failed field-level validation. See errors object.'),
      ('429', 'Too Many Requests',     'Rate limit exceeded. Check Retry-After header.'),
      ('500', 'Internal Server Error', 'Unexpected server error. Contact support@tippingjar.co.za.'),
    ];

    return Container(
      key: _errorsKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDarker,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.error_outline_rounded, label: 'Error Codes'),
        const SizedBox(height: 16),
        Text('Error handling',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 10),
        Text('All errors follow a consistent JSON structure with a detail field.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15)),
        const SizedBox(height: 32),

        w > 820
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _errorTable(errors)),
              const SizedBox(width: 28),
              SizedBox(width: 320, child: _errorExample()),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _errorTable(errors),
              const SizedBox(height: 24),
              _errorExample(),
            ]),
      ]),
    );
  }

  Widget _errorTable(List<(String, String, String)> errors) => Column(
    children: errors.map((e) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _errorColor(e.$1).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(e.$1, style: GoogleFonts.jetBrainsMono(
              color: _errorColor(e.$1), fontSize: 11,
              fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.$2, style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(e.$3, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
        ])),
      ]),
    )).toList(),
  );

  Color _errorColor(String code) {
    if (code.startsWith('2')) return kPrimary;
    if (code.startsWith('4')) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  Widget _errorExample() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0D1A14),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Text('Error response shape',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          _CopyButton(code: _errorShape),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Text(_errorShape, style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFFCDD6F4), fontSize: 12, height: 1.65)),
      ),
    ]),
  );

  // ─── Rate Limits ──────────────────────────────────────────────────────────
  Widget _rateLimits(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const limits = [
      (Icons.public_rounded,        'Unauthenticated',   '60 req / min',   'Per IP address'),
      (Icons.person_rounded,        'Authenticated',     '300 req / min',  'Per user token'),
      (Icons.volunteer_activism_rounded, 'Tip creation', '30 req / hour',  'Per IP / user'),
      (Icons.refresh_rounded,       'Token refresh',     '20 req / hour',  'Per user'),
      (Icons.api_rounded,           'Platform API',      '1 000 req / min','Per platform key'),
    ];

    return Container(
      key: _rateKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.speed_rounded, label: 'Rate Limits'),
        const SizedBox(height: 16),
        Text('Rate limiting',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 10),
        Text('Limits apply per IP for public endpoints and per access token for authenticated ones.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15)),
        const SizedBox(height: 32),
        Wrap(spacing: 16, runSpacing: 16,
          children: limits.map((l) => _RateLimitCard(
            icon: l.$1, tier: l.$2, limit: l.$3, scope: l.$4)).toList(),
        ),
        const SizedBox(height: 32),
        _infoBox(
          icon: Icons.info_outline_rounded,
          color: kTeal,
          title: 'Rate limit headers',
          body: 'Every response includes:\n'
              '  X-RateLimit-Limit      — your limit for this window\n'
              '  X-RateLimit-Remaining  — requests remaining\n'
              '  X-RateLimit-Reset      — Unix timestamp the window resets\n'
              '  Retry-After            — seconds to wait (only on 429 responses)',
        ),
      ]),
    );
  }

  // ─── Webhooks ─────────────────────────────────────────────────────────────
  Widget _webhooks(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const events = [
      ('tip.completed',    'Fires immediately when a tip payment succeeds.',   kPrimary),
      ('tip.failed',       'Fires when a Stripe payment attempt fails.',       Color(0xFFF87171)),
      ('tip.refunded',     'Fires when a tip is refunded to the tipper.',      Color(0xFFFBBF24)),
      ('jar.created',      'A creator published a new jar.',                   kTeal),
      ('jar.goal_reached', 'A jar\'s total_raised has met or exceeded goal.',  kPrimary),
      ('creator.created',  'A new creator profile was registered.',            kTeal),
      ('payout.initiated', 'Stripe has initiated a bank transfer.',            Color(0xFFFBBF24)),
      ('payout.completed', 'Payout has arrived in the creator\'s account.',    kPrimary),
    ];

    return Container(
      key: _webhooksKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDarker,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.webhook_rounded, label: 'Webhooks'),
        const SizedBox(height: 16),
        Text('Real-time event notifications',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Register an HTTPS endpoint in your dashboard. TippingJar will POST signed payloads to your URL on every event. Verify signatures using HMAC-SHA256 with your webhook secret.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.65),
          ),
        ),
        const SizedBox(height: 40),
        w > 800
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _webhookEventsList(events)),
              const SizedBox(width: 28),
              Expanded(child: Column(children: [
                _codeBlock('Payload example', _webhookPayload),
                const SizedBox(height: 16),
                _codeBlock('Signature verification (Node.js)', _webhookVerifySnippet),
              ])),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _webhookEventsList(events),
              const SizedBox(height: 24),
              _codeBlock('Payload example', _webhookPayload),
              const SizedBox(height: 16),
              _codeBlock('Signature verification (Node.js)', _webhookVerifySnippet),
            ]),
        const SizedBox(height: 32),
        _infoBox(
          icon: Icons.verified_user_rounded,
          color: kPrimary,
          title: 'Signature verification',
          body: 'Every webhook request includes a TJ-Signature header. Compute\n'
              'HMAC-SHA256(payload_body, your_webhook_secret) and compare it to\n'
              'the header value. Reject any requests where they don\'t match.',
        ),
      ]),
    );
  }

  Widget _webhookEventsList(List<(String, String, Color)> events) => Column(
    children: events.map((e) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: e.$3.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(e.$1, style: GoogleFonts.jetBrainsMono(
              color: e.$3, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(e.$2,
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12))),
      ]),
    )).toList(),
  );

  Widget _codeBlock(String title, String code) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0D1A14),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Text(title, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11,
              fontWeight: FontWeight.w600)),
          const Spacer(),
          _CopyButton(code: code),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Text(code, style: GoogleFonts.jetBrainsMono(
            color: const Color(0xFFCDD6F4), fontSize: 11, height: 1.65)),
      ),
    ]),
  );

  // ─── SDKs ─────────────────────────────────────────────────────────────────
  Widget _sdks(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      key: _sdksKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDark,
      child: Column(children: [
        _SectionLabel(icon: Icons.code_rounded, label: 'SDKs'),
        const SizedBox(height: 16),
        Text('Official client libraries',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('All SDKs are open source and MIT-licensed.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 36),
        Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
          children: const [
            _SdkCard(name: 'Python', icon: Icons.code_rounded,
                install: 'pip install tippingjar', version: 'v1.4.0',
                lang: 'Python 3.8+'),
            _SdkCard(name: 'Node.js', icon: Icons.javascript_rounded,
                install: 'npm install @tippingjar/sdk', version: 'v1.6.2',
                lang: 'TypeScript ready'),
            _SdkCard(name: 'Dart / Flutter', icon: Icons.flutter_dash_rounded,
                install: 'tippingjar: ^1.2.0', version: 'v1.2.0',
                lang: 'Null-safe'),
            _SdkCard(name: 'Go', icon: Icons.terminal_rounded,
                install: 'go get github.com/tippingjar/go', version: 'v1.1.0',
                lang: 'Go 1.21+'),
          ],
        ),
      ]),
    );
  }

  // ─── Platform API ──────────────────────────────────────────────────────────
  Widget _platformApiSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const px = '''# Authenticate with your platform key
curl -H "X-Platform-Key: tj_platform_sk_v1_..." \\
  https://api.tippingjar.co.za/api/platform/creators/''';

    const py = '''import requests

PLATFORM_KEY = "tj_platform_sk_v1_..."
headers = {"X-Platform-Key": PLATFORM_KEY}

# List creators
creators = requests.get(
    "https://api.tippingjar.co.za/api/platform/creators/",
    headers=headers,
).json()

# Register an end-user
user = requests.post(
    "https://api.tippingjar.co.za/api/platform/users/",
    headers=headers,
    json={"email": "fan@example.com", "external_id": "usr_123"},
).json()

# Initiate a tip
tip = requests.post(
    "https://api.tippingjar.co.za/api/platform/tips/",
    headers=headers,
    json={
        "creator_slug": "john-doe",
        "amount": 50,
        "tipper_email": "fan@example.com",
    },
).json()''';

    const endpoints = [
      ('GET',  '/api/platform/me/',        'Get platform info + key prefix'),
      ('GET',  '/api/platform/creators/',  'List active creators (public)'),
      ('GET',  '/api/platform/users/',     'List end-users on this platform'),
      ('POST', '/api/platform/users/',     'Register or update an end-user'),
      ('POST', '/api/platform/tips/',      'Initiate a tip as a platform user'),
    ];

    return Container(
      key: _platformApiKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDarker,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.api_rounded, label: 'Platform API'),
        const SizedBox(height: 16),
        Text('Embed tipping in your app',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'The Platform API lets third-party applications integrate TippingJar tipping without '
            'requiring end-users to create TippingJar accounts directly. Authenticate requests '
            'using the X-Platform-Key header. Each platform has its own isolated user pool and '
            'rate limit envelope.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.65),
          ),
        ),
        const SizedBox(height: 32),

        // Key format card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.key_rounded, color: kPrimary, size: 16),
              const SizedBox(width: 8),
              Text('Key format', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kDarker, borderRadius: BorderRadius.circular(8)),
              child: Text('X-Platform-Key: tj_platform_sk_v1_<32-char-hex>',
                  style: GoogleFonts.jetBrainsMono(color: kPrimary, fontSize: 13)),
            ),
            const SizedBox(height: 10),
            Text('Platform keys are generated once on approval and hashed server-side. '
                'Store them as environment secrets — they cannot be retrieved again.',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 32),

        // Endpoints table
        Text('Endpoints', style: GoogleFonts.dmSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3)),
        const SizedBox(height: 14),
        ...endpoints.map((ep) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardBg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (ep.$1 == 'GET' ? kPrimary : Colors.orange).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
              child: Text(ep.$1, style: GoogleFonts.jetBrainsMono(
                  color: ep.$1 == 'GET' ? kPrimary : Colors.orange,
                  fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(ep.$2, style: GoogleFonts.jetBrainsMono(
                color: Colors.white, fontSize: 12))),
            Text(ep.$3, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          ]),
        )),

        const SizedBox(height: 32),

        // Code examples
        _DevCodeBlock(
          tabs: const ['cURL', 'Python'],
          snippets: const [px, py],
          selectedIdx: _codeTab,
          onTab: (i) => setState(() => _codeTab = i),
        ),
      ]),
    );
  }

  // ─── Partner Program ──────────────────────────────────────────────────────
  Widget _partnerProgramSection(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      key: _partnerKey,
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 80),
      color: kDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(icon: Icons.handshake_rounded, label: 'Partner Program'),
        const SizedBox(height: 16),
        Text('Become a TippingJar partner',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8)),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'The Partner Program gives SA-registered businesses access to the Platform API '
            'and dedicated support. Applications are reviewed within 48 business hours.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 15, height: 1.65),
          ),
        ),
        const SizedBox(height: 36),
        Wrap(spacing: 20, runSpacing: 20, children: const [
          _RequirementCard(
            icon: Icons.business_rounded,
            title: 'SA-registered business',
            body: 'Your company must be registered with CIPC (Pty Ltd, CC, or NPC).',
          ),
          _RequirementCard(
            icon: Icons.description_rounded,
            title: 'Company documents',
            body: 'CIPC certificate, VAT letter, director ID, and bank confirmation letter.',
          ),
          _RequirementCard(
            icon: Icons.schedule_rounded,
            title: '48 h review',
            body: 'Our compliance team reviews every application within two business days.',
          ),
          _RequirementCard(
            icon: Icons.support_agent_rounded,
            title: 'Dedicated support',
            body: 'Approved partners receive a dedicated integration engineer contact.',
          ),
        ]),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary.withOpacity(0.08), const Color(0xFF14B8A6).withOpacity(0.06)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimary.withOpacity(0.25)),
          ),
          child: Column(children: [
            Text('Ready to apply?', style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Complete a short multi-step form with your business details.',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/partner-apply'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              label: Text('Apply for Platform API access',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary, foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─── CTA ──────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [kPrimary.withOpacity(0.08), kTeal.withOpacity(0.08)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kPrimary.withOpacity(0.2)),
    ),
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
        child: const Icon(Icons.api_rounded, color: Colors.white, size: 24),
      ),
      const SizedBox(height: 20),
      Text('Start building today',
          style: GoogleFonts.dmSans(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Free sandbox environment · No credit card required · ZAR currency ready',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 15),
          textAlign: TextAlign.center),
      const SizedBox(height: 32),
      Wrap(spacing: 14, runSpacing: 12, alignment: WrapAlignment.center, children: [
        ElevatedButton(
          onPressed: () => context.go('/register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            elevation: 0, shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('Get your API key',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
                  fontSize: 15, color: Colors.white)),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('View on GitHub',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ]),
    ]),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
    child: Column(children: [
      Text('© 2026 TippingJar · tippingjar.co.za · support@tippingjar.co.za',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 12),
          textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text('API v1  ·  All amounts in ZAR  ·  HTTPS only',
          style: GoogleFonts.dmSans(color: kMuted.withOpacity(0.6), fontSize: 11),
          textAlign: TextAlign.center),
    ]),
  );

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _infoBox({required IconData icon, required Color color,
      required String title, required String body}) =>
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(title, style: GoogleFonts.dmSans(
              color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: GoogleFonts.jetBrainsMono(
              color: kMuted, fontSize: 12, height: 1.6)),
        ])),
      ]),
    );

  Widget _jsonBlock(String code) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF060A08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(code, style: GoogleFonts.jetBrainsMono(
        color: const Color(0xFFCDD6F4), fontSize: 11, height: 1.65)),
  );
}

// ─── Small stateless helpers ──────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: kPrimary, size: 15),
      const SizedBox(width: 8),
      Text(label.toUpperCase(),
          style: GoogleFonts.dmSans(color: kPrimary, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.4)),
    ]);
}

class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _GroupHeader({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kPrimary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kPrimary.withOpacity(0.15)),
    ),
    child: Row(children: [
      Icon(icon, color: kPrimary, size: 18),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 15)),
        Text(desc, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
      ]),
    ]),
  );
}

class _AuthStepCard extends StatelessWidget {
  final String step, title, desc;
  final IconData icon;
  const _AuthStepCard({required this.step, required this.icon,
      required this.title, required this.desc});
  @override
  Widget build(BuildContext context) => Container(
    width: 210,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kPrimary, size: 16),
        ),
        const Spacer(),
        Text(step, style: GoogleFonts.jetBrainsMono(
            color: kMuted, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 12),
      Text(title, style: GoogleFonts.dmSans(color: Colors.white,
          fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 5),
      Text(desc, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.5)),
    ]),
  );
}

class _RateLimitCard extends StatelessWidget {
  final IconData icon;
  final String tier, limit, scope;
  const _RateLimitCard({required this.icon, required this.tier,
      required this.limit, required this.scope});
  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: kPrimary, size: 22),
      const SizedBox(height: 12),
      Text(limit, style: GoogleFonts.dmSans(
          color: kPrimary, fontWeight: FontWeight.w800, fontSize: 22,
          letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(tier, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 2),
      Text(scope, style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
    ]),
  );
}

class _ExpandableEndpoint extends StatelessWidget {
  final String id, method, path, desc;
  final bool auth, expanded;
  final Widget? requestBody, responseBody;
  final VoidCallback onToggle;

  const _ExpandableEndpoint({
    required this.id, required this.method, required this.path,
    required this.desc, required this.auth, required this.expanded,
    required this.onToggle, this.requestBody, this.responseBody,
  });

  Color get _methodColor => switch (method) {
    'GET'    => const Color(0xFF4ADE80),
    'POST'   => const Color(0xFF60A5FA),
    'PATCH'  => const Color(0xFFFBBF24),
    'DELETE' => const Color(0xFFF87171),
    _        => kMuted,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFF0F1F18) : kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: expanded ? kPrimary.withOpacity(0.3) : kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: _methodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(method, style: GoogleFonts.jetBrainsMono(
                    color: _methodColor, fontSize: 10,
                    fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(path, style: GoogleFonts.jetBrainsMono(
                    color: Colors.white, fontSize: 12)),
              ),
              if (auth) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: kTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kTeal.withOpacity(0.3)),
                  ),
                  child: Text('Auth', style: GoogleFonts.dmSans(
                      color: kTeal, fontSize: 9, fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
                ),
              ],
              const SizedBox(width: 12),
              Flexible(child: Text(desc, style: GoogleFonts.dmSans(
                  color: kMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Icon(expanded ? Icons.keyboard_arrow_up_rounded
                           : Icons.keyboard_arrow_down_rounded,
                  color: kMuted, size: 18),
            ]),
          ),
        ),
        if (expanded) ...[
          Container(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (requestBody != null) ...[
                Text('Request body',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                requestBody!,
                const SizedBox(height: 16),
              ],
              if (responseBody != null) ...[
                Text('Response',
                    style: GoogleFonts.dmSans(color: kMuted, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                responseBody!,
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.dmSans(
        color: kPrimary, fontWeight: FontWeight.w900,
        fontSize: 24, letterSpacing: -0.5)),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
  ]);
}

class _SdkCard extends StatelessWidget {
  final String name, install, version, lang;
  final IconData icon;
  const _SdkCard({required this.name, required this.icon,
      required this.install, required this.version, required this.lang});
  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: kPrimary, size: 18),
        ),
        const Spacer(),
        Text(version, style: GoogleFonts.jetBrainsMono(
            color: kMuted, fontSize: 10)),
      ]),
      const SizedBox(height: 12),
      Text(name, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 3),
      Text(lang, style: GoogleFonts.dmSans(color: kMuted, fontSize: 11)),
      const SizedBox(height: 8),
      Text(install, style: GoogleFonts.jetBrainsMono(color: kPrimary, fontSize: 10)),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: kBorder),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('View on GitHub',
              style: GoogleFonts.dmSans(color: Colors.white,
                  fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    ]),
  );
}

class _CopyButton extends StatefulWidget {
  final String code;
  const _CopyButton({required this.code});
  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _copy,
    child: AnimatedContainer(
      duration: 200.ms,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _copied ? kPrimary.withOpacity(0.15) : kCardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _copied ? kPrimary : kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
            color: _copied ? kPrimary : kMuted, size: 12),
        const SizedBox(width: 4),
        Text(_copied ? 'Copied!' : 'Copy',
            style: GoogleFonts.dmSans(
                color: _copied ? kPrimary : kMuted,
                fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── Live API Key Panel ───────────────────────────────────────────────────────

class _ApiKeyPanel extends StatefulWidget {
  final AuthProvider auth;
  const _ApiKeyPanel({required this.auth});
  @override
  State<_ApiKeyPanel> createState() => _ApiKeyPanelState();
}

class _ApiKeyPanelState extends State<_ApiKeyPanel> {
  List<ApiKeyModel> _keys = [];
  bool _loading = false;
  String? _error;
  // key just created — shown once with full value visible
  ApiKeyModel? _newKey;

  @override
  void initState() {
    super.initState();
    if (widget.auth.isAuthenticated) _loadKeys();
  }

  @override
  void didUpdateWidget(_ApiKeyPanel old) {
    super.didUpdateWidget(old);
    if (!old.auth.isAuthenticated && widget.auth.isAuthenticated) _loadKeys();
  }

  Future<void> _loadKeys() async {
    setState(() { _loading = true; _error = null; });
    try {
      final keys = await widget.auth.api.getApiKeys();
      if (mounted) setState(() { _keys = keys; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createKey(String name) async {
    setState(() { _loading = true; _error = null; });
    try {
      final key = await widget.auth.api.createApiKey(name);
      if (mounted) setState(() {
        _newKey = key;
        _keys.insert(0, key);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _revoke(ApiKeyModel key) async {
    setState(() => _loading = true);
    try {
      await widget.auth.api.revokeApiKey(key.id);
      if (mounted) setState(() {
        _keys.removeWhere((k) => k.id == key.id);
        if (_newKey?.id == key.id) _newKey = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController(text: 'My Key');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kBorder)),
        title: Text('New API Key',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Give this key a name to identify it later.',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            style: GoogleFonts.dmSans(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Production Server',
              hintStyle: GoogleFonts.dmSans(color: kMuted),
              filled: true, fillColor: const Color(0xFF0D1A14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kPrimary)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: kMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createKey(ctrl.text.trim().isEmpty ? 'My Key' : ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Generate', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.auth.isAuthenticated) return _unauthPanel(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.vpn_key_rounded, color: kPrimary, size: 16),
          ),
          const SizedBox(width: 10),
          Text('API Keys',
              style: GoogleFonts.dmSans(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          if (_loading) const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
        ]),
        const SizedBox(height: 6),
        Text('Keys authenticate API requests. Never share them publicly.',
            style: GoogleFonts.dmSans(color: kMuted, fontSize: 12, height: 1.5)),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF87171).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
            ),
            child: Text(_error!, style: GoogleFonts.dmSans(
                color: const Color(0xFFF87171), fontSize: 12)),
          ),
        ],

        // "New key" reveal banner — shown once after creation
        if (_newKey != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning_amber_rounded, color: kPrimary, size: 14),
                const SizedBox(width: 6),
                Text('Copy this key now — it won\'t be shown again',
                    style: GoogleFonts.dmSans(color: kPrimary, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF060A08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kPrimary.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Expanded(child: Text(_newKey!.rawKey ?? '',
                      style: GoogleFonts.jetBrainsMono(
                          color: kPrimary, fontSize: 10),
                      overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  _CopyButton(code: _newKey!.rawKey ?? ''),
                ]),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _newKey = null),
                child: Text('Dismiss', style: GoogleFonts.dmSans(
                    color: kMuted, fontSize: 11,
                    decoration: TextDecoration.underline,
                    decorationColor: kMuted)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 14),

        // Keys list
        if (_keys.isEmpty && !_loading)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No API keys yet. Generate one below.',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 12)),
          ))
        else
          ..._keys.map((k) => _KeyRow(key_: k, onRevoke: () => _revoke(k))),

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _showCreateDialog,
            icon: const Icon(Icons.add_rounded, size: 15, color: Colors.white),
            label: Text('Generate new key',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
                    fontSize: 13, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _unauthPanel(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.lock_rounded, color: kPrimary, size: 16),
        ),
        const SizedBox(width: 10),
        Text('API Keys',
            style: GoogleFonts.dmSans(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
      const SizedBox(height: 10),
      Text('Sign in to generate and manage your API keys.',
          style: GoogleFonts.dmSans(color: kMuted, fontSize: 13, height: 1.5)),
      const SizedBox(height: 16),
      // Demo key preview (redacted)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1A14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          const Icon(Icons.vpn_key_rounded, color: kMuted, size: 14),
          const SizedBox(width: 10),
          Text('tj_live_sk_v1_••••••••••••••••••••',
              style: GoogleFonts.jetBrainsMono(color: kMuted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary, foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Sign in',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/register'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Register',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ]),
    ]),
  );
}

class _KeyRow extends StatelessWidget {
  final ApiKeyModel key_;
  final VoidCallback onRevoke;
  const _KeyRow({required this.key_, required this.onRevoke});

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(key_.name, style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(key_.prefix, style: GoogleFonts.jetBrainsMono(
              color: kMuted, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Created ${_formatDate(key_.createdAt)}',
              style: GoogleFonts.dmSans(color: kMuted, fontSize: 10)),
          if (key_.lastUsedAt != null)
            Text('Last used ${_formatDate(key_.lastUsedAt!)}',
                style: GoogleFonts.dmSans(color: kMuted, fontSize: 10)),
        ]),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRevoke,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF87171).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
            ),
            child: Text('Revoke', style: GoogleFonts.dmSans(
                color: const Color(0xFFF87171), fontSize: 10,
                fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ─── Code snippets ────────────────────────────────────────────────────────────

// Auth snippets
const _authCurl = r'''# Step 1 — Obtain token pair
curl -X POST https://api.tippingjar.co.za/v1/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "janedoe", "password": "SuperSecret123"}'

# Response:
# { "access": "eyJ...", "refresh": "eyJ...", "user": { ... } }

# Step 2 — Use the access token
curl https://api.tippingjar.co.za/v1/creators/me/ \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Step 3 — Refresh when expired (60 min TTL)
curl -X POST https://api.tippingjar.co.za/v1/auth/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{"refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}'
''';

const _authPython = r'''import requests

BASE = "https://api.tippingjar.co.za/v1"

# Authenticate
resp = requests.post(f"{BASE}/auth/token/", json={
    "username": "janedoe",
    "password": "SuperSecret123",
})
tokens = resp.json()
access  = tokens["access"]
refresh = tokens["refresh"]

# Make authenticated requests
headers = {"Authorization": f"Bearer {access}"}
profile = requests.get(f"{BASE}/creators/me/", headers=headers).json()
print(profile["display_name"])  # → Jane Creates

# Refresh token when expired
new_tokens = requests.post(f"{BASE}/auth/token/refresh/", json={
    "refresh": refresh,
}).json()
access = new_tokens["access"]
''';

const _authNode = r'''import axios from "axios";

const BASE = "https://api.tippingjar.co.za/v1";

// Authenticate
const { data: tokens } = await axios.post(`${BASE}/auth/token/`, {
  username: "janedoe",
  password: "SuperSecret123",
});

const { access, refresh } = tokens;

// Make authenticated requests
const client = axios.create({
  baseURL: BASE,
  headers: { Authorization: `Bearer ${access}` },
});

const { data: profile } = await client.get("/creators/me/");
console.log(profile.display_name); // → Jane Creates

// Auto-refresh on 401
client.interceptors.response.use(null, async (error) => {
  if (error.response?.status === 401) {
    const { data } = await axios.post(`${BASE}/auth/token/refresh/`, { refresh });
    error.config.headers.Authorization = `Bearer ${data.access}`;
    return axios(error.config);
  }
  return Promise.reject(error);
});
''';

// Quick-start snippets (tip creation)
const _curlSnippet = r'''# 1. Get your access token
curl -X POST https://api.tippingjar.co.za/v1/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{"username": "janedoe", "password": "SuperSecret123"}'

# 2. Send a tip (sandbox — no Stripe key required)
curl -X POST https://api.tippingjar.co.za/v1/tips/initiate/ \
  -H "Content-Type: application/json" \
  -d '{
    "creator_slug": "jane-creates",
    "amount": 50.00,
    "message": "Love your work!",
    "tipper_name": "BigFan"
  }'

# Response (sandbox)
{
  "success": true,
  "tip_id": 123,
  "amount": "50.00",
  "creator_name": "Jane Creates"
}''';

const _pythonSnippet = r'''import requests

BASE = "https://api.tippingjar.co.za/v1"

# Authenticate first
tokens = requests.post(f"{BASE}/auth/token/", json={
    "username": "janedoe", "password": "SuperSecret123",
}).json()

headers = {"Authorization": f"Bearer {tokens['access']}"}

# Send a tip
tip = requests.post(f"{BASE}/tips/initiate/", json={
    "creator_slug": "jane-creates",
    "amount": 50.00,       # ZAR
    "message": "Love your work!",
    "tipper_name": "BigFan",
    # "jar_id": 7,         # optional — tip into a specific jar
}).json()

print(tip["tip_id"])  # → 123
''';

const _nodeSnippet = r'''import axios from "axios";

const BASE = "https://api.tippingjar.co.za/v1";

// Authenticate
const { data: { access } } = await axios.post(`${BASE}/auth/token/`, {
  username: "janedoe", password: "SuperSecret123",
});

// Send a tip
const { data: tip } = await axios.post(`${BASE}/tips/initiate/`, {
  creatorSlug: "jane-creates",
  amount: 50.00,         // ZAR
  message: "Love your work!",
  tipperName: "BigFan",
  // jarId: 7,           // optional
}, {
  headers: { Authorization: `Bearer ${access}` },
});

console.log(tip.tip_id); // → 123
''';

const _dartSnippet = r'''import 'package:http/http.dart' as http;
import 'dart:convert';

const base = 'https://api.tippingjar.co.za/v1';

// Authenticate
final authRes = await http.post(
  Uri.parse('$base/auth/token/'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'username': 'janedoe', 'password': 'SuperSecret123'}),
);
final access = jsonDecode(authRes.body)['access'] as String;

// Send a tip
final tipRes = await http.post(
  Uri.parse('$base/tips/initiate/'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $access',
  },
  body: jsonEncode({
    'creator_slug': 'jane-creates',
    'amount': 50.00,      // ZAR
    'message': 'Love your work!',
    'tipper_name': 'BigFan',
    // 'jar_id': 7,       // optional
  }),
);
final tip = jsonDecode(tipRes.body);
print(tip['tip_id']); // → 123
''';

// Webhook snippets
const _webhookPayload = '''{
  "id": "evt_01HXYZ3Qf8TzKYlo2C1Bx",
  "type": "tip.completed",
  "created": 1740481200,
  "livemode": true,
  "data": {
    "tip": {
      "id": 123,
      "amount": "50.00",
      "currency": "zar",
      "message": "Love your work!",
      "status": "completed",
      "jar": null,
      "creator": {
        "slug": "jane-creates",
        "display_name": "Jane Creates"
      },
      "tipper_name": "BigFan",
      "created_at": "2026-02-21T08:20:00Z"
    }
  }
}''';

const _webhookVerifySnippet = r'''import crypto from "crypto";

function verifyWebhook(rawBody, signature, secret) {
  const expected = crypto
    .createHmac("sha256", secret)
    .update(rawBody, "utf8")
    .digest("hex");

  // Constant-time comparison to prevent timing attacks
  return crypto.timingSafeEqual(
    Buffer.from(expected, "hex"),
    Buffer.from(signature, "hex"),
  );
}

// Express example
app.post("/webhook/tippingjar", express.raw({ type: "*/*" }), (req, res) => {
  const sig = req.headers["tj-signature"];
  if (!verifyWebhook(req.body, sig, process.env.WEBHOOK_SECRET)) {
    return res.status(401).send("Invalid signature");
  }
  const event = JSON.parse(req.body);
  if (event.type === "tip.completed") {
    console.log("Tip received:", event.data.tip.amount, "ZAR");
  }
  res.sendStatus(200);
});
''';

const _errorShape = '''{
  "detail": "Authentication credentials were not provided.",

  // Validation errors (HTTP 422) include field-level details:
  "errors": {
    "amount": ["Ensure this value is greater than or equal to 1."],
    "creator_slug": ["This field is required."]
  },

  // Rate limit errors (HTTP 429) include:
  "retry_after": 42   // seconds until limit resets
}''';

// ── Shared widget: tabbed code block ──────────────────────────────────────────
class _DevCodeBlock extends StatelessWidget {
  final List<String> tabs;
  final List<String> snippets;
  final int selectedIdx;
  final ValueChanged<int> onTab;

  const _DevCodeBlock({
    required this.tabs,
    required this.snippets,
    required this.selectedIdx,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    final idx = selectedIdx.clamp(0, tabs.length - 1);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder))),
          child: Row(children: [
            ...tabs.asMap().entries.map((e) => GestureDetector(
              onTap: () => onTab(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(
                    color: idx == e.key ? kPrimary : Colors.transparent, width: 2)),
                ),
                child: Text(e.value,
                    style: GoogleFonts.jetBrainsMono(
                        color: idx == e.key ? kPrimary : kMuted,
                        fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            )),
            const Spacer(),
            _CopyButton(code: snippets[idx]),
            const SizedBox(width: 12),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(20),
          child: Text(snippets[idx],
              style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFCDD6F4), fontSize: 12, height: 1.75)),
        ),
      ]),
    );
  }
}

// ── Shared widget: requirement card ──────────────────────────────────────────
class _RequirementCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _RequirementCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kPrimary, size: 18),
      ),
      const SizedBox(height: 14),
      Text(title, style: GoogleFonts.dmSans(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 6),
      Text(body, style: GoogleFonts.dmSans(
          color: kMuted, fontSize: 12, height: 1.55)),
    ]),
  );
}
