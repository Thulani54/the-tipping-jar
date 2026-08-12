// Shapes returned by the Rust /api/v2 services.

export interface User {
  id: string;
  email: string;
  username: string;
  role: "fan" | "creator" | "enterprise" | "admin";
  phone_number: string;
  two_fa_enabled: boolean;
  is_minor: boolean;
  referral_code_used: string;
  created_at: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface Creator {
  id: string;
  user_id: string;
  display_name: string;
  slug: string;
  tagline: string;
  category: string;
  tip_goal: string | null;
  is_active: boolean;
  kyc_status: string;
  avatar_url: string;
  cover_url: string;
  is_featured: boolean;
  tip_presets: string; // JSON array, e.g. "[20,50,100]"
  thanks_note: string;
  links: string; // JSON object {instagram, twitter, youtube, website}
  theme: string; // accent hex for the public page, e.g. "#7C3AED"
  profile_type: string; // "individual" | "organisation"
  org_type: string;     // "" | "ngo" | "church" | "school" | "business" | "other"
  registration_number: string;
  country: string;      // ISO like "ZA"
  city: string;
  created_at: string;
}

export interface Tip {
  id: string;
  creator_id: string;
  creator_name: string;
  tipper_name: string;
  tipper_email: string;
  amount: string;
  message: string;
  status: string;
  reference: string;
  platform_fee: string;
  service_fee: string;
  creator_net: string;
  thanks_message: string;
  thanked_at: string | null;
  jar_id: string | null;
  created_at: string;
}

export interface FeeQuote {
  amount: string;
  platform_fee: string;
  service_fee: string;
  creator_net: string;
  total_fee: string;
  platform_pct: string;
  service_pct: string;
}

export interface BlogPost {
  id: string;
  title: string;
  slug: string;
  category: string;
  excerpt: string;
  content: string;
  author_name: string;
  read_time: string;
  is_published: boolean;
  created_at: string;
  updated_at: string;
}

export interface Job {
  id: string;
  title: string;
  department: string;
  location: string;
  employment_type: string;
  description: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Enterprise {
  id: string;
  admin_user_id: string;
  name: string;
  slug: string;
  plan: string;
  website: string;
  approval_status: string;
  contact_name: string;
  contact_email: string;
  contact_phone: string;
  is_active: boolean;
  created_at: string;
}

export interface ReferralCode {
  id: string;
  owner_user_id: string;
  code: string;
  commission_rate: string;
  is_active: boolean;
  created_at: string;
}

export interface Dispute {
  id: string;
  name: string;
  email: string;
  reason: string;
  description: string;
  tip_ref: string;
  status: string;
  token: string;
  created_at: string;
}

export interface SupportTier {
  id: string;
  creator_id: string;
  name: string;
  price: string;
  description: string;
  perks: string[];
  is_active: boolean;
  sort_order: number;
  created_at: string;
}

export interface Jar {
  id: string;
  creator_id: string;
  name: string;
  slug: string;
  description: string;
  goal: string | null;
  is_active: boolean;
  created_at: string;
}

export interface Pledge {
  id: string;
  creator_id: string;
  tier_id: string | null;
  fan_name: string;
  fan_email: string;
  amount: string;
  status: string;
  created_at: string;
}

export interface CreatorStats {
  creator_id: string;
  total_amount: string;
  tip_count: number;
  supporter_count: number;
  creator_net_total: string;
  this_month_amount: string;
}

// ── Admin portal ─────────────────────────────────────────────────────
export interface AdminDashboard {
  totals: {
    users: number;
    creators: number;
    creators_active: number;
    tips: number;
    tips_completed: number;
    gross_volume: string;
    creator_net: string;
    transactions: number;
    payouts_pending: number;
    payouts_pending_amount: string;
    fees_earned: string;
    contacts: number;
    disputes: number;
  };
  recent_tips: Tip[];
  recent_transactions: Transaction[];
}

export interface AdminUser {
  id: string;
  email: string;
  username: string;
  role: string;
  phone_number: string;
  two_fa_enabled: boolean;
  is_minor: boolean;
  referral_code_used: string;
  created_at: string;
}

export interface AdminCreator {
  id: string;
  user_id: string;
  display_name: string;
  slug: string;
  tagline: string;
  category: string;
  tip_goal: string | null;
  is_active: boolean;
  kyc_status: string;
  is_featured: boolean;
  has_avatar: boolean;
  has_cover: boolean;
  bank_details: { bank?: string; account_name?: string; account_no?: string };
  profile_type: string;
  org_type: string;
  country: string;
  city: string;
  created_at: string;
}

export interface AdminTickets {
  contacts: { id: string; name?: string; email?: string; subject?: string; message?: string; created_at?: string }[];
  disputes: { id: string; email?: string; reason?: string; status?: string; tracking_token?: string; created_at?: string }[];
  partners: { id: string; company?: string; email?: string; created_at?: string }[];
}

export interface Supporter {
  name: string;
  email: string;
  tip_count: number;
  total: string;
  last_tip_at: string;
}

export interface AuditEntry {
  id: string;
  actor: string;
  action: string;
  target: string;
  detail: string;
  created_at: string;
}

export interface ExclusivePost {
  id: string;
  creator_id: string;
  title: string;
  body: string;
  image_url: string;
  kind: "post" | "video" | "audio" | "gallery";
  media_url: string;
  access: "monthly_tip" | "subscription" | "one_tip" | "public";
  min_tip: string;
  tier_id: string | null;
  created_at: string;
}

export interface UnlockResp {
  posts: ExclusivePost[];
  grants: {
    tipped_this_month: boolean;
    tier_ids: string[];
    month_tip_total: string;
  };
}

export interface Subscriber {
  id: string;
  tier_id: string;
  tier_name: string;
  email: string;
  name: string;
  status: string;
  created_at: string;
}

export interface StudioDesign {
  id: string;
  creator_id: string;
  title: string;
  kind: string;
  canvas: string; // JSON blob of the editor's element state
  thumb: string; // small PNG data-URL preview
  created_at: string;
}

export interface Transaction {
  id: string;
  reference: string;
  creator_id: string;
  amount: string;
  platform_fee: string;
  service_fee: string;
  creator_net: string;
  status: string;
  merchant_order_no: string;
  trans_no: string;
  currency: string;
  pay_url: string;
  description: string;
  creator_name: string;
  tipper_name: string;
  tipper_email: string;
  message: string;
  jar_id: string | null;
  created_at: string;
}

export interface Payout {
  id: string;
  creator_id: string;
  amount: string;
  status: string;
  reference: string;
  created_at: string;
}

export interface Balance {
  creator_id: string;
  net_balance: string;
  withdrawn: string;
  available: string;
  transaction_count: number;
}

export interface CheckoutResult {
  pay_url: string;
  merchant_order_no: string;
  reference: string;
  amount: string;
  creator_net: string;
  status: string;
}
