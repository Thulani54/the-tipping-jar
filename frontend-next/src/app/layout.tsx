import type { Metadata } from "next";
import { Manrope, Space_Mono } from "next/font/google";
import "bootstrap-icons/font/bootstrap-icons.css";
import "./globals.css";
import { AuthProvider } from "@/lib/auth";
import { SiteFrame } from "@/components/SiteFrame";

// Manrope — a clean geometric grotesque — is the site typeface for both body
// text and headings. Space Mono stays for the monospaced voice (receipt slips,
// eyebrow labels, code samples).
const sans = Manrope({
  subsets: ["latin"],
  variable: "--font-sans",
  weight: ["400", "500", "600", "700", "800"],
  display: "swap",
});
const mono = Space_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  weight: ["400", "700"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Tipping Jar — Support that adds up",
  description:
    "The fan-tipping platform for African creators. Drop a tip, fill the jar, and turn appreciation into steady support.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${sans.variable} ${mono.variable}`}>
      <body className="min-h-screen bg-darker font-sans text-ink antialiased">
        <AuthProvider>
          <SiteFrame>{children}</SiteFrame>
        </AuthProvider>
      </body>
    </html>
  );
}
