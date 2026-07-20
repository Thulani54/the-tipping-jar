// API client for the Tipping Jar Rust microservices, reached via nginx under
// /api/v2/<service>/. Each service has its own path prefix.

import type {
  AuthResponse,
  BlogPost,
  Creator,
  Dispute,
  Enterprise,
  FeeQuote,
  Job,
  ReferralCode,
  Tip,
  User,
} from "@/types";

const BASE =
  process.env.NEXT_PUBLIC_API_BASE ?? "https://api.siyangoma.co.za/api/v2";

export class ApiError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

async function request<T>(
  path: string,
  opts: { method?: string; body?: unknown; token?: string | null } = {},
): Promise<T> {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (opts.token) headers["Authorization"] = `Bearer ${opts.token}`;

  const res = await fetch(`${BASE}${path}`, {
    method: opts.method ?? "GET",
    headers,
    body: opts.body ? JSON.stringify(opts.body) : undefined,
    cache: "no-store",
  });

  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    const msg = (data && (data.error || data.detail)) || `HTTP ${res.status}`;
    throw new ApiError(msg, res.status);
  }
  return data as T;
}

export const api = {
  // ── accounts ──────────────────────────────────────────────────────
  register: (body: {
    email: string;
    password: string;
    username?: string;
    role?: string;
    phone_number?: string;
    referral_code?: string;
  }) => request<AuthResponse>("/accounts/auth/register", { method: "POST", body }),

  login: (email: string, password: string) =>
    request<AuthResponse>("/accounts/auth/login", {
      method: "POST",
      body: { email, password },
    }),

  me: (token: string) => request<User>("/accounts/auth/me", { token }),

  // ── creators ──────────────────────────────────────────────────────
  listCreators: () => request<Creator[]>("/creators/creators"),
  getCreator: (slug: string) => request<Creator>(`/creators/creators/${slug}`),
  createCreator: (
    token: string,
    body: { display_name: string; tagline?: string; category?: string; tip_goal?: number },
  ) => request<Creator>("/creators/creators", { method: "POST", body, token }),

  // ── payments ──────────────────────────────────────────────────────
  quote: (amount: number) =>
    request<FeeQuote>("/payments/quote", { method: "POST", body: { amount } }),

  // ── tips ──────────────────────────────────────────────────────────
  listTips: () => request<Tip[]>("/tips/tips"),
  tipsForCreator: (creatorId: string) =>
    request<Tip[]>(`/tips/tips/creator/${creatorId}`),
  createTip: (body: {
    creator_slug?: string;
    creator_id?: string;
    amount: number;
    tipper_name?: string;
    tipper_email?: string;
    message?: string;
  }) => request<Tip>("/tips/tips", { method: "POST", body }),

  // ── blog ──────────────────────────────────────────────────────────
  listPosts: () => request<BlogPost[]>("/blog/posts"),
  getPost: (slug: string) => request<BlogPost>(`/blog/posts/${slug}`),

  // ── careers ───────────────────────────────────────────────────────
  listJobs: () => request<Job[]>("/careers/jobs"),

  // ── enterprise ────────────────────────────────────────────────────
  listEnterprises: () => request<Enterprise[]>("/enterprise/enterprises"),

  // ── referrals ─────────────────────────────────────────────────────
  myReferralCode: (token: string) =>
    request<ReferralCode>("/referrals/codes", { method: "POST", token }),

  // ── support ───────────────────────────────────────────────────────
  contact: (body: { name: string; email: string; subject?: string; message: string }) =>
    request<unknown>("/support/contact", { method: "POST", body }),
  createDispute: (body: {
    name: string;
    email: string;
    reason: string;
    description: string;
    tip_ref?: string;
  }) => request<{ reference: string; token: string; dispute: Dispute }>("/support/disputes", {
    method: "POST",
    body,
  }),
  trackDispute: (token: string) =>
    request<Dispute>(`/support/disputes/${token}`),

  // ── admin ─────────────────────────────────────────────────────────
  dashboard: () => request<unknown>("/admin/dashboard"),
};
