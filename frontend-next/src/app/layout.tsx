import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/lib/auth";
import { Nav } from "@/components/Nav";
import { Footer } from "@/components/Footer";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: "Tipping Jar — Fan tipping for creators",
  description:
    "The fan-tipping platform for African creators. Get tips, build a community, and grow your support.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
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
