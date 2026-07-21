import type { Config } from "tailwindcss";

// "The Jar Fills" — deep navy ink, fresh money-green, coin gold, porcelain.
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        navy: "#0A1728", // deepest — dark sections
        primary: "#0F2439", // navy — brand fills / buttons
        ink: "#0F2439", // text + structure
        teal: "#12A25C", // fresh money-green accent (links, pills) — legacy alias
        green: "#12A25C", // same accent, semantic name used by new components
        mint: "#57CE8B", // bright fill (the jar's support)
        gold: "#E0A536", // coin gold
        blue: "#2563EB",
        muted: "#5A6B7B", // slate secondary text
        border: "#E2E7E3", // hairline (faint cool)
        card: "#FFFFFF", // white surface
        dark: "#FFFFFF", // remapped: section surface
        darker: "#EFF2F0", // remapped: porcelain canvas
      },
      fontFamily: {
        display: ["var(--font-display)", "Georgia", "serif"],
        sans: ["var(--font-body)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "ui-monospace", "monospace"],
      },
      backgroundImage: {
        // Flat navy — kept as a class so bg-brand-gradient renders solid.
        "brand-gradient": "linear-gradient(#0F2439, #0F2439)",
      },
      boxShadow: {
        soft: "0 14px 40px -22px rgba(15, 36, 57, 0.28)",
        lift: "0 24px 60px -28px rgba(15, 36, 57, 0.38)",
      },
      maxWidth: {
        content: "1180px",
      },
    },
  },
  plugins: [],
};

export default config;
