import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_nav.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});
  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  int _codeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      appBar: AppNav(activeRoute: '/developers'),
      body: SingleChildScrollView(
        child: Column(children: [
          _hero(context),
          _quickstart(context),
          _endpoints(context),
          _sdks(),
          _webhooks(context),
          _cta(context),
          _footer(),
        ]),
      ),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _hero(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
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
          child: Text('Developers',
              style: GoogleFonts.inter(
                  color: kPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        Text('Build on top of\nTippingJar',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: w > 700 ? 56 : 36,
                letterSpacing: -2,
                height: 1.05),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 80.ms, duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            'A simple, powerful REST API to create tip flows, manage payouts, and react to events with webhooks. Start in minutes.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 18, height: 1.65),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 160.ms, duration: 500.ms),
        ),
        const SizedBox(height: 40),
        Wrap(spacing: 14, runSpacing: 12, alignment: WrapAlignment.center, children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0, shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Read the docs',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: kBorder),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
            ),
            child: Text('Get API key',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ]).animate().fadeIn(delay: 240.ms, duration: 500.ms),
        const SizedBox(height: 56),

        // Inline stat strip
        Wrap(spacing: 40, runSpacing: 20, alignment: WrapAlignment.center,
          children: [
            _Stat(value: '< 200ms', label: 'Median latency'),
            _Stat(value: '99.99%', label: 'API uptime'),
            _Stat(value: '5 min', label: 'Avg. integration time'),
            _Stat(value: 'Free', label: 'Sandbox environment'),
          ],
        ).animate().fadeIn(delay: 320.ms, duration: 500.ms),
      ]),
    );
  }

  // ─── Quick-start code block ────────────────────────────────────────────────
  Widget _quickstart(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final tabs = ['cURL', 'Python', 'Node.js', 'Dart'];
    final snippets = [
      _curlSnippet,
      _pythonSnippet,
      _nodeSnippet,
      _dartSnippet,
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: kDark,
      child: Column(children: [
        Text('Up and running in 5 minutes',
            style: GoogleFonts.inter(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 10),
        Text('Create a tip payment intent with a single API call.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1A14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Tab bar
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorder)),
                ),
                child: Row(children: [
                  ...tabs.asMap().entries.map((e) => GestureDetector(
                    onTap: () => setState(() => _codeTab = e.key),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _codeTab == e.key ? kPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
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
              // Code
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                child: Text(snippets[_codeTab],
                    style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFFCDD6F4),
                        fontSize: 13, height: 1.7)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── API endpoints reference ───────────────────────────────────────────────
  Widget _endpoints(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final routes = [
      ('POST',   '/api/tips/initiate',          'Create a PaymentIntent for a tip'),
      ('GET',    '/api/creators/{slug}',         'Fetch a creator profile'),
      ('GET',    '/api/creators/{slug}/tips',    'List recent tips for a creator'),
      ('POST',   '/api/users/register',          'Register a new user'),
      ('POST',   '/api/auth/token',              'Obtain a JWT access token'),
      ('POST',   '/api/auth/token/refresh',      'Refresh an access token'),
      ('GET',    '/api/creators/me',             'Get authenticated creator profile'),
      ('PATCH',  '/api/creators/me',             'Update creator profile'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: kDarker,
      child: Column(children: [
        Text('API reference',
            style: GoogleFonts.inter(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text('Base URL: https://api.tippingjar.io/v1',
            style: GoogleFonts.jetBrainsMono(color: kPrimary, fontSize: 13)),
        const SizedBox(height: 40),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: routes.asMap().entries.map((e) =>
              _EndpointRow(
                method: e.value.$1,
                path: e.value.$2,
                desc: e.value.$3,
                delay: 40 * e.key,
              ),
            ).toList(),
          ),
        ),
      ]),
    );
  }

  // ─── SDKs ──────────────────────────────────────────────────────────────────
  Widget _sdks() => Container(
    padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 28),
    color: kDark,
    child: Column(children: [
      Text('Official SDKs',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -0.8),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('All SDKs are open source and MIT-licensed.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 36),
      Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
        children: [
          _SdkCard(name: 'Python', icon: Icons.code_rounded,
              desc: 'pip install tippingjar', version: 'v1.4.0'),
          _SdkCard(name: 'Node.js', icon: Icons.javascript_rounded,
              desc: 'npm install @tippingjar/sdk', version: 'v1.6.2'),
          _SdkCard(name: 'Dart / Flutter', icon: Icons.flutter_dash_rounded,
              desc: 'tippingjar: ^1.2.0', version: 'v1.2.0'),
          _SdkCard(name: 'Go', icon: Icons.terminal_rounded,
              desc: 'go get github.com/tippingjar/go', version: 'v1.1.0'),
        ],
      ),
    ]),
  );

  // ─── Webhooks ──────────────────────────────────────────────────────────────
  Widget _webhooks(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final events = [
      ('tip.completed',    'Fires when a tip payment succeeds.'),
      ('tip.failed',       'Fires when a payment attempt fails.'),
      ('tip.refunded',     'Fires when a tip is refunded.'),
      ('creator.created',  'New creator profile created.'),
      ('payout.initiated', 'Stripe initiates a bank transfer.'),
      ('payout.completed', 'Payout arrives in creator\'s account.'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w > 900 ? 80 : 28, vertical: 72),
      color: kDarker,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Webhooks',
            style: GoogleFonts.inter(color: Colors.white,
                fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text('React to real-time events using signed HTTPS webhooks.',
            style: GoogleFonts.inter(color: kMuted, fontSize: 16),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Events list
            Expanded(
              child: Column(
                children: events.map((e) =>
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(e.$1,
                            style: GoogleFonts.jetBrainsMono(
                                color: kPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.$2,
                          style: GoogleFonts.inter(color: kMuted, fontSize: 13))),
                    ]),
                  ),
                ).toList(),
              ),
            ),
            if (w > 800) ...[
              const SizedBox(width: 32),
              // Webhook payload example
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1A14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: kBorder)),
                      ),
                      child: Row(children: [
                        Text('Payload example',
                            style: GoogleFonts.inter(
                                color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _CopyButton(code: _webhookPayload),
                      ]),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      child: Text(_webhookPayload,
                          style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFFCDD6F4),
                              fontSize: 12, height: 1.65)),
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ]),
    );
  }

  // ─── CTA ───────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kBorder),
    ),
    child: Column(children: [
      Container(
        width: 56, height: 56,
        decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
        child: const Icon(Icons.api_rounded, color: Colors.white, size: 24),
      ),
      const SizedBox(height: 20),
      Text('Start building today',
          style: GoogleFonts.inter(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -1),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Free sandbox, no credit card required.',
          style: GoogleFonts.inter(color: kMuted, fontSize: 16),
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
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('View GitHub',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ]),
    ]),
  );

  Widget _footer() => Container(
    color: kDarker,
    padding: const EdgeInsets.all(24),
    child: const Text('© 2026 TippingJar. All rights reserved.',
        style: TextStyle(color: kMuted, fontSize: 12),
        textAlign: TextAlign.center),
  );
}

// ─── Code snippets ────────────────────────────────────────────────────────────
const _curlSnippet = r'''curl -X POST https://api.tippingjar.io/v1/tips/initiate \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "creator_slug": "jenna-art",
    "amount": 500,
    "currency": "usd",
    "message": "Love your work! 🎨"
  }'

# Response
{
  "client_secret": "pi_3Qf8Tz2eZvKYlo..._secret_...",
  "payment_intent_id": "pi_3Qf8Tz2eZvKYlo...",
  "amount": 500,
  "currency": "usd",
  "status": "requires_payment_method"
}''';

const _pythonSnippet = r'''import tippingjar

client = tippingjar.Client(api_key="YOUR_API_KEY")

intent = client.tips.initiate(
    creator_slug="jenna-art",
    amount=500,          # in cents
    currency="usd",
    message="Love your work! 🎨",
)

print(intent.client_secret)
# → pi_3Qf8Tz2eZvKYlo..._secret_...''';

const _nodeSnippet = r'''import TippingJar from "@tippingjar/sdk";

const client = new TippingJar({ apiKey: "YOUR_API_KEY" });

const intent = await client.tips.initiate({
  creatorSlug: "jenna-art",
  amount: 500,       // in cents
  currency: "usd",
  message: "Love your work! 🎨",
});

console.log(intent.clientSecret);
// → pi_3Qf8Tz2eZvKYlo..._secret_...''';

const _dartSnippet = r'''import 'package:tippingjar/tippingjar.dart';

final client = TippingJar(apiKey: 'YOUR_API_KEY');

final intent = await client.tips.initiate(
  creatorSlug: 'jenna-art',
  amount: 500,      // in cents
  currency: 'usd',
  message: 'Love your work! 🎨',
);

print(intent.clientSecret);
// → pi_3Qf8Tz2eZvKYlo..._secret_...''';

const _webhookPayload = '''{
  "id": "evt_3Qf8Tz2eZvKYlo2C1K9Bx",
  "type": "tip.completed",
  "created": 1708432800,
  "data": {
    "tip": {
      "id": "tip_abc123",
      "amount": 500,
      "currency": "usd",
      "message": "Love your work! 🎨",
      "status": "completed",
      "creator": {
        "slug": "jenna-art",
        "username": "jenna"
      },
      "tipper": {
        "username": "fan_user"
      }
    }
  }
}''';

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.inter(
        color: kPrimary, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.inter(color: kMuted, fontSize: 13)),
  ]);
}

class _EndpointRow extends StatelessWidget {
  final String method, path, desc;
  final int delay;
  const _EndpointRow({required this.method, required this.path,
      required this.desc, required this.delay});

  Color get _methodColor => switch (method) {
    'GET'   => const Color(0xFF4ADE80),
    'POST'  => const Color(0xFF60A5FA),
    'PATCH' => const Color(0xFFFBBF24),
    _       => kMuted,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 52,
          child: Text(method,
              style: GoogleFonts.jetBrainsMono(
                  color: _methodColor, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(path,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13))),
        const SizedBox(width: 12),
        Text(desc, style: GoogleFonts.inter(color: kMuted, fontSize: 12)),
      ]),
    ).animate().fadeIn(delay: delay.ms, duration: 300.ms);
  }
}

class _SdkCard extends StatelessWidget {
  final String name, desc, version;
  final IconData icon;
  const _SdkCard({required this.name, required this.icon,
      required this.desc, required this.version});
  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCardBg,
      borderRadius: BorderRadius.circular(16),
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
        Text(version,
            style: GoogleFonts.jetBrainsMono(color: kMuted, fontSize: 11)),
      ]),
      const SizedBox(height: 12),
      Text(name, style: GoogleFonts.inter(
          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 6),
      Text(desc, style: GoogleFonts.jetBrainsMono(color: kMuted, fontSize: 11)),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: kBorder),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
          ),
          child: Text('View on GitHub',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
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
            color: _copied ? kPrimary : kMuted, size: 13),
        const SizedBox(width: 5),
        Text(_copied ? 'Copied!' : 'Copy',
            style: GoogleFonts.inter(
                color: _copied ? kPrimary : kMuted,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
