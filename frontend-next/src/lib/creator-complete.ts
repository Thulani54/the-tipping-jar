import type { Creator } from "@/types";

// Every field a creator must fill in before their public tip page opens
// for donations. Bank details are deliberately excluded — those gate
// PAYOUTS (from the internal balance to a real account), not the ability
// to accept tips into that balance in the first place.
export type ChecklistItem = { key: string; label: string; done: boolean };

export function tipReadinessChecklist(creator: Creator): ChecklistItem[] {
  const linksHasAny = (() => {
    try {
      const l = creator.links ? JSON.parse(creator.links) : {};
      return Object.values(l).some((v) => (v || "").toString().trim().length > 0);
    } catch {
      return false;
    }
  })();
  const presetsSet = (() => {
    try {
      const p = creator.tip_presets ? JSON.parse(creator.tip_presets) : [];
      return Array.isArray(p) && p.length >= 2;
    } catch {
      return false;
    }
  })();

  const list: ChecklistItem[] = [
    { key: "name", label: "Display name", done: (creator.display_name || "").trim().length > 0 },
    { key: "tagline", label: "Tagline", done: (creator.tagline || "").trim().length > 0 },
    { key: "avatar", label: "Avatar photo", done: !!creator.avatar_url },
    { key: "cover", label: "Cover photo", done: !!creator.cover_url },
    { key: "category", label: "Category", done: (creator.category || "").trim().length > 0 },
    { key: "goal", label: "Monthly goal", done: !!(creator.tip_goal && Number(creator.tip_goal) > 0) },
    { key: "presets", label: "At least two preset tip amounts", done: presetsSet },
    { key: "thanks", label: "Thank-you note", done: (creator.thanks_note || "").trim().length > 0 },
    { key: "social", label: "At least one social link", done: linksHasAny },
    { key: "location", label: "Country + city", done: (creator.country || "").length > 0 && (creator.city || "").trim().length > 0 },
  ];
  if ((creator.profile_type || "individual") === "organisation") {
    list.push({ key: "reg", label: "Registration number", done: (creator.registration_number || "").trim().length > 0 });
  }
  return list;
}

export function tipReadinessPct(creator: Creator): number {
  const list = tipReadinessChecklist(creator);
  return Math.round((list.filter((c) => c.done).length / list.length) * 100);
}

export function isReadyForTips(creator: Creator): boolean {
  if (creator.is_active === false) return false;
  return tipReadinessPct(creator) >= 100;
}
