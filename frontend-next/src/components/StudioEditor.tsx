"use client";

// Creator Studio — an advanced promo-graphic editor.
//
// Capabilities: canvas presets; solid/linear/radial backgrounds with angle
// control; draggable text / rect / circle / line / triangle / image / QR
// elements with rotation + resize handles; brand fonts, multi-line text,
// letter-spacing, shadows; stickers; image upload (auto-compressed); a
// QR-code generator for the creator's tip link; layers (reorder, duplicate,
// opacity); snap-to-centre guides; undo/redo + keyboard shortcuts; templates;
// PNG / JPEG / WEBP / clipboard export; gallery persisted via the Rust creators
// service (save + update + delete).

import { useCallback, useEffect, useRef, useState } from "react";
import QRCode from "qrcode";
import { api } from "@/lib/api";
import type { StudioDesign } from "@/types";

const LOG_W = 540; // logical canvas width — all coordinates are in this space
const MAX_CANVAS_BYTES = 195_000; // backend rejects canvas JSON > 200KB

type Kind =
  | "square"
  | "portrait"
  | "story"
  | "landscape"
  | "banner"
  | "thumb"
  | "poster"
  | "card";
const PRESETS: Record<Kind, { label: string; w: number; h: number }> = {
  square: { label: "Square", w: 1080, h: 1080 },
  portrait: { label: "Portrait", w: 1080, h: 1350 },
  story: { label: "Story", w: 1080, h: 1920 },
  landscape: { label: "Landscape", w: 1920, h: 1080 },
  banner: { label: "LinkedIn banner", w: 1584, h: 396 },
  thumb: { label: "YouTube thumb", w: 1280, h: 720 },
  poster: { label: "A4 poster", w: 1240, h: 1754 },
  card: { label: "Web card", w: 1600, h: 900 },
};

type Font = "display" | "body" | "mono";
// Manrope is the site typeface for both display and body weights; Space Mono
// is the monospace face. Both are loaded as CSS vars in app/layout.tsx.
const FONTS: Record<Font, { label: string; css: string; canvas: string }> = {
  display: { label: "Display", css: "var(--font-sans)", canvas: "Manrope" },
  body: { label: "Body", css: "var(--font-sans)", canvas: "Manrope" },
  mono: { label: "Mono", css: "var(--font-mono)", canvas: "'Space Mono'" },
};

type ElType = "text" | "rect" | "circle" | "line" | "triangle" | "image" | "qr";

type El = {
  id: string;
  type: ElType;
  x: number; // centre, logical px
  y: number;
  w?: number;
  h?: number;
  rotation?: number; // degrees
  opacity?: number; // 0–1
  color: string;
  hidden?: boolean;
  locked?: boolean;
  flipX?: boolean;
  flipY?: boolean;
  // text
  text?: string;
  size?: number;
  weight?: number;
  font?: Font;
  align?: "left" | "center" | "right";
  spacing?: number; // letter-spacing, logical px
  lineHeight?: number; // multiplier, default 1.25
  shadow?: boolean;
  // rect
  radius?: number;
  stroke?: string;
  strokeWidth?: number;
  // line
  thickness?: number;
  // image / qr
  src?: string;
};

type Bg = {
  mode: "solid" | "linear" | "radial";
  c1: string;
  c2: string;
  angle: number;
  image?: string; // data URL for a background photo
  imageOpacity?: number; // 0–1
};

type CanvasState = { kind: Kind; bg: Bg; els: El[] };

const uid = () => Math.random().toString(36).slice(2, 9);
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));

const NAVY = "#0F2439";
const MINT = "#57CE8B";
const GREEN = "#12A25C";
const GOLD = "#E0A536";
const SWATCHES = ["#FFFFFF", NAVY, GREEN, MINT, GOLD, "#EF4444", "#3B82F6", "#000000"];
const STICKERS = [
  "🫙", "🪙", "💚", "🎉", "🔥", "⭐", "🎵", "📣", "✨", "❤️", "🙌", "☕",
  "🏆", "💎", "🎨", "📸", "🎤", "🎧", "🎸", "🍀", "🚀", "👑", "🎁", "🕊",
];

const text = (p: Partial<El>): El => ({
  id: uid(), type: "text", x: 270, y: 270, size: 32, weight: 700, font: "display",
  align: "center", color: "#FFFFFF", text: "Text", opacity: 1, ...p,
});

const DEFAULT_STATE: CanvasState = {
  kind: "square",
  bg: { mode: "linear", c1: NAVY, c2: GREEN, angle: 135 },
  els: [
    text({ y: 210, text: "Support my work", size: 44, weight: 800 }),
    text({ y: 285, text: "tippingjar.co.za", size: 20, font: "mono", color: MINT }),
  ],
};

const TEMPLATES: { name: string; state: CanvasState }[] = [
  {
    name: "Support me",
    state: {
      kind: "square",
      bg: { mode: "linear", c1: NAVY, c2: "#12324F", angle: 160 },
      els: [
        text({ y: 92, text: "🫙", size: 64 }),
        text({ y: 205, text: "Enjoying my work?", size: 40, weight: 800 }),
        text({ y: 268, text: "Drop a tip in my jar", size: 22, color: MINT, font: "body", weight: 500 }),
        { id: uid(), type: "rect", x: 270, y: 372, w: 300, h: 62, radius: 31, color: MINT, opacity: 1 },
        text({ y: 372, text: "tippingjar.co.za / you", size: 18, font: "mono", color: NAVY }),
      ],
    },
  },
  {
    name: "Goal",
    state: {
      kind: "square",
      bg: { mode: "solid", c1: "#EFF2F0", c2: "#EFF2F0", angle: 0 },
      els: [
        text({ y: 120, text: "Monthly goal", size: 22, font: "mono", color: GREEN }),
        text({ y: 205, text: "78%", size: 110, weight: 800, color: NAVY }),
        { id: uid(), type: "rect", x: 270, y: 320, w: 380, h: 22, radius: 11, color: "#DDE4DF", opacity: 1 },
        { id: uid(), type: "rect", x: 216, y: 320, w: 272, h: 22, radius: 11, color: GREEN, opacity: 1 },
        text({ y: 396, text: "Help me get there →", size: 24, color: NAVY, weight: 700 }),
      ],
    },
  },
  {
    name: "Thank you",
    state: {
      kind: "square",
      bg: { mode: "radial", c1: "#1B3A5C", c2: NAVY, angle: 0 },
      els: [
        text({ y: 160, text: "💚", size: 72 }),
        text({ y: 262, text: "Thank you!", size: 56, weight: 800 }),
        text({ y: 330, text: "Your support keeps this going", size: 22, color: MINT, font: "body", weight: 500 }),
      ],
    },
  },
  {
    name: "Live story",
    state: {
      kind: "story",
      bg: { mode: "linear", c1: GREEN, c2: NAVY, angle: 180 },
      els: [
        { id: uid(), type: "circle", x: 270, y: 250, w: 170, h: 170, color: "rgba(255,255,255,0.14)", opacity: 1 },
        text({ y: 250, text: "🎵", size: 76 }),
        text({ y: 430, text: "I'm live now", size: 52, weight: 800 }),
        text({ y: 505, text: "Tip a song request", size: 24, color: "#DFF5E9", font: "body", weight: 500 }),
        { id: uid(), type: "rect", x: 270, y: 640, w: 320, h: 64, radius: 32, color: "#FFFFFF", opacity: 1 },
        text({ y: 640, text: "tippingjar.co.za / you", size: 18, font: "mono", color: NAVY }),
      ],
    },
  },
  {
    name: "New drop",
    state: {
      kind: "square",
      bg: { mode: "linear", c1: "#7C3AED", c2: NAVY, angle: 145 },
      els: [
        text({ y: 108, text: "OUT NOW", size: 22, font: "mono", spacing: 8, color: GOLD }),
        text({ y: 200, text: "New single", size: 30, weight: 500, color: MINT }),
        text({ y: 280, text: '"Song title"', size: 60, weight: 800 }),
        text({ y: 372, text: "Available on every streaming platform", size: 20, font: "body", weight: 500, color: "#DFDBFF" }),
        { id: uid(), type: "rect", x: 270, y: 470, w: 300, h: 62, radius: 31, color: MINT, opacity: 1 },
        text({ y: 470, text: "Tip the artist ↗", size: 20, font: "display", weight: 700, color: NAVY }),
      ],
    },
  },
  {
    name: "Milestone",
    state: {
      kind: "square",
      bg: { mode: "radial", c1: GOLD, c2: "#8A6112", angle: 0 },
      els: [
        text({ y: 108, text: "🏆", size: 84 }),
        text({ y: 230, text: "10,000", size: 96, weight: 800 }),
        text({ y: 315, text: "supporters", size: 26, weight: 500, font: "body", color: "#FFF6E0" }),
        text({ y: 400, text: "Thank you — this is only because of you.", size: 20, color: "#FFEEC2", font: "body", spacing: 0 }),
        text({ y: 470, text: "tippingjar.co.za / you", size: 16, font: "mono", color: NAVY }),
      ],
    },
  },
  {
    name: "Event",
    state: {
      kind: "portrait",
      bg: { mode: "linear", c1: NAVY, c2: "#0F766E", angle: 175 },
      els: [
        text({ y: 130, text: "LIVE EVENT", size: 22, font: "mono", spacing: 6, color: GOLD }),
        text({ y: 240, text: "Friday", size: 100, weight: 800 }),
        text({ y: 330, text: "August 15 · 20:00", size: 26, font: "mono", color: MINT }),
        { id: uid(), type: "rect", x: 270, y: 460, w: 400, h: 3, radius: 2, color: MINT, opacity: 0.5 },
        text({ y: 560, text: "Venue name", size: 28, weight: 700 }),
        text({ y: 610, text: "Cape Town", size: 20, font: "body", color: "#B4D9CB" }),
        { id: uid(), type: "rect", x: 270, y: 800, w: 340, h: 64, radius: 32, color: MINT, opacity: 1 },
        text({ y: 800, text: "Tickets · tippingjar / you", size: 18, font: "mono", color: NAVY }),
      ],
    },
  },
  {
    name: "Quote",
    state: {
      kind: "square",
      bg: { mode: "solid", c1: "#EFF2F0", c2: "#EFF2F0", angle: 0 },
      els: [
        text({ y: 90, text: "“", size: 140, weight: 800, color: GREEN }),
        text({ y: 260, text: "The work is the reward.", size: 42, weight: 800, color: NAVY }),
        text({ y: 330, text: "Everything else is a bonus.", size: 42, weight: 800, color: NAVY }),
        text({ y: 430, text: "— your name", size: 22, font: "mono", color: "#5A6B7B" }),
        text({ y: 490, text: "tippingjar.co.za / you", size: 16, font: "mono", color: GREEN }),
      ],
    },
  },
  {
    name: "Behind-the-scenes",
    state: {
      kind: "portrait",
      bg: { mode: "linear", c1: "#1B0F2A", c2: "#4C1D95", angle: 165 },
      els: [
        text({ y: 130, text: "🎬 BTS", size: 22, font: "mono", spacing: 6, color: GOLD }),
        text({ y: 260, text: "Behind the", size: 60, weight: 800 }),
        text({ y: 330, text: "scenes.", size: 90, weight: 800, color: MINT }),
        text({ y: 490, text: "Fresh drops for supporters this week:", size: 22, font: "body", color: "#DFDBFF" }),
        text({ y: 560, text: "· Studio demo", size: 22, font: "body", weight: 700 }),
        text({ y: 610, text: "· Photo dump", size: 22, font: "body", weight: 700 }),
        text({ y: 660, text: "· Early access", size: 22, font: "body", weight: 700 }),
        { id: uid(), type: "rect", x: 270, y: 800, w: 380, h: 64, radius: 32, color: MINT, opacity: 1 },
        text({ y: 800, text: "Unlock at tippingjar / you", size: 18, font: "mono", color: NAVY }),
      ],
    },
  },
  {
    name: "Sale/discount",
    state: {
      kind: "square",
      bg: { mode: "linear", c1: "#DC2626", c2: "#7F1D1D", angle: 135 },
      els: [
        text({ y: 100, text: "LIMITED", size: 22, font: "mono", spacing: 8 }),
        text({ y: 210, text: "40% OFF", size: 96, weight: 800, color: GOLD }),
        text({ y: 300, text: "Everything · This week only", size: 22, font: "body", weight: 500, color: "#FEE2E2" }),
        { id: uid(), type: "rect", x: 270, y: 400, w: 340, h: 62, radius: 31, color: "#FFFFFF", opacity: 1 },
        text({ y: 400, text: "Code: TIPFAM", size: 24, font: "mono", weight: 800, color: NAVY }),
        text({ y: 490, text: "tippingjar.co.za / you", size: 16, font: "mono", color: "#FEE2E2" }),
      ],
    },
  },
];

type PointerMode =
  | { op: "drag"; id: string; dx: number; dy: number }
  | { op: "resize"; id: string; startW: number; startH: number; startSize: number; sx: number; sy: number }
  | { op: "rotate"; id: string };

// ─────────────────────────────────────────────────────────────────────────────

export function StudioEditor({ token, slug }: { token: string | null; slug?: string | null }) {
  const [state, setState] = useState<CanvasState>(DEFAULT_STATE);
  const [selected, setSelected] = useState<string | null>(null);
  const [gallery, setGallery] = useState<StudioDesign[]>([]);
  const [loadedId, setLoadedId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const [guides, setGuides] = useState<{ v: boolean; h: boolean }>({ v: false, h: false });
  const [stickerOpen, setStickerOpen] = useState(false);
  const [overlay, setOverlay] = useState<"none" | "grid" | "safe">("none");

  const stageRef = useRef<HTMLDivElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const bgFileRef = useRef<HTMLInputElement>(null);
  const mode = useRef<PointerMode | null>(null);
  const history = useRef<{ past: string[]; future: string[]; last: number }>({ past: [], future: [], last: 0 });

  const preset = PRESETS[state.kind];
  const logH = (preset.h / preset.w) * LOG_W;
  const sel = state.els.find((e) => e.id === selected) ?? null;

  // ── History ─────────────────────────────────────────────────────────
  const commit = useCallback(
    (force = false) => {
      const now = Date.now();
      if (!force && now - history.current.last < 400) return;
      history.current.past.push(JSON.stringify(state));
      if (history.current.past.length > 60) history.current.past.shift();
      history.current.future = [];
      history.current.last = now;
    },
    [state],
  );
  const undo = useCallback(() => {
    const prev = history.current.past.pop();
    if (!prev) return;
    history.current.future.push(JSON.stringify(state));
    setState(JSON.parse(prev));
    setSelected(null);
  }, [state]);
  const redo = useCallback(() => {
    const next = history.current.future.pop();
    if (!next) return;
    history.current.past.push(JSON.stringify(state));
    setState(JSON.parse(next));
    setSelected(null);
  }, [state]);

  const patchEl = (id: string, patch: Partial<El>) =>
    setState((s) => ({ ...s, els: s.els.map((e) => (e.id === id ? { ...e, ...patch } : e)) }));
  const setBg = (patch: Partial<Bg>) => {
    commit();
    setState((s) => ({ ...s, bg: { ...s.bg, ...patch } }));
  };

  // ── Element ops ─────────────────────────────────────────────────────
  const addEl = (el: El) => {
    commit(true);
    setState((s) => ({ ...s, els: [...s.els, el] }));
    setSelected(el.id);
  };
  const duplicateSel = useCallback(() => {
    if (!sel) return;
    const copy = { ...sel, id: uid(), x: clamp(sel.x + 24, 0, LOG_W), y: clamp(sel.y + 24, 0, logH) };
    commit(true);
    setState((s) => ({ ...s, els: [...s.els, copy] }));
    setSelected(copy.id);
  }, [sel, commit, logH]);
  const removeSel = useCallback(() => {
    if (!selected) return;
    commit(true);
    setState((s) => ({ ...s, els: s.els.filter((e) => e.id !== selected) }));
    setSelected(null);
  }, [selected, commit]);
  const reorderSel = (dir: 1 | -1) => {
    if (!selected) return;
    commit(true);
    setState((s) => {
      const i = s.els.findIndex((e) => e.id === selected);
      const j = i + dir;
      if (i < 0 || j < 0 || j >= s.els.length) return s;
      const els = [...s.els];
      [els[i], els[j]] = [els[j], els[i]];
      return { ...s, els };
    });
  };
  // Bring the selected element all the way to the front (end of the array,
  // rendered last / on top) or send it all the way to the back.
  const zSel = (where: "front" | "back") => {
    if (!selected) return;
    commit(true);
    setState((s) => {
      const el = s.els.find((e) => e.id === selected);
      if (!el) return s;
      const others = s.els.filter((e) => e.id !== selected);
      return { ...s, els: where === "front" ? [...others, el] : [el, ...others] };
    });
  };
  // Toggle a boolean flag on the selected element.
  const toggleSel = (key: "hidden" | "locked" | "flipX" | "flipY") => {
    if (!selected) return;
    commit(true);
    setState((s) => ({
      ...s,
      els: s.els.map((e) => (e.id === selected ? { ...e, [key]: !e[key] } : e)),
    }));
  };
  // Toggle a boolean flag on any element by id (used by layer-row eye/lock).
  const toggleFlag = (id: string, key: "hidden" | "locked") => {
    commit(true);
    setState((s) => ({
      ...s,
      els: s.els.map((e) => (e.id === id ? { ...e, [key]: !e[key] } : e)),
    }));
  };

  // Load a photo as the background image (cover-fitted). Compressed to keep
  // the serialized canvas well under the 195 KB save cap.
  async function addBgImage(file: File) {
    const src = await new Promise<string>((res, rej) => {
      const img = new Image();
      const fr = new FileReader();
      fr.onload = () => {
        img.onload = () => {
          const max = 1400;
          const k = Math.min(1, max / Math.max(img.width, img.height));
          const c = document.createElement("canvas");
          c.width = Math.round(img.width * k);
          c.height = Math.round(img.height * k);
          c.getContext("2d")!.drawImage(img, 0, 0, c.width, c.height);
          res(c.toDataURL("image/jpeg", 0.78));
        };
        img.onerror = rej;
        img.src = fr.result as string;
      };
      fr.onerror = rej;
      fr.readAsDataURL(file);
    });
    commit(true);
    setState((s) => ({ ...s, bg: { ...s.bg, image: src, imageOpacity: s.bg.imageOpacity ?? 1 } }));
  }

  // Center the selected element horizontally / vertically on the canvas.
  const alignSel = (axis: "h" | "v") => {
    if (!selected) return;
    commit(true);
    setState((s) => ({
      ...s,
      els: s.els.map((e) =>
        e.id === selected
          ? axis === "h"
            ? { ...e, x: LOG_W / 2 }
            : { ...e, y: logH / 2 }
          : e,
      ),
    }));
  };

  async function addImage(file: File) {
    const url = await new Promise<string>((res, rej) => {
      const img = new Image();
      const fr = new FileReader();
      fr.onload = () => {
        img.onload = () => {
          const max = 1000;
          const k = Math.min(1, max / Math.max(img.width, img.height));
          const c = document.createElement("canvas");
          c.width = Math.round(img.width * k);
          c.height = Math.round(img.height * k);
          c.getContext("2d")!.drawImage(img, 0, 0, c.width, c.height);
          res(c.toDataURL("image/jpeg", 0.82));
        };
        img.onerror = rej;
        img.src = fr.result as string;
      };
      fr.onerror = rej;
      fr.readAsDataURL(file);
    });
    const img = new Image();
    img.src = url;
    await img.decode().catch(() => null);
    const ratio = img.height / Math.max(1, img.width);
    addEl({ id: uid(), type: "image", x: LOG_W / 2, y: logH / 2, w: 240, h: Math.round(240 * ratio), color: "#fff", src: url, opacity: 1 });
  }

  async function addQr() {
    const link = `https://tippingjar.co.za/creator/${slug || "you"}`;
    const url = window.prompt("QR code link:", link);
    if (!url) return;
    const src = await QRCode.toDataURL(url, { width: 512, margin: 1, color: { dark: NAVY, light: "#FFFFFF" } });
    addEl({ id: uid(), type: "qr", x: LOG_W / 2, y: logH / 2, w: 140, h: 140, color: "#fff", src, opacity: 1 });
  }

  // Drops the creator's public tip URL as a pre-styled mono-font text block —
  // one click instead of typing it every time.
  function addTipLink() {
    const url = `tippingjar.co.za / ${slug || "you"}`;
    addEl(text({ x: LOG_W / 2, y: logH - 60, text: url, size: 20, font: "mono", color: NAVY, weight: 600 }));
  }

  // ── Pointer interactions ────────────────────────────────────────────
  const stageScale = () => (stageRef.current?.getBoundingClientRect().width ?? LOG_W) / LOG_W;

  function startDrag(e: React.PointerEvent, el: El) {
    e.stopPropagation();
    if (el.hidden) return;
    setSelected(el.id);
    if (el.locked) return; // selectable but not draggable
    commit(true);
    const rect = stageRef.current!.getBoundingClientRect();
    const k = stageScale();
    mode.current = { op: "drag", id: el.id, dx: e.clientX - rect.left - el.x * k, dy: e.clientY - rect.top - el.y * k };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  }
  function startResize(e: React.PointerEvent, el: El) {
    e.stopPropagation();
    commit(true);
    mode.current = {
      op: "resize", id: el.id,
      startW: el.w ?? 100, startH: el.h ?? 100, startSize: el.size ?? 28,
      sx: e.clientX, sy: e.clientY,
    };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  }
  function startRotate(e: React.PointerEvent, el: El) {
    e.stopPropagation();
    commit(true);
    mode.current = { op: "rotate", id: el.id };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  }

  function onMove(e: React.PointerEvent) {
    const m = mode.current;
    if (!m) return;
    const rect = stageRef.current!.getBoundingClientRect();
    const k = stageScale();
    const el = state.els.find((x) => x.id === m.id);
    if (!el) return;

    if (m.op === "drag") {
      let x = clamp((e.clientX - rect.left - m.dx) / k, 0, LOG_W);
      let y = clamp((e.clientY - rect.top - m.dy) / k, 0, logH);
      const snapV = Math.abs(x - LOG_W / 2) < 7;
      const snapH = Math.abs(y - logH / 2) < 7;
      if (snapV) x = LOG_W / 2;
      if (snapH) y = logH / 2;
      setGuides({ v: snapV, h: snapH });
      patchEl(m.id, { x, y });
    } else if (m.op === "resize") {
      const d = (e.clientX - m.sx + (e.clientY - m.sy)) / 2 / k;
      if (el.type === "text") {
        patchEl(m.id, { size: clamp(Math.round(m.startSize + d * 0.6), 10, 200) });
      } else {
        const ratio = m.startH / Math.max(1, m.startW);
        const keep = el.type === "circle" || el.type === "image" || el.type === "qr";
        const w = clamp(Math.round(m.startW + d), 16, 540);
        const h = keep ? Math.round(w * ratio) : clamp(Math.round(m.startH + (e.clientY - m.sy) / k), 8, 960);
        patchEl(m.id, { w, h });
      }
    } else {
      const cx = rect.left + el.x * k;
      const cy = rect.top + el.y * k;
      let deg = (Math.atan2(e.clientY - cy, e.clientX - cx) * 180) / Math.PI + 90;
      const snapped = Math.round(deg / 15) * 15;
      if (Math.abs(deg - snapped) < 4) deg = snapped;
      patchEl(m.id, { rotation: Math.round(((deg % 360) + 360) % 360) });
    }
  }
  const endPointer = () => {
    mode.current = null;
    setGuides({ v: false, h: false });
  };

  // ── Keyboard shortcuts ──────────────────────────────────────────────
  useEffect(() => {
    function onKey(e: KeyboardEvent) {
      const t = e.target as HTMLElement;
      if (t.tagName === "INPUT" || t.tagName === "TEXTAREA" || t.isContentEditable) return;
      const mod = e.metaKey || e.ctrlKey;
      if (mod && e.key.toLowerCase() === "z") {
        e.preventDefault();
        if (e.shiftKey) redo(); else undo();
      } else if (mod && e.key.toLowerCase() === "y") {
        e.preventDefault(); redo();
      } else if (mod && e.key.toLowerCase() === "d") {
        e.preventDefault(); duplicateSel();
      } else if (e.key === "Delete" || e.key === "Backspace") {
        if (selected) { e.preventDefault(); removeSel(); }
      } else if (selected && e.key === "[") {
        e.preventDefault(); e.shiftKey ? zSel("back") : reorderSel(-1);
      } else if (selected && e.key === "]") {
        e.preventDefault(); e.shiftKey ? zSel("front") : reorderSel(1);
      } else if (selected && !mod && /^[1-8]$/.test(e.key)) {
        // Quick swatch: number keys apply SWATCHES[n-1] to the selection.
        e.preventDefault();
        const c = SWATCHES[Number(e.key) - 1];
        if (c) patchEl(selected, { color: c });
      } else if (selected && !mod && e.key.toLowerCase() === "l") {
        e.preventDefault(); toggleSel("locked");
      } else if (selected && !mod && e.key.toLowerCase() === "h") {
        e.preventDefault(); toggleSel("hidden");
      } else if (!mod && e.shiftKey && e.key.toLowerCase() === "g") {
        e.preventDefault();
        setOverlay((o) => (o === "grid" ? "none" : "grid"));
      } else if (selected && ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(e.key)) {
        e.preventDefault();
        const step = e.shiftKey ? 10 : 2;
        const d = { ArrowUp: [0, -step], ArrowDown: [0, step], ArrowLeft: [-step, 0], ArrowRight: [step, 0] }[e.key]!;
        setState((s) => ({
          ...s,
          els: s.els.map((el) =>
            el.id === selected ? { ...el, x: clamp(el.x + d[0], 0, LOG_W), y: clamp(el.y + d[1], 0, logH) } : el,
          ),
        }));
      }
    }
    // Clipboard paste — accept an image from anywhere on the page.
    async function onPaste(e: ClipboardEvent) {
      const active = document.activeElement as HTMLElement | null;
      if (active && (active.tagName === "INPUT" || active.tagName === "TEXTAREA")) return;
      const item = Array.from(e.clipboardData?.items ?? []).find((it) => it.type.startsWith("image/"));
      if (!item) return;
      const file = item.getAsFile();
      if (file) { e.preventDefault(); await addImage(file); }
    }
    window.addEventListener("keydown", onKey);
    window.addEventListener("paste", onPaste);
    return () => {
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("paste", onPaste);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selected, undo, redo, duplicateSel, removeSel, logH]);

  // ── Gallery ─────────────────────────────────────────────────────────
  const loadGallery = useCallback(() => {
    if (!token) return;
    api.myDesigns(token).then(setGallery).catch(() => setGallery([]));
  }, [token]);
  useEffect(loadGallery, [loadGallery]);

  // ── Export painting ─────────────────────────────────────────────────
  async function paint(scaleTo: number): Promise<HTMLCanvasElement> {
    await document.fonts.ready.catch(() => null);
    const c = document.createElement("canvas");
    const k = scaleTo / LOG_W;
    c.width = scaleTo;
    c.height = Math.round(logH * k);
    const ctx = c.getContext("2d")!;

    const { bg } = state;
    if (bg.mode === "solid") {
      ctx.fillStyle = bg.c1;
    } else if (bg.mode === "radial") {
      const g = ctx.createRadialGradient(c.width / 2, c.height / 2, 10, c.width / 2, c.height / 2, Math.max(c.width, c.height) * 0.75);
      g.addColorStop(0, bg.c1);
      g.addColorStop(1, bg.c2);
      ctx.fillStyle = g;
    } else {
      const rad = ((bg.angle - 90) * Math.PI) / 180;
      const r = Math.sqrt(c.width ** 2 + c.height ** 2) / 2;
      const cx = c.width / 2, cy = c.height / 2;
      const g = ctx.createLinearGradient(cx - Math.cos(rad) * r, cy - Math.sin(rad) * r, cx + Math.cos(rad) * r, cy + Math.sin(rad) * r);
      g.addColorStop(0, bg.c1);
      g.addColorStop(1, bg.c2);
      ctx.fillStyle = g;
    }
    ctx.fillRect(0, 0, c.width, c.height);

    // Background photo, if any — cover-fit and honour opacity.
    if (bg.image) {
      const bgImg = await new Promise<HTMLImageElement | null>((res) => {
        const im = new Image();
        im.onload = () => res(im);
        im.onerror = () => res(null);
        im.src = bg.image!;
      });
      if (bgImg) {
        const rw = bgImg.width, rh = bgImg.height;
        const kk = Math.max(c.width / rw, c.height / rh);
        const dw = rw * kk, dh = rh * kk;
        ctx.save();
        ctx.globalAlpha = bg.imageOpacity ?? 1;
        ctx.drawImage(bgImg, (c.width - dw) / 2, (c.height - dh) / 2, dw, dh);
        ctx.restore();
      }
    }

    // preload images
    const imgs = new Map<string, HTMLImageElement>();
    await Promise.all(
      state.els
        .filter((e) => e.src && !e.hidden)
        .map(
          (e) =>
            new Promise<void>((res) => {
              const im = new Image();
              im.onload = () => { imgs.set(e.id, im); res(); };
              im.onerror = () => res();
              im.src = e.src!;
            }),
        ),
    );

    for (const el of state.els) {
      if (el.hidden) continue;
      ctx.save();
      ctx.globalAlpha = el.opacity ?? 1;
      ctx.translate(el.x * k, el.y * k);
      if (el.rotation) ctx.rotate((el.rotation * Math.PI) / 180);
      if (el.flipX || el.flipY) ctx.scale(el.flipX ? -1 : 1, el.flipY ? -1 : 1);

      if (el.type === "text") {
        const size = (el.size ?? 28) * k;
        const fam = FONTS[el.font ?? "display"].canvas;
        ctx.font = `${el.weight ?? 700} ${size}px ${fam}, system-ui, sans-serif`;
        try {
          (ctx as CanvasRenderingContext2D & { letterSpacing: string }).letterSpacing = `${(el.spacing ?? 0) * k}px`;
        } catch { /* older browsers */ }
        if (el.shadow) {
          ctx.shadowColor = "rgba(0,0,0,0.45)";
          ctx.shadowBlur = 8 * k;
          ctx.shadowOffsetY = 2 * k;
        }
        ctx.fillStyle = el.color;
        ctx.textBaseline = "middle";
        const lines = (el.text ?? "").split("\n");
        const lh = size * (el.lineHeight ?? 1.25);
        const widths = lines.map((l) => ctx.measureText(l).width);
        const maxW = Math.max(...widths, 1);
        lines.forEach((line, i) => {
          const ly = (i - (lines.length - 1) / 2) * lh;
          if (el.align === "left") { ctx.textAlign = "left"; ctx.fillText(line, -maxW / 2, ly); }
          else if (el.align === "right") { ctx.textAlign = "right"; ctx.fillText(line, maxW / 2, ly); }
          else { ctx.textAlign = "center"; ctx.fillText(line, 0, ly); }
        });
      } else if (el.type === "rect") {
        const w = (el.w ?? 100) * k, h = (el.h ?? 100) * k;
        ctx.fillStyle = el.color;
        ctx.beginPath();
        ctx.roundRect(-w / 2, -h / 2, w, h, (el.radius ?? 0) * k);
        ctx.fill();
        if (el.strokeWidth && el.strokeWidth > 0 && el.stroke) {
          ctx.strokeStyle = el.stroke;
          ctx.lineWidth = el.strokeWidth * k;
          ctx.stroke();
        }
      } else if (el.type === "circle") {
        ctx.fillStyle = el.color;
        ctx.beginPath();
        ctx.ellipse(0, 0, ((el.w ?? 100) / 2) * k, ((el.h ?? 100) / 2) * k, 0, 0, Math.PI * 2);
        ctx.fill();
      } else if (el.type === "line") {
        const w = (el.w ?? 200) * k;
        ctx.strokeStyle = el.color;
        ctx.lineWidth = (el.thickness ?? 6) * k;
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(-w / 2, 0);
        ctx.lineTo(w / 2, 0);
        ctx.stroke();
      } else if (el.type === "triangle") {
        const w = (el.w ?? 120) * k, h = (el.h ?? 110) * k;
        ctx.fillStyle = el.color;
        ctx.beginPath();
        ctx.moveTo(0, -h / 2);
        ctx.lineTo(w / 2, h / 2);
        ctx.lineTo(-w / 2, h / 2);
        ctx.closePath();
        ctx.fill();
      } else if (el.src) {
        const im = imgs.get(el.id);
        if (im) {
          const w = (el.w ?? 100) * k, h = (el.h ?? 100) * k;
          if (el.type === "qr") {
            ctx.fillStyle = "#FFFFFF";
            ctx.beginPath();
            ctx.roundRect(-w / 2 - 6 * k, -h / 2 - 6 * k, w + 12 * k, h + 12 * k, 10 * k);
            ctx.fill();
          }
          ctx.drawImage(im, -w / 2, -h / 2, w, h);
        }
      }
      ctx.restore();
    }
    return c;
  }

  async function exportAs(fmt: "png" | "jpeg" | "webp" | "clipboard", scale = 1) {
    setNote(null);
    const canvas = await paint(preset.w * scale);
    if (fmt === "clipboard") {
      try {
        const blob = await new Promise<Blob>((res) => canvas.toBlob((b) => res(b!), "image/png"));
        await navigator.clipboard.write([new ClipboardItem({ "image/png": blob })]);
        setNote("Copied to clipboard.");
      } catch {
        setNote("Clipboard not available in this browser — use Export PNG.");
      }
      return;
    }
    const a = document.createElement("a");
    a.href =
      fmt === "png"
        ? canvas.toDataURL("image/png")
        : canvas.toDataURL(fmt === "webp" ? "image/webp" : "image/jpeg", 0.92);
    a.download = `tipping-jar-${state.kind}${scale > 1 ? "@2x" : ""}.${fmt}`;
    a.click();
  }

  async function persist(asNew: boolean) {
    if (!token || busy) return;
    const canvas = JSON.stringify(state);
    if (canvas.length > MAX_CANVAS_BYTES) {
      setNote("This design is too large to save — reduce image size or count. You can still export it.");
      return;
    }
    setBusy(true);
    setNote(null);
    try {
      const thumb = (await paint(270)).toDataURL("image/jpeg", 0.8);
      const body = {
        title: (state.els.find((e) => e.type === "text")?.text ?? "Design").split("\n")[0].slice(0, 60),
        kind: state.kind,
        canvas,
        thumb,
      };
      if (!asNew && loadedId) {
        await api.updateDesign(token, loadedId, body);
        setNote("Design updated.");
      } else {
        const d = await api.saveDesign(token, body);
        setLoadedId(d.id);
        setNote("Saved to your gallery.");
      }
      loadGallery();
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not save the design.");
    } finally {
      setBusy(false);
    }
  }

  function loadDesign(d: StudioDesign) {
    try {
      const parsed = JSON.parse(d.canvas) as CanvasState & { bg1?: string; bg2?: string };
      // v1 designs stored bg1/bg2 flat — migrate on load
      const bg: Bg = parsed.bg ?? {
        mode: parsed.bg1 === parsed.bg2 ? "solid" : "linear",
        c1: parsed.bg1 ?? NAVY,
        c2: parsed.bg2 ?? GREEN,
        angle: 135,
      };
      if (Array.isArray(parsed.els)) {
        history.current = { past: [], future: [], last: 0 };
        setState({ kind: parsed.kind ?? "square", bg, els: parsed.els });
        setLoadedId(d.id);
        setSelected(null);
        setNote(`Loaded “${d.title || d.kind}”.`);
      }
    } catch {
      setNote("That design could not be loaded.");
    }
  }

  async function removeDesign(id: string) {
    if (!token) return;
    await api.deleteDesign(token, id).catch(() => null);
    if (id === loadedId) setLoadedId(null);
    setGallery((g) => g.filter((d) => d.id !== id));
  }

  // ── UI helpers ──────────────────────────────────────────────────────
  const chip = (active: boolean) =>
    `rounded-full px-3 py-1.5 text-xs font-semibold transition ${
      active ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
    }`;
  const cq = (v: number) => `calc(${(v / LOG_W) * 100} * 1cqw)`; // logical px → container units

  const label = (el: El) =>
    el.type === "text" ? (el.text ?? "Text").split("\n")[0].slice(0, 18) : el.type === "qr" ? "QR code" : el.type;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-xl font-extrabold tracking-tight text-ink">Creator Studio</h2>
          <p className="body-muted mt-1">
            Design share-ready graphics — templates, layers, brand fonts, your tip-link QR. Saved
            to your gallery on every device.
          </p>
        </div>
        <div className="flex gap-1.5">
          <button onClick={undo} className="btn-ghost !px-3 !py-1.5 text-xs" title="Undo (Ctrl+Z)"><i className="bi bi-arrow-counterclockwise" /></button>
          <button onClick={redo} className="btn-ghost !px-3 !py-1.5 text-xs" title="Redo (Ctrl+Shift+Z)"><i className="bi bi-arrow-clockwise" /></button>
        </div>
      </div>

      {/* Templates */}
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-mono text-[11px] uppercase tracking-[0.16em] text-muted">Templates</span>
        {TEMPLATES.map((t) => (
          <button
            key={t.name}
            onClick={() => {
              history.current = { past: [], future: [], last: 0 };
              setState(JSON.parse(JSON.stringify(t.state)));
              setLoadedId(null);
              setSelected(null);
            }}
            className={chip(false)}
          >
            {t.name}
          </button>
        ))}
      </div>

      {/* Size + insert toolbar */}
      <div className="flex flex-wrap items-center gap-2">
        {(Object.keys(PRESETS) as Kind[]).map((k) => (
          <button key={k} onClick={() => { commit(true); setState((s) => ({ ...s, kind: k })); }} className={chip(state.kind === k)}>
            {PRESETS[k].label}
          </button>
        ))}
        <span className="mx-1 h-5 w-px bg-border" />
        <button onClick={() => addEl(text({ x: LOG_W / 2, y: logH / 2, text: "New text", size: 28 }))} className={chip(false)}><i className="bi bi-type" /> Text</button>
        <button onClick={() => addEl({ id: uid(), type: "rect", x: LOG_W / 2, y: logH / 2, w: 180, h: 100, radius: 16, color: GOLD, opacity: 1 })} className={chip(false)}><i className="bi bi-square-fill" /> Rect</button>
        <button onClick={() => addEl({ id: uid(), type: "circle", x: LOG_W / 2, y: logH / 2, w: 120, h: 120, color: MINT, opacity: 1 })} className={chip(false)}><i className="bi bi-circle-fill" /> Circle</button>
        <button onClick={() => addEl({ id: uid(), type: "line", x: LOG_W / 2, y: logH / 2, w: 220, h: 8, thickness: 6, color: "#FFFFFF", opacity: 1 })} className={chip(false)}><i className="bi bi-dash-lg" /> Line</button>
        <button onClick={() => addEl({ id: uid(), type: "triangle", x: LOG_W / 2, y: logH / 2, w: 120, h: 110, color: GOLD, opacity: 1 })} className={chip(false)}><i className="bi bi-triangle-fill" /> Triangle</button>
        <div className="relative">
          <button onClick={() => setStickerOpen((v) => !v)} className={chip(stickerOpen)}><i className="bi bi-emoji-smile" /> Sticker</button>
          {stickerOpen && (
            <div className="absolute left-0 top-9 z-20 grid grid-cols-6 gap-1 rounded-xl border border-border bg-white p-2 shadow-lift">
              {STICKERS.map((s) => (
                <button
                  key={s}
                  className="rounded-lg p-1.5 text-xl hover:bg-darker"
                  onClick={() => {
                    setStickerOpen(false);
                    addEl(text({ x: LOG_W / 2, y: logH / 2, text: s, size: 64 }));
                  }}
                >
                  {s}
                </button>
              ))}
            </div>
          )}
        </div>
        <button onClick={() => fileRef.current?.click()} className={chip(false)}><i className="bi bi-image" /> Image</button>
        <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => { const f = e.target.files?.[0]; if (f) addImage(f); e.target.value = ""; }} />
        <button onClick={addQr} className={chip(false)}><i className="bi bi-qr-code" /> Tip-link QR</button>
        <button onClick={addTipLink} className={chip(false)} title="Insert your tipping-jar URL as pre-styled text">
          <i className="bi bi-link-45deg" /> Tip URL
        </button>
        <span className="mx-1 h-5 w-px bg-border" />
        <button
          onClick={() => setOverlay((o) => (o === "grid" ? "none" : "grid"))}
          className={chip(overlay === "grid")}
          title="Toggle grid overlay (Shift+G)"
        >
          <i className="bi bi-grid-3x3" /> Grid
        </button>
        <button
          onClick={() => setOverlay((o) => (o === "safe" ? "none" : "safe"))}
          className={chip(overlay === "safe")}
          title="Toggle safe-area overlay"
        >
          <i className="bi bi-aspect-ratio" /> Safe area
        </button>
        <details className="ml-auto">
          <summary className="cursor-pointer text-xs font-medium text-muted hover:text-ink">
            <i className="bi bi-keyboard mr-1" /> Shortcuts
          </summary>
          <div className="absolute z-20 mt-2 w-72 rounded-xl border border-border bg-white p-3 shadow-lift">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">Editing</p>
            <ul className="mt-1.5 space-y-1 font-mono text-[11px] text-ink">
              <li className="flex justify-between"><span>Undo / Redo</span><span className="text-muted">⌘Z / ⇧⌘Z</span></li>
              <li className="flex justify-between"><span>Duplicate selection</span><span className="text-muted">⌘D</span></li>
              <li className="flex justify-between"><span>Nudge / big nudge</span><span className="text-muted">arrows / ⇧arrows</span></li>
              <li className="flex justify-between"><span>Delete</span><span className="text-muted">⌫</span></li>
              <li className="flex justify-between"><span>Send back / forward</span><span className="text-muted">[ / ]</span></li>
              <li className="flex justify-between"><span>To back / front</span><span className="text-muted">⇧[ / ⇧]</span></li>
              <li className="flex justify-between"><span>Apply swatch</span><span className="text-muted">1 – 8</span></li>
              <li className="flex justify-between"><span>Paste image</span><span className="text-muted">⌘V</span></li>
              <li className="flex justify-between"><span>Lock / Hide selection</span><span className="text-muted">L / H</span></li>
              <li className="flex justify-between"><span>Grid overlay</span><span className="text-muted">⇧G</span></li>
            </ul>
          </div>
        </details>
      </div>

      <div className="grid gap-6 xl:grid-cols-[1fr_320px]">
        {/* ── Stage ── */}
        <div className="card grid place-items-center !p-6">
          <div
            ref={stageRef}
            onPointerMove={onMove}
            onPointerUp={endPointer}
            onPointerDown={() => setSelected(null)}
            className="relative w-full max-w-[540px] touch-none select-none overflow-hidden rounded-xl shadow-lift"
            style={{
              aspectRatio: `${preset.w} / ${preset.h}`,
              containerType: "inline-size",
              background:
                state.bg.mode === "solid"
                  ? state.bg.c1
                  : state.bg.mode === "radial"
                    ? `radial-gradient(circle at 50% 50%, ${state.bg.c1}, ${state.bg.c2})`
                    : `linear-gradient(${state.bg.angle}deg, ${state.bg.c1}, ${state.bg.c2})`,
            }}
          >
            {/* background photo */}
            {state.bg.image && (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={state.bg.image}
                alt=""
                draggable={false}
                className="pointer-events-none absolute inset-0 h-full w-full object-cover"
                style={{ opacity: state.bg.imageOpacity ?? 1 }}
              />
            )}

            {/* grid overlay */}
            {overlay === "grid" && (
              <div
                className="pointer-events-none absolute inset-0"
                style={{
                  backgroundImage:
                    "linear-gradient(to right, rgba(255,255,255,0.14) 1px, transparent 1px)," +
                    "linear-gradient(to bottom, rgba(255,255,255,0.14) 1px, transparent 1px)",
                  backgroundSize: "10% 10%",
                  mixBlendMode: "difference",
                }}
              />
            )}
            {/* safe-area overlay — a 90% inset frame most social crops respect */}
            {overlay === "safe" && (
              <div className="pointer-events-none absolute inset-[5%] rounded-lg border-2 border-dashed border-mint/70" />
            )}

            {/* snap guides */}
            {guides.v && <span className="pointer-events-none absolute inset-y-0 left-1/2 w-px bg-mint" />}
            {guides.h && <span className="pointer-events-none absolute inset-x-0 top-1/2 h-px bg-mint" />}

            {state.els.map((el) => {
              if (el.hidden) return null;
              const isSel = el.id === selected;
              const sx = el.flipX ? -1 : 1;
              const sy = el.flipY ? -1 : 1;
              const base: React.CSSProperties = {
                left: `${(el.x / LOG_W) * 100}%`,
                top: `${(el.y / logH) * 100}%`,
                transform: `translate(-50%, -50%) rotate(${el.rotation ?? 0}deg) scale(${sx}, ${sy})`,
                opacity: el.opacity ?? 1,
              };
              let body: React.ReactNode = null;
              if (el.type === "text") {
                body = (
                  <div
                    style={{
                      color: el.color,
                      fontWeight: el.weight ?? 700,
                      fontFamily: FONTS[el.font ?? "display"].css,
                      fontSize: cq(el.size ?? 28),
                      letterSpacing: cq(el.spacing ?? 0),
                      lineHeight: el.lineHeight ?? 1.25,
                      whiteSpace: "pre",
                      textAlign: el.align ?? "center",
                      textShadow: el.shadow ? "0 2px 8px rgba(0,0,0,0.45)" : undefined,
                    }}
                  >
                    {el.text}
                  </div>
                );
              } else if (el.type === "line") {
                body = <div style={{ width: cq(el.w ?? 220), height: cq(el.thickness ?? 6), background: el.color, borderRadius: 999 }} />;
              } else if (el.type === "triangle") {
                body = <div style={{ width: cq(el.w ?? 120), height: cq(el.h ?? 110), background: el.color, clipPath: "polygon(50% 0, 100% 100%, 0 100%)" }} />;
              } else if (el.type === "image" || el.type === "qr") {
                body = (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={el.src}
                    alt=""
                    draggable={false}
                    style={{
                      width: cq(el.w ?? 100),
                      aspectRatio: `${el.w ?? 100} / ${el.h ?? 100}`,
                      objectFit: "cover",
                      borderRadius: el.type === "qr" ? 8 : 6,
                      background: el.type === "qr" ? "#fff" : undefined,
                      padding: el.type === "qr" ? "0.6cqw" : undefined,
                    }}
                  />
                );
              } else {
                const stroked = el.type === "rect" && el.strokeWidth && el.stroke;
                body = (
                  <div
                    style={{
                      width: cq(el.w ?? 100),
                      aspectRatio: `${el.w ?? 100} / ${el.h ?? 100}`,
                      background: el.color,
                      borderRadius: el.type === "circle" ? "50%" : cq(el.radius ?? 0),
                      boxShadow: stroked ? `inset 0 0 0 ${cq(el.strokeWidth ?? 0)} ${el.stroke}` : undefined,
                    }}
                  />
                );
              }
              return (
                <div
                  key={el.id}
                  onPointerDown={(e) => startDrag(e, el)}
                  className="absolute cursor-move"
                  style={{ ...base, boxShadow: isSel ? "0 0 0 2px #57CE8B" : undefined, borderRadius: 4 }}
                >
                  {body}
                  {isSel && (
                    <>
                      <span
                        onPointerDown={(e) => startRotate(e, el)}
                        className="absolute -top-6 left-1/2 h-4 w-4 -translate-x-1/2 cursor-grab rounded-full border-2 border-white bg-green shadow"
                        title="Rotate"
                      />
                      <span
                        onPointerDown={(e) => startResize(e, el)}
                        className="absolute -bottom-2 -right-2 h-4 w-4 cursor-nwse-resize rounded-full border-2 border-white bg-primary shadow"
                        title="Resize"
                      />
                    </>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* ── Right panel ── */}
        <div className="space-y-4">
          {/* Background */}
          <div className="card !p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Background</p>
            <div className="mt-2 flex gap-1.5">
              {(["solid", "linear", "radial"] as const).map((m) => (
                <button key={m} onClick={() => setBg({ mode: m })} className={chip(state.bg.mode === m)}>{m}</button>
              ))}
            </div>
            <div className="mt-3 flex items-center gap-2">
              <input type="color" value={state.bg.c1} onChange={(e) => setBg({ c1: e.target.value })} className="h-8 w-10 cursor-pointer rounded border border-border" aria-label="Colour 1" />
              {state.bg.mode !== "solid" && (
                <input type="color" value={state.bg.c2} onChange={(e) => setBg({ c2: e.target.value })} className="h-8 w-10 cursor-pointer rounded border border-border" aria-label="Colour 2" />
              )}
              {state.bg.mode === "linear" && (
                <label className="ml-auto flex items-center gap-2 text-xs text-muted">
                  {state.bg.angle}°
                  <input type="range" min={0} max={360} value={state.bg.angle} onChange={(e) => setBg({ angle: Number(e.target.value) })} className="tip-range !w-24" />
                </label>
              )}
            </div>
            <div className="mt-3 flex flex-wrap items-center gap-2">
              <button
                onClick={() => bgFileRef.current?.click()}
                className={chip(!!state.bg.image)}
                title="Set a background photo (cover-fitted)"
              >
                <i className="bi bi-image" /> {state.bg.image ? "Change photo" : "Add photo"}
              </button>
              {state.bg.image && (
                <>
                  <button
                    onClick={() => setBg({ image: undefined })}
                    className="text-xs font-medium text-muted hover:text-red-500"
                  >
                    <i className="bi bi-x-lg" /> Remove
                  </button>
                  <label className="ml-auto flex items-center gap-2 text-xs text-muted">
                    {Math.round((state.bg.imageOpacity ?? 1) * 100)}%
                    <input
                      type="range"
                      min={10}
                      max={100}
                      value={Math.round((state.bg.imageOpacity ?? 1) * 100)}
                      onChange={(e) => setBg({ imageOpacity: Number(e.target.value) / 100 })}
                      className="tip-range !w-24"
                    />
                  </label>
                </>
              )}
              <input
                ref={bgFileRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => {
                  const f = e.target.files?.[0];
                  if (f) addBgImage(f);
                  e.target.value = "";
                }}
              />
            </div>
          </div>

          {/* Selected element */}
          {sel && (
            <div className="card space-y-3 !p-4">
              <div className="flex items-center justify-between">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">{label(sel)}</p>
                <div className="flex gap-1">
                  <button onClick={() => zSel("back")} className="rounded p-1 text-muted hover:text-ink" title="Send to back (Shift+[)"><i className="bi bi-chevron-double-down" /></button>
                  <button onClick={() => reorderSel(-1)} className="rounded p-1 text-muted hover:text-ink" title="Send backward ([)"><i className="bi bi-layer-backward" /></button>
                  <button onClick={() => reorderSel(1)} className="rounded p-1 text-muted hover:text-ink" title="Bring forward (])"><i className="bi bi-layer-forward" /></button>
                  <button onClick={() => zSel("front")} className="rounded p-1 text-muted hover:text-ink" title="Bring to front (Shift+])"><i className="bi bi-chevron-double-up" /></button>
                  <span className="mx-1 h-4 w-px bg-border" />
                  <button onClick={() => alignSel("h")} className="rounded p-1 text-muted hover:text-ink" title="Centre horizontally"><i className="bi bi-align-center" /></button>
                  <button onClick={() => alignSel("v")} className="rounded p-1 text-muted hover:text-ink" title="Centre vertically"><i className="bi bi-align-middle" /></button>
                  <span className="mx-1 h-4 w-px bg-border" />
                  <button onClick={() => toggleSel("flipX")} className={`rounded p-1 ${sel.flipX ? "text-primary" : "text-muted hover:text-ink"}`} title="Flip horizontally"><i className="bi bi-symmetry-horizontal" /></button>
                  <button onClick={() => toggleSel("flipY")} className={`rounded p-1 ${sel.flipY ? "text-primary" : "text-muted hover:text-ink"}`} title="Flip vertically"><i className="bi bi-symmetry-vertical" /></button>
                  <button onClick={() => toggleSel("locked")} className={`rounded p-1 ${sel.locked ? "text-primary" : "text-muted hover:text-ink"}`} title="Lock (L)"><i className={`bi ${sel.locked ? "bi-lock-fill" : "bi-unlock"}`} /></button>
                  <button onClick={() => toggleSel("hidden")} className={`rounded p-1 ${sel.hidden ? "text-primary" : "text-muted hover:text-ink"}`} title="Hide (H)"><i className={`bi ${sel.hidden ? "bi-eye-slash" : "bi-eye"}`} /></button>
                  <span className="mx-1 h-4 w-px bg-border" />
                  <button onClick={duplicateSel} className="rounded p-1 text-muted hover:text-ink" title="Duplicate (Ctrl+D)"><i className="bi bi-copy" /></button>
                  <button onClick={removeSel} className="rounded p-1 text-red-500" title="Delete"><i className="bi bi-trash" /></button>
                </div>
              </div>

              {/* Precise position — the numeric X/Y row shows what the
                  drag surface gives you but lets you snap to a pixel. */}
              <div className="grid grid-cols-2 gap-2">
                <label className="text-[11px] text-muted">
                  X
                  <input
                    type="number"
                    value={Math.round(sel.x)}
                    onChange={(e) => patchEl(sel.id, { x: clamp(Number(e.target.value), 0, LOG_W) })}
                    className="mt-0.5 w-full rounded border border-border bg-white px-2 py-1 text-xs text-ink focus:border-primary/40 focus:outline-none"
                  />
                </label>
                <label className="text-[11px] text-muted">
                  Y
                  <input
                    type="number"
                    value={Math.round(sel.y)}
                    onChange={(e) => patchEl(sel.id, { y: clamp(Number(e.target.value), 0, logH) })}
                    className="mt-0.5 w-full rounded border border-border bg-white px-2 py-1 text-xs text-ink focus:border-primary/40 focus:outline-none"
                  />
                </label>
              </div>

              {sel.type === "text" && (
                <>
                  <textarea
                    value={sel.text ?? ""}
                    rows={2}
                    onChange={(e) => patchEl(sel.id, { text: e.target.value })}
                    className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
                  />
                  <div className="flex gap-1.5">
                    {(Object.keys(FONTS) as Font[]).map((f) => (
                      <button key={f} onClick={() => patchEl(sel.id, { font: f })} className={chip((sel.font ?? "display") === f)}>
                        {FONTS[f].label}
                      </button>
                    ))}
                  </div>
                  <div className="flex gap-1.5">
                    {(["left", "center", "right"] as const).map((a) => (
                      <button key={a} onClick={() => patchEl(sel.id, { align: a })} className={chip((sel.align ?? "center") === a)}>
                        <i className={`bi bi-text-${a === "center" ? "center" : a}`} />
                      </button>
                    ))}
                    <button onClick={() => patchEl(sel.id, { shadow: !sel.shadow })} className={chip(!!sel.shadow)} title="Text shadow">
                      <i className="bi bi-back" /> Shadow
                    </button>
                  </div>
                  <label className="block text-xs text-muted">Size · {sel.size ?? 28}
                    <input type="range" min={10} max={140} value={sel.size ?? 28} onChange={(e) => patchEl(sel.id, { size: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">Weight · {sel.weight ?? 700}
                    <input type="range" min={300} max={900} step={100} value={sel.weight ?? 700} onChange={(e) => patchEl(sel.id, { weight: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">Letter spacing · {sel.spacing ?? 0}
                    <input type="range" min={-2} max={20} value={sel.spacing ?? 0} onChange={(e) => patchEl(sel.id, { spacing: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">Line height · {(sel.lineHeight ?? 1.25).toFixed(2)}
                    <input
                      type="range" min={90} max={220} step={5}
                      value={Math.round((sel.lineHeight ?? 1.25) * 100)}
                      onChange={(e) => patchEl(sel.id, { lineHeight: Number(e.target.value) / 100 })}
                      className="tip-range mt-1"
                    />
                  </label>
                </>
              )}

              {(sel.type === "rect" || sel.type === "circle" || sel.type === "triangle" || sel.type === "image" || sel.type === "qr") && (
                <label className="block text-xs text-muted">Size · {sel.w ?? 100}
                  <input
                    type="range" min={24} max={520} value={sel.w ?? 100}
                    onChange={(e) => {
                      const w = Number(e.target.value);
                      const ratio = (sel.h ?? 100) / Math.max(1, sel.w ?? 100);
                      patchEl(sel.id, { w, h: Math.round(w * ratio) });
                    }}
                    className="tip-range mt-1"
                  />
                </label>
              )}
              {sel.type === "rect" && (
                <>
                  <label className="block text-xs text-muted">Corner radius · {sel.radius ?? 0}
                    <input type="range" min={0} max={120} value={sel.radius ?? 0} onChange={(e) => patchEl(sel.id, { radius: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <div className="grid grid-cols-[auto_1fr] gap-2">
                    <label className="text-[11px] text-muted">
                      Stroke
                      <input
                        type="color"
                        value={/^#/.test(sel.stroke ?? "") ? (sel.stroke as string) : "#0F2439"}
                        onChange={(e) => patchEl(sel.id, { stroke: e.target.value, strokeWidth: sel.strokeWidth || 4 })}
                        className="mt-0.5 h-7 w-full cursor-pointer rounded border border-border"
                        aria-label="Stroke colour"
                      />
                    </label>
                    <label className="text-[11px] text-muted">
                      Width · {sel.strokeWidth ?? 0}
                      <input
                        type="range" min={0} max={40}
                        value={sel.strokeWidth ?? 0}
                        onChange={(e) => patchEl(sel.id, { strokeWidth: Number(e.target.value) })}
                        className="tip-range mt-0.5"
                      />
                    </label>
                  </div>
                </>
              )}
              {sel.type === "line" && (
                <>
                  <label className="block text-xs text-muted">Length · {sel.w ?? 220}
                    <input type="range" min={30} max={520} value={sel.w ?? 220} onChange={(e) => patchEl(sel.id, { w: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">Thickness · {sel.thickness ?? 6}
                    <input type="range" min={2} max={40} value={sel.thickness ?? 6} onChange={(e) => patchEl(sel.id, { thickness: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                </>
              )}

              <label className="block text-xs text-muted">Rotation · {sel.rotation ?? 0}°
                <input type="range" min={0} max={359} value={sel.rotation ?? 0} onChange={(e) => patchEl(sel.id, { rotation: Number(e.target.value) })} className="tip-range mt-1" />
              </label>
              <label className="block text-xs text-muted">Opacity · {Math.round((sel.opacity ?? 1) * 100)}%
                <input type="range" min={10} max={100} value={Math.round((sel.opacity ?? 1) * 100)} onChange={(e) => patchEl(sel.id, { opacity: Number(e.target.value) / 100 })} className="tip-range mt-1" />
              </label>

              {sel.type !== "image" && sel.type !== "qr" && (
                <div className="flex flex-wrap gap-1.5">
                  {SWATCHES.map((c) => (
                    <button key={c} onClick={() => patchEl(sel.id, { color: c })} className="h-6 w-6 rounded-full border border-border" style={{ background: c, outline: sel.color === c ? "2px solid var(--green)" : undefined, outlineOffset: 1 }} aria-label={`Colour ${c}`} />
                  ))}
                  <input type="color" value={/^#/.test(sel.color) ? sel.color : "#ffffff"} onChange={(e) => patchEl(sel.id, { color: e.target.value })} className="h-6 w-8 cursor-pointer rounded border border-border" aria-label="Custom colour" />
                </div>
              )}
            </div>
          )}

          {/* Layers */}
          {state.els.length > 0 && (
            <div className="card !p-4">
              <div className="flex items-center justify-between">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                  Layers · {state.els.length}
                </p>
                <span className="text-[10px] font-mono text-muted">top → bottom</span>
              </div>
              <div className="mt-2 space-y-1">
                {[...state.els].reverse().map((el) => {
                  const active = el.id === selected;
                  return (
                    <div
                      key={el.id}
                      className={`group flex items-center gap-1 rounded-lg px-1.5 py-1 transition ${
                        active ? "bg-mint/15" : "hover:bg-darker"
                      }`}
                    >
                      <button
                        onClick={() => setSelected(el.id)}
                        className="flex flex-1 items-center gap-2 truncate text-left text-xs font-medium text-ink"
                        title="Select layer"
                      >
                        <i className={`bi ${
                          el.type === "text" ? "bi-type" : el.type === "image" ? "bi-image" : el.type === "qr" ? "bi-qr-code"
                          : el.type === "circle" ? "bi-circle-fill" : el.type === "line" ? "bi-dash-lg" : el.type === "triangle" ? "bi-triangle-fill" : "bi-square-fill"
                        } ${el.hidden ? "opacity-40" : ""}`} />
                        <span className={`truncate ${el.hidden ? "italic text-muted" : ""}`}>{label(el)}</span>
                      </button>
                      <button
                        onClick={() => toggleFlag(el.id, "hidden")}
                        className="rounded p-1 text-muted hover:text-ink"
                        title={el.hidden ? "Show layer" : "Hide layer"}
                      >
                        <i className={`bi ${el.hidden ? "bi-eye-slash" : "bi-eye"}`} />
                      </button>
                      <button
                        onClick={() => toggleFlag(el.id, "locked")}
                        className={`rounded p-1 ${el.locked ? "text-primary" : "text-muted hover:text-ink"}`}
                        title={el.locked ? "Unlock layer" : "Lock layer"}
                      >
                        <i className={`bi ${el.locked ? "bi-lock-fill" : "bi-unlock"}`} />
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Export + save */}
          <div className="card space-y-2 !p-4">
            <div className="grid grid-cols-2 gap-2">
              <button onClick={() => exportAs("png")} className="btn-primary !py-2.5 text-sm"><i className="bi bi-download" /> PNG</button>
              <button onClick={() => exportAs("png", 2)} className="btn-ghost !py-2.5 text-sm">PNG @2x</button>
              <button onClick={() => exportAs("jpeg")} className="btn-ghost !py-2.5 text-sm">JPEG</button>
              <button onClick={() => exportAs("webp")} className="btn-ghost !py-2.5 text-sm">WEBP</button>
              <button onClick={() => exportAs("clipboard")} className="btn-ghost !py-2.5 text-sm col-span-2"><i className="bi bi-clipboard" /> Copy</button>
            </div>
            <button onClick={() => persist(false)} disabled={!token || busy} className="btn-primary w-full !py-2.5 text-sm disabled:cursor-not-allowed disabled:opacity-50">
              {busy ? "Saving…" : loadedId ? <><i className="bi bi-cloud-arrow-up" /> Update design</> : <><i className="bi bi-cloud-arrow-up" /> Save to gallery</>}
            </button>
            {loadedId && (
              <button onClick={() => persist(true)} disabled={!token || busy} className="btn-ghost w-full !py-2 text-xs disabled:opacity-50">
                Save as copy
              </button>
            )}
            {note && <p className="text-xs text-teal">{note}</p>}
          </div>
        </div>
      </div>

      {/* Gallery */}
      <div>
        <h3 className="mb-3 text-base font-bold text-ink">Your gallery</h3>
        {gallery.length === 0 ? (
          <div className="card grid place-items-center py-10 text-center">
            <div className="text-3xl text-teal"><i className="bi bi-images" /></div>
            <p className="mt-3 font-semibold text-ink">No saved designs yet</p>
            <p className="body-muted mt-1">Design something above and save it to your gallery.</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
            {gallery.map((d) => (
              <div key={d.id} className={`card group relative overflow-hidden !p-2 ${d.id === loadedId ? "ring-2 ring-mint" : ""}`}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={d.thumb || undefined} alt={d.title || d.kind} className="w-full cursor-pointer rounded-lg" onClick={() => loadDesign(d)} />
                <div className="mt-1.5 flex items-center justify-between px-1">
                  <span className="truncate text-xs font-semibold text-ink">{d.title || d.kind}</span>
                  <button onClick={() => removeDesign(d.id)} className="text-xs text-muted hover:text-red-500" aria-label="Delete design">
                    <i className="bi bi-trash" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
