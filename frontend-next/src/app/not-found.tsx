// 404 — ported from frontend/lib/screens/not_found_screen.dart
// Next.js special file: default export, no params.

import Link from "next/link";

export default function NotFound() {
  return (
    <div className="container-content grid min-h-[70vh] place-items-center text-center">
      <div>
        <p className="bg-brand-gradient bg-clip-text text-[120px] font-black leading-none tracking-tighter text-transparent">
          404
        </p>
        <h1 className="mt-6 text-2xl font-extrabold tracking-tight text-white md:text-3xl">
          Page not found
        </h1>
        <p className="body-muted mx-auto mt-3 max-w-sm">
          The page you&apos;re looking for doesn&apos;t exist or has been moved.
        </p>
        <div className="mt-9 flex flex-wrap items-center justify-center gap-3">
          <Link href="/" className="btn-primary">
            Go home
          </Link>
          <Link href="/creators" className="btn-ghost">
            Browse creators
          </Link>
        </div>
      </div>
    </div>
  );
}
