"use client";

// Creator Studio — web port of frontend/lib/screens/studio_tab.dart.
// A promo-graphic editor: canvas presets, text + shape elements you can drag
// and style, PNG export, and a gallery persisted to the Rust creators service
// (/creators/studio/designs).

import { useCallback, useEffect, useRef, useState } from "react";
import { api } from "@/lib/api";
import type { StudioDesign } from "@/types";

const LOG_W = 540; // logical canvas width — matches the Flutter editor

type Kind = "square" | "portrait" | "story" | "landscape";
const PRESETS: Record<Kind, { label: string; w: number; h: number }> = {
  square: { label: "Square", w: 1080, h: 1080 },
  portrait: { label: "Portrait", w: 1080, h: 1350 },
  story: { label: "Story", w: 1080, h: 1920 },
  landscape: { label: "Landscape", w: 1920, h: 1080 },
};

type El = {
  id: string;
  type: "text" | "rect" | "circle";
  x: number; // logical px, element centre
  y: number;
  text?: string;
  size?: number; // font size (text) in logical px
  weight?: number;
  w?: number; // shapes
  h?: number;
  radius?: number;
  color: string;
};

type CanvasState = {
  kind: Kind;
  bg1: string;
  bg2: string; // same as bg1 → solid
  els: El[];
};

const uid = () => Math.random().toString(36).slice(2, 9);

const DEFAULT_STATE: CanvasState = {
  kind: "square",
  bg1: "#0F2439",
  bg2: "#12A25C",
  els: [
    { id: uid(), type: "text", x: 270, y: 220, text: "Support my work", size: 42, weight: 800, color: "#FFFFFF" },
    { id: uid(), type: "text", x: 270, y: 300, text: "tippingjar.co.za/creator/you", size: 20, weight: 500, color: "#57CE8B" },
  ],
};

const SWATCHES = ["#FFFFFF", "#0F2439", "#12A25C", "#57CE8B", "#E0A536", "#EF4444", "#3B82F6", "#000000"];

export function StudioEditor({ token }: { token: string | null }) {
  const [state, setState] = useState<CanvasState>(DEFAULT_STATE);
  const [selected, setSelected] = useState<string | null>(null);
  const [gallery, setGallery] = useState<StudioDesign[]>([]);
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const drag = useRef<{ id: string; dx: number; dy: number } | null>(null);

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

  // ── Pointer drag ──────────────────────────────────────────────────
  function startDrag(e: React.PointerEvent, el: El) {
    e.stopPropagation();
    setSelected(el.id);
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

  // ── Add / remove elements ─────────────────────────────────────────
  const addText = () =>
    setState((s) => {
      const el: El = { id: uid(), type: "text", x: LOG_W / 2, y: logH / 2, text: "New text", size: 28, weight: 700, color: "#FFFFFF" };
      setSelected(el.id);
      return { ...s, els: [...s.els, el] };
    });
  const addShape = (type: "rect" | "circle") =>
    setState((s) => {
      const el: El =
        type === "rect"
          ? { id: uid(), type, x: LOG_W / 2, y: logH / 2, w: 180, h: 100, radius: 16, color: "#E0A536" }
          : { id: uid(), type, x: LOG_W / 2, y: logH / 2, w: 120, h: 120, color: "#57CE8B" };
      setSelected(el.id);
      return { ...s, els: [...s.els, el] };
    });
  const removeSel = () => {
    if (!selected) return;
    setState((s) => ({ ...s, els: s.els.filter((e) => e.id !== selected) }));
    setSelected(null);
  };

  // ── Render to a real canvas (export + thumbnail) ──────────────────
  function paint(scaleTo: number): HTMLCanvasElement {
    const c = document.createElement("canvas");
    const k = scaleTo / LOG_W;
    c.width = scaleTo;
    c.height = Math.round(logH * k);
    const ctx = c.getContext("2d")!;
    if (state.bg1 === state.bg2) {
      ctx.fillStyle = state.bg1;
    } else {
      const g = ctx.createLinearGradient(0, 0, c.width, c.height);
      g.addColorStop(0, state.bg1);
      g.addColorStop(1, state.bg2);
      ctx.fillStyle = g;
    }
    ctx.fillRect(0, 0, c.width, c.height);
    for (const el of state.els) {
      if (el.type === "text") {
        ctx.fillStyle = el.color;
        ctx.font = `${el.weight ?? 700} ${(el.size ?? 28) * k}px system-ui, -apple-system, sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText(el.text ?? "", el.x * k, el.y * k);
      } else if (el.type === "rect") {
        ctx.fillStyle = el.color;
        const w = (el.w ?? 100) * k;
        const h = (el.h ?? 100) * k;
        const r = (el.radius ?? 0) * k;
        const x = el.x * k - w / 2;
        const y = el.y * k - h / 2;
        ctx.beginPath();
        ctx.roundRect(x, y, w, h, r);
        ctx.fill();
      } else {
        ctx.fillStyle = el.color;
        ctx.beginPath();
        ctx.ellipse(el.x * k, el.y * k, ((el.w ?? 100) / 2) * k, ((el.h ?? 100) / 2) * k, 0, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    return c;
  }

  function download() {
    const png = paint(preset.w).toDataURL("image/png");
    const a = document.createElement("a");
    a.href = png;
    a.download = `tipping-jar-${state.kind}.png`;
    a.click();
  }

  async function saveToGallery() {
    if (!token || busy) return;
    setBusy(true);
    setNote(null);
    try {
      const thumb = paint(270).toDataURL("image/png");
      await api.saveDesign(token, {
        title: (state.els.find((e) => e.type === "text")?.text ?? "Design").slice(0, 60),
        kind: state.kind,
        canvas: JSON.stringify(state),
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
      const parsed = JSON.parse(d.canvas) as CanvasState;
      if (parsed && Array.isArray(parsed.els)) {
        setState({ ...DEFAULT_STATE, ...parsed });
        setSelected(null);
      }
    } catch {
      setNote("That design could not be loaded.");
    }
  }

  async function removeDesign(id: string) {
    if (!token) return;
    await api.deleteDesign(token, id).catch(() => null);
    setGallery((g) => g.filter((d) => d.id !== id));
  }

  const chipCls = (active: boolean) =>
    `rounded-full px-3 py-1.5 text-xs font-semibold transition ${
      active ? "bg-primary text-white" : "border border-border text-muted hover:text-ink"
    }`;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-extrabold tracking-tight text-ink">Creator Studio</h2>
        <p className="body-muted mt-1">
          Design share-ready promo graphics for your tip page. Saved designs live in your
          gallery on every device.
        </p>
      </div>

      {/* Size presets + element tools */}
      <div className="flex flex-wrap items-center gap-2">
        {(Object.keys(PRESETS) as Kind[]).map((k) => (
          <button key={k} onClick={() => setState((s) => ({ ...s, kind: k }))} className={chipCls(state.kind === k)}>
            {PRESETS[k].label}
          </button>
        ))}
        <span className="mx-1 h-5 w-px bg-border" />
        <button onClick={addText} className={chipCls(false)}>
          <i className="bi bi-type" /> Text
        </button>
        <button onClick={() => addShape("rect")} className={chipCls(false)}>
          <i className="bi bi-square-fill" /> Rect
        </button>
        <button onClick={() => addShape("circle")} className={chipCls(false)}>
          <i className="bi bi-circle-fill" /> Circle
        </button>
        {sel && (
          <button onClick={removeSel} className="rounded-full border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-500 hover:bg-red-50">
            <i className="bi bi-trash" /> Delete
          </button>
        )}
      </div>

      <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
        {/* Stage */}
        <div className="card grid place-items-center !p-6">
          <div
            ref={stageRef}
            onPointerMove={onMove}
            onPointerUp={endDrag}
            onPointerDown={() => setSelected(null)}
            className="relative w-full max-w-[540px] touch-none select-none overflow-hidden rounded-xl shadow-lift"
            style={{
              aspectRatio: `${preset.w} / ${preset.h}`,
              containerType: "inline-size",
              background:
                state.bg1 === state.bg2
                  ? state.bg1
                  : `linear-gradient(135deg, ${state.bg1}, ${state.bg2})`,
            }}
          >
            {state.els.map((el) => {
              const scale = 100 / LOG_W; // percentages of stage width
              const common = {
                left: `${el.x * scale}%`,
                top: `${(el.y / logH) * 100}%`,
                transform: "translate(-50%, -50%)",
              } as React.CSSProperties;
              const ring = el.id === selected ? "0 0 0 2px #57CE8B" : undefined;
              if (el.type === "text") {
                return (
                  <div
                    key={el.id}
                    onPointerDown={(e) => startDrag(e, el)}
                    className="absolute cursor-move whitespace-nowrap px-1"
                    style={{
                      ...common,
                      color: el.color,
                      fontWeight: el.weight ?? 700,
                      fontSize: `calc(${((el.size ?? 28) / LOG_W) * 100} * 1cqw)`,
                      boxShadow: ring,
                      borderRadius: 4,
                    }}
                  >
                    {el.text}
                  </div>
                );
              }
              return (
                <div
                  key={el.id}
                  onPointerDown={(e) => startDrag(e, el)}
                  className="absolute cursor-move"
                  style={{
                    ...common,
                    width: `${(el.w ?? 100) * scale}%`,
                    aspectRatio: `${el.w ?? 100} / ${el.h ?? 100}`,
                    background: el.color,
                    borderRadius: el.type === "circle" ? "50%" : `${((el.radius ?? 0) / (el.w ?? 100)) * 100}%`,
                    boxShadow: ring,
                  }}
                />
              );
            })}
          </div>
        </div>

        {/* Props + actions */}
        <div className="space-y-4">
          <div className="card !p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-muted">Background</p>
            <div className="mt-2 flex items-center gap-2">
              <input type="color" value={state.bg1} onChange={(e) => setState((s) => ({ ...s, bg1: e.target.value }))} className="h-8 w-10 cursor-pointer rounded border border-border" aria-label="Background start colour" />
              <input type="color" value={state.bg2} onChange={(e) => setState((s) => ({ ...s, bg2: e.target.value }))} className="h-8 w-10 cursor-pointer rounded border border-border" aria-label="Background end colour" />
              <button onClick={() => setState((s) => ({ ...s, bg2: s.bg1 }))} className="ml-auto text-xs font-semibold text-muted hover:text-ink">
                Solid
              </button>
            </div>
          </div>

          {sel && (
            <div className="card space-y-3 !p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                {sel.type === "text" ? "Text" : sel.type === "rect" ? "Rectangle" : "Circle"}
              </p>
              {sel.type === "text" && (
                <>
                  <input
                    value={sel.text ?? ""}
                    onChange={(e) => patchEl(sel.id, { text: e.target.value })}
                    className="w-full rounded-lg border border-border bg-white px-3 py-2 text-sm text-ink focus:border-primary/40 focus:outline-none"
                  />
                  <label className="block text-xs text-muted">
                    Size
                    <input type="range" min={12} max={96} value={sel.size ?? 28} onChange={(e) => patchEl(sel.id, { size: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                  <label className="block text-xs text-muted">
                    Weight
                    <input type="range" min={300} max={900} step={100} value={sel.weight ?? 700} onChange={(e) => patchEl(sel.id, { weight: Number(e.target.value) })} className="tip-range mt-1" />
                  </label>
                </>
              )}
              {sel.type !== "text" && (
                <label className="block text-xs text-muted">
                  Size
                  <input
                    type="range"
                    min={30}
                    max={400}
                    value={sel.w ?? 100}
                    onChange={(e) => {
                      const w = Number(e.target.value);
                      const ratio = (sel.h ?? 100) / (sel.w ?? 100);
                      patchEl(sel.id, { w, h: Math.round(w * ratio) });
                    }}
                    className="tip-range mt-1"
                  />
                </label>
              )}
              <div className="flex flex-wrap gap-1.5">
                {SWATCHES.map((c) => (
                  <button
                    key={c}
                    onClick={() => patchEl(sel.id, { color: c })}
                    className="h-6 w-6 rounded-full border border-border"
                    style={{ background: c, outline: sel.color === c ? "2px solid var(--green)" : undefined, outlineOffset: 1 }}
                    aria-label={`Colour ${c}`}
                  />
                ))}
                <input type="color" value={sel.color} onChange={(e) => patchEl(sel.id, { color: e.target.value })} className="h-6 w-8 cursor-pointer rounded border border-border" aria-label="Custom colour" />
              </div>
            </div>
          )}

          <div className="card space-y-2 !p-4">
            <button onClick={download} className="btn-primary w-full !py-2.5 text-sm">
              <i className="bi bi-download" /> Export PNG
            </button>
            <button onClick={saveToGallery} disabled={!token || busy} className="btn-ghost w-full !py-2.5 text-sm disabled:cursor-not-allowed disabled:opacity-50">
              {busy ? "Saving…" : <><i className="bi bi-cloud-arrow-up" /> Save to gallery</>}
            </button>
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
              <div key={d.id} className="card group relative overflow-hidden !p-2">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={d.thumb || undefined}
                  alt={d.title || d.kind}
                  className="w-full cursor-pointer rounded-lg"
                  onClick={() => loadDesign(d)}
                />
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
