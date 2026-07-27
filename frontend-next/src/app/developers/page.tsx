"use client";

import Link from "next/link";
import { useState } from "react";

const BASE_URL = "https://api.tippingjar.co.za/v1";

/* ─── Code snippets ──────────────────────────────────────────────────────── */

const AUTH_CURL = `# Step 1 — Obtain token pair
curl -X POST https://api.tippingjar.co.za/v1/auth/token/ \\
  -H "Content-Type: application/json" \\
  -d '{"username": "janedoe", "password": "SuperSecret123"}'

# Response:
# { "access": "eyJ...", "refresh": "eyJ...", "user": { ... } }

# Step 2 — Use the access token
curl https://api.tippingjar.co.za/v1/creators/me/ \\
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Step 3 — Refresh when expired (60 min TTL)
curl -X POST https://api.tippingjar.co.za/v1/auth/token/refresh/ \\
  -H "Content-Type: application/json" \\
  -d '{"refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}'`;

const AUTH_PYTHON = `import requests

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
access = new_tokens["access"]`;

const AUTH_NODE = `import axios from "axios";

const BASE = "https://api.tippingjar.co.za/v1";

// Authenticate
const { data: tokens } = await axios.post(\`\${BASE}/auth/token/\`, {
  username: "janedoe",
  password: "SuperSecret123",
});

const { access, refresh } = tokens;

// Make authenticated requests
const client = axios.create({
  baseURL: BASE,
  headers: { Authorization: \`Bearer \${access}\` },
});

const { data: profile } = await client.get("/creators/me/");
console.log(profile.display_name); // → Jane Creates

// Auto-refresh on 401
client.interceptors.response.use(null, async (error) => {
  if (error.response?.status === 401) {
    const { data } = await axios.post(\`\${BASE}/auth/token/refresh/\`, { refresh });
    error.config.headers.Authorization = \`Bearer \${data.access}\`;
    return axios(error.config);
  }
  return Promise.reject(error);
});`;

const CURL_SNIPPET = `# 1. Get your access token
curl -X POST https://api.tippingjar.co.za/v1/auth/token/ \\
  -H "Content-Type: application/json" \\
  -d '{"username": "janedoe", "password": "SuperSecret123"}'

# 2. Send a tip (sandbox — no Stripe key required)
curl -X POST https://api.tippingjar.co.za/v1/tips/initiate/ \\
  -H "Content-Type: application/json" \\
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
}`;

const PYTHON_SNIPPET = `import requests

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

print(tip["tip_id"])  # → 123`;

const NODE_SNIPPET = `import axios from "axios";

const BASE = "https://api.tippingjar.co.za/v1";

// Authenticate
const { data: { access } } = await axios.post(\`\${BASE}/auth/token/\`, {
  username: "janedoe", password: "SuperSecret123",
});

// Send a tip
const { data: tip } = await axios.post(\`\${BASE}/tips/initiate/\`, {
  creatorSlug: "jane-creates",
  amount: 50.00,         // ZAR
  message: "Love your work!",
  tipperName: "BigFan",
  // jarId: 7,           // optional
}, {
  headers: { Authorization: \`Bearer \${access}\` },
});

console.log(tip.tip_id); // → 123`;

const DART_SNIPPET = `import 'package:http/http.dart' as http;
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
print(tip['tip_id']); // → 123`;

const WEBHOOK_PAYLOAD = `{
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
}`;

const WEBHOOK_VERIFY = `import crypto from "crypto";

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
});`;

const ERROR_SHAPE = `{
  "detail": "Authentication credentials were not provided.",

  // Validation errors (HTTP 422) include field-level details:
  "errors": {
    "amount": ["Ensure this value is greater than or equal to 1."],
    "creator_slug": ["This field is required."]
  },

  // Rate limit errors (HTTP 429) include:
  "retry_after": 42   // seconds until limit resets
}`;

const PLATFORM_CURL = `# Authenticate with your platform key
curl -H "X-Platform-Key: tj_platform_sk_v1_..." \\
  https://api.tippingjar.co.za/api/platform/creators/`;

const PLATFORM_PYTHON = `import requests

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
).json()`;

/* ─── Data ───────────────────────────────────────────────────────────────── */

interface Endpoint {
  method: "GET" | "POST" | "PATCH" | "DELETE";
  path: string;
  desc: string;
  auth: boolean;
  request?: string;
  response: string;
}

interface Group {
  icon: string;
  title: string;
  desc: string;
  endpoints: Endpoint[];
}

const GROUPS: Group[] = [
  {
    icon: "bi-shield-lock-fill",
    title: "Authentication",
    desc: "Obtain and refresh JWT access tokens.",
    endpoints: [
      {
        method: "POST",
        path: "/api/auth/token/",
        desc: "Obtain JWT token pair (access + refresh)",
        auth: false,
        request: `{
  "username": "janedoe",
  "password": "SuperSecret123"
}`,
        response: `{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 42,
    "username": "janedoe",
    "email": "jane@example.com",
    "role": "creator"
  }
}`,
      },
      {
        method: "POST",
        path: "/api/auth/token/refresh/",
        desc: "Exchange a refresh token for a new access token",
        auth: false,
        request: `{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}`,
        response: `{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}`,
      },
      {
        method: "POST",
        path: "/api/users/register/",
        desc: "Register a new user account",
        auth: false,
        request: `{
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "SuperSecret123",
  "role": "creator"    // "creator" | "fan"
}`,
        response: `{
  "id": 42,
  "username": "janedoe",
  "email": "jane@example.com",
  "role": "creator",
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}`,
      },
    ],
  },
  {
    icon: "bi-person-fill",
    title: "Creators",
    desc: "Manage creator profiles and retrieve public data.",
    endpoints: [
      {
        method: "GET",
        path: "/api/creators/",
        desc: "List all active creator profiles",
        auth: false,
        response: `{
  "count": 128,
  "next": "${BASE_URL}/creators/?page=2",
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
}`,
      },
      {
        method: "GET",
        path: "/api/creators/me/",
        desc: "Retrieve the authenticated creator's own profile",
        auth: true,
        response: `{
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
}`,
      },
      {
        method: "PATCH",
        path: "/api/creators/me/",
        desc: "Update the authenticated creator's profile",
        auth: true,
        request: `{
  "display_name": "Jane Creates",
  "tagline": "Art that moves you",
  "tip_goal": "5000.00",
  "bank_name": "Nedbank",
  "bank_account_number": "1234567890",
  "bank_account_type": "savings",
  "bank_country": "ZA"
}`,
        response: `{ /* updated CreatorProfile object */ }`,
      },
      {
        method: "GET",
        path: "/api/creators/me/stats/",
        desc: "Dashboard stats — earnings, tip count, monthly progress",
        auth: true,
        response: `{
  "total_earned": "18740.00",
  "tips_this_month": 47,
  "earned_this_month": "3240.00",
  "tip_goal": "5000.00",
  "goal_progress_pct": 64.8,
  "top_tippers": [
    { "tipper_name": "SuperFan", "total": "1200.00" }
  ]
}`,
      },
      {
        method: "GET",
        path: "/api/creators/{slug}/",
        desc: "Fetch a public creator profile by slug",
        auth: false,
        response: `{
  "display_name": "Jane Creates",
  "slug": "jane-creates",
  "tagline": "Digital art & animations",
  "total_tips": "3240.00",
  "is_active": true
}`,
      },
    ],
  },
  {
    icon: "bi-piggy-bank-fill",
    title: "Jars",
    desc: "Campaign-specific tip jars with optional fundraising goals.",
    endpoints: [
      {
        method: "GET",
        path: "/api/creators/me/jars/",
        desc: "List all jars owned by the authenticated creator",
        auth: true,
        response: `{
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
}`,
      },
      {
        method: "POST",
        path: "/api/creators/me/jars/",
        desc: "Create a new jar (slug auto-generated from name)",
        auth: true,
        request: `{
  "name": "Studio Equipment Fund",
  "description": "Help me buy a new mic and camera.",
  "goal": "10000.00"       // optional
}`,
        response: `{ /* JarObject */ }`,
      },
      {
        method: "PATCH",
        path: "/api/creators/me/jars/{id}/",
        desc: "Update a jar — name, description, goal, or active status",
        auth: true,
        request: `{
  "name": "New Mic Fund",
  "goal": "5000.00",
  "is_active": false
}`,
        response: `{ /* updated JarObject */ }`,
      },
      {
        method: "DELETE",
        path: "/api/creators/me/jars/{id}/",
        desc: "Permanently delete a jar",
        auth: true,
        response: `HTTP 204 No Content`,
      },
      {
        method: "GET",
        path: "/api/creators/{slug}/jars/",
        desc: "List all active public jars for a creator",
        auth: false,
        response: `[ /* array of JarObjects */ ]`,
      },
      {
        method: "GET",
        path: "/api/creators/{slug}/jars/{jar_slug}/",
        desc: "Fetch a specific public jar by creator slug + jar slug",
        auth: false,
        response: `{
  "id": 7,
  "name": "Studio Equipment Fund",
  "slug": "studio-equipment-fund",
  "creator_slug": "jane-creates",
  "goal": "10000.00",
  "total_raised": "4320.00",
  "tip_count": 38,
  "progress_pct": 43.2
}`,
      },
    ],
  },
  {
    icon: "bi-cash-coin",
    title: "Tips",
    desc: "Initiate tip payments and retrieve tip history.",
    endpoints: [
      {
        method: "POST",
        path: "/api/tips/initiate/",
        desc: "Create a tip payment intent (Stripe) or complete tip in sandbox",
        auth: false,
        request: `{
  "creator_slug": "jane-creates",
  "amount": 50.00,            // ZAR
  "message": "Love your work!",
  "tipper_name": "Anonymous",  // optional
  "jar_id": 7                  // optional — attribute to a specific jar
}`,
        response: `{
  // Sandbox (no Stripe key configured):
  "success": true,
  "tip_id": 123,
  "amount": "50.00",
  "creator_name": "Jane Creates"

  // Production (Stripe enabled):
  "client_secret": "pi_3Qf8Tz2eZvKYlo..._secret_...",
}`,
      },
      {
        method: "GET",
        path: "/api/tips/me/",
        desc: "List completed tips received by the authenticated creator",
        auth: true,
        response: `{
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
}`,
      },
      {
        method: "GET",
        path: "/api/tips/sent/",
        desc: "List tips sent by the authenticated fan user",
        auth: true,
        response: `{
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
}`,
      },
      {
        method: "GET",
        path: "/api/tips/{slug}/",
        desc: "Public feed of completed tips for a creator",
        auth: false,
        response: `[ /* array of tip objects */ ]`,
      },
    ],
  },
];

const AUTH_STEPS: [string, string, string, string][] = [
  ["01", "bi-person-plus-fill", "Register", "Create an account at tippingjar.co.za or via POST /api/users/register/"],
  ["02", "bi-key-fill", "Get Token", "POST credentials to /api/auth/token/ — receive an access + refresh token pair"],
  ["03", "bi-shield-lock-fill", "Authenticate", "Pass the access token in the Authorization: Bearer <token> header on every request"],
  ["04", "bi-arrow-repeat", "Refresh", "Use your refresh token to obtain a new access token before it expires (60 min TTL)"],
];

const ERRORS: [string, string, string][] = [
  ["400", "Bad Request", "Invalid request body or missing required fields."],
  ["401", "Unauthorized", "Missing or invalid Bearer token. Re-authenticate."],
  ["403", "Forbidden", "Authenticated but not allowed to perform this action."],
  ["404", "Not Found", "Resource does not exist or has been deleted."],
  ["405", "Method Not Allowed", "HTTP method not supported on this endpoint."],
  ["422", "Validation Error", "Request body failed field-level validation. See errors object."],
  ["429", "Too Many Requests", "Rate limit exceeded. Check Retry-After header."],
  ["500", "Internal Server Error", "Unexpected server error. Contact support@tippingjar.co.za."],
];

const RATE_LIMITS: [string, string, string, string][] = [
  ["bi-globe", "Unauthenticated", "60 req / min", "Per IP address"],
  ["bi-person-fill", "Authenticated", "300 req / min", "Per user token"],
  ["bi-cash-coin", "Tip creation", "30 req / hour", "Per IP / user"],
  ["bi-arrow-repeat", "Token refresh", "20 req / hour", "Per user"],
  ["bi-puzzle-fill", "Platform API", "1 000 req / min", "Per platform key"],
];

const WEBHOOK_EVENTS: [string, string, string][] = [
  ["tip.completed", "Fires immediately when a tip payment succeeds.", "text-teal"],
  ["tip.failed", "Fires when a Stripe payment attempt fails.", "text-[#F87171]"],
  ["tip.refunded", "Fires when a tip is refunded to the tipper.", "text-[#FBBF24]"],
  ["jar.created", "A creator published a new jar.", "text-teal"],
  ["jar.goal_reached", "A jar's total_raised has met or exceeded goal.", "text-teal"],
  ["creator.created", "A new creator profile was registered.", "text-teal"],
  ["payout.initiated", "Stripe has initiated a bank transfer.", "text-[#FBBF24]"],
  ["payout.completed", "Payout has arrived in the creator's account.", "text-teal"],
];

const SDKS: [string, string, string, string][] = [
  ["Python", "pip install tippingjar", "v1.4.0", "Python 3.8+"],
  ["Node.js", "npm install @tippingjar/sdk", "v1.6.2", "TypeScript ready"],
  ["Dart / Flutter", "tippingjar: ^1.2.0", "v1.2.0", "Null-safe"],
  ["Go", "go get github.com/tippingjar/go", "v1.1.0", "Go 1.21+"],
];

const PLATFORM_ENDPOINTS: [string, string, string][] = [
  ["GET", "/api/platform/me/", "Get platform info + key prefix"],
  ["GET", "/api/platform/creators/", "List active creators (public)"],
  ["GET", "/api/platform/users/", "List end-users on this platform"],
  ["POST", "/api/platform/users/", "Register or update an end-user"],
  ["POST", "/api/platform/tips/", "Initiate a tip as a platform user"],
];

const REQUIREMENTS: [string, string, string][] = [
  ["bi-building", "SA-registered business", "Your company must be registered with CIPC (Pty Ltd, CC, or NPC)."],
  ["bi-file-earmark-text-fill", "Company documents", "CIPC certificate, VAT letter, director ID, and bank confirmation letter."],
  ["bi-stopwatch", "48 h review", "Our compliance team reviews every application within two business days."],
  ["bi-headset", "Dedicated support", "Approved partners receive a dedicated integration engineer contact."],
];

/* ─── Helpers ────────────────────────────────────────────────────────────── */

function methodClass(method: string): string {
  switch (method) {
    case "GET":
      return "text-[#4ADE80] bg-[#4ADE80]/10";
    case "POST":
      return "text-[#60A5FA] bg-[#60A5FA]/10";
    case "PATCH":
      return "text-[#FBBF24] bg-[#FBBF24]/10";
    case "DELETE":
      return "text-[#F87171] bg-[#F87171]/10";
    default:
      return "text-muted bg-card";
  }
}

function errorClass(code: string): string {
  if (code.startsWith("2")) return "text-teal bg-teal/10";
  if (code.startsWith("4")) return "text-[#FBBF24] bg-[#FBBF24]/10";
  return "text-[#F87171] bg-[#F87171]/10";
}

function SectionLabel({ label }: { label: string }) {
  return (
    <p className="text-xs font-bold uppercase tracking-widest text-teal">{label}</p>
  );
}

function CodeBlock({ title, code }: { title?: string; code: string }) {
  return (
    <div className="overflow-hidden rounded-xl border border-border bg-[#0D1A14]">
      {title && (
        <div className="border-b border-border px-4 py-2.5 text-xs font-semibold text-muted">
          {title}
        </div>
      )}
      <pre className="overflow-x-auto p-4 text-xs leading-relaxed text-[#CDD6F4]">
        <code className="font-mono">{code}</code>
      </pre>
    </div>
  );
}

function CodeTabs({ tabs, snippets }: { tabs: string[]; snippets: string[] }) {
  const [idx, setIdx] = useState(0);
  return (
    <div className="overflow-hidden rounded-xl border border-border bg-[#0D1A14]">
      <div className="flex flex-wrap border-b border-border">
        {tabs.map((t, i) => (
          <button
            key={t}
            onClick={() => setIdx(i)}
            className={`border-b-2 px-4 py-3 font-mono text-xs font-semibold transition ${
              idx === i ? "border-teal text-teal" : "border-transparent text-muted"
            }`}
          >
            {t}
          </button>
        ))}
      </div>
      <pre className="overflow-x-auto p-5 text-xs leading-relaxed text-[#CDD6F4]">
        <code className="font-mono">{snippets[idx]}</code>
      </pre>
    </div>
  );
}

function EndpointRow({ ep }: { ep: Endpoint }) {
  const [open, setOpen] = useState(false);
  return (
    <div
      className={`mb-1.5 overflow-hidden rounded-xl border ${
        open ? "border-teal/30 bg-[#0F1F18]" : "border-border bg-card"
      }`}
    >
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center gap-3 px-4 py-3 text-left"
      >
        <span
          className={`w-16 shrink-0 rounded px-1 py-0.5 text-center font-mono text-[10px] font-bold ${methodClass(
            ep.method,
          )}`}
        >
          {ep.method}
        </span>
        <span className="font-mono text-xs text-ink">{ep.path}</span>
        {ep.auth && (
          <span className="rounded border border-teal/30 bg-teal/10 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wide text-teal">
            Auth
          </span>
        )}
        <span className="ml-auto hidden truncate text-xs text-muted sm:block">
          {ep.desc}
        </span>
        <span className="ml-2 flex text-muted"><i className={`bi ${open ? "bi-chevron-up" : "bi-chevron-down"}`} /></span>
      </button>
      {open && (
        <div className="border-t border-border p-4">
          <p className="mb-4 text-xs text-muted sm:hidden">{ep.desc}</p>
          {ep.request && (
            <div className="mb-4">
              <p className="mb-2 text-[11px] font-bold uppercase tracking-wide text-muted">
                Request body
              </p>
              <pre className="overflow-x-auto rounded-lg bg-darker p-3.5 text-[11px] leading-relaxed text-[#CDD6F4]">
                <code className="font-mono">{ep.request}</code>
              </pre>
            </div>
          )}
          <p className="mb-2 text-[11px] font-bold uppercase tracking-wide text-muted">
            Response
          </p>
          <pre className="overflow-x-auto rounded-lg bg-darker p-3.5 text-[11px] leading-relaxed text-[#CDD6F4]">
            <code className="font-mono">{ep.response}</code>
          </pre>
        </div>
      )}
    </div>
  );
}

function InfoBox({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-xl border border-teal/25 bg-teal/[0.07] p-4">
      <p className="text-sm font-bold text-teal">{title}</p>
      <pre className="mt-1.5 whitespace-pre-wrap font-mono text-xs leading-relaxed text-muted">
        {body}
      </pre>
    </div>
  );
}

/* ─── Page ───────────────────────────────────────────────────────────────── */

export default function DevelopersPage() {
  return (
    <>
      {/* Hero */}
      <section className="border-b border-border bg-darker">
        <div className="container-content py-20 text-center md:py-24">
          <span className="inline-block rounded-full border border-teal/30 bg-teal/10 px-4 py-1.5 font-mono text-xs font-semibold text-teal">
            API v1 · REST · JSON
          </span>
          <h1 className="heading-xl mx-auto mt-6 max-w-2xl">
            The Tipping Jar Developer Platform
          </h1>
          <p className="body-muted mx-auto mt-5 max-w-xl text-lg">
            A fast, secure REST API to integrate tipping flows into any product. Accept tips in
            ZAR, manage creator jars, issue payouts, and react to events with signed webhooks.
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            <a href="#quickstart" className="btn-primary gap-2 text-sm">
              <i className="bi bi-lightning-charge-fill" /> Quick Start
            </a>
            <a href="#authentication" className="btn-ghost gap-2 text-sm">
              <i className="bi bi-key-fill" /> Get API Key
            </a>
          </div>
          <div className="mt-12 flex flex-wrap items-center justify-center gap-x-12 gap-y-6">
            {[
              ["< 200ms", "Median latency"],
              ["99.99%", "API uptime"],
              ["ZAR", "Default currency"],
              ["Free", "Sandbox included"],
            ].map(([v, l]) => (
              <div key={l} className="text-center">
                <p className="text-2xl font-black text-teal">{v}</p>
                <p className="mt-1 text-sm text-muted">{l}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Authentication */}
      <section id="authentication" className="container-content py-16 md:py-20">
        <SectionLabel label="Authentication" />
        <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
          API Keys &amp; Bearer Tokens
        </h2>
        <p className="body-muted mt-3 max-w-3xl">
          The Tipping Jar uses JWT Bearer tokens for authentication. Obtain a token pair by
          posting credentials to the token endpoint. Include your access token in every
          authenticated request via the Authorization header.
        </p>

        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {AUTH_STEPS.map(([step, icon, title, desc]) => (
            <div key={step} className="card">
              <div className="flex items-center justify-between">
                <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal/10 text-base text-teal">
                  <i className={`bi ${icon}`} />
                </span>
                <span className="font-mono text-xs font-bold text-muted">{step}</span>
              </div>
              <h3 className="mt-3 font-semibold text-ink">{title}</h3>
              <p className="mt-1.5 text-xs leading-relaxed text-muted">{desc}</p>
            </div>
          ))}
        </div>

        <div className="mt-8 grid gap-6 lg:grid-cols-[5fr_6fr]">
          {/* API key sign-in panel */}
          <div className="card h-fit">
            <div className="flex items-center gap-2.5">
              <span className="grid h-8 w-8 place-items-center rounded-lg bg-teal/10 text-sm text-teal">
                <i className="bi bi-shield-lock-fill" />
              </span>
              <h3 className="font-semibold text-ink">API Keys</h3>
            </div>
            <p className="body-muted mt-2.5 text-sm">
              Sign in to generate and manage your API keys.
            </p>
            <div className="mt-4 flex items-center gap-2.5 rounded-lg border border-border bg-[#0D1A14] px-3.5 py-3">
              <span className="text-muted"><i className="bi bi-key-fill" /></span>
              <span className="font-mono text-[11px] text-muted">
                tj_live_sk_v1_••••••••••••••••••••
              </span>
            </div>
            <div className="mt-4 flex gap-2.5">
              <Link href="/login" className="btn-primary flex-1 text-center text-sm">
                Sign in
              </Link>
              <Link href="/register" className="btn-ghost flex-1 text-center text-sm">
                Register
              </Link>
            </div>
          </div>

          <CodeTabs tabs={["cURL", "Python", "Node.js"]} snippets={[AUTH_CURL, AUTH_PYTHON, AUTH_NODE]} />
        </div>

        <div className="mt-8">
          <InfoBox
            title="Access token lifetime"
            body="Access tokens expire after 60 minutes. Refresh tokens last 7 days. Your application should detect 401 Unauthorized responses and call /api/auth/token/refresh/ automatically to obtain a new access token."
          />
        </div>
      </section>

      {/* Quick Start */}
      <section id="quickstart" className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20">
          <div className="text-center">
            <SectionLabel label="Quick Start" />
            <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
              Send your first tip in 5 minutes
            </h2>
            <p className="body-muted mt-3">
              Authenticate, then create a tip payment with a single API call.
            </p>
          </div>
          <div className="mx-auto mt-10 max-w-3xl">
            <CodeTabs
              tabs={["cURL", "Python", "Node.js", "Dart"]}
              snippets={[CURL_SNIPPET, PYTHON_SNIPPET, NODE_SNIPPET, DART_SNIPPET]}
            />
          </div>
        </div>
      </section>

      {/* API Reference */}
      <section id="reference" className="container-content py-16 md:py-20">
        <SectionLabel label="API Reference" />
        <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
          Complete endpoint reference
        </h2>
        <p className="mt-3 flex flex-wrap items-center gap-2 text-sm text-muted">
          Base URL <span className="font-mono text-teal">{BASE_URL}</span>
        </p>

        <div className="mt-10 space-y-8">
          {GROUPS.map((g) => (
            <div key={g.title}>
              <div className="mb-3 flex items-center gap-3 rounded-xl border border-teal/15 bg-teal/[0.05] p-4">
                <span className="text-lg">{g.icon}</span>
                <div>
                  <h3 className="font-semibold text-ink">{g.title}</h3>
                  <p className="text-xs text-muted">{g.desc}</p>
                </div>
              </div>
              {g.endpoints.map((ep) => (
                <EndpointRow key={ep.method + ep.path} ep={ep} />
              ))}
            </div>
          ))}
        </div>
      </section>

      {/* Error Codes */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20">
          <SectionLabel label="Error Codes" />
          <h2 className="mt-4 text-3xl font-extrabold tracking-tight">Error handling</h2>
          <p className="body-muted mt-3">
            All errors follow a consistent JSON structure with a detail field.
          </p>
          <div className="mt-8 grid gap-7 lg:grid-cols-[1fr_320px]">
            <div className="space-y-2">
              {ERRORS.map(([code, title, desc]) => (
                <div
                  key={code}
                  className="flex items-start gap-3 rounded-xl border border-border bg-card p-3.5"
                >
                  <span
                    className={`w-12 shrink-0 rounded px-1.5 py-1 text-center font-mono text-[11px] font-bold ${errorClass(
                      code,
                    )}`}
                  >
                    {code}
                  </span>
                  <div>
                    <p className="text-sm font-semibold text-ink">{title}</p>
                    <p className="text-xs text-muted">{desc}</p>
                  </div>
                </div>
              ))}
            </div>
            <CodeBlock title="Error response shape" code={ERROR_SHAPE} />
          </div>
        </div>
      </section>

      {/* Rate Limits */}
      <section className="container-content py-16 md:py-20">
        <SectionLabel label="Rate Limits" />
        <h2 className="mt-4 text-3xl font-extrabold tracking-tight">Rate limiting</h2>
        <p className="body-muted mt-3">
          Limits apply per IP for public endpoints and per access token for authenticated ones.
        </p>
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {RATE_LIMITS.map(([icon, tier, limit, scope]) => (
            <div key={tier} className="card">
              <span className="text-xl text-teal"><i className={`bi ${icon}`} /></span>
              <p className="mt-3 text-2xl font-extrabold tracking-tight text-teal">{limit}</p>
              <p className="mt-1 font-semibold text-ink">{tier}</p>
              <p className="text-xs text-muted">{scope}</p>
            </div>
          ))}
        </div>
        <div className="mt-8">
          <InfoBox
            title="Rate limit headers"
            body={`Every response includes:
  X-RateLimit-Limit      — your limit for this window
  X-RateLimit-Remaining  — requests remaining
  X-RateLimit-Reset      — Unix timestamp the window resets
  Retry-After            — seconds to wait (only on 429 responses)`}
          />
        </div>
      </section>

      {/* Webhooks */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20">
          <SectionLabel label="Webhooks" />
          <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
            Real-time event notifications
          </h2>
          <p className="body-muted mt-3 max-w-2xl">
            Register an HTTPS endpoint in your dashboard. The Tipping Jar will POST signed
            payloads to your URL on every event. Verify signatures using HMAC-SHA256 with your
            webhook secret.
          </p>
          <div className="mt-10 grid gap-7 lg:grid-cols-2">
            <div className="space-y-2.5">
              {WEBHOOK_EVENTS.map(([name, desc, accent]) => (
                <div
                  key={name}
                  className="flex items-center gap-3 rounded-xl border border-border bg-card p-3.5"
                >
                  <span className={`rounded bg-white/[0.04] px-2 py-1 font-mono text-[10px] font-semibold ${accent}`}>
                    {name}
                  </span>
                  <span className="text-xs text-muted">{desc}</span>
                </div>
              ))}
            </div>
            <div className="space-y-4">
              <CodeBlock title="Payload example" code={WEBHOOK_PAYLOAD} />
              <CodeBlock title="Signature verification (Node.js)" code={WEBHOOK_VERIFY} />
            </div>
          </div>
          <div className="mt-8">
            <InfoBox
              title="Signature verification"
              body={`Every webhook request includes a TJ-Signature header. Compute
HMAC-SHA256(payload_body, your_webhook_secret) and compare it to
the header value. Reject any requests where they don't match.`}
            />
          </div>
        </div>
      </section>

      {/* SDKs */}
      <section className="container-content py-16 md:py-20 text-center">
        <SectionLabel label="SDKs" />
        <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
          Official client libraries
        </h2>
        <p className="body-muted mt-3">All SDKs are open source and MIT-licensed.</p>
        <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {SDKS.map(([name, install, version, lang]) => (
            <div key={name} className="card text-left">
              <p className="font-semibold text-ink">{name}</p>
              <p className="mt-1 text-xs text-muted">{lang}</p>
              <p className="mt-2 font-mono text-[10px] text-teal">{install}</p>
              <p className="mt-1 font-mono text-[10px] text-muted">{version}</p>
              <button className="btn-ghost mt-4 w-full !py-2 text-xs">View on GitHub</button>
            </div>
          ))}
        </div>
      </section>

      {/* Platform API */}
      <section className="border-y border-border bg-dark">
        <div className="container-content py-16 md:py-20">
          <SectionLabel label="Platform API" />
          <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
            Embed tipping in your app
          </h2>
          <p className="body-muted mt-3 max-w-2xl">
            The Platform API lets third-party applications integrate The Tipping Jar tipping
            without requiring end-users to create accounts directly. Authenticate requests using
            the X-Platform-Key header. Each platform has its own isolated user pool and rate
            limit envelope.
          </p>

          <div className="card mt-8">
            <div className="flex items-center gap-2">
              <span className="text-teal"><i className="bi bi-key-fill" /></span>
              <h3 className="font-semibold text-ink">Key format</h3>
            </div>
            <div className="mt-3 rounded-lg bg-darker px-3.5 py-2.5">
              <code className="font-mono text-sm text-teal">
                X-Platform-Key: tj_platform_sk_v1_&lt;32-char-hex&gt;
              </code>
            </div>
            <p className="mt-2.5 text-xs leading-relaxed text-muted">
              Platform keys are generated once on approval and hashed server-side. Store them as
              environment secrets — they cannot be retrieved again.
            </p>
          </div>

          <h3 className="mt-8 text-lg font-bold text-ink">Endpoints</h3>
          <div className="mt-3 space-y-2.5">
            {PLATFORM_ENDPOINTS.map(([method, path, desc]) => (
              <div
                key={method + path}
                className="flex flex-wrap items-center gap-3 rounded-xl border border-border bg-card px-4 py-3.5"
              >
                <span
                  className={`rounded px-2 py-0.5 font-mono text-[11px] font-bold ${
                    method === "GET" ? "text-teal bg-teal/10" : "text-[#FB923C] bg-[#FB923C]/10"
                  }`}
                >
                  {method}
                </span>
                <span className="font-mono text-xs text-ink">{path}</span>
                <span className="ml-auto text-xs text-muted">{desc}</span>
              </div>
            ))}
          </div>

          <div className="mt-8">
            <CodeTabs tabs={["cURL", "Python"]} snippets={[PLATFORM_CURL, PLATFORM_PYTHON]} />
          </div>
        </div>
      </section>

      {/* Partner Program */}
      <section className="container-content py-16 md:py-20">
        <SectionLabel label="Partner Program" />
        <h2 className="mt-4 text-3xl font-extrabold tracking-tight">
          Become a Tipping Jar partner
        </h2>
        <p className="body-muted mt-3 max-w-2xl">
          The Partner Program gives SA-registered businesses access to the Platform API and
          dedicated support. Applications are reviewed within 48 business hours.
        </p>
        <div className="mt-8 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {REQUIREMENTS.map(([icon, title, body]) => (
            <div key={title} className="card">
              <span className="text-xl text-teal"><i className={`bi ${icon}`} /></span>
              <h3 className="mt-3 font-semibold text-ink">{title}</h3>
              <p className="mt-1.5 text-xs leading-relaxed text-muted">{body}</p>
            </div>
          ))}
        </div>

        <div className="mt-12 rounded-3xl border border-teal/25 bg-primary/[0.04] p-10 text-center">
          <h3 className="text-2xl font-extrabold tracking-tight text-ink">Ready to apply?</h3>
          <p className="body-muted mt-2.5">
            Complete a short multi-step form with your business details.
          </p>
          <Link href="/partner-apply" className="btn-primary mt-6 text-sm">
            Apply for Platform API access →
          </Link>
        </div>
      </section>

      {/* CTA */}
      <section className="container-content pb-20">
        <div className="mx-auto max-w-3xl rounded-3xl bg-brand-gradient p-12 text-center md:p-14">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-white/15 text-2xl">
            <i className="bi bi-puzzle-fill" />
          </div>
          <h2 className="heading-xl mt-5 text-ink">Start building today</h2>
          <p className="mt-3 text-white/70">
            Free sandbox · No credit card · ZAR currency ready
          </p>
          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            <Link
              href="/register"
              className="inline-flex rounded-full bg-white px-8 py-3 font-semibold text-primary transition hover:opacity-90"
            >
              Get your API key
            </Link>
            <button className="inline-flex rounded-full border border-white/30 px-8 py-3 font-semibold text-ink transition hover:border-white">
              View on GitHub
            </button>
          </div>
        </div>
      </section>
    </>
  );
}
