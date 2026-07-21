import type { Metadata } from "next";
import { Bricolage_Grotesque, Hanken_Grotesk, Space_Mono } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/lib/auth";
import { Nav } from "@/components/Nav";
import { Footer } from "@/components/Footer";

// Display: characterful contemporary grotesque. Body: warm, readable grotesque.
// Mono: the tip-slip / receipt voice.
const display = Bricolage_Grotesque({
  subsets: ["latin"],
  variable: "--font-display",
  weight: ["500", "600", "700", "800"],
});
const body = Hanken_Grotesk({
  subsets: ["latin"],
  variable: "--font-body",
  weight: ["400", "500", "600", "700"],
});
const mono = Space_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  weight: ["400", "700"],
});

export const metadata: Metadata = {
  title: "Tipping Jar — Support that adds up",
  description:
    "The fan-tipping platform for African creators. Drop a tip, fill the jar, and turn appreciation into steady support.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${display.variable} ${body.variable} ${mono.variable}`}
    >
      <body className="min-h-screen bg-darker font-sans text-ink antialiased">
        <AuthProvider>
          <Nav />
          <main className="min-h-[70vh]">{children}</main>
          <Footer />
        </AuthProvider>
      </body>
    </html>
  );
}
