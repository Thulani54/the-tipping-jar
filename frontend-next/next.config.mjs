/** @type {import('next').NextConfig} */

// The temporary plain-HTTP IP preview (http://<ip>:9001) sets PREVIEW_HTTP=1 at
// build time. In that mode only, we omit HSTS and `upgrade-insecure-requests`
// so same-origin http API calls aren't force-upgraded to https (there is no TLS
// on the preview port). Every normal/production build keeps both controls.
const isHttpPreview = process.env.PREVIEW_HTTP === "1";

const cspBase = "frame-ancestors 'none'; object-src 'none'; base-uri 'self'";

const securityHeaders = [
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=()",
  },
  {
    key: "Content-Security-Policy",
    value: isHttpPreview ? cspBase : `${cspBase}; upgrade-insecure-requests`,
  },
  // HSTS only on real (HTTPS) builds — it is ignored over plain HTTP anyway.
  ...(isHttpPreview
    ? []
    : [
        {
          key: "Strict-Transport-Security",
          value: "max-age=31536000; includeSubDomains",
        },
      ]),
];

const nextConfig = {
  // Standalone output → small self-contained server for the Docker image.
  output: "standalone",
  reactStrictMode: true,
  images: {
    remotePatterns: [{ protocol: "https", hostname: "**" }],
  },
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
