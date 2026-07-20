/** @type {import('next').NextConfig} */
const nextConfig = {
  // Standalone output → small self-contained server for the Docker image.
  output: "standalone",
  reactStrictMode: true,
  images: {
    remotePatterns: [{ protocol: "https", hostname: "**" }],
  },
};

export default nextConfig;
