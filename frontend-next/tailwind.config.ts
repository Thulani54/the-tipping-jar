import type { Config } from "tailwindcss";

// Palette adopted from the mycareerhand design system — a light, premium look:
// navy primary, mint + gold accents, white surfaces on a soft canvas.
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        navy: "#142A47", // deep navy
        primary: "#1E3A5F", // navy — main brand
        mint: "#72DA69", // bright mint (gradients / fills)
        gold: "#F0A73C", // gold accent
        teal: "#2F9E44", // readable green accent (links, pills) on light
        blue: "#2563EB",
        ink: "#0A0A0F", // near-black text
        muted: "#5B6472", // slate secondary text
        border: "#E5E7EB", // light hairline
        card: "#FFFFFF", // white surface
        dark: "#FFFFFF", // remapped: section surface
        darker: "#F7F7F9", // remapped: page canvas
      },
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
      },
      backgroundImage: {
        // Flat navy — no visible gradient (kept as a class so existing
        // bg-brand-gradient usages render as a solid brand fill).
        "brand-gradient": "linear-gradient(#1E3A5F, #1E3A5F)",
      },
      boxShadow: {
        soft: "0 10px 30px -14px rgba(20, 42, 71, 0.22)",
      },
      maxWidth: {
        content: "1200px",
      },
    },
  },
  plugins: [],
};

export default config;
