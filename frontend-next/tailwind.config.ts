import type { Config } from "tailwindcss";

// Brand palette ported 1:1 from the Flutter app's theme.dart.
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        dark: "#0A0F0D",
        darker: "#060A08",
        primary: "#004423", // deep forest green
        teal: "#0097B2", // ocean teal
        blue: "#2563EB", // electric blue
        card: "#111A16",
        border: "#1E2E26",
        muted: "#7A9088",
      },
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
      },
      backgroundImage: {
        "brand-gradient": "linear-gradient(135deg, #004423 0%, #0097B2 100%)",
      },
      maxWidth: {
        content: "1200px",
      },
    },
  },
  plugins: [],
};

export default config;
