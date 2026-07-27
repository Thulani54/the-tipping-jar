"use client";

// Creator Studio — an advanced promo-graphic editor for the tip page.
// Vector + image canvas with drag/arrange, rich text, shapes, uploaded photos,
// per-element effects (opacity, rotation, shadow, glow, letter-spacing), undo/
// redo, PNG / JPEG / WEBP export, and a gallery persisted to the Rust creators
// service (/creators/studio/designs) as a JSON canvas blob + PNG thumbnail.

import { useCallback, useEffect, useRef, useState } from "react";
import {
  Palette, Undo2, Redo2, Heading, Type, Square, Circle, Triangle, Minus,
  ImagePlus, Copy, BringToFront, SendToBack, Trash2, Download, CloudUpload,
  AlignLeft, AlignCenter, AlignRight, Italic, Sparkles, Contrast, Droplet,
  RotateCw, MoveHorizontal, MoveVertical, MousePointerClick, Image as ImageIcon,
} from "lucide-react";
import { api } from "@/lib/api";
import type { StudioDesign } from "@/types";

const LOG_W = 540; // logical canvas width
const MAX_CANVAS_BYTES = 195_000; // backend rejects canvas JSON > 200KB

type Kind = "square" | "portrait" | "story" | "landscape" | "wide";
const PRESETS: Record<Kind, { label: string; w: number; h: number }> = {
  square: { label: "Square", w: 1080, h: 1080 },
  portrait: { label: "Portrait", w: 1080, h: 1350 },
  story: { label: "Story", w: 1080, h: 1920 },
  landscape: { label: "Landscape", w: 1920, h: 1080 },
  wide: { label: "Banner", w: 1500, h: 500 },
};

type ElType = "text" | "rect" | "circle" | "triangle" | "line" | "image";
type Align = "left" | "center" | "right";

type El = {
  id: string;
  type: ElType;
  x: number;
  y: number;
  // text
  text?: string;
  size?: number;
  weight?: number;
  font?: string;
  italic?: boolean;
  align?: Align;
  spacing?: number; // letter spacing (logical px)
  // shapes / image
  w?: number;
  h?: number;
  radius?: number;
  thickness?: number; // line
  src?: string; // image data-URL
  color: string;
  // effects
  opacity?: number;
  rotation?: number;
  shadow?: boolean;
  glow?: boolean;
};

type BgType = "solid" | "gradient";
type CanvasState = {
  kind: Kind;
  bgType: BgType;
  bg1: string;
  bg2: string;
  angle: number;
  els: El[];
};

const uid = () => Math.random().toString(36).slice(2, 9);

const FONTS: { label: string; value: string }[] = [
  { label: "Sans", value: "system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif" },
  { label: "Serif", value: "Georgia, 'Times New Roman', serif" },
  { label: "Mono", value: "'Courier New', ui-monospace, monospace" },
  { label: "Rounded", value: "'Trebuchet MS', 'Segoe UI', sans-serif" },
  { label: "Impact", value: "Impact, 'Arial Black', sans-serif" },
];

const BG_SOLIDS = [
  "#0F2439", "#12A25C", "#57CE8B", "#E0A536", "#111827", "#FFFFFF",
  "#F43F5E", "#3B82F6", "#8B5CF6", "#F59E0B", "#10B981", "#EC4899",
  "#1E293B", "#0EA5E9", "#EF4444", "#FDE68A",
];
const BG_GRADS: [string, string, number][] = [
  ["#0F2439", "#12A25C", 135],
  ["#12A25C", "#57CE8B", 135],
  ["#0F2439", "#4C1D95", 150],
  ["#E0A536", "#F43F5E", 130],
  ["#3B82F6", "#8B5CF6", 135],
  ["#111827", "#334155", 160],
  ["#F59E0B", "#EC4899", 120],
  ["#0EA5E9", "#22D3EE", 135],
  ["#EC4899", "#8B5CF6", 135],
  ["#065F46", "#10B981", 140],
];

const SWATCHES = [
  "#FFFFFF", "#0F2439", "#12A25C", "#57CE8B", "#E0A536", "#F43F5E",
  "#3B82F6", "#8B5CF6", "#111827", "#F59E0B", "#EC4899", "#000000",
];

const DEFAULT_STATE: CanvasState = {
  kind: "square",
  bgType: "gradient",
  bg1: "#0F2439",
  bg2: "#12A25C",
  angle: 135,
  els: [
    { id: uid(), type: "text", x: 270, y: 210, text: "Support my work", size: 46, weight: 800, font: FONTS[0].value, align: "center", color: "#FFFFFF" },
    { id: uid(), type: "rect", x: 270, y: 300, w: 120, h: 5, radius: 3, color: "#57CE8B" },
    { id: uid(), type: "text", x: 270, y: 360, text: "tippingjar.co.za/creator/you", size: 20, weight: 500, font: FONTS[2].value, align: "center", color: "#57CE8B" },
  ],
};

function normalize(parsed: Partial<CanvasState> & { els?: El[] }): CanvasState {
  const bg1 = parsed.bg1 ?? "#0F2439";
  const bg2 = parsed.bg2 ?? bg1;
  return {
    kind: (parsed.kind as Kind) ?? "square",
    bgType: parsed.bgType ?? (bg1 === bg2 ? "solid" : "gradient"),
    bg1,
    bg2,
    angle: typeof parsed.angle === "number" ? parsed.angle : 135,
    els: Array.isArray(parsed.els) ? parsed.els.map((e) => ({ ...e })) : [],
  };
}

const TEMPLATES: { label: string; make: () => CanvasState }[] = [
  {
    label: "Bold",
    make: () => ({
      kind: "square", bgType: "gradient", bg1: "#0F2439", bg2: "#12A25C", angle: 135,
      els: [
        { id: uid(), type: "text", x: 270, y: 200, text: "BACK MY\nWORK", size: 64, weight: 800, font: FONTS[4].value, align: "center", color: "#FFFFFF" },
        { id: uid(), type: "text", x: 270, y: 360, text: "Every tip counts", size: 22, weight: 600, font: FONTS[0].value, align: "center", color: "#57CE8B" },
      ],
    }),
  },
  {
    label: "Minimal",
    make: () => ({
      kind: "square", bgType: "solid", bg1: "#FFFFFF", bg2: "#FFFFFF", angle: 135,
      els: [
        { id: uid(), type: "circle", x: 270, y: 190, w: 90, h: 90, color: "#12A25C" },
        { id: uid(), type: "text", x: 270, y: 300, text: "Thank you for\nyour support", size: 40, weight: 700, font: FONTS[1].value, align: "center", color: "#0F2439" },
        { id: uid(), type: "text", x: 270, y: 400, text: "@yourhandle", size: 18, weight: 500, font: FONTS[2].value, align: "center", color: "#5A6B7B" },
      ],
    }),
  },
  {
    label: "Goal",
    make: () => ({
      kind: "portrait", bgType: "gradient", bg1: "#3B82F6", bg2: "#8B5CF6", angle: 150,
      els: [
        { id: uid(), type: "text", x: 270, y: 190, text: "MONTHLY GOAL", size: 22, weight: 700, font: FONTS[0].value, align: "center", color: "#FFFFFF", spacing: 4 },
        { id: uid(), type: "text", x: 270, y: 270, text: "R5 000", size: 72, weight: 800, font: FONTS[4].value, align: "center", color: "#FFFFFF" },
        { id: uid(), type: "rect", x: 270, y: 380, w: 360, h: 22, radius: 11, color: "#FFFFFF" },
        { id: uid(), type: "rect", x: 180, y: 380, w: 180, h: 22, radius: 11, color: "#E0A536" },
      ],
    }),
  },
  {
    label: "Neon",
    make: () => ({
      kind: "landscape", bgType: "solid", bg1: "#111827", bg2: "#111827", angle: 135,
      els: [
        { id: uid(), type: "text", x: 270, y: 130, text: "LIVE NOW", size: 40, weight: 800, font: FONTS[4].value, align: "center", color: "#EC4899", glow: true, spacing: 3 },
        { id: uid(), type: "line", x: 270, y: 175, w: 300, thickness: 4, color: "#8B5CF6" },
        { id: uid(), type: "text", x: 270, y: 210, text: "Drop a tip in the jar", size: 20, weight: 600, font: FONTS[0].value, align: "center", color: "#FFFFFF" },
      ],
    }),
  },
];

export function StudioEditor({ token }: { token: string | null }) {
  const [state, setState] = useState<CanvasState>(DEFAULT_STATE);
  const [selected, setSelected] = useState<string | null>(null);
  const [gallery, setGallery] = useState<StudioDesign[]>([]);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const [fmt, setFmt] = useState<"png" | "jpeg" | "webp">("png");
  const stageRef = useRef<HTMLDivElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const drag = useRef<{ id: string; dx: number; dy: number } | null>(null);
  const imgCache = useRef<Map<string, HTMLImageElement>>(new Map());

  // ── Undo / redo ───────────────────────────────────────────────────
  const stateRef = useRef(state);
  useEffect(() => {
    stateRef.current = state;
  }, [state]);
  const past = useRef<CanvasState[]>([]);
  const future = useRef<CanvasState[]>([]);
  const [, bumpHist] = useState(0);
  const snapshot = useCallback(() => {
    past.current.push(stateRef.current);
    if (past.current.length > 60) past.current.shift();
    future.current = [];
    bumpHist((n) => n + 1);
  }, []);
  const undo = useCallback(() => {
    if (!past.current.length) return;
    future.current.push(stateRef.current);
    setState(past.current.pop()!);
    setSelected(null);
    bumpHist((n) => n + 1);
  }, []);
  const redo = useCallback(() => {
    if (!future.current.length) return;
    past.current.push(stateRef.current);
    setState(future.current.pop()!);
    setSelected(null);
    bumpHist((n) => n + 1);
  }, []);

  const preset = PRESETS[state.kind];
  const logH = (preset.h / preset.w) * LOG_W;
  const sel = state.els.find((e) => e.id === selected) ?? null;

  const loadGallery = useCallback(() => {
    if (!token) return;
    api.myDesigns(token).then(setGallery).catch(() => setGallery([]));
  }, [token]);
  useEffect(loadGallery, [loadGallery]);

  const patchEl = (id: string, patch: Partial<El>) =>
    setState((s) => ({ ...s, els: s.els.map((e) => (e.id === id ? { ...e, ...patch } : e)) }));

  // ── Images ────────────────────────────────────────────────────────
  function loadImage(src: string): Promise<HTMLImageElement> {
    const cached = imgCache.current.get(src);
    if (cached?.complete) return Promise.resolve(cached);
    return new Promise((res, rej) => {
      const img = new window.Image();
      img.onload = () => {
        imgCache.current.set(src, img);
        res(img);
      };
      img.onerror = rej;
      img.src = src;
    });
  }
  async function ensureImages() {
    await Promise.all(
      state.els.filter((e) => e.type === "image" && e.src).map((e) => loadImage(e.src!).catch(() => null)),
    );
  }
  function downscale(file: File, maxSide = 720, quality = 0.72): Promise<string> {
    return new Promise((res, rej) => {
      const img = new window.Image();
      img.onload = () => {
        const scale = Math.min(1, maxSide / Math.max(img.width, img.height));
        const c = document.createElement("canvas");
        c.width = Math.max(1, Math.round(img.width * scale));
        c.height = Math.max(1, Math.round(img.height * scale));
        c.getContext("2d")!.drawImage(img, 0, 0, c.width, c.height);
        res(c.toDataURL("image/jpeg", quality));
      };
      img.onerror = rej;
      img.src = URL.createObjectURL(file);
    });
  }
  async function onUpload(file: File | undefined) {
    if (!file) return;
    setNote(null);
    try {
      const src = await downscale(file);
      const img = await loadImage(src);
      const ratio = img.naturalHeight / img.naturalWidth || 1;
      const w = 240;
      add({ id: uid(), type: "image", x: LOG_W / 2, y: logH / 2, w, h: Math.round(w * ratio), radius: 12, src, color: "#000000" });
    } catch {
      setNote("That image could not be loaded.");
    }
  }

  // ── Pointer drag ──────────────────────────────────────────────────
  function startDrag(e: React.PointerEvent, el: El) {
    e.stopPropagation();
    setSelected(el.id);
    snapshot();
    const rect = stageRef.current!.getBoundingClientRect();
    const scale = rect.width / LOG_W;
    drag.current = { id: el.id, dx: e.clientX - rect.left - el.x * scale, dy: e.clientY - rect.top - el.y * scale };
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  }
  function onMove(e: React.PointerEvent) {
    if (!drag.current) return;
    const rect = stageRef.current!.getBoundingClientRect();
    const scale = rect.width / LOG_W;
    const x = Math.max(0, Math.min(LOG_W, (e.clientX - rect.left - drag.current.dx) / scale));
    const y = Math.max(0, Math.min(logH, (e.clientY - rect.top - drag.current.dy) / scale));
    patchEl(drag.current.id, { x, y });
  }
  const endDrag = () => (drag.current = null);

  // ── Add / arrange ─────────────────────────────────────────────────
  const add = (el: El) => {
    snapshot();
    setSelected(el.id);
    setState((s) => ({ ...s, els: [...s.els, el] }));
  };
  const addText = (big = false) =>
    add({ id: uid(), type: "text", x: LOG_W / 2, y: logH / 2, text: big ? "Headline" : "New text", size: big ? 48 : 26, weight: big ? 800 : 600, font: FONTS[0].value, align: "center", color: "#FFFFFF" });
  const addShape = (type: ElType) => {
    const base = { id: uid(), x: LOG_W / 2, y: logH / 2, color: "#E0A536" } as El;
    if (type === "rect") add({ ...base, type, w: 180, h: 110, radius: 18 });
    else if (type === "circle") add({ ...base, type, w: 130, h: 130, color: "#57CE8B" });
    else if (type === "triangle") add({ ...base, type, w: 140, h: 130, color: "#3B82F6" });
    else add({ ...base, type: "line", w: 220, thickness: 6, color: "#57CE8B" });
  };
  const removeSel = useCallback(() => {
    if (!stateRef.current.els.some((e) => e.id === selected)) return;
    snapshot();
    setState((s) => ({ ...s, els: s.els.filter((e) => e.id !== selected) }));
    setSelected(null);
  }, [selected, snapshot]);
  const duplicateSel = () => {
    if (!sel) return;
    snapshot();
    const copy = { ...sel, id: uid(), x: Math.min(LOG_W, sel.x + 26), y: Math.min(logH, sel.y + 26) };
    setState((s) => ({ ...s, els: [...s.els, copy] }));
    setSelected(copy.id);
  };
  const layer = (dir: "up" | "down") => {
    if (!selected) return;
    snapshot();
    setState((s) => {
      const i = s.els.findIndex((e) => e.id === selected);
      if (i < 0) return s;
      const j = dir === "up" ? Math.min(s.els.length - 1, i + 1) : Math.max(0, i - 1);
      if (i === j) return s;
      const els = [...s.els];
      [els[i], els[j]] = [els[j], els[i]];
      return { ...s, els };
    });
  };
  const center = (axis: "x" | "y") => {
    if (!sel) return;
    snapshot();
    patchEl(sel.id, axis === "x" ? { x: LOG_W / 2 } : { y: logH / 2 });
  };
  const applyBg = (patch: Partial<CanvasState>) => {
    snapshot();
    setState((s) => ({ ...s, ...patch }));
  };
  const applyTemplate = (make: () => CanvasState) => {
    snapshot();
    setState(make());
    setSelected(null);
  };

  // ── Keyboard shortcuts ────────────────────────────────────────────
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement | null;
      if (t && (t.tagName === "INPUT" || t.tagName === "TEXTAREA")) return;
      const meta = e.ctrlKey || e.metaKey;
      if (meta && e.key.toLowerCase() === "z") {
        e.preventDefault();
        e.shiftKey ? redo() : undo();
      } else if (meta && e.key.toLowerCase() === "y") {
        e.preventDefault();
        redo();
      } else if ((e.key === "Delete" || e.key === "Backspace") && selected) {
        e.preventDefault();
        removeSel();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [selected, undo, redo, removeSel]);

  // ── Paint to canvas (export / thumbnail) ──────────────────────────
  function paint(scaleTo: number): HTMLCanvasElement {
    const c = document.createElement("canvas");
    const k = scaleTo / LOG_W;
    c.width = scaleTo;
    c.height = Math.round(logH * k);
    const ctx = c.getContext("2d")!;
    if (state.bgType === "solid" || state.bg1 === state.bg2) {
      ctx.fillStyle = state.bg1;
    } else {
      const rad = (state.angle * Math.PI) / 180;
      const len = Math.abs(Math.cos(rad)) * c.width + Math.abs(Math.sin(rad)) * c.height;
      const cx = c.width / 2, cy = c.height / 2;
      const dx = (Math.cos(rad) * len) / 2, dy = (Math.sin(rad) * len) / 2;
      const g = ctx.createLinearGradient(cx - dx, cy - dy, cx + dx, cy + dy);
      g.addColorStop(0, state.bg1);
      g.addColorStop(1, state.bg2);
      ctx.fillStyle = g;
    }
    ctx.fillRect(0, 0, c.width, c.height);

    for (const el of state.els) {
      ctx.save();
      ctx.globalAlpha = el.opacity ?? 1;
      ctx.translate(el.x * k, el.y * k);
      if (el.rotation) ctx.rotate((el.rotation * Math.PI) / 180);
      if (el.glow) {
        ctx.shadowColor = el.color;
        ctx.shadowBlur = 26 * k;
      } else if (el.shadow) {
        ctx.shadowColor = "rgba(0,0,0,0.38)";
        ctx.shadowBlur = 14 * k;
        ctx.shadowOffsetY = 7 * k;
      }
      ctx.fillStyle = el.color;
      if (el.type === "text") {
        ctx.font = `${el.italic ? "italic " : ""}${el.weight ?? 700} ${(el.size ?? 28) * k}px ${el.font ?? "system-ui, sans-serif"}`;
        ctx.textAlign = el.align ?? "center";
        ctx.textBaseline = "middle";
        try {
          (ctx as CanvasRenderingContext2D & { letterSpacing?: string }).letterSpacing = `${(el.spacing ?? 0) * k}px`;
        } catch {
          /* older browsers: ignore */
        }
        const lines = (el.text ?? "").split("\n");
        const lh = (el.size ?? 28) * k * 1.2;
        lines.forEach((ln, i) => ctx.fillText(ln, 0, (i - (lines.length - 1) / 2) * lh));
      } else if (el.type === "image") {
        const img = imgCache.current.get(el.src ?? "");
        if (img) {
          const w = (el.w ?? 100) * k, h = (el.h ?? 100) * k, r = (el.radius ?? 0) * k;
          ctx.beginPath();
          ctx.roundRect(-w / 2, -h / 2, w, h, r);
          ctx.clip();
          ctx.drawImage(img, -w / 2, -h / 2, w, h);
        }
      } else if (el.type === "rect") {
        const w = (el.w ?? 100) * k, h = (el.h ?? 100) * k, r = (el.radius ?? 0) * k;
        ctx.beginPath();
        ctx.roundRect(-w / 2, -h / 2, w, h, r);
        ctx.fill();
      } else if (el.type === "circle") {
        ctx.beginPath();
        ctx.ellipse(0, 0, ((el.w ?? 100) / 2) * k, ((el.h ?? 100) / 2) * k, 0, 0, Math.PI * 2);
        ctx.fill();
      } else if (el.type === "triangle") {
        const w = (el.w ?? 120) * k, h = (el.h ?? 120) * k;
        ctx.beginPath();
        ctx.moveTo(0, -h / 2);
        ctx.lineTo(w / 2, h / 2);
        ctx.lineTo(-w / 2, h / 2);
        ctx.closePath();
        ctx.fill();
      } else {
        const w = (el.w ?? 160) * k, t = (el.thickness ?? 6) * k;
        ctx.beginPath();
        ctx.roundRect(-w / 2, -t / 2, w, t, t / 2);
        ctx.fill();
      }
      ctx.restore();
    }
    return c;
  }

  async function download() {
    await ensureImages();
    const mime = fmt === "png" ? "image/png" : fmt === "jpeg" ? "image/jpeg" : "image/webp";
    const url = paint(preset.w).toDataURL(mime, fmt === "png" ? undefined : 0.92);
    const a = document.createElement("a");
    a.href = url;
    a.download = `tippingjar-${state.kind}.${fmt}`;
    a.click();
  }

  async function saveToGallery() {
    if (!token || busy) return;
    const canvas = JSON.stringify(state);
    if (canvas.length > MAX_CANVAS_BYTES) {
      setNote("This design is too large to save — reduce image size or count. You can still export it.");
      return;
    }
    setBusy(true);
    setNote(null);
    try {
      await ensureImages();
      const thumb = paint(280).toDataURL("image/jpeg", 0.7);
      await api.saveDesign(token, {
        title: (state.els.find((e) => e.type === "text")?.text ?? "Design").replace(/\n/g, " ").slice(0, 60),
        kind: state.kind,
        canvas,
        thumb,
      });
      setNote("Saved to your gallery.");
      loadGallery();
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Could not save the design.");
    } finally {
      setBusy(false);
    }
  }

  function loadDesign(d: StudioDesign) {
    try {
      snapshot();
      const next = normalize(JSON.parse(d.canvas));
      next.els.forEach((e) => e.type === "image" && e.src && loadImage(e.src).catch(() => null));
      setState(next);
      setSelected(null);
    } catch {
      setNote("That design could not be loaded.");
    }
  }

  async function removeDesign(id: string) {
    if (!token) return;
    await api.deleteDesign(token, id).catch(() => null);
    setGallery((g) => g.filter((d) => d.id !== id));
  }

  // ── Element render (preview) ──────────────────────────────────────
  function renderEl(el: El) {
    const s = 100 / LOG_W;
    const ring = el.id === selected;
    const glowFilter = el.glow ? `drop-shadow(0 0 12px ${el.color})` : el.shadow ? "drop-shadow(0 6px 12px rgba(0,0,0,0.38))" : undefined;
    const common: React.CSSProperties = {
      left: `${el.x * s}%`,
      top: `${(el.y / logH) * 100}%`,
      transform: `translate(-50%, -50%) rotate(${el.rotation ?? 0}deg)`,
      opacity: el.opacity ?? 1,
      filter: glowFilter,
    };
    const onDown = (e: React.PointerEvent) => startDrag(e, el);
    if (el.type === "text") {
      return (
        <div
          key={el.id}
          onPointerDown={onDown}
          className="el-in absolute cursor-move px-1 transition-shadow"
          style={{
            ...common,
            color: el.color,
            fontWeight: el.weight ?? 700,
            fontStyle: el.italic ? "italic" : "normal",
            fontFamily: el.font ?? "system-ui, sans-serif",
            textAlign: el.align ?? "center",
            whiteSpace: "pre",
            lineHeight: 1.15,
            letterSpacing: `calc(${((el.spacing ?? 0) / LOG_W) * 100} * 1cqw)`,
            fontSize: `calc(${((el.size ?? 28) / LOG_W) * 100} * 1cqw)`,
            boxShadow: ring ? "0 0 0 2px #57CE8B" : undefined,
            borderRadius: 4,
          }}
        >
          {el.text}
        </div>
      );
    }
    if (el.type === "image") {
      return (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          key={el.id}
          src={el.src}
          alt=""
          draggable={false}
          onPointerDown={onDown}
          className="el-in absolute cursor-move object-cover"
          style={{
            ...common,
            width: `${(el.w ?? 100) * s}%`,
            aspectRatio: `${el.w ?? 100} / ${el.h ?? 100}`,
            borderRadius: `${((el.radius ?? 0) / (el.w ?? 100)) * 100}%`,
            boxShadow: ring ? "0 0 0 2px #57CE8B" : undefined,
          }}
        />
      );
    }
    if (el.type === "line") {
      return (
        <div
          key={el.id}
          onPointerDown={onDown}
          className="el-in absolute cursor-move"
          style={{
            ...common,
            width: `${(el.w ?? 160) * s}%`,
            height: `calc(${((el.thickness ?? 6) / LOG_W) * 100} * 1cqw)`,
            background: el.color,
            borderRadius: 999,
            boxShadow: ring ? "0 0 0 2px #57CE8B" : undefined,
          }}
        />
      );
    }
    const clip = el.type === "triangle" ? "polygon(50% 0, 100% 100%, 0 100%)" : undefined;
    return (
      <div
        key={el.id}
        onPointerDown={onDown}
        className="el-in absolute cursor-move"
        style={{
          ...common,
          width: `${(el.w ?? 100) * s}%`,
          aspectRatio: `${el.w ?? 100} / ${el.h ?? 100}`,
          background: el.color,
          borderRadius: el.type === "circle" ? "50%" : el.type === "rect" ? `${((el.radius ?? 0) / (el.w ?? 100)) * 100}%` : 0,
          clipPath: clip,
          boxShadow: ring && el.type !== "triangle" ? "0 0 0 2px #57CE8B" : undefined,
          outline: ring && el.type === "triangle" ? "2px solid #57CE8B" : undefined,
        }}
      />
    );
  }

  const iconBtn =
    "grid h-9 w-9 place-items-center rounded-lg border border-border bg-white text-ink transition-all hover:border-teal hover:text-teal disabled:cursor-not-allowed disabled:opacity-40";
  const toolBtn =
    "inline-flex items-center gap-1.5 rounded-xl border border-border bg-white px-3 py-2 text-xs font-medium text-ink shadow-soft transition-all duration-200 hover:-translate-y-0.5 hover:border-teal hover:text-teal";

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="flex items-center gap-2 text-xl font-medium tracking-tight text-ink">
            <Palette className="h-5 w-5 text-teal" /> Creator Studio
          </h2>
          <p className="body-muted mt-1">
            Design share-ready promo graphics. Drag to arrange, add photos, style anything, then
            export or save to your gallery.
          </p>
        </div>
        <div className="flex items-center gap-1.5">
          <button onClick={undo} disabled={!past.current.length} className={iconBtn} title="Undo (Ctrl+Z)">
            <Undo2 className="h-4 w-4" />
          </button>
          <button onClick={redo} disabled={!future.current.length} className={iconBtn} title="Redo (Ctrl+Shift+Z)">
            <Redo2 className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-2 rounded-2xl border border-border bg-white p-2.5 shadow-soft">
        {(Object.keys(PRESETS) as Kind[]).map((k) => (
          <button
            key={k}
            onClick={() => applyBg({ kind: k })}
            className={`rounded-xl px-3 py-2 text-xs font-medium transition-all ${
              state.kind === k ? "bg-primary text-white shadow-soft" : "text-muted hover:bg-ink/5 hover:text-ink"
            }`}
            title={`${PRESETS[k].w}×${PRESETS[k].h}`}
          >
            {PRESETS[k].label}
          </button>
        ))}
        <span className="mx-1 hidden h-6 w-px bg-border sm:block" />
        <button onClick={() => addText(true)} className={toolBtn}><Heading className="h-4 w-4" /> Heading</button>
        <button onClick={() => addText(false)} className={toolBtn}><Type className="h-4 w-4" /> Text</button>
        <button onClick={() => addShape("rect")} className={toolBtn}><Square className="h-4 w-4" /> Rect</button>
        <button onClick={() => addShape("circle")} className={toolBtn}><Circle className="h-4 w-4" /> Circle</button>
        <button onClick={() => addShape("triangle")} className={toolBtn}><Triangle className="h-4 w-4" /> Triangle</button>
        <button onClick={() => addShape("line")} className={toolBtn}><Minus className="h-4 w-4" /> Line</button>
        <button onClick={() => fileRef.current?.click()} className={`${toolBtn} !border-teal/40 !text-teal`}>
          <ImagePlus className="h-4 w-4" /> Image
        </button>
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(e) => {
            onUpload(e.target.files?.[0]);
            e.target.value = "";
          }}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        {/* Stage */}
        <div className="checker grid place-items-center overflow-hidden rounded-[20px] border border-border bg-white p-6 shadow-soft">
          <div
            ref={stageRef}
            onPointerMove={onMove}
            onPointerUp={endDrag}
            onPointerLeave={endDrag}
            onPointerDown={() => setSelected(null)}
            className="relative w-full max-w-[540px] touch-none select-none overflow-hidden rounded-xl shadow-lift transition-all duration-300"
            style={{
              aspectRatio: `${preset.w} / ${preset.h}`,
              containerType: "inline-size",
              background:
                state.bgType === "solid" || state.bg1 === state.bg2
                  ? state.bg1
                  : `linear-gradient(${state.angle}deg, ${state.bg1}, ${state.bg2})`,
            }}
          >
            {state.els.map(renderEl)}
          </div>
        </div>

        {/* Right rail */}
        <div className="space-y-4">
          {/* Templates */}
          <div className="card panel-in !p-4">
            <p className="text-xs font-medium uppercase tracking-wide text-muted">Templates</p>
            <div className="mt-2.5 grid grid-cols-4 gap-2">
              {TEMPLATES.map((t) => (
                <button
                  key={t.label}
                  onClick={() => applyTemplate(t.make)}
                  className="rounded-lg border border-border bg-white px-2 py-2 text-[11px] font-medium text-muted transition-all hover:-translate-y-0.5 hover:border-teal hover:text-teal"
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>

          {/* Background */}
          <div className="card panel-in !p-4">
            <div className="flex items-center justify-between">
              <p className="text-xs font-medium uppercase tracking-wide text-muted">Background</p>
              <div className="flex gap-1">
                {(["solid", "gradient"] as BgType[]).map((b) => (
                  <button
                    key={b}
                    onClick={() => applyBg({ bgType: b, ...(b === "gradient" && state.bg1 === state.bg2 ? { bg2: "#12A25C" } : {}) })}
                    className={`rounded-md px-2 py-0.5 text-[11px] font-medium capitalize transition-colors ${
                      state.bgType === b ? "bg-primary text-white" : "text-muted hover:text-ink"
                    }`}
                  >
                    {b}
                  </button>
                ))}
              </div>
            </div>

            <div className="mt-3 flex flex-wrap gap-1.5">
              {BG_SOLIDS.map((cc) => (
                <button
                  key={cc}
                  onClick={() => applyBg({ bgType: "solid", bg1: cc, bg2: cc })}
                  className="h-6 w-6 rounded-md border border-border transition-transform hover:scale-110"
                  style={{ background: cc, outline: state.bgType === "solid" && state.bg1 === cc ? "2px solid var(--green)" : undefined, outlineOffset: 1 }}
                  aria-label={`Background ${cc}`}
                />
              ))}
            </div>

            <p className="mt-3 text-[11px] font-medium text-muted">Gradients</p>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {BG_GRADS.map(([a, b, ang], i) => (
                <button
                  key={i}
                  onClick={() => applyBg({ bgType: "gradient", bg1: a, bg2: b, angle: ang })}
                  className="h-7 w-7 rounded-md border border-border transition-transform hover:scale-110"
                  style={{ background: `linear-gradient(${ang}deg, ${a}, ${b})` }}
                  aria-label="Gradient preset"
                />
              ))}
            </div>

            <div className="mt-3 flex items-center gap-2">
              <input type="color" value={state.bg1} onFocus={snapshot} onChange={(e) => setState((s) => ({ ...s, bg1: e.target.value }))} className="h-8 w-9 cursor-pointer rounded border border-border" aria-label="Colour 1" />
              {state.bgType === "gradient" && (
                <input type="color" value={state.bg2} onFocus={snapshot} onChange={(e) => setState((s) => ({ ...s, bg2: e.target.value }))} className="h-8 w-9 cursor-pointer rounded border border-border" aria-label="Colour 2" />
              )}
              {state.bgType === "gradient" && (
                <label className="flex flex-1 items-center gap-2 text-[11px] text-muted">
                  Angle
                  <input type="range" min={0} max={360} value={state.angle} onPointerDown={snapshot} onChange={(e) => setState((s) => ({ ...s, angle: Number(e.target.value) }))} className="tip-range" />
                </label>
              )}
            </div>
          </div>

          {/* Selected element */}
          {sel ? (
            <div className="card panel-in space-y-3 !p-4">
              <div className="flex items-center justify-between">
                <p className="text-xs font-medium uppercase tracking-wide text-muted">
                  {sel.type === "text" ? "Text" : sel.type}
                </p>
                <div className="flex gap-1">
                  <button onClick={() => layer("down")} className={iconBtn} title="Send back"><SendToBack className="h-4 w-4" /></button>
                  <button onClick={() => layer("up")} className={iconBtn} title="Bring forward"><BringToFront className="h-4 w-4" /></button>
                  <button onClick={duplicateSel} className={iconBtn} title="Duplicate"><Copy className="h-4 w-4" /></button>
                  <button onClick={removeSel} className="grid h-9 w-9 place-items-center rounded-lg border border-red-200 text-red-500 transition-colors hover:bg-red-50" title="Delete"><Trash2 className="h-4 w-4" /></button>
                </div>
              </div>

              {sel.type === "text" && (
                <>
                  <textarea
                    value={sel.text ?? ""}
                    onChange={(e) => patchEl(sel.id, { text: e.target.value })}
                    rows={2}
                    className="w-full resize-none rounded-lg border border-border bg-white px-3 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
                  />
                  <div className="flex flex-wrap gap-1.5">
                    {FONTS.map((f) => (
                      <button
                        key={f.label}
                        onClick={() => { snapshot(); patchEl(sel.id, { font: f.value }); }}
                        className={`rounded-md border px-2 py-1 text-[11px] font-medium transition-colors ${
                          sel.font === f.value ? "border-teal bg-teal/10 text-teal" : "border-border text-muted hover:text-ink"
                        }`}
                        style={{ fontFamily: f.value }}
                      >
                        {f.label}
                      </button>
                    ))}
                  </div>
                  <div className="flex items-center gap-1.5">
                    <button onClick={() => { snapshot(); patchEl(sel.id, { align: "left" }); }} className={`${iconBtn} ${sel.align === "left" ? "border-teal text-teal" : ""}`} title="Align left"><AlignLeft className="h-4 w-4" /></button>
                    <button onClick={() => { snapshot(); patchEl(sel.id, { align: "center" }); }} className={`${iconBtn} ${sel.align === "center" ? "border-teal text-teal" : ""}`} title="Align center"><AlignCenter className="h-4 w-4" /></button>
                    <button onClick={() => { snapshot(); patchEl(sel.id, { align: "right" }); }} className={`${iconBtn} ${sel.align === "right" ? "border-teal text-teal" : ""}`} title="Align right"><AlignRight className="h-4 w-4" /></button>
                    <button onClick={() => { snapshot(); patchEl(sel.id, { italic: !sel.italic }); }} className={`${iconBtn} ${sel.italic ? "border-teal text-teal" : ""}`} title="Italic"><Italic className="h-4 w-4" /></button>
                  </div>
                  <label className="block text-xs text-muted">
                    Size
                    <input type="range" min={12} max={140} value={sel.size ?? 28} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { size: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">
                    Weight
                    <input type="range" min={300} max={900} step={100} value={sel.weight ?? 700} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { weight: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">
                    Letter spacing
                    <input type="range" min={-4} max={24} value={sel.spacing ?? 0} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { spacing: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                </>
              )}

              {(sel.type === "rect" || sel.type === "circle" || sel.type === "triangle" || sel.type === "image") && (
                <label className="block text-xs text-muted">
                  Size
                  <input
                    type="range"
                    min={24}
                    max={500}
                    value={sel.w ?? 100}
                    onPointerDown={snapshot}
                    onChange={(e) => {
                      const w = Number(e.target.value);
                      const ratio = (sel.h ?? 100) / (sel.w ?? 100);
                      patchEl(sel.id, { w, h: Math.round(w * ratio) });
                    }}
                    className="tip-range mt-1"
                  />
                </label>
              )}
              {(sel.type === "rect" || sel.type === "image") && (
                <label className="block text-xs text-muted">
                  Corner radius
                  <input type="range" min={0} max={140} value={sel.radius ?? 0} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { radius: Number(e.target.value) })} className="tip-range mt-1" />
                </label>
              )}
              {sel.type === "line" && (
                <>
                  <label className="block text-xs text-muted">
                    Length
                    <input type="range" min={40} max={520} value={sel.w ?? 160} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { w: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">
                    Thickness
                    <input type="range" min={2} max={40} value={sel.thickness ?? 6} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { thickness: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                </>
              )}

              {/* Effects */}
              <label className="flex items-center gap-1.5 text-xs text-muted">
                <Droplet className="h-3.5 w-3.5" /> Opacity
                <input type="range" min={10} max={100} value={Math.round((sel.opacity ?? 1) * 100)} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { opacity: Number(e.target.value) / 100 })} className="tip-range mt-1" />
              </label>
              <label className="flex items-center gap-1.5 text-xs text-muted">
                <RotateCw className="h-3.5 w-3.5" /> Rotation
                <input type="range" min={-180} max={180} value={sel.rotation ?? 0} onPointerDown={snapshot} onChange={(e) => patchEl(sel.id, { rotation: Number(e.target.value) })} className="tip-range mt-1" />
              </label>
              <div className="flex flex-wrap items-center gap-1.5">
                <button onClick={() => { snapshot(); patchEl(sel.id, { shadow: !sel.shadow, glow: false }); }} className={`inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[11px] font-medium transition-colors ${sel.shadow ? "border-teal bg-teal/10 text-teal" : "border-border text-muted hover:text-ink"}`}>
                  <Contrast className="h-3.5 w-3.5" /> Shadow
                </button>
                <button onClick={() => { snapshot(); patchEl(sel.id, { glow: !sel.glow, shadow: false }); }} className={`inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-[11px] font-medium transition-colors ${sel.glow ? "border-teal bg-teal/10 text-teal" : "border-border text-muted hover:text-ink"}`}>
                  <Sparkles className="h-3.5 w-3.5" /> Glow
                </button>
                <button onClick={() => center("x")} className={`${iconBtn} ml-auto`} title="Center horizontally"><MoveHorizontal className="h-4 w-4" /></button>
                <button onClick={() => center("y")} className={iconBtn} title="Center vertically"><MoveVertical className="h-4 w-4" /></button>
              </div>

              {sel.type !== "image" && (
                <div className="flex flex-wrap gap-1.5 border-t border-border pt-3">
                  {SWATCHES.map((cc) => (
                    <button
                      key={cc}
                      onClick={() => { snapshot(); patchEl(sel.id, { color: cc }); }}
                      className="h-6 w-6 rounded-full border border-border transition-transform hover:scale-110"
                      style={{ background: cc, outline: sel.color === cc ? "2px solid var(--green)" : undefined, outlineOffset: 1 }}
                      aria-label={`Colour ${cc}`}
                    />
                  ))}
                  <input type="color" value={sel.color} onFocus={snapshot} onChange={(e) => patchEl(sel.id, { color: e.target.value })} className="h-6 w-8 cursor-pointer rounded border border-border" aria-label="Custom colour" />
                </div>
              )}
            </div>
          ) : (
            <div className="card panel-in grid place-items-center py-8 text-center !p-4">
              <MousePointerClick className="h-6 w-6 text-muted/50" />
              <p className="mt-2 text-xs text-muted">Select an element to edit it, or add one from the toolbar.</p>
            </div>
          )}

          {/* Export / save */}
          <div className="card space-y-2.5 !p-4">
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium uppercase tracking-wide text-muted">Export</span>
              <div className="ml-auto flex rounded-lg border border-border p-0.5">
                {(["png", "jpeg", "webp"] as const).map((f) => (
                  <button
                    key={f}
                    onClick={() => setFmt(f)}
                    className={`rounded-md px-2 py-0.5 text-[11px] font-medium uppercase transition-colors ${fmt === f ? "bg-primary text-white" : "text-muted hover:text-ink"}`}
                  >
                    {f}
                  </button>
                ))}
              </div>
            </div>
            <button onClick={download} className="btn-primary w-full !py-2.5 !font-medium text-sm">
              <Download className="h-4 w-4" /> Download {fmt.toUpperCase()}
            </button>
            <button onClick={saveToGallery} disabled={!token || busy} className="btn-ghost w-full !py-2.5 !font-medium text-sm disabled:cursor-not-allowed disabled:opacity-50">
              <CloudUpload className="h-4 w-4" /> {busy ? "Saving…" : "Save to gallery"}
            </button>
            {note && <p className="text-center text-xs text-teal">{note}</p>}
          </div>
        </div>
      </div>

      {/* Gallery */}
      <div>
        <h3 className="mb-3 text-base font-medium text-ink">Your gallery</h3>
        {gallery.length === 0 ? (
          <div className="card grid place-items-center py-10 text-center">
            <span className="grid h-14 w-14 place-items-center rounded-2xl bg-teal/10 text-teal">
              <ImageIcon className="h-7 w-7" strokeWidth={2} />
            </span>
            <p className="mt-4 font-medium text-ink">No saved designs yet</p>
            <p className="body-muted mt-1">Design something above and save it to your gallery.</p>
          </div>
        ) : (
          <div className="stagger grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
            {gallery.map((d) => (
              <div key={d.id} className="card group relative overflow-hidden !p-2 transition-all duration-300 hover:-translate-y-1 hover:shadow-lift">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={d.thumb || undefined}
                  alt={d.title || d.kind}
                  className="w-full cursor-pointer rounded-lg transition-transform duration-300 group-hover:scale-[1.03]"
                  onClick={() => loadDesign(d)}
                />
                <div className="mt-1.5 flex items-center justify-between px-1">
                  <span className="truncate text-xs font-medium text-ink">{d.title || d.kind}</span>
                  <button onClick={() => removeDesign(d.id)} className="text-muted transition-colors hover:text-red-500" aria-label="Delete design">
                    <Trash2 className="h-3.5 w-3.5" />
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
